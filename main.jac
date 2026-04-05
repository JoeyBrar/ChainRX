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

glob FONT: str = "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif";

cl {
    def ErrorBanner(msg: str) -> any {
        if not msg { return <span></span>; }
        return <div style={{
            "padding": "12px 16px",
            "backgroundColor": "rgba(255,59,48,0.1)",
            "borderRadius": "12px",
            "color": "#ff3b30",
            "marginBottom": "12px",
            "fontSize": "14px",
            "fontWeight": "500"
        }}>{msg}</div>;
    }

    def ResultsSection(results: any, on_copy: any, theme: any) -> any {
        if results["empty"] { return <span></span>; }
        total = results["total_flags"];
        chains = results["flagged_chains"];
        is_elderly = results["is_elderly"];

        return <div>
            <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "12px"}}>
                <div style={{"display": "flex", "alignItems": "center", "gap": "8px"}}>
                    <h2 style={{"fontSize": "20px", "fontWeight": "700", "color": theme["t1"], "margin": "0", "letterSpacing": "-0.02em"}}>{"Flagged Chains"}</h2>
                    {<span style={{"backgroundColor": "rgba(255,149,0,0.15)", "color": "#ff9500", "padding": "2px 8px", "borderRadius": "6px", "fontSize": "11px", "fontWeight": "600"}}>{"65+"}</span> if is_elderly else <span></span>}
                </div>
                <div style={{"display": "flex", "gap": "8px", "alignItems": "center"}}>
                    <span style={{"fontSize": "13px", "color": theme["t2"], "fontWeight": "500"}}>{str(total) + " found"}</span>
                    {<button onClick={on_copy} style={{"padding": "6px 12px", "backgroundColor": theme["c2"], "border": "none", "borderRadius": "8px", "fontSize": "13px", "fontWeight": "500", "cursor": "pointer", "color": theme["t1"]}}>{"Copy"}</button> if total > 0 else <span></span>}
                </div>
            </div>
            {<div style={{"textAlign": "center", "padding": "48px 20px", "borderRadius": "16px", "backgroundColor": theme["c1"]}}>
                <div style={{"fontSize": "32px", "marginBottom": "8px", "color": "#34c759"}}>{"+"}</div>
                <div style={{"color": theme["t1"], "fontSize": "17px", "fontWeight": "600"}}>{"All Clear"}</div>
                <div style={{"color": theme["t2"], "fontSize": "14px", "marginTop": "4px"}}>{"No dangerous interaction chains detected."}</div>
            </div> if total == 0 else <div>
                {[<ResultCard key={str(idx)} chain={chains[idx]} /> for idx in range(len(chains))]}
            </div>}
        </div>;
    }

    def RegimensBar(regimens: list, on_select: any, theme: any) -> any {
        if len(regimens) == 0 { return <span></span>; }
        return <div style={{"marginBottom": "20px"}}>
            <div style={{"fontSize": "12px", "fontWeight": "600", "color": theme["t2"], "marginBottom": "8px", "letterSpacing": "0.02em"}}>{"PRESETS"}</div>
            <div style={{"display": "flex", "flexWrap": "wrap", "gap": "6px"}}>
                {[
                    <button
                        key={regimens[idx]["name"]}
                        onClick={lambda e { on_select(regimens[int(e.currentTarget.dataset.idx)]["drugs"]); }}
                        data-idx={str(idx)}
                        style={{
                            "padding": "6px 14px",
                            "backgroundColor": theme["c2"],
                            "border": "none",
                            "borderRadius": "20px",
                            "fontSize": "13px",
                            "fontWeight": "500",
                            "cursor": "pointer",
                            "color": theme["t1"],
                            "transition": "background-color 0.15s",
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
        has dark: bool = True;
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
                } else {
                    # Token might be stale — re-register
                    localStorage.removeItem("jac_token");
                    resp_retry = await fetch("/user/register", {
                        "method": "POST",
                        "headers": {"Content-Type": "application/json"},
                        "body": JSON.stringify({
                            "username": "user_" + str(int(Math.random() * 999999)),
                            "password": "chainrx2026"
                        })
                    });
                    retry_data = await resp_retry.json();
                    if retry_data["ok"] {
                        token = retry_data["data"]["token"];
                        localStorage.setItem("jac_token", token);
                        resp2b = await fetch("/function/get_all_drugs", {
                            "method": "POST",
                            "headers": {
                                "Content-Type": "application/json",
                                "Authorization": "Bearer " + str(token)
                            },
                            "body": JSON.stringify({})
                        });
                        data2 = await resp2b.json();
                        if data2["ok"] {
                            all_drugs = data2["data"]["result"];
                        }
                    }
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
        btn_cursor = "pointer" if can_analyze else "default";
        btn_text = "Analyzing..." if loading else "Analyze Interactions";

        flagged = results["flagged_chains"];
        has_results = not results["empty"];
        has_flags = results["total_flags"] > 0;

        document.body.style.margin = "0";
        document.body.style.padding = "0";
        document.documentElement.style.margin = "0";
        document.documentElement.style.padding = "0";

        # Theme colors
        bg = "#0a0a1a" if dark else "#ffffff";
        card_bg = "#1c1c1e" if dark else "#f5f5f7";
        card_bg2 = "#2c2c2e" if dark else "#e5e5ea";
        text1 = "#f5f5f7" if dark else "#1d1d1f";
        text2 = "#86868b";
        text3 = "#48484a" if dark else "#aeaeb2";
        border = "rgba(255,255,255,0.06)" if dark else "rgba(0,0,0,0.06)";
        input_bg = "#2c2c2e" if dark else "#ffffff";
        input_border = "rgba(255,255,255,0.1)" if dark else "rgba(0,0,0,0.08)";
        accent = "#007aff";
        disabled_bg = "#3a3a3c" if dark else "#d2d2d7";
        toggle_bg = "rgba(255,255,255,0.06)" if dark else "rgba(0,0,0,0.03)";

        return <div style={{
            "minHeight": "100vh",
            "backgroundColor": bg,
            "fontFamily": "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif",
            "color": text1,
            "WebkitFontSmoothing": "antialiased",
            "display": "flex",
            "flexDirection": "column"
        }}>
            <div style={{
                "maxWidth": "680px",
                "width": "100%",
                "margin": "0 auto",
                "padding": "0 24px",
                "boxSizing": "border-box",
                "flex": "1"
            }}>
                <div style={{
                    "display": "flex",
                    "justifyContent": "space-between",
                    "alignItems": "center",
                    "padding": "16px 0"
                }}>
                    <span style={{"fontSize": "15px", "fontWeight": "600", "color": text1, "letterSpacing": "-0.01em"}}>{"ChainRX"}</span>
                    <button
                        onClick={lambda { dark = not dark; }}
                        style={{
                            "background": toggle_bg,
                            "border": "none",
                            "borderRadius": "50%",
                            "width": "36px",
                            "height": "36px",
                            "display": "flex",
                            "alignItems": "center",
                            "justifyContent": "center",
                            "fontSize": "18px",
                            "color": text1,
                            "cursor": "pointer",
                            "transition": "background-color 0.2s"
                        }}
                    >{(String.fromCharCode(9788) if dark else String.fromCharCode(9790))}</button>
                </div>

                <div style={{
                    "textAlign": "center",
                    "padding": "40px 0 48px"
                }}>
                    <div style={{
                        "display": "inline-flex",
                        "alignItems": "center",
                        "gap": "8px",
                        "backgroundColor": toggle_bg,
                        "padding": "5px 12px",
                        "borderRadius": "20px",
                        "marginBottom": "16px"
                    }}>
                        <span style={{"width": "5px", "height": "5px", "borderRadius": "50%", "backgroundColor": "#30d158"}}></span>
                        <span style={{"fontSize": "11px", "color": text2, "fontWeight": "500", "letterSpacing": "0.04em"}}>{"JACHACKS 2026"}</span>
                    </div>
                    <h1 style={{
                        "fontSize": "48px",
                        "fontWeight": "700",
                        "color": text1,
                        "letterSpacing": "-0.04em",
                        "margin": "0 0 10px"
                    }}>{"ChainRX"}</h1>
                    <p style={{
                        "fontSize": "17px",
                        "color": text2,
                        "maxWidth": "420px",
                        "margin": "0 auto",
                        "lineHeight": "1.5",
                        "letterSpacing": "-0.01em"
                    }}>{"Detect compounding drug interaction chains that pairwise checkers miss."}</p>
                </div>

                <div style={{
                    "backgroundColor": card_bg,
                    "borderRadius": "20px",
                    "padding": "24px",
                    "marginBottom": "16px"
                }}>
                    <RegimensBar regimens={regimens} on_select={select_regimen} theme={{"t1": text1, "t2": text2, "c2": card_bg2}} />

                    <div style={{"fontSize": "12px", "fontWeight": "600", "color": text2, "marginBottom": "8px", "letterSpacing": "0.02em"}}>{"MEDICATIONS"}</div>
                    <DrugSelector
                        drugs={all_drugs}
                        selected={selected_drugs}
                        onToggle={toggle_drug}
                        card_bg={card_bg}
                    />

                    <div style={{
                        "display": "flex",
                        "alignItems": "center",
                        "justifyContent": "space-between",
                        "marginTop": "16px",
                        "padding": "10px 14px",
                        "backgroundColor": card_bg2,
                        "borderRadius": "12px"
                    }}>
                        <label style={{
                            "fontSize": "15px",
                            "fontWeight": "500",
                            "color": text1,
                            "display": "flex",
                            "alignItems": "center",
                            "gap": "8px",
                            "cursor": "pointer"
                        }}>
                            <input
                                type="checkbox"
                                checked={is_elderly}
                                onChange={lambda e {
                                    is_elderly = e.target.checked;
                                    results = {"flagged_chains": [], "total_flags": 0, "is_elderly": False, "empty": True};
                                }}
                                style={{"width": "18px", "height": "18px", "accentColor": accent, "cursor": "pointer"}}
                            />
                            {"Patient is 65+"}
                        </label>
                        <span style={{"fontSize": "13px", "color": text2}}>{"1.3x risk adjustment"}</span>
                    </div>

                    <button
                        onClick={analyze}
                        disabled={not can_analyze}
                        style={{
                            "width": "100%",
                            "marginTop": "16px",
                            "padding": "14px",
                            "backgroundColor": accent if can_analyze else disabled_bg,
                            "color": "#ffffff" if can_analyze else text3,
                            "border": "none",
                            "borderRadius": "12px",
                            "fontSize": "16px",
                            "fontWeight": "600",
                            "cursor": btn_cursor,
                            "transition": "background-color 0.2s",
                            "letterSpacing": "-0.01em"
                        }}
                    >{btn_text}</button>
                </div>

                {<div style={{"textAlign": "center", "padding": "8px", "color": "#34c759", "fontSize": "14px", "fontWeight": "500"}}>{"Copied to clipboard"}</div> if copied else <span></span>}

                <ErrorBanner msg={error_msg} />

                {<DrugGraph
                    medications={selected_drugs}
                    interactions={interactions}
                    flagged_paths={flagged}
                    is_dark={dark}
                /> if has_results else <span></span>}

                {<div style={{
                    "backgroundColor": card_bg,
                    "borderRadius": "18px",
                    "padding": "20px 24px",
                    "marginBottom": "16px"
                }}>
                    <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "12px"}}>
                        <div style={{"fontSize": "15px", "fontWeight": "600", "color": text1}}>{"AI Summary"}</div>
                        <span style={{"fontSize": "11px", "color": text2, "fontWeight": "500"}}>{"Claude Haiku 4.5"}</span>
                    </div>
                    {<div style={{
                        "fontSize": "15px",
                        "color": text2,
                        "lineHeight": "1.6",
                        "padding": "16px",
                        "backgroundColor": card_bg2,
                        "borderRadius": "12px"
                    }}>{summary}</div> if summary else <button
                        onClick={get_summary}
                        disabled={summary_loading}
                        style={{
                            "width": "100%",
                            "padding": "14px",
                            "backgroundColor": card_bg2,
                            "border": "none",
                            "borderRadius": "12px",
                            "fontSize": "15px",
                            "fontWeight": "500",
                            "cursor": "pointer" if not summary_loading else "wait",
                            "color": accent if not summary_loading else text3,
                            "transition": "background-color 0.15s"
                        }}
                    >{("Generating..." if summary_loading else "Generate Plain-English Summary")}</button>}
                </div> if has_flags else <span></span>}

                <ResultsSection results={results} on_copy={copy_results} theme={{"t1": text1, "t2": text2, "c1": card_bg, "c2": card_bg2}} />

                {<div style={{
                    "display": "flex",
                    "justifyContent": "center",
                    "gap": "1px",
                    "margin": "24px 0 16px",
                    "backgroundColor": border,
                    "borderRadius": "16px",
                    "overflow": "hidden"
                }}>
                    <div style={{"flex": "1", "backgroundColor": card_bg, "padding": "20px 16px", "textAlign": "center"}}>
                        <div style={{"fontSize": "28px", "fontWeight": "700", "color": text1, "letterSpacing": "-0.02em"}}>{str(len(selected_drugs))}</div>
                        <div style={{"fontSize": "12px", "color": text2, "fontWeight": "500", "marginTop": "2px"}}>{"Medications"}</div>
                    </div>
                    <div style={{"flex": "1", "backgroundColor": card_bg, "padding": "20px 16px", "textAlign": "center"}}>
                        <div style={{"fontSize": "28px", "fontWeight": "700", "color": "#ff3b30" if has_flags else "#34c759", "letterSpacing": "-0.02em"}}>{str(results["total_flags"])}</div>
                        <div style={{"fontSize": "12px", "color": text2, "fontWeight": "500", "marginTop": "2px"}}>{"Chains Flagged"}</div>
                    </div>
                    <div style={{"flex": "1", "backgroundColor": card_bg, "padding": "20px 16px", "textAlign": "center"}}>
                        <div style={{"fontSize": "28px", "fontWeight": "700", "color": text1, "letterSpacing": "-0.02em"}}>{str(len(interactions))}</div>
                        <div style={{"fontSize": "12px", "color": text2, "fontWeight": "500", "marginTop": "2px"}}>{"Interactions"}</div>
                    </div>
                </div> if has_results else <span></span>}
            </div>

            <div style={{"padding": "64px 24px 40px"}}>
                <div style={{"maxWidth": "680px", "margin": "0 auto"}}>
                    <div style={{
                        "display": "flex",
                        "justifyContent": "space-between",
                        "flexWrap": "wrap",
                        "gap": "32px",
                        "paddingBottom": "24px",
                        "borderBottom": "1px solid " + border
                    }}>
                        <div>
                            <div style={{"fontSize": "17px", "fontWeight": "600", "color": text1, "marginBottom": "6px"}}>{"ChainRX"}</div>
                            <div style={{"fontSize": "13px", "color": text3, "lineHeight": "1.6", "maxWidth": "260px"}}>{"Multi-drug interaction chain detection using graph traversal and compounding risk analysis."}</div>
                        </div>
                        <div>
                            <div style={{"fontSize": "11px", "fontWeight": "600", "color": text3, "letterSpacing": "0.05em", "marginBottom": "10px"}}>{"TECHNOLOGY"}</div>
                            <div style={{"fontSize": "13px", "color": text2, "lineHeight": "1.8"}}>
                                {"Jaseci / JAC Language"}<br />
                                {"Graph Walkers + Compounding Rules"}<br />
                                {"Claude Haiku 4.5 (summaries only)"}<br />
                                {"Claude Haiku 4.5 for summaries"}
                            </div>
                        </div>
                        <div>
                            <div style={{"fontSize": "11px", "fontWeight": "600", "color": text3, "letterSpacing": "0.05em", "marginBottom": "10px"}}>{"DATA"}</div>
                            <div style={{"fontSize": "13px", "color": text2, "lineHeight": "1.8"}}>
                                {"150 medications"}<br />
                                {"400+ pairwise interactions"}<br />
                                {"30 compounding rules"}<br />
                                {"Depth-3 chain traversal"}
                            </div>
                        </div>
                    </div>
                    <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "padding": "16px 0", "flexWrap": "wrap", "gap": "8px"}}>
                        <div style={{"fontSize": "12px", "color": text3}}>{"JacHacks 2026"}</div>
                        <div style={{"fontSize": "11px", "color": text3}}>{"For educational purposes only. Not medical advice."}</div>
                    </div>
                </div>
            </div>
        </div>;
    }
}
