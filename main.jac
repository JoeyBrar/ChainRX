"""ChainRX: Drug interaction chain detector. Orchestrator, API, and frontend."""

import from graph { Drug, InteractsWith }
import from data { DRUG_INTERACTIONS }
import from rules { RISK_THRESHOLD }
import from walkers { ChainWalker, reset_collector, get_collected_chains }

cl import from react { useState, useEffect, useCallback }
cl import from .components.DrugSelector { DrugSelector }
cl import from .components.ResultCard { ResultCard }

"""Build drug graph for given medication names. Returns map of name -> node."""
def build_graph(medications: list[str]) -> dict[str, Drug] {
    drug_nodes = dict[str, Drug]();

    for med in medications {
        drug_nodes[med] = Drug(name=med);
    }

    for interaction in DRUG_INTERACTIONS {
        a = str(interaction["drug_a"]);
        b = str(interaction["drug_b"]);
        if a in drug_nodes and b in drug_nodes {
            itype = str(interaction["type"]);
            mech = str(interaction["mechanism"]);
            sev = float(interaction["severity"]);

            drug_nodes[a] +>:InteractsWith(
                interaction_type=itype,
                mechanism=mech,
                severity=sev
            ):+> drug_nodes[b];

            drug_nodes[b] +>:InteractsWith(
                interaction_type=itype,
                mechanism=mech,
                severity=sev
            ):+> drug_nodes[a];
        }
    }
    return drug_nodes;
}

"""Remove duplicate chains and sort by risk descending."""
def deduplicate_chains(all_chains: list[dict]) -> list[dict] {
    seen = set[str]();
    unique = list[dict]();
    for chain in all_chains {
        path_key = " -> ".join(chain["path"]);
        if path_key not in seen {
            seen.add(path_key);
            chain["path_str"] = path_key;
            unique.append(chain);
        }
    }
    unique.sort(key=lambda x: x["risk"], reverse=True);
    return unique;
}

"""Build human-readable explanation of compounding risk."""
def get_explanation(chain: dict) -> str {
    path = chain["path"];
    risk = float(chain["risk"]);
    depth = int(chain["depth"]);
    severity_label = "LOW";
    if risk >= 0.9 {
        severity_label = "CRITICAL";
    } elif risk >= 0.7 {
        severity_label = "HIGH";
    } elif risk >= RISK_THRESHOLD {
        severity_label = "MODERATE";
    }
    return f"[{severity_label}] {' -> '.join(path)} (risk: {risk}, depth: {depth})";
}

"""Look up the mechanism description for a pair of drugs."""
def get_mechanism(drug_a: str, drug_b: str) -> str {
    for interaction in DRUG_INTERACTIONS {
        a = str(interaction["drug_a"]);
        b = str(interaction["drug_b"]);
        if (a == drug_a and b == drug_b) or (a == drug_b and b == drug_a) {
            return str(interaction["mechanism"]);
        }
    }
    return "Direct interaction";
}

"""Core orchestrator: build graph, spawn walkers, collect results."""
def run_analysis(medications: list[str]) -> list[dict] {
    reset_collector();
    drug_nodes = build_graph(medications);

    for name in drug_nodes {
        ChainWalker(
            current_path=[],
            accumulated_risk=0.0,
            max_depth=3,
            last_interaction_type=""
        ) spawn drug_nodes[name];
    }

    all_chains = get_collected_chains();
    results = deduplicate_chains(all_chains);

    for r in results {
        r["explanation"] = get_explanation(r);
        # Add per-step mechanisms
        path = r["path"];
        mechanisms = list[str]();
        i = 0;
        while i < len(path) - 1 {
            mech = get_mechanism(str(path[i]), str(path[i + 1]));
            mechanisms.append(f"{path[i]} + {path[i+1]}: {mech}");
            i += 1;
        }
        r["mechanisms"] = mechanisms;
    }
    return results;
}

"""Get all unique drug names from the interaction dataset."""
def get_all_drugs() -> list[str] {
    drugs = set[str]();
    for interaction in DRUG_INTERACTIONS {
        drugs.add(str(interaction["drug_a"]));
        drugs.add(str(interaction["drug_b"]));
    }
    return sorted(list(drugs));
}

walker:pub check_medications {
    has medications: list[str] = [];

    can analyze with `root() entry {
        results = run_analysis(self.medications);
        report {
            "medications": self.medications,
            "flagged_chains": results,
            "total_flags": len(results),
            "threshold": RISK_THRESHOLD,
            "all_drugs": get_all_drugs()
        };
    }
}

walker:pub list_drugs {
    can fetch with `root() entry {
        report {"drugs": get_all_drugs()};
    }
}

cl {
    def ErrorBanner(msg: str) -> any {
        if not msg {
            return <span></span>;
        }
        return <div style={{
            "padding": "1rem",
            "backgroundColor": "#fef2f2",
            "border": "1px solid #fecaca",
            "borderRadius": "0.75rem",
            "color": "#dc2626",
            "marginBottom": "1rem"
        }}>{msg}</div>;
    }

    def ResultsSection(results: any) -> any {
        if results is None {
            return <span></span>;
        }
        total = results["total_flags"];
        chains = results["flagged_chains"];

        badge_bg = "#fee2e2" if total > 0 else "#dcfce7";
        badge_color = "#991b1b" if total > 0 else "#166534";

        return <div>
            <div style={{
                "display": "flex",
                "justifyContent": "space-between",
                "alignItems": "center",
                "marginBottom": "1rem"
            }}>
                <h2 style={{
                    "fontSize": "1.25rem",
                    "fontWeight": "700",
                    "color": "#0f172a"
                }}>Results</h2>
                <span style={{
                    "backgroundColor": badge_bg,
                    "color": badge_color,
                    "padding": "0.25rem 0.75rem",
                    "borderRadius": "9999px",
                    "fontSize": "0.875rem",
                    "fontWeight": "600"
                }}>{str(total)} chain(s) flagged</span>
            </div>
            {<div style={{
                "textAlign": "center",
                "padding": "3rem",
                "color": "#16a34a",
                "fontSize": "1.1rem",
                "fontWeight": "600"
            }}>No risky interaction chains detected. These medications appear safe together.</div> if total == 0 else <div>
                {[<ResultCard key={str(idx)} chain={chains[idx]} /> for idx in range(len(chains))]}
            </div>}
        </div>;
    }

    def:pub app() -> any {
        has selected_drugs: list = [];
        has results: any = None;
        has loading: bool = False;
        has all_drugs: list = [];
        has error_msg: str = "";

        async can load_drugs with entry {
            try {
                token = localStorage.getItem("jac_token");
                if not token {
                    resp = await fetch("/user/register", {
                        "method": "POST",
                        "headers": {"Content-Type": "application/json"},
                        "body": JSON.stringify({
                            "username": "user_" + str(int(Math.random() * 999999)),
                            "password": "chainrx2026"
                        })
                    });
                    reg_data = await resp.json();
                    if reg_data["ok"] {
                        token = reg_data["data"]["token"];
                        localStorage.setItem("jac_token", token);
                    }
                }
                resp2 = await fetch("/function/get_all_drugs", {
                    "method": "POST",
                    "headers": {
                        "Content-Type": "application/json",
                        "Authorization": "Bearer " + str(token)
                    },
                    "body": JSON.stringify({})
                });
                data = await resp2.json();
                if data["ok"] {
                    all_drugs = data["data"]["result"];
                }
            } except e {
                console.error("Failed to load drugs:", e);
            }
        }

        toggle_drug = useCallback(lambda drug {
            if drug in selected_drugs {
                selected_drugs = [d for d in selected_drugs if d != drug];
            } else {
                selected_drugs = selected_drugs + [drug];
            }
            results = None;
        }, [selected_drugs]);

        analyze = useCallback(lambda {
            async def do_analyze() {
                loading = True;
                error_msg = "";
                try {
                    token = localStorage.getItem("jac_token");
                    resp = await fetch("/function/run_analysis", {
                        "method": "POST",
                        "headers": {
                            "Content-Type": "application/json",
                            "Authorization": "Bearer " + str(token)
                        },
                        "body": JSON.stringify({"medications": selected_drugs})
                    });
                    data = await resp.json();
                    if data["ok"] {
                        flagged = data["data"]["result"];
                        results = {
                            "flagged_chains": flagged,
                            "total_flags": len(flagged)
                        };
                    } else {
                        error_msg = "Analysis failed";
                    }
                } except e {
                    error_msg = "Network error: " + str(e);
                }
                loading = False;
            }
            do_analyze();
        }, [selected_drugs]);

        can_analyze = len(selected_drugs) >= 2 and not loading;
        btn_bg = "#2563eb" if can_analyze else "#94a3b8";
        btn_cursor = "pointer" if can_analyze else "not-allowed";
        btn_text = "Analyzing..." if loading else "Analyze Interactions";

        return <div style={{
            "minHeight": "100vh",
            "backgroundColor": "#f8fafc",
            "fontFamily": "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
        }}>
            <div style={{
                "maxWidth": "52rem",
                "margin": "0 auto",
                "padding": "2rem 1.5rem"
            }}>
                <div style={{"textAlign": "center", "marginBottom": "2.5rem"}}>
                    <h1 style={{
                        "fontSize": "2.5rem",
                        "fontWeight": "800",
                        "color": "#0f172a",
                        "marginBottom": "0.5rem",
                        "letterSpacing": "-0.025em"
                    }}>ChainRX</h1>
                    <p style={{
                        "fontSize": "1.1rem",
                        "color": "#64748b",
                        "maxWidth": "28rem",
                        "margin": "0 auto"
                    }}>Drug interaction chain detector. Select medications to analyze compounding risk pathways.</p>
                </div>

                <div style={{
                    "backgroundColor": "#ffffff",
                    "borderRadius": "1rem",
                    "padding": "1.5rem",
                    "marginBottom": "1.5rem",
                    "boxShadow": "0 1px 3px rgba(0,0,0,0.1)"
                }}>
                    <label style={{
                        "fontSize": "0.875rem",
                        "fontWeight": "600",
                        "color": "#374151",
                        "marginBottom": "0.5rem",
                        "display": "block"
                    }}>Medications</label>
                    <DrugSelector
                        drugs={all_drugs}
                        selected={selected_drugs}
                        onToggle={toggle_drug}
                    />
                    <button
                        onClick={analyze}
                        disabled={not can_analyze}
                        style={{
                            "width": "100%",
                            "marginTop": "1rem",
                            "padding": "0.875rem",
                            "backgroundColor": btn_bg,
                            "color": "#ffffff",
                            "border": "none",
                            "borderRadius": "0.75rem",
                            "fontSize": "1rem",
                            "fontWeight": "700",
                            "cursor": btn_cursor,
                            "transition": "all 0.2s"
                        }}
                    >{btn_text}</button>
                </div>

                <ErrorBanner msg={error_msg} />
                <ResultsSection results={results} />
            </div>
        </div>;
    }
}
