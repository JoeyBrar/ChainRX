"""Drug multi-select dropdown component."""

cl import from react { useRef, useEffect }

def:pub DrugSelector(drugs: list, selected: list, onToggle: any) -> any {
    has search: str = "";
    has is_open: bool = False;
    input_ref = useRef(None);

    filtered = [d for d in drugs if d.toLowerCase().includes(search.toLowerCase())];

    # Close dropdown when clicking outside
    useEffect(lambda {
        def handle_click(e: any) {
            if input_ref.current and not input_ref.current.closest("[data-drug-selector]").contains(e.target) {
                is_open = False;
            }
        }
        document.addEventListener("mousedown", handle_click);
        return lambda { document.removeEventListener("mousedown", handle_click); };
    }, []);

    return <div style={{"position": "relative", "width": "100%"}} data-drug-selector="true">
        <div
            style={{
                "display": "flex",
                "flexWrap": "wrap",
                "gap": "0.5rem",
                "padding": "0.5rem",
                "border": "2px solid " + ("#3b82f6" if is_open else "#e2e8f0"),
                "borderRadius": "0.75rem",
                "minHeight": "3rem",
                "backgroundColor": "#ffffff",
                "transition": "border-color 0.2s",
                "alignItems": "center",
                "cursor": "text"
            }}
            onClick={lambda {
                is_open = True;
                if input_ref.current {
                    input_ref.current.focus();
                }
            }}
        >
            {[
                <span
                    key={drug}
                    style={{
                        "backgroundColor": "#dbeafe",
                        "color": "#1e40af",
                        "padding": "0.2rem 0.6rem",
                        "borderRadius": "9999px",
                        "fontSize": "0.85rem",
                        "fontWeight": "500",
                        "display": "inline-flex",
                        "alignItems": "center",
                        "gap": "0.3rem",
                        "whiteSpace": "nowrap"
                    }}
                >
                    {drug}
                    <span
                        onClick={lambda e {
                            e.stopPropagation();
                            onToggle(drug);
                        }}
                        style={{
                            "cursor": "pointer",
                            "fontWeight": "bold",
                            "fontSize": "0.75rem",
                            "lineHeight": "1",
                            "marginLeft": "0.15rem",
                            "color": "#3b82f6"
                        }}
                    >{"x"}</span>
                </span>
                for drug in selected
            ]}
            <input
                ref={input_ref}
                type="text"
                placeholder={"Select medications..." if len(selected) == 0 else "Search..."}
                value={search}
                onChange={lambda e { search = e.target.value; }}
                onFocus={lambda { is_open = True; }}
                style={{
                    "border": "none",
                    "outline": "none",
                    "fontSize": "0.875rem",
                    "flex": "1",
                    "minWidth": "8rem",
                    "padding": "0.25rem",
                    "backgroundColor": "transparent"
                }}
            />
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
            {[
                <div
                    key={drug}
                    onClick={lambda e {
                        e.stopPropagation();
                        onToggle(drug);
                        search = "";
                        if input_ref.current {
                            input_ref.current.focus();
                        }
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
                    {drug}
                    {<span style={{"color": "#3b82f6", "marginLeft": "0.5rem", "fontSize": "0.75rem"}}>{"(selected)"}</span> if drug in selected else <span></span>}
                </div>
                for drug in filtered
            ]}
            {<div style={{
                "padding": "0.75rem",
                "color": "#94a3b8",
                "fontSize": "0.875rem",
                "textAlign": "center"
            }}>{"No drugs found"}</div> if len(filtered) == 0 else <span></span>}
        </div> if is_open else <span></span>}
    </div>;
}
