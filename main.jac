"""ChainRX: Drug interaction chain detector. Orchestrator, API, and frontend."""

import from graph { Drug, InteractsWith }
import from data { DRUG_INTERACTIONS }
import from rules { RISK_THRESHOLD }
import from walkers { ChainWalker, reset_collector, get_collected_chains }

cl import from react { useState, useEffect, useCallback }
cl import from .components.DrugSelector { DrugSelector }
cl import from .components.ResultCard { ResultCard }
cl import from .components.DrugGraph { DrugGraph }

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

glob ELDERLY_MULTIPLIER: float = 1.3;

"""Core orchestrator: build graph, spawn walkers, collect results."""
def run_analysis(medications: list[str], is_elderly: bool = False) -> list[dict] {
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
        if is_elderly {
            r["risk"] = float(int(float(r["risk"]) * ELDERLY_MULTIPLIER * 1000)) / 1000.0;
            r["elderly_adjusted"] = True;
        } else {
            r["elderly_adjusted"] = False;
        }
        r["explanation"] = get_explanation(r);
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

"""Get pairwise interactions for a set of medications."""
def get_interactions_for(medications: list[str]) -> list[dict] {
    result = list[dict]();
    for interaction in DRUG_INTERACTIONS {
        a = str(interaction["drug_a"]);
        b = str(interaction["drug_b"]);
        if a in medications and b in medications {
            result.append(interaction);
        }
    }
    return result;
}

"""Given a technical summary of drug interaction chains, produce a 2-3 sentence
patient-friendly explanation that a non-medical person can understand. Mention the
specific drugs involved, what the danger is in plain language, and what action to
take (e.g. talk to your pharmacist). Do not use medical jargon. Be concise."""
def explain_for_patient(chain_summary: str) -> str by llm();

"""Generate a plain-English summary of flagged interaction chains."""
def generate_summary(flagged_chains: list[dict]) -> str {
    if len(flagged_chains) == 0 {
        return "No dangerous interaction chains were detected.";
    }
    # Build technical summary for the LLM
    lines = list[str]();
    i = 0;
    limit = 5;
    if len(flagged_chains) < limit {
        limit = len(flagged_chains);
    }
    while i < limit {
        c = flagged_chains[i];
        path_str = " -> ".join(c["path"]);
        lines.append(f"Chain: {path_str} (risk score: {c['risk']})");
        for m in c["mechanisms"] {
            lines.append(f"  - {m}");
        }
        i += 1;
    }
    summary_input = "\n".join(lines);
    try {
        return explain_for_patient(summary_input);
    } except Exception as ex {
        return f"Unable to generate summary: {str(ex)}";
    }
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

glob REGIMENS: list[dict] = [
    {"name": "Post-MI", "drugs": ["Aspirin", "Clopidogrel", "Metoprolol", "Atorvastatin", "Lisinopril"]},
    {"name": "Diabetes + HTN", "drugs": ["Metformin", "Glipizide", "Lisinopril", "Hydrochlorothiazide", "Amlodipine"]},
    {"name": "Depression + Pain", "drugs": ["Sertraline", "Tramadol", "Gabapentin", "Ibuprofen"]},
    {"name": "Afib + Anticoag", "drugs": ["Warfarin", "Amiodarone", "Digoxin", "Metoprolol"]},
    {"name": "Elderly Polypharmacy", "drugs": ["Omeprazole", "Metformin", "Lisinopril", "Amitriptyline", "Diphenhydramine", "Furosemide"]},
    {"name": "Psych Combo", "drugs": ["Fluoxetine", "Trazodone", "Alprazolam", "Lithium"]},
    {"name": "Infection + Cardiac", "drugs": ["Ciprofloxacin", "Amiodarone", "Warfarin", "Ondansetron"]},
    {"name": "Chronic Pain", "drugs": ["Oxycodone", "Gabapentin", "Diazepam", "Naproxen", "Amitriptyline"]}
];

"""Get available common regimens."""
def get_regimens() -> list[dict] {
    return REGIMENS;
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

    def ResultsSection(results: any, on_copy: any) -> any {
        if results["empty"] {
            return <span></span>;
        }
        total = results["total_flags"];
        chains = results["flagged_chains"];
        is_elderly = results["is_elderly"];

        badge_bg = "#fee2e2" if total > 0 else "#dcfce7";
        badge_color = "#991b1b" if total > 0 else "#166534";

        return <div>
            <div style={{
                "display": "flex",
                "justifyContent": "space-between",
                "alignItems": "center",
                "marginBottom": "1rem",
                "flexWrap": "wrap",
                "gap": "0.5rem"
            }}>
                <div style={{"display": "flex", "alignItems": "center", "gap": "0.75rem"}}>
                    <h2 style={{
                        "fontSize": "1.25rem",
                        "fontWeight": "700",
                        "color": "#0f172a",
                        "margin": "0"
                    }}>Results</h2>
                    {<span style={{
                        "backgroundColor": "#fef3c7",
                        "color": "#92400e",
                        "padding": "0.2rem 0.6rem",
                        "borderRadius": "9999px",
                        "fontSize": "0.75rem",
                        "fontWeight": "600"
                    }}>{"65+ adjusted"}</span> if is_elderly else <span></span>}
                </div>
                <div style={{"display": "flex", "gap": "0.5rem", "alignItems": "center"}}>
                    <span style={{
                        "backgroundColor": badge_bg,
                        "color": badge_color,
                        "padding": "0.25rem 0.75rem",
                        "borderRadius": "9999px",
                        "fontSize": "0.875rem",
                        "fontWeight": "600"
                    }}>{str(total) + " chain(s) flagged"}</span>
                    {<button
                        onClick={on_copy}
                        style={{
                            "padding": "0.25rem 0.75rem",
                            "backgroundColor": "#f1f5f9",
                            "border": "1px solid #cbd5e1",
                            "borderRadius": "0.5rem",
                            "fontSize": "0.8rem",
                            "fontWeight": "600",
                            "cursor": "pointer",
                            "color": "#475569"
                        }}
                    >{"Copy Results"}</button> if total > 0 else <span></span>}
                </div>
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

    def RegimensBar(regimens: list, on_select: any) -> any {
        if len(regimens) == 0 {
            return <span></span>;
        }
        return <div style={{
            "marginBottom": "1rem"
        }}>
            <label style={{
                "fontSize": "0.8rem",
                "fontWeight": "600",
                "color": "#6b7280",
                "marginBottom": "0.5rem",
                "display": "block",
                "textTransform": "uppercase",
                "letterSpacing": "0.05em"
            }}>{"Quick Select"}</label>
            <div style={{
                "display": "flex",
                "flexWrap": "wrap",
                "gap": "0.5rem"
            }}>
                {[
                    <button
                        key={regimens[idx]["name"]}
                        onClick={lambda e { on_select(regimens[int(e.currentTarget.dataset.idx)]["drugs"]); }}
                        data-idx={str(idx)}
                        style={{
                            "padding": "0.4rem 0.85rem",
                            "backgroundColor": "#f8fafc",
                            "border": "1px solid #e2e8f0",
                            "borderRadius": "9999px",
                            "fontSize": "0.8rem",
                            "fontWeight": "500",
                            "cursor": "pointer",
                            "color": "#334155",
                            "transition": "all 0.15s",
                            "whiteSpace": "nowrap"
                        }}
                    >{regimens[idx]["name"]}</button>
                    for idx in range(len(regimens))
                ]}
            </div>
        </div>;
    }

    def:pub app() -> any {
        has selected_drugs: list = [];
        has results: any = {"flagged_chains": [], "total_flags": 0, "is_elderly": False, "empty": True};
        has loading: bool = False;
        has all_drugs: list = [];
        has error_msg: str = "";
        has is_elderly: bool = False;
        has regimens: list = [];
        has copied: bool = False;
        has interactions: list = [];
        has summary: str = "";
        has summary_loading: bool = False;

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
                resp3 = await fetch("/function/get_regimens", {
                    "method": "POST",
                    "headers": {
                        "Content-Type": "application/json",
                        "Authorization": "Bearer " + str(token)
                    },
                    "body": JSON.stringify({})
                });
                reg = await resp3.json();
                if reg["ok"] {
                    regimens = reg["data"]["result"];
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
            results = {"flagged_chains": [], "total_flags": 0, "is_elderly": False, "empty": True};
        }, [selected_drugs]);

        select_regimen = useCallback(lambda drugs {
            selected_drugs = drugs;
            results = {"flagged_chains": [], "total_flags": 0, "is_elderly": False, "empty": True};
        }, []);

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
                        "body": JSON.stringify({
                            "medications": selected_drugs,
                            "is_elderly": is_elderly
                        })
                    });
                    data = await resp.json();
                    if data["ok"] {
                        flagged = data["data"]["result"];

                        # Fetch pairwise interactions for graph
                        resp_inter = await fetch("/function/get_interactions_for", {
                            "method": "POST",
                            "headers": {
                                "Content-Type": "application/json",
                                "Authorization": "Bearer " + str(token)
                            },
                            "body": JSON.stringify({"medications": selected_drugs})
                        });
                        inter_data = await resp_inter.json();
                        if inter_data["ok"] {
                            interactions = inter_data["data"]["result"];
                        }

                        summary = "";
                        results = {
                            "flagged_chains": flagged,
                            "total_flags": len(flagged),
                            "is_elderly": is_elderly,
                            "empty": False
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
        }, [selected_drugs, is_elderly]);

        copy_results = useCallback(lambda {
            if results["empty"] or results["total_flags"] == 0 {
                return;
            }
            chains = results["flagged_chains"];
            lines = ["ChainRX Analysis Report", "Medications: " + selected_drugs.join(", "), "Patient: " + ("65+ (elderly-adjusted)" if results["is_elderly"] else "Under 65"), ""];
            idx = 0;
            while idx < len(chains) {
                c = chains[idx];
                score = Math.min(Math.round(c["risk"] * 100) / 10, 10.0);
                label = "CRITICAL";
                if c["risk"] < 0.6 { label = "LOW"; }
                elif c["risk"] < 0.7 { label = "MODERATE"; }
                elif c["risk"] < 0.9 { label = "HIGH"; }
                lines.push("[" + label + " " + str(score) + "/10] " + c["path"].join(" -> "));
                m_idx = 0;
                while m_idx < len(c["mechanisms"]) {
                    lines.push("  Step " + str(m_idx + 1) + ": " + c["mechanisms"][m_idx]);
                    m_idx = m_idx + 1;
                }
                lines.push("");
                idx = idx + 1;
            }
            navigator.clipboard.writeText(lines.join("\n"));
            copied = True;
            setTimeout(lambda { copied = False; }, 2000);
        }, [results, selected_drugs]);

        get_summary = useCallback(lambda {
            async def do_summary() {
                summary_loading = True;
                try {
                    token = localStorage.getItem("jac_token");
                    resp = await fetch("/function/generate_summary", {
                        "method": "POST",
                        "headers": {
                            "Content-Type": "application/json",
                            "Authorization": "Bearer " + str(token)
                        },
                        "body": JSON.stringify({
                            "flagged_chains": results["flagged_chains"]
                        })
                    });
                    data = await resp.json();
                    if data["ok"] {
                        summary = data["data"]["result"];
                    } else {
                        summary = "Failed to generate summary.";
                    }
                } except e {
                    summary = "Error: " + str(e);
                }
                summary_loading = False;
            }
            do_summary();
        }, [results]);

        can_analyze = len(selected_drugs) >= 2 and not loading;
        btn_bg = "#2563eb" if can_analyze else "#94a3b8";
        btn_cursor = "pointer" if can_analyze else "not-allowed";
        btn_text = "Analyzing..." if loading else "Analyze Interactions";

        flagged = results["flagged_chains"];
        has_results = not results["empty"];
        has_flags = results["total_flags"] > 0;

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
                    <RegimensBar regimens={regimens} on_select={select_regimen} />

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

                    <div style={{
                        "display": "flex",
                        "alignItems": "center",
                        "gap": "0.75rem",
                        "marginTop": "1rem",
                        "padding": "0.75rem",
                        "backgroundColor": "#f8fafc",
                        "borderRadius": "0.75rem",
                        "border": "1px solid #e2e8f0"
                    }}>
                        <label style={{
                            "fontSize": "0.875rem",
                            "fontWeight": "600",
                            "color": "#374151",
                            "display": "flex",
                            "alignItems": "center",
                            "gap": "0.5rem",
                            "cursor": "pointer"
                        }}>
                            <input
                                type="checkbox"
                                checked={is_elderly}
                                onChange={lambda e {
                                    is_elderly = e.target.checked;
                                    results = {"flagged_chains": [], "total_flags": 0, "is_elderly": False, "empty": True};
                                }}
                                style={{
                                    "width": "1.1rem",
                                    "height": "1.1rem",
                                    "accentColor": "#2563eb",
                                    "cursor": "pointer"
                                }}
                            />
                            {"Patient is 65+"}
                        </label>
                        <span style={{
                            "fontSize": "0.8rem",
                            "color": "#6b7280"
                        }}>{"(applies 1.3x elderly risk multiplier)"}</span>
                    </div>

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

                {<div style={{
                    "textAlign": "center",
                    "padding": "0.5rem",
                    "color": "#16a34a",
                    "fontSize": "0.85rem",
                    "fontWeight": "600"
                }}>{"Copied to clipboard!"}</div> if copied else <span></span>}

                <ErrorBanner msg={error_msg} />
                {<DrugGraph
                    medications={selected_drugs}
                    interactions={interactions}
                    flagged_paths={flagged}
                /> if has_results else <span></span>}

                {<div style={{
                    "backgroundColor": "#ffffff",
                    "borderRadius": "1rem",
                    "padding": "1.25rem",
                    "marginBottom": "1.5rem",
                    "boxShadow": "0 1px 3px rgba(0,0,0,0.1)"
                }}>
                    <div style={{
                        "display": "flex",
                        "justifyContent": "space-between",
                        "alignItems": "center",
                        "marginBottom": "0.75rem"
                    }}>
                        <h3 style={{
                            "fontSize": "1rem",
                            "fontWeight": "700",
                            "color": "#0f172a",
                            "margin": "0"
                        }}>{"Plain-English Summary"}</h3>
                        <span style={{
                            "fontSize": "0.7rem",
                            "color": "#94a3b8",
                            "backgroundColor": "#f1f5f9",
                            "padding": "0.15rem 0.5rem",
                            "borderRadius": "9999px"
                        }}>{"Powered by Claude Haiku 4.5"}</span>
                    </div>
                    {<div style={{
                        "fontSize": "0.95rem",
                        "color": "#334155",
                        "lineHeight": "1.7",
                        "padding": "0.75rem",
                        "backgroundColor": "#f8fafc",
                        "borderRadius": "0.5rem",
                        "border": "1px solid #e2e8f0"
                    }}>{summary}</div> if summary else <button
                        onClick={get_summary}
                        disabled={summary_loading}
                        style={{
                            "width": "100%",
                            "padding": "0.75rem",
                            "backgroundColor": "#f8fafc",
                            "border": "1px dashed #cbd5e1",
                            "borderRadius": "0.75rem",
                            "fontSize": "0.9rem",
                            "fontWeight": "600",
                            "cursor": "pointer" if not summary_loading else "wait",
                            "color": "#475569",
                            "transition": "all 0.2s"
                        }}
                    >{("Generating summary..." if summary_loading else "Generate Patient-Friendly Summary")}</button>}
                </div> if has_flags else <span></span>}

                <ResultsSection results={results} on_copy={copy_results} />
            </div>
        </div>;
    }
}
