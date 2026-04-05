"""Drug multi-select dropdown component."""

cl import from react { useRef, useEffect }

def:pub DrugSelector(drugs: list, selected: list, onToggle: any) -> any {
    has search: str = "";
    has is_open: bool = False;
    input_ref = useRef(None);

    filtered = [d for d in drugs if d.toLowerCase().includes(search.toLowerCase())];

    useEffect(lambda {
        def handle_click(e: any) {
            if input_ref.current and not input_ref.current.closest("[data-ds]").contains(e.target) {
                is_open = False;
            }
        }
        document.addEventListener("mousedown", handle_click);
        return lambda { document.removeEventListener("mousedown", handle_click); };
    }, []);

    return <div style={{"position": "relative", "width": "100%"}} data-ds="true">
        <div
            style={{
                "display": "flex",
                "flexWrap": "wrap",
                "gap": "6px",
                "padding": "10px 12px",
                "border": "1px solid " + ("rgba(0,0,0,0.2)" if is_open else "rgba(0,0,0,0.08)"),
                "borderRadius": "12px",
                "minHeight": "44px",
                "backgroundColor": "#ffffff",
                "transition": "border-color 0.2s, box-shadow 0.2s",
                "alignItems": "center",
                "cursor": "text",
                "boxShadow": "0 0 0 3px rgba(0,122,255,0.12)" if is_open else "none"
            }}
            onClick={lambda {
                is_open = True;
                if input_ref.current { input_ref.current.focus(); }
            }}
        >
            {[
                <span
                    key={drug}
                    style={{
                        "backgroundColor": "#f5f5f7",
                        "color": "#1d1d1f",
                        "padding": "4px 10px",
                        "borderRadius": "8px",
                        "fontSize": "13px",
                        "fontWeight": "500",
                        "display": "inline-flex",
                        "alignItems": "center",
                        "gap": "6px",
                        "whiteSpace": "nowrap",
                        "letterSpacing": "-0.01em"
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
                            "fontSize": "11px",
                            "color": "#86868b",
                            "width": "16px",
                            "height": "16px",
                            "display": "inline-flex",
                            "alignItems": "center",
                            "justifyContent": "center",
                            "borderRadius": "50%",
                            "backgroundColor": "rgba(0,0,0,0.06)"
                        }}
                    >{"x"}</span>
                </span>
                for drug in selected
            ]}
            <input
                ref={input_ref}
                type="text"
                placeholder={"Search medications..." if len(selected) == 0 else "Add more..."}
                value={search}
                onChange={lambda e { search = e.target.value; }}
                onFocus={lambda { is_open = True; }}
                style={{
                    "border": "none",
                    "outline": "none",
                    "fontSize": "15px",
                    "flex": "1",
                    "minWidth": "120px",
                    "padding": "2px 4px",
                    "backgroundColor": "transparent",
                    "color": "#1d1d1f",
                    "letterSpacing": "-0.01em"
                }}
            />
        </div>
        {<div style={{
            "position": "absolute",
            "top": "100%",
            "left": "0",
            "right": "0",
            "marginTop": "6px",
            "backgroundColor": "#ffffff",
            "border": "1px solid rgba(0,0,0,0.08)",
            "borderRadius": "12px",
            "maxHeight": "240px",
            "overflowY": "auto",
            "zIndex": "50",
            "boxShadow": "0 8px 30px rgba(0,0,0,0.12)",
            "padding": "4px"
        }}>
            {[
                <div
                    key={drug}
                    onClick={lambda e {
                        e.stopPropagation();
                        onToggle(drug);
                        search = "";
                        if input_ref.current { input_ref.current.focus(); }
                    }}
                    style={{
                        "padding": "8px 12px",
                        "cursor": "pointer",
                        "backgroundColor": "#f5f5f7" if drug in selected else "transparent",
                        "borderRadius": "8px",
                        "fontSize": "14px",
                        "color": "#1d1d1f",
                        "fontWeight": "500" if drug in selected else "400",
                        "transition": "background-color 0.1s",
                        "display": "flex",
                        "justifyContent": "space-between",
                        "alignItems": "center"
                    }}
                >
                    <span>{drug}</span>
                    {<span style={{"color": "#007aff", "fontSize": "12px", "fontWeight": "500"}}>{"added"}</span> if drug in selected else <span></span>}
                </div>
                for drug in filtered
            ]}
            {<div style={{
                "padding": "16px",
                "color": "#86868b",
                "fontSize": "14px",
                "textAlign": "center"
            }}>{"No results"}</div> if len(filtered) == 0 else <span></span>}
        </div> if is_open else <span></span>}
    </div>;
}
