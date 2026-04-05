"""Result card component for flagged interaction chains."""

def:pub ResultCard(chain: any) -> any {
    risk = chain["risk"];
    path = chain["path"];
    mechanisms = chain["mechanisms"];
    depth = chain["depth"];

    severity_label = "Critical";
    color = "#ff3b30";
    tint = "#fff5f5";
    if risk < 0.6 {
        severity_label = "Low";
        color = "#34c759";
        tint = "#f0fdf4";
    } elif risk < 0.7 {
        severity_label = "Moderate";
        color = "#ff9500";
        tint = "#fffbeb";
    } elif risk < 0.9 {
        severity_label = "High";
        color = "#ff6b35";
        tint = "#fff7ed";
    }

    score = Math.min(Math.round(risk * 10 * 10) / 10, 10.0);
    bar_pct = str(Math.min(Math.round(score * 10), 100)) + "%";

    return <div style={{
        "backgroundColor": "#ffffff",
        "borderRadius": "16px",
        "marginBottom": "10px",
        "overflow": "hidden",
        "boxShadow": "0 1px 2px rgba(0,0,0,0.04)"
    }}>
        <div style={{
            "display": "flex",
            "justifyContent": "space-between",
            "alignItems": "center",
            "padding": "16px 20px",
            "backgroundColor": tint
        }}>
            <div style={{"display": "flex", "alignItems": "center", "gap": "10px"}}>
                <span style={{
                    "width": "8px",
                    "height": "8px",
                    "borderRadius": "50%",
                    "backgroundColor": color,
                    "flexShrink": "0"
                }}></span>
                <span style={{
                    "fontSize": "13px",
                    "fontWeight": "600",
                    "color": color,
                    "letterSpacing": "-0.01em"
                }}>{severity_label}</span>
            </div>
            <div style={{"display": "flex", "alignItems": "center", "gap": "10px"}}>
                <div style={{
                    "width": "48px",
                    "height": "4px",
                    "backgroundColor": "rgba(0,0,0,0.06)",
                    "borderRadius": "2px",
                    "overflow": "hidden"
                }}>
                    <div style={{
                        "width": bar_pct,
                        "height": "100%",
                        "backgroundColor": color,
                        "borderRadius": "2px"
                    }}></div>
                </div>
                <span style={{
                    "fontSize": "20px",
                    "fontWeight": "700",
                    "color": "#1d1d1f",
                    "letterSpacing": "-0.02em",
                    "fontVariantNumeric": "tabular-nums"
                }}>{str(score)}</span>
            </div>
        </div>

        <div style={{"padding": "16px 20px"}}>
            <div style={{
                "display": "flex",
                "alignItems": "center",
                "gap": "6px",
                "marginBottom": "14px",
                "flexWrap": "wrap"
            }}>
                {[
                    <span key={str(idx)} style={{"display": "flex", "alignItems": "center", "gap": "6px"}}>
                        <span style={{
                            "backgroundColor": "#f5f5f7",
                            "padding": "5px 12px",
                            "borderRadius": "8px",
                            "fontWeight": "500",
                            "fontSize": "13px",
                            "color": "#1d1d1f",
                            "letterSpacing": "-0.01em"
                        }}>{path[idx]}</span>
                        {<span style={{
                            "color": "#86868b",
                            "fontSize": "13px"
                        }}>{" " + String.fromCharCode(8594) + " "}</span> if idx < len(path) - 1 else <span></span>}
                    </span>
                    for idx in range(len(path))
                ]}
            </div>

            {[
                <div key={str(idx)} style={{
                    "padding": "10px 0",
                    "borderTop": "1px solid rgba(0,0,0,0.04)" if idx > 0 else "none",
                    "fontSize": "13px",
                    "color": "#424245",
                    "lineHeight": "1.5",
                    "display": "flex",
                    "gap": "8px"
                }}>
                    <span style={{
                        "color": "#86868b",
                        "fontSize": "12px",
                        "fontWeight": "600",
                        "minWidth": "16px",
                        "flexShrink": "0",
                        "paddingTop": "1px"
                    }}>{str(idx + 1)}</span>
                    <span>{mechanisms[idx]}</span>
                </div>
                for idx in range(len(mechanisms))
            ]}
        </div>
    </div>;
}
