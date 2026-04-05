"""Compounding rules for multi-drug chain risk escalation."""

glob COMPOUNDING_RULES: dict[tuple, float] = {
    # Kidney cascade: NSAID reduces kidney function -> metformin/other accumulates
    ("reduces_kidney_function", "additive_kidney_stress"): 1.5,
    ("reduces_kidney_function", "reduced_clearance"): 1.6,
    ("additive_kidney_stress", "reduces_kidney_function"): 1.4,
    ("reduces_kidney_function", "hyperkalemia_risk"): 1.4,
    ("hyperkalemia_risk", "reduces_kidney_function"): 1.3,

    # Serotonin cascade: multiple serotonergic agents compound
    ("serotonin_increase", "serotonin_increase"): 1.8,

    # Bleeding cascade: anticoagulant + antiplatelet + NSAID
    ("bleeding_risk", "bleeding_risk"): 1.7,
    ("bleeding_risk", "reduces_kidney_function"): 1.3,

    # QT prolongation cascade
    ("qt_prolongation", "qt_prolongation"): 1.6,
    ("qt_prolongation", "serotonin_increase"): 1.2,

    # CNS depression cascade
    ("cns_depression", "cns_depression"): 1.7,
    ("cns_depression", "serotonin_increase"): 1.3,

    # Hypotension cascade
    ("additive_hypotension", "reduces_kidney_function"): 1.4,
    ("additive_hypotension", "additive_hypotension"): 1.5
};

glob RISK_THRESHOLD: float = 0.6;

def get_multiplier(upstream: str, downstream: str) -> float {
    key = (upstream, downstream);
    if key in COMPOUNDING_RULES {
        return COMPOUNDING_RULES[key];
    }
    return 1.0;
}
