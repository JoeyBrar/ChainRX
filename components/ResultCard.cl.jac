"""Result card component showing a flagged interaction chain."""

def:pub ResultCard(chain: any) -> any {
    risk = chain["risk"];
    path = chain["path"];
    mechanisms = chain["mechanisms"];
    depth = chain["depth"];

    severity_label = "CRITICAL";
    color = "#dc2626";
    bg = "#fef2f2";
    border_color = "#fecaca";
    if risk < 0.6 {
        severity_label = "LOW";
        color = "#16a34a";
        bg = "#f0fdf4";
        border_color = "#bbf7d0";
    } elif risk < 0.7 {
        severity_label = "MODERATE";
        color = "#ca8a04";
        bg = "#fefce8";
        border_color = "#fef08a";
    } elif risk < 0.9 {
        severity_label = "HIGH";
        color = "#ea580c";
        bg = "#fff7ed";
        border_color = "#fed7aa";
    }

    risk_pct = str(int(risk * 100)) + "%";

    return <div style={{
        "backgroundColor": bg,
        "border": "2px solid " + border_color,
        "borderRadius": "1rem",
        "padding": "1.25rem",
        "marginBottom": "1rem",
        "boxShadow": "0 2px 8px rgba(0,0,0,0.06)"
    }}>
        <div style={{
            "display": "flex",
            "justifyContent": "space-between",
            "alignItems": "center",
            "marginBottom": "0.75rem"
        }}>
            <span style={{
                "backgroundColor": color,
                "color": "#ffffff",
                "padding": "0.25rem 0.75rem",
                "borderRadius": "9999px",
                "fontSize": "0.75rem",
                "fontWeight": "700",
                "textTransform": "uppercase",
                "letterSpacing": "0.05em"
            }}>{severity_label}</span>
            <span style={{
                "fontSize": "1.5rem",
                "fontWeight": "800",
                "color": color
            }}>{risk_pct}</span>
        </div>

        <div style={{
            "display": "flex",
            "alignItems": "center",
            "gap": "0.5rem",
            "marginBottom": "0.75rem",
            "flexWrap": "wrap"
        }}>
            {[
                <span key={str(idx)}>
                    <span style={{
                        "backgroundColor": "#ffffff",
                        "padding": "0.35rem 0.75rem",
                        "borderRadius": "0.5rem",
                        "fontWeight": "600",
                        "fontSize": "0.9rem",
                        "border": "1px solid #d1d5db"
                    }}>{path[idx]}</span>
                    {<span style={{
                        "color": "#9ca3af",
                        "fontSize": "1.2rem",
                        "fontWeight": "bold"
                    }}> -&gt; </span> if idx < len(path) - 1 else <span></span>}
                </span>
                for idx in range(len(path))
            ]}
        </div>

        <div style={{
            "fontSize": "0.8rem",
            "color": "#4b5563",
            "lineHeight": "1.6"
        }}>
            {[
                <div key={str(idx)} style={{
                    "padding": "0.35rem 0",
                    "borderTop": "1px solid " + border_color if idx > 0 else "none"
                }}>
                    <span style={{"fontWeight": "600"}}>Step {str(idx + 1)}: </span>{mechanisms[idx]}
                </div>
                for idx in range(len(mechanisms))
            ]}
        </div>

        <div style={{
            "marginTop": "0.5rem",
            "fontSize": "0.75rem",
            "color": "#9ca3af"
        }}>
            Chain depth: {str(depth)} | Compounding risk detected
        </div>
    </div>;
}
