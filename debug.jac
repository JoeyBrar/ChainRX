"""Debug: check what spawn returns."""

import from graph { Drug, InteractsWith }
import from walkers { ChainWalker }

with entry {
    a = Drug(name="Warfarin");
    b = Drug(name="Aspirin");
    a +>:InteractsWith(interaction_type="bleeding_risk", mechanism="test", severity=0.7):+> b;
    b +>:InteractsWith(interaction_type="bleeding_risk", mechanism="test", severity=0.7):+> a;

    result = ChainWalker(
        current_path=[],
        accumulated_risk=0.0,
        flagged_chains=[],
        max_depth=3,
        last_interaction_type=""
    ) spawn a;

    print(f"type: {type(result)}");
    print(f"result: {result}");
}
