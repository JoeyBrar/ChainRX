## Inspiration

Antibacterial resistance to drugs is catching up faster than we can create new ones. To fight this, a UMich lab is making an ML pipeline intended to predict drug combination synergies that go against antibacterial resistance (If a bacteria is resistant to drug A, and drug B, it might not be resistant to a combination of drugs A + B). But there is a slight problem; although drugs A + B may suppress the bacteria, they could interact weirdly and have harmful side effects. This problem inspired ChainRx.

Over 40% of American adults over 65 take 5+ medications daily. Every drug interaction checker available — DrugBank, Medscape, Drugs.com — only check pairs. Drug A with Drug B, fine. Drug B with Drug C, fine. But when A raises levels of B, and B amplifies C's side effects, that chain compounds into something dangerous that no pairwise check catches.

Existing drug interaction tools primarily rely on pairwise checks and don’t model higher order interaction chains. We built ChainRx to fix that. Currently there is no widely adopted tool where chains are utilized for this purpose.

## What it does

Users input their medications. ChainRx models them as nodes using the Jaseci graph system. The pairwise drug interactions between each inputted medication are directed edges, with type and severity. This info is taken from drugbank.com, which is a reliable comprehensive AI-powered biomedical knowledgebase. However, because there are thousands of drugs in the database, we only took the top 150 medications. The `by llm()` function is used to get the node / edge information about other drugs in case the user inputs a drug not in our data. Then, walker agents start from each node and traverse every path up to 4 nodes deep, applying the following pharmacological compounding rules at each step:

$$
R = \sum_{i=1}^{n} s_i \cdot m(t_{i-1}, t_i)
$$

where
<ul>
  <li><b>R</b>: chain risk</li>
  <li><b>s<sub>i</sub></b>: weight_severity</li>
  <li><b>m</b>: interaction multiplier</li>
</ul>

When accumulated risk `R` exceeds the walker’s threshold value, the chain is flagged. For example, take the following triple interaction: Metformin reduces kidney function, Lisinopril adds renal stress, Ibuprofen on top triggers acute kidney injury risk. In this example, all 3 pairwise interactions are mild, but they add up to be deadly. Due to the walkers’ risk count, ChainRx is able to catch this and flag it as dangerous. 

## How we built it

ChainRx is built entirely in JAC using Object-Spatial Programming; The `Drug` nodes, `Interaction type / Mechanism / Severity` edges, and walkers that traverse the graph accumulating compounded risk. The frontend uses jac-client with medication selection and chain visualization as cards. An Anthropic API key is used for Claude Haiku 4.5. We use the LLM to summarize the drug interactions, get inputted drug data not recognized by ChainRx, and find safe drug replacements for adverse drug pairs.

## Challenges we ran into

JAC is very new, so the AI coding tools easily hallucinate its syntax. Debugging was a pain. We kept the Jaseci language reference open and validated it manually. Additionally, the vscode Jac extension’s graph visualizer had a bug; the command itself was broken, and had an error where it tried to open up a non-existent file. We had to edit the extension’s code manually to point it at the correct file to be opened.

## Accomplishments that we're proud of

We are proud that we created a completely novel solution that is translation and practical for patients and healthcare professionals. This will be able to save countless lives and is highly accessible to all populations. In addition, there is nothing in the market that does what ChainRx does right now even though multi-drug consequences are becoming increasingly very relevant for hospitals.

## What we learned

- How to build full stack applications quickly w/ Jaseci
- Object-Spatial Programming can give unique interesting solutions to niche problems where complex relations exist between objects
- When you should and shouldn’t use LLM’s for processing data, in terms of convenience, accuracy, security/privacy. 

## What's next for ChainRX

To improve ChainRx’s capabilities, we aim to get better and larger data sources by integrating US FDA adverse event reports, clinical trial data, and pharmacogenomic profiles to improve chain risk scoring. In the future, we also aim to train our own ML model on real adverse drug event outcomes to replace the rule-based multipliers with learned interaction weights that our current walkers are going by. We will still ensure that the predicted results align with current knowledge and research as grounding, and recommend a consultation with a doctor in such cases.

More importantly, we plan to embed ChainRx into EHR systems and pharmacy workflows in elderly homes and hospitals across the country for real-time multi-drug chain alerts. This would help lots of people.
