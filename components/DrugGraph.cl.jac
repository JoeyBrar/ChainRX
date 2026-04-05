"""Interactive force-directed drug interaction graph visualization."""

cl import from react { useRef, useEffect }

def:pub DrugGraph(medications: list, interactions: list, flagged_paths: list) -> any {
    canvas_ref = useRef(None);

    useEffect(lambda {
        canvas = canvas_ref.current;
        if not canvas { return lambda {}; }
        ctx = canvas.getContext("2d");
        dpr = window.devicePixelRatio or 1;
        rect = canvas.getBoundingClientRect();
        w = rect.width;
        h = 500;
        canvas.width = w * dpr;
        canvas.height = h * dpr;
        canvas.style.height = str(h) + "px";
        ctx.scale(dpr, dpr);

        # Build nodes — spread evenly in a circle
        nodes = [];
        node_map = {};
        count = len(medications);
        i = 0;
        while i < count {
            # Offset by -90deg so first node is at top
            angle = (2 * Math.PI * i / count) - (Math.PI / 2);
            # Use most of the canvas area
            radius = Math.min(w, h) * 0.42;
            nodes.push({
                "id": medications[i],
                "x": w / 2 + Math.cos(angle) * radius,
                "y": h / 2 + Math.sin(angle) * radius,
                "vx": 0, "vy": 0,
                "flagged": False,
                "flag_count": 0
            });
            node_map[medications[i]] = i;
            i = i + 1;
        }

        # Mark flagged nodes with count of how many chains they appear in
        pi = 0;
        while pi < len(flagged_paths) {
            path = flagged_paths[pi]["path"];
            pj = 0;
            while pj < len(path) {
                drug = path[pj];
                if drug in node_map {
                    nodes[node_map[drug]]["flagged"] = True;
                    nodes[node_map[drug]]["flag_count"] = nodes[node_map[drug]]["flag_count"] + 1;
                }
                pj = pj + 1;
            }
            pi = pi + 1;
        }

        # Build edges with dedup
        edges = [];
        edge_set = {};
        ei = 0;
        while ei < len(interactions) {
            inter = interactions[ei];
            a = inter["drug_a"];
            b = inter["drug_b"];
            # Sort to dedup
            key = a + "|" + b if a < b else b + "|" + a;
            if a in node_map and b in node_map and not (key in edge_set) {
                edge_set[key] = True;
                is_flagged = False;
                fi = 0;
                while fi < len(flagged_paths) {
                    fp = flagged_paths[fi]["path"];
                    fj = 0;
                    while fj < len(fp) - 1 {
                        if (fp[fj] == a and fp[fj + 1] == b) or (fp[fj] == b and fp[fj + 1] == a) {
                            is_flagged = True;
                        }
                        fj = fj + 1;
                    }
                    fi = fi + 1;
                }
                edges.push({
                    "source": node_map[a],
                    "target": node_map[b],
                    "severity": inter["severity"],
                    "type": inter["type"],
                    "flagged": is_flagged
                });
            }
            ei = ei + 1;
        }

        # Physics
        running = {"val": True};
        mouse = {"x": -1000, "y": -1000, "dragging": -1, "hover": -1};

        def simulate() {
            # Repulsion
            ni = 0;
            while ni < len(nodes) {
                nj = ni + 1;
                while nj < len(nodes) {
                    dx = nodes[nj]["x"] - nodes[ni]["x"];
                    dy = nodes[nj]["y"] - nodes[ni]["y"];
                    dist = Math.sqrt(dx * dx + dy * dy) + 1;
                    force = (3000 + count * 200) / (dist * dist);
                    fx = (dx / dist) * force;
                    fy = (dy / dist) * force;
                    nodes[ni]["vx"] = nodes[ni]["vx"] - fx;
                    nodes[ni]["vy"] = nodes[ni]["vy"] - fy;
                    nodes[nj]["vx"] = nodes[nj]["vx"] + fx;
                    nodes[nj]["vy"] = nodes[nj]["vy"] + fy;
                    nj = nj + 1;
                }
                ni = ni + 1;
            }

            # Edge attraction
            ej = 0;
            while ej < len(edges) {
                s = edges[ej]["source"];
                t = edges[ej]["target"];
                dx = nodes[t]["x"] - nodes[s]["x"];
                dy = nodes[t]["y"] - nodes[s]["y"];
                dist = Math.sqrt(dx * dx + dy * dy) + 1;
                ideal = 160 + count * 12;
                force = (dist - ideal) * 0.005;
                fx = (dx / dist) * force;
                fy = (dy / dist) * force;
                nodes[s]["vx"] = nodes[s]["vx"] + fx;
                nodes[s]["vy"] = nodes[s]["vy"] + fy;
                nodes[t]["vx"] = nodes[t]["vx"] - fx;
                nodes[t]["vy"] = nodes[t]["vy"] - fy;
                ej = ej + 1;
            }

            # Center gravity
            ci = 0;
            while ci < len(nodes) {
                nodes[ci]["vx"] = nodes[ci]["vx"] + (w / 2 - nodes[ci]["x"]) * 0.003;
                nodes[ci]["vy"] = nodes[ci]["vy"] + (h / 2 - nodes[ci]["y"]) * 0.003;
                ci = ci + 1;
            }

            # Apply velocity with damping + bounds
            pad = 55;
            ui = 0;
            while ui < len(nodes) {
                if ui != mouse["dragging"] {
                    nodes[ui]["vx"] = nodes[ui]["vx"] * 0.82;
                    nodes[ui]["vy"] = nodes[ui]["vy"] * 0.82;
                    nodes[ui]["x"] = nodes[ui]["x"] + nodes[ui]["vx"];
                    nodes[ui]["y"] = nodes[ui]["y"] + nodes[ui]["vy"];
                }
                nodes[ui]["x"] = Math.max(pad, Math.min(w - pad, nodes[ui]["x"]));
                nodes[ui]["y"] = Math.max(pad, Math.min(h - pad, nodes[ui]["y"]));
                ui = ui + 1;
            }
        }

        def draw(timestamp: any) {
            ctx.clearRect(0, 0, w, h);

            # Draw edges
            di = 0;
            while di < len(edges) {
                e = edges[di];
                s = nodes[e["source"]];
                t = nodes[e["target"]];
                sx = s["x"];
                sy = s["y"];
                tx = t["x"];
                ty = t["y"];

                # Highlight if either endpoint is hovered
                is_hovered = mouse["hover"] == e["source"] or mouse["hover"] == e["target"];

                ctx.beginPath();
                ctx.moveTo(sx, sy);
                ctx.lineTo(tx, ty);

                if e["flagged"] {
                    alpha = 0.9 if is_hovered else 0.5;
                    ctx.strokeStyle = "rgba(220, 38, 38, " + str(alpha) + ")";
                    ctx.lineWidth = 3 if is_hovered else 2;
                    ctx.setLineDash([]);
                } else {
                    alpha = 0.5 if is_hovered else 0.2;
                    ctx.strokeStyle = "rgba(148, 163, 184, " + str(alpha) + ")";
                    ctx.lineWidth = 1.5 if is_hovered else 1;
                    ctx.setLineDash([4, 4]);
                }
                ctx.stroke();
                ctx.setLineDash([]);

                # Edge label on hover
                if is_hovered {
                    mx = (sx + tx) / 2;
                    my = (sy + ty) / 2;
                    label = e["type"].replace("_", " ");
                    ctx.font = "bold 10px -apple-system, sans-serif";
                    text_w = ctx.measureText(label).width;
                    ctx.fillStyle = "rgba(255,255,255,0.9)";
                    ctx.fillRect(mx - text_w / 2 - 4, my - 8, text_w + 8, 16);
                    ctx.fillStyle = "#dc2626" if e["flagged"] else "#475569";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    ctx.fillText(label, mx, my);
                }
                di = di + 1;
            }

            # Draw nodes
            ni2 = 0;
            while ni2 < len(nodes) {
                n = nodes[ni2];
                is_hover = mouse["hover"] == ni2;
                base_r = 26 if n["flagged"] else 22;
                r = base_r + (3 if is_hover else 0);

                # Animated pulse glow for flagged nodes
                if n["flagged"] {
                    pulse = Math.sin((timestamp or 0) / 400 + ni2) * 0.04 + 0.12;
                    ctx.beginPath();
                    ctx.arc(n["x"], n["y"], r + 10, 0, Math.PI * 2);
                    ctx.fillStyle = "rgba(220, 38, 38, " + str(pulse) + ")";
                    ctx.fill();
                }

                # Shadow
                ctx.beginPath();
                ctx.arc(n["x"], n["y"] + 2, r, 0, Math.PI * 2);
                ctx.fillStyle = "rgba(0,0,0,0.06)";
                ctx.fill();

                # Node circle
                ctx.beginPath();
                ctx.arc(n["x"], n["y"], r, 0, Math.PI * 2);
                if n["flagged"] {
                    # Gradient-like effect
                    ctx.fillStyle = "#fff1f2" if not is_hover else "#ffe4e6";
                    ctx.strokeStyle = "#dc2626";
                    ctx.lineWidth = 2.5;
                } else {
                    ctx.fillStyle = "#f0f4ff" if not is_hover else "#e0e7ff";
                    ctx.strokeStyle = "#6366f1" if is_hover else "#94a3b8";
                    ctx.lineWidth = 2 if is_hover else 1.5;
                }
                ctx.fill();
                ctx.stroke();

                # Label — full name, wrapped if needed
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                name = n["id"];
                if is_hover {
                    ctx.font = "bold 11px -apple-system, sans-serif";
                    ctx.fillStyle = "#0f172a";
                } else {
                    ctx.font = "11px -apple-system, sans-serif";
                    ctx.fillStyle = "#1e293b" if n["flagged"] else "#475569";
                }

                # Truncate only if very long
                if len(name) > 14 {
                    name = name[0:12] + "..";
                }
                ctx.fillText(name, n["x"], n["y"]);

                # Flag count badge
                if n["flagged"] and n["flag_count"] > 1 {
                    badge_x = n["x"] + r * 0.7;
                    badge_y = n["y"] - r * 0.7;
                    ctx.beginPath();
                    ctx.arc(badge_x, badge_y, 8, 0, Math.PI * 2);
                    ctx.fillStyle = "#dc2626";
                    ctx.fill();
                    ctx.font = "bold 9px sans-serif";
                    ctx.fillStyle = "#ffffff";
                    ctx.fillText(str(n["flag_count"]), badge_x, badge_y);
                }

                ni2 = ni2 + 1;
            }

            # Tooltip on hover
            if mouse["hover"] >= 0 {
                hn = nodes[mouse["hover"]];
                # Count connections
                conn = 0;
                eci = 0;
                while eci < len(edges) {
                    if edges[eci]["source"] == mouse["hover"] or edges[eci]["target"] == mouse["hover"] {
                        conn = conn + 1;
                    }
                    eci = eci + 1;
                }
                tip = hn["id"] + " | " + str(conn) + " interaction(s)";
                if hn["flagged"] {
                    tip = tip + " | in " + str(hn["flag_count"]) + " chain(s)";
                }
                ctx.font = "12px -apple-system, sans-serif";
                tw = ctx.measureText(tip).width;
                tx2 = Math.min(hn["x"] - tw / 2 - 8, w - tw - 20);
                ty2 = hn["y"] - 48;
                if ty2 < 10 { ty2 = hn["y"] + 40; }

                # Tooltip background
                ctx.fillStyle = "rgba(15, 23, 42, 0.9)";
                ctx.beginPath();
                ctx.roundRect(tx2, ty2, tw + 16, 26, 6);
                ctx.fill();
                ctx.fillStyle = "#ffffff";
                ctx.textAlign = "left";
                ctx.textBaseline = "middle";
                ctx.fillText(tip, tx2 + 8, ty2 + 13);
            }
        }

        # Mouse interaction
        def get_node_at(mx: any, my: any) -> int {
            gi = len(nodes) - 1;
            while gi >= 0 {
                n = nodes[gi];
                dx = mx - n["x"];
                dy = my - n["y"];
                r = 28;
                if dx * dx + dy * dy < r * r {
                    return gi;
                }
                gi = gi - 1;
            }
            return -1;
        }

        def on_mouse_move(evt: any) {
            r = canvas.getBoundingClientRect();
            mouse["x"] = evt.clientX - r.left;
            mouse["y"] = evt.clientY - r.top;
            if mouse["dragging"] >= 0 {
                nodes[mouse["dragging"]]["x"] = mouse["x"];
                nodes[mouse["dragging"]]["y"] = mouse["y"];
                nodes[mouse["dragging"]]["vx"] = 0;
                nodes[mouse["dragging"]]["vy"] = 0;
            }
            mouse["hover"] = get_node_at(mouse["x"], mouse["y"]);
            canvas.style.cursor = "grab" if mouse["hover"] >= 0 else "default";
        }

        def on_mouse_down(evt: any) {
            r = canvas.getBoundingClientRect();
            mx = evt.clientX - r.left;
            my = evt.clientY - r.top;
            hit = get_node_at(mx, my);
            if hit >= 0 {
                mouse["dragging"] = hit;
                canvas.style.cursor = "grabbing";
            }
        }

        def on_mouse_up(evt: any) {
            mouse["dragging"] = -1;
            canvas.style.cursor = "grab" if mouse["hover"] >= 0 else "default";
        }

        def on_mouse_leave(evt: any) {
            mouse["hover"] = -1;
            mouse["dragging"] = -1;
            canvas.style.cursor = "default";
        }

        canvas.addEventListener("mousemove", on_mouse_move);
        canvas.addEventListener("mousedown", on_mouse_down);
        canvas.addEventListener("mouseup", on_mouse_up);
        canvas.addEventListener("mouseleave", on_mouse_leave);

        # Animation loop — runs continuously for interactivity
        def tick(ts: any) {
            if not running["val"] { return; }
            simulate();
            draw(ts);
            requestAnimationFrame(tick);
        }
        requestAnimationFrame(tick);

        return lambda {
            running["val"] = False;
            canvas.removeEventListener("mousemove", on_mouse_move);
            canvas.removeEventListener("mousedown", on_mouse_down);
            canvas.removeEventListener("mouseup", on_mouse_up);
            canvas.removeEventListener("mouseleave", on_mouse_leave);
        };
    }, [medications, interactions, flagged_paths]);

    return <div style={{
        "backgroundColor": "#ffffff",
        "borderRadius": "1rem",
        "padding": "1rem",
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
            }}>{"Interaction Graph"}</h3>
            <div style={{"display": "flex", "gap": "1rem", "fontSize": "0.75rem", "color": "#6b7280", "alignItems": "center"}}>
                <span style={{"display": "flex", "alignItems": "center", "gap": "4px"}}>
                    <span style={{"display": "inline-block", "width": "16px", "height": "3px", "backgroundColor": "#dc2626", "borderRadius": "2px"}}></span>
                    {"flagged"}
                </span>
                <span style={{"display": "flex", "alignItems": "center", "gap": "4px"}}>
                    <span style={{"display": "inline-block", "width": "16px", "height": "1px", "backgroundColor": "#94a3b8", "borderStyle": "dashed"}}></span>
                    {"interaction"}
                </span>
                <span style={{"color": "#94a3b8"}}>{"| drag nodes to rearrange"}</span>
            </div>
        </div>
        <canvas
            ref={canvas_ref}
            style={{
                "width": "100%",
                "height": "500px",
                "borderRadius": "0.75rem",
                "backgroundColor": "#fafbfc",
                "border": "1px solid #f1f5f9"
            }}
        />
    </div>;
}
