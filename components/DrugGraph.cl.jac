"""Interactive force-directed drug interaction graph visualization."""

cl import from react { useRef, useEffect }

def:pub DrugGraph(medications: list, interactions: list, flagged_paths: list) -> any {
    canvas_ref = useRef(None);

    if len(interactions) == 0 {
        return <div style={{
            "backgroundColor": "#ffffff",
            "borderRadius": "20px",
            "padding": "20px 24px",
            "marginBottom": "16px",
            "boxShadow": "0 1px 3px rgba(0,0,0,0.04)"
        }}>
            <div style={{
                "fontSize": "15px",
                "fontWeight": "600",
                "color": "#1d1d1f",
                "marginBottom": "12px",
                "letterSpacing": "-0.01em"
            }}>{"Interaction Graph"}</div>
            <div style={{
                "textAlign": "center",
                "padding": "40px 20px",
                "backgroundColor": "#f5f5f7",
                "borderRadius": "14px"
            }}>
                <div style={{"fontSize": "17px", "fontWeight": "600", "color": "#1d1d1f"}}>{"No known interactions"}</div>
                <div style={{"fontSize": "14px", "color": "#86868b", "marginTop": "4px"}}>{"These medications have no documented pairwise interactions in our database."}</div>
            </div>
        </div>;
    }

    useEffect(lambda {
        canvas = canvas_ref.current;
        if not canvas { return lambda {}; }
        ctx = canvas.getContext("2d");
        dpr = window.devicePixelRatio or 1;
        rect = canvas.getBoundingClientRect();
        w = rect.width;
        h = 480;
        canvas.width = w * dpr;
        canvas.height = h * dpr;
        canvas.style.height = str(h) + "px";
        ctx.scale(dpr, dpr);

        count = len(medications);

        # Build adjacency for smarter layout
        adj = {};
        mi = 0;
        while mi < count {
            adj[mi] = [];
            mi = mi + 1;
        }

        node_map = {};
        ni = 0;
        while ni < count {
            node_map[medications[ni]] = ni;
            ni = ni + 1;
        }

        # Build edges + adjacency
        edges = [];
        edge_set = {};
        ei = 0;
        while ei < len(interactions) {
            inter = interactions[ei];
            a = inter["drug_a"];
            b = inter["drug_b"];
            key = a + "|" + b if a < b else b + "|" + a;
            if a in node_map and b in node_map and not (key in edge_set) {
                edge_set[key] = True;
                si = node_map[a];
                ti = node_map[b];
                adj[si].push(ti);
                adj[ti].push(si);

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
                    "source": si,
                    "target": ti,
                    "type": inter["type"],
                    "flagged": is_flagged
                });
            }
            ei = ei + 1;
        }

        # Mark flagged nodes
        flag_counts = {};
        pi = 0;
        while pi < count {
            flag_counts[pi] = 0;
            pi = pi + 1;
        }
        pj = 0;
        while pj < len(flagged_paths) {
            path = flagged_paths[pj]["path"];
            pk = 0;
            while pk < len(path) {
                if path[pk] in node_map {
                    flag_counts[node_map[path[pk]]] = flag_counts[node_map[path[pk]]] + 1;
                }
                pk = pk + 1;
            }
            pj = pj + 1;
        }

        # Initial layout: circular, using full canvas
        cx = w / 2;
        cy = h / 2;
        spread = Math.min(w, h) * 0.40;
        nodes = [];
        i = 0;
        while i < count {
            angle = (2 * Math.PI * i / count) - (Math.PI / 2);
            nodes.push({
                "id": medications[i],
                "x": cx + Math.cos(angle) * spread,
                "y": cy + Math.sin(angle) * spread,
                "vx": 0, "vy": 0,
                "flagged": flag_counts[i] > 0,
                "fc": flag_counts[i]
            });
            i = i + 1;
        }

        running = {"val": True};
        mouse = {"x": -999, "y": -999, "drag": -1, "hover": -1};
        frame = {"val": 0};

        def simulate() {
            # Repulsion — all pairs
            ni2 = 0;
            while ni2 < count {
                nj = ni2 + 1;
                while nj < count {
                    dx = nodes[nj]["x"] - nodes[ni2]["x"];
                    dy = nodes[nj]["y"] - nodes[ni2]["y"];
                    d = Math.sqrt(dx * dx + dy * dy) + 1;
                    f = 4000 / (d * d);
                    fx = (dx / d) * f;
                    fy = (dy / d) * f;
                    nodes[ni2]["vx"] = nodes[ni2]["vx"] - fx;
                    nodes[ni2]["vy"] = nodes[ni2]["vy"] - fy;
                    nodes[nj]["vx"] = nodes[nj]["vx"] + fx;
                    nodes[nj]["vy"] = nodes[nj]["vy"] + fy;
                    nj = nj + 1;
                }
                ni2 = ni2 + 1;
            }
            # Edge spring
            ej = 0;
            while ej < len(edges) {
                s = edges[ej]["source"];
                t = edges[ej]["target"];
                dx = nodes[t]["x"] - nodes[s]["x"];
                dy = nodes[t]["y"] - nodes[s]["y"];
                d = Math.sqrt(dx * dx + dy * dy) + 1;
                ideal = 140;
                f = (d - ideal) * 0.006;
                fx = (dx / d) * f;
                fy = (dy / d) * f;
                nodes[s]["vx"] = nodes[s]["vx"] + fx;
                nodes[s]["vy"] = nodes[s]["vy"] + fy;
                nodes[t]["vx"] = nodes[t]["vx"] - fx;
                nodes[t]["vy"] = nodes[t]["vy"] - fy;
                ej = ej + 1;
            }
            # Gentle center pull
            ci = 0;
            while ci < count {
                nodes[ci]["vx"] = nodes[ci]["vx"] + (cx - nodes[ci]["x"]) * 0.002;
                nodes[ci]["vy"] = nodes[ci]["vy"] + (cy - nodes[ci]["y"]) * 0.002;
                ci = ci + 1;
            }
            # Integrate
            pad = 60;
            ui = 0;
            while ui < count {
                if ui != mouse["drag"] {
                    nodes[ui]["vx"] = nodes[ui]["vx"] * 0.8;
                    nodes[ui]["vy"] = nodes[ui]["vy"] * 0.8;
                    nodes[ui]["x"] = nodes[ui]["x"] + nodes[ui]["vx"];
                    nodes[ui]["y"] = nodes[ui]["y"] + nodes[ui]["vy"];
                }
                nodes[ui]["x"] = Math.max(pad, Math.min(w - pad, nodes[ui]["x"]));
                nodes[ui]["y"] = Math.max(pad, Math.min(h - pad, nodes[ui]["y"]));
                ui = ui + 1;
            }
        }

        def draw(ts: any) {
            ctx.clearRect(0, 0, w, h);

            # Edges
            di = 0;
            while di < len(edges) {
                e = edges[di];
                s = nodes[e["source"]];
                t = nodes[e["target"]];
                hl = mouse["hover"] == e["source"] or mouse["hover"] == e["target"];

                # Curved edges to reduce overlap
                mx = (s["x"] + t["x"]) / 2;
                my = (s["y"] + t["y"]) / 2;
                dx = t["x"] - s["x"];
                dy = t["y"] - s["y"];
                # Offset perpendicular for curve
                offset = 0;
                if len(edges) > 3 {
                    offset = 15 * (di % 2 * 2 - 1) if di > 0 else 0;
                }
                cpx = mx + (-dy / (Math.sqrt(dx*dx + dy*dy) + 1)) * offset;
                cpy = my + (dx / (Math.sqrt(dx*dx + dy*dy) + 1)) * offset;

                ctx.beginPath();
                ctx.moveTo(s["x"], s["y"]);
                ctx.quadraticCurveTo(cpx, cpy, t["x"], t["y"]);

                if e["flagged"] {
                    a = 0.8 if hl else 0.35;
                    ctx.strokeStyle = "rgba(255, 59, 48, " + str(a) + ")";
                    ctx.lineWidth = 2.5 if hl else 1.8;
                    ctx.setLineDash([]);
                } else {
                    a = 0.6 if hl else 0.15;
                    ctx.strokeStyle = "rgba(0, 0, 0, " + str(a) + ")";
                    ctx.lineWidth = 1.5 if hl else 0.8;
                    ctx.setLineDash([5, 5]);
                }
                ctx.stroke();
                ctx.setLineDash([]);

                # Edge label on hover
                if hl {
                    label = e["type"].replace("_", " ");
                    ctx.font = "500 10px -apple-system, sans-serif";
                    tw = ctx.measureText(label).width;
                    lx = cpx;
                    ly = cpy;
                    ctx.fillStyle = "rgba(255,255,255,0.92)";
                    ctx.beginPath();
                    ctx.roundRect(lx - tw / 2 - 6, ly - 8, tw + 12, 16, 4);
                    ctx.fill();
                    ctx.fillStyle = "#ff3b30" if e["flagged"] else "#424245";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    ctx.fillText(label, lx, ly);
                }
                di = di + 1;
            }

            # Nodes
            ni3 = 0;
            while ni3 < count {
                n = nodes[ni3];
                hv = mouse["hover"] == ni3;
                r = 20 if hv else 17;

                # Pulse for flagged
                if n["flagged"] {
                    pulse = Math.sin((ts or 0) / 500 + ni3) * 0.03 + 0.1;
                    ctx.beginPath();
                    ctx.arc(n["x"], n["y"], r + 8, 0, Math.PI * 2);
                    ctx.fillStyle = "rgba(255, 59, 48, " + str(pulse) + ")";
                    ctx.fill();
                }

                # Shadow
                ctx.beginPath();
                ctx.arc(n["x"], n["y"] + 1, r, 0, Math.PI * 2);
                ctx.fillStyle = "rgba(0,0,0,0.05)";
                ctx.fill();

                # Circle
                ctx.beginPath();
                ctx.arc(n["x"], n["y"], r, 0, Math.PI * 2);
                if n["flagged"] {
                    ctx.fillStyle = "#fff5f5" if not hv else "#ffecec";
                    ctx.strokeStyle = "#ff3b30";
                    ctx.lineWidth = 2;
                } else {
                    ctx.fillStyle = "#ffffff" if not hv else "#f0f0f5";
                    ctx.strokeStyle = "#007aff" if hv else "rgba(0,0,0,0.12)";
                    ctx.lineWidth = 1.5;
                }
                ctx.fill();
                ctx.stroke();

                # Abbreviation inside
                abbr = n["id"][0:3].toUpperCase();
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.font = "600 10px -apple-system, sans-serif";
                ctx.fillStyle = "#ff3b30" if n["flagged"] else "#1d1d1f";
                ctx.fillText(abbr, n["x"], n["y"]);

                # Full name below
                ctx.font = "500 10px -apple-system, sans-serif" if hv else "10px -apple-system, sans-serif";
                ctx.fillStyle = "#1d1d1f" if hv else "#86868b";
                ly = n["y"] + r + 12;
                tw = ctx.measureText(n["id"]).width;
                ctx.fillStyle = "rgba(245,245,247,0.85)";
                ctx.beginPath();
                ctx.roundRect(n["x"] - tw / 2 - 4, ly - 6, tw + 8, 13, 3);
                ctx.fill();
                ctx.fillStyle = "#1d1d1f" if (hv or n["flagged"]) else "#86868b";
                ctx.fillText(n["id"], n["x"], ly);

                # Badge
                if n["flagged"] and n["fc"] > 1 {
                    bx = n["x"] + r * 0.65;
                    by = n["y"] - r * 0.65;
                    ctx.beginPath();
                    ctx.arc(bx, by, 7, 0, Math.PI * 2);
                    ctx.fillStyle = "#ff3b30";
                    ctx.fill();
                    ctx.font = "600 8px -apple-system, sans-serif";
                    ctx.fillStyle = "#ffffff";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    ctx.fillText(str(n["fc"]), bx, by);
                }
                ni3 = ni3 + 1;
            }

            # Tooltip
            if mouse["hover"] >= 0 {
                hn = nodes[mouse["hover"]];
                conn = 0;
                eci = 0;
                while eci < len(edges) {
                    if edges[eci]["source"] == mouse["hover"] or edges[eci]["target"] == mouse["hover"] {
                        conn = conn + 1;
                    }
                    eci = eci + 1;
                }
                tip = hn["id"];
                if conn > 0 {
                    tip = tip + " " + String.fromCharCode(183) + " " + str(conn) + " interaction" + ("s" if conn > 1 else "");
                }
                if hn["flagged"] {
                    tip = tip + " " + String.fromCharCode(183) + " " + str(hn["fc"]) + " chain" + ("s" if hn["fc"] > 1 else "");
                }
                ctx.font = "500 12px -apple-system, sans-serif";
                tw = ctx.measureText(tip).width;
                tx = Math.max(8, Math.min(hn["x"] - tw / 2 - 10, w - tw - 24));
                ty = hn["y"] - 44;
                if ty < 8 { ty = hn["y"] + 36; }
                ctx.fillStyle = "rgba(29,29,31,0.9)";
                ctx.beginPath();
                ctx.roundRect(tx, ty, tw + 20, 28, 8);
                ctx.fill();
                ctx.fillStyle = "#ffffff";
                ctx.textAlign = "left";
                ctx.textBaseline = "middle";
                ctx.fillText(tip, tx + 10, ty + 14);
            }
        }

        # Mouse handlers
        def hit(mx: any, my: any) -> int {
            gi = count - 1;
            while gi >= 0 {
                dx = mx - nodes[gi]["x"];
                dy = my - nodes[gi]["y"];
                if dx * dx + dy * dy < 625 {
                    return gi;
                }
                gi = gi - 1;
            }
            return -1;
        }
        def on_mm(e: any) {
            r = canvas.getBoundingClientRect();
            mouse["x"] = e.clientX - r.left;
            mouse["y"] = e.clientY - r.top;
            if mouse["drag"] >= 0 {
                nodes[mouse["drag"]]["x"] = mouse["x"];
                nodes[mouse["drag"]]["y"] = mouse["y"];
                nodes[mouse["drag"]]["vx"] = 0;
                nodes[mouse["drag"]]["vy"] = 0;
            }
            mouse["hover"] = hit(mouse["x"], mouse["y"]);
            canvas.style.cursor = "grabbing" if mouse["drag"] >= 0 else ("grab" if mouse["hover"] >= 0 else "default");
        }
        def on_md(e: any) {
            r = canvas.getBoundingClientRect();
            h2 = hit(e.clientX - r.left, e.clientY - r.top);
            if h2 >= 0 {
                mouse["drag"] = h2;
                canvas.style.cursor = "grabbing";
            }
        }
        def on_mu(e: any) {
            mouse["drag"] = -1;
        }
        def on_ml(e: any) {
            mouse["hover"] = -1;
            mouse["drag"] = -1;
            canvas.style.cursor = "default";
        }
        canvas.addEventListener("mousemove", on_mm);
        canvas.addEventListener("mousedown", on_md);
        canvas.addEventListener("mouseup", on_mu);
        canvas.addEventListener("mouseleave", on_ml);

        def tick(ts: any) {
            if not running["val"] { return; }
            simulate();
            draw(ts);
            requestAnimationFrame(tick);
        }
        requestAnimationFrame(tick);

        return lambda {
            running["val"] = False;
            canvas.removeEventListener("mousemove", on_mm);
            canvas.removeEventListener("mousedown", on_md);
            canvas.removeEventListener("mouseup", on_mu);
            canvas.removeEventListener("mouseleave", on_ml);
        };
    }, [medications, interactions, flagged_paths]);

    return <div style={{
        "backgroundColor": "#ffffff",
        "borderRadius": "20px",
        "padding": "20px 24px",
        "marginBottom": "16px",
        "boxShadow": "0 1px 3px rgba(0,0,0,0.04)"
    }}>
        <div style={{
            "display": "flex",
            "justifyContent": "space-between",
            "alignItems": "center",
            "marginBottom": "12px"
        }}>
            <div style={{
                "fontSize": "15px",
                "fontWeight": "600",
                "color": "#1d1d1f",
                "letterSpacing": "-0.01em"
            }}>{"Interaction Graph"}</div>
            <div style={{"display": "flex", "gap": "12px", "fontSize": "11px", "color": "#86868b", "alignItems": "center"}}>
                <span style={{"display": "flex", "alignItems": "center", "gap": "4px"}}>
                    <span style={{"display": "inline-block", "width": "10px", "height": "2px", "backgroundColor": "#ff3b30", "borderRadius": "1px"}}></span>
                    {"flagged"}
                </span>
                <span style={{"display": "flex", "alignItems": "center", "gap": "4px"}}>
                    <span style={{"display": "inline-block", "width": "10px", "height": "1px", "backgroundColor": "#aeaeb2", "borderStyle": "dashed"}}></span>
                    {"interaction"}
                </span>
                <span style={{"color": "#c7c7cc"}}>{"drag to move"}</span>
            </div>
        </div>
        <canvas
            ref={canvas_ref}
            style={{
                "width": "100%",
                "height": "480px",
                "borderRadius": "14px",
                "backgroundColor": "#f5f5f7"
            }}
        />
    </div>;
}
