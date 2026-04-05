"""Drug multi-select dropdown component."""

cl import from react { useState }

def:pub DrugSelector(drugs: list, selected: list, onToggle: any) -> any {
    has search: str = "";
    has is_open: bool = False;

    filtered = [d for d in drugs if d.toLowerCase().includes(search.toLowerCase())];

    return <div style={{"position": "relative", "width": "100%"}}>
        <div
            style={{
                "display": "flex",
                "flexWrap": "wrap",
                "gap": "0.5rem",
                "padding": "0.75rem",
                "border": "2px solid #e2e8f0",
                "borderRadius": "0.75rem",
                "minHeight": "3rem",
                "cursor": "pointer",
                "backgroundColor": "#ffffff",
                "transition": "border-color 0.2s"
            }}
            onClick={lambda -> None { is_open = not is_open; }}
        >
            {[
                <span
                    key={drug}
                    style={{
                        "backgroundColor": "#dbeafe",
                        "color": "#1e40af",
                        "padding": "0.25rem 0.75rem",
                        "borderRadius": "9999px",
                        "fontSize": "0.875rem",
                        "fontWeight": "500",
                        "display": "flex",
                        "alignItems": "center",
                        "gap": "0.35rem"
                    }}
                >
                    {drug}
                    <span
                        onClick={lambda e -> None {
                            e.stopPropagation();
                            onToggle(drug);
                        }}
                        style={{
                            "cursor": "pointer",
                            "fontWeight": "bold",
                            "marginLeft": "0.25rem"
                        }}
                    >x</span>
                </span>
                for drug in selected
            ] if len(selected) > 0 else <span style={{"color": "#94a3b8"}}>Select medications...</span>}
        </div>
        {<div style={{
            "position": "absolute",
            "top": "100%",
            "left": "0",
            "right": "0",
            "marginTop": "0.25rem",
            "backgroundColor": "#ffffff",
            "border": "2px solid #e2e8f0",
            "borderRadius": "0.75rem",
            "maxHeight": "15rem",
            "overflowY": "auto",
            "zIndex": "50",
            "boxShadow": "0 10px 25px rgba(0,0,0,0.1)"
        }}>
            <input
                type="text"
                placeholder="Search drugs..."
                value={search}
                onChange={lambda e -> None { search = e.target.value; }}
                onClick={lambda e -> None { e.stopPropagation(); }}
                style={{
                    "width": "100%",
                    "padding": "0.75rem",
                    "border": "none",
                    "borderBottom": "1px solid #e2e8f0",
                    "outline": "none",
                    "fontSize": "0.875rem",
                    "boxSizing": "border-box"
                }}
            />
            {[
                <div
                    key={drug}
                    onClick={lambda e -> None {
                        e.stopPropagation();
                        onToggle(drug);
                    }}
                    style={{
                        "padding": "0.6rem 0.75rem",
                        "cursor": "pointer",
                        "backgroundColor": "#eff6ff" if drug in selected else "transparent",
                        "fontWeight": "600" if drug in selected else "400",
                        "fontSize": "0.875rem",
                        "transition": "background-color 0.15s"
                    }}
                >
                    {"[x] " if drug in selected else "[ ] "}{drug}
                </div>
                for drug in filtered
            ]}
        </div> if is_open else <span></span>}
    </div>;
}
