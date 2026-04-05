"""Drug interaction dataset for ChainRX. Real, medically documented interactions."""

glob DRUG_INTERACTIONS: list[dict] = [
    # === TRIPLE WHAMMY (ACEi/ARB + NSAID + Diuretic/Metformin) ===
    {
        "drug_a": "Ibuprofen",
        "drug_b": "Lisinopril",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce renal prostaglandin synthesis, blunting ACE inhibitor renal protection",
        "severity": 0.55
    },
    {
        "drug_a": "Ibuprofen",
        "drug_b": "Metformin",
        "type": "additive_kidney_stress",
        "mechanism": "NSAIDs impair renal clearance of metformin, increasing lactic acidosis risk",
        "severity": 0.5
    },
    {
        "drug_a": "Lisinopril",
        "drug_b": "Metformin",
        "type": "additive_kidney_stress",
        "mechanism": "Both drugs depend on renal clearance; combined use in renal impairment raises toxicity",
        "severity": 0.35
    },
    {
        "drug_a": "Ibuprofen",
        "drug_b": "Furosemide",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce diuretic efficacy and worsen renal perfusion when combined with loop diuretics",
        "severity": 0.5
    },
    {
        "drug_a": "Lisinopril",
        "drug_b": "Furosemide",
        "type": "additive_hypotension",
        "mechanism": "ACE inhibitor plus diuretic causes excessive blood pressure drop and renal hypoperfusion",
        "severity": 0.4
    },

    # === SEROTONIN SYNDROME CHAINS ===
    {
        "drug_a": "Sertraline",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "SSRI plus opioid with serotonergic activity causes additive serotonin accumulation",
        "severity": 0.6
    },
    {
        "drug_a": "Sertraline",
        "drug_b": "Ondansetron",
        "type": "serotonin_increase",
        "mechanism": "SSRI combined with 5-HT3 antagonist may increase serotonergic tone via receptor modulation",
        "severity": 0.3
    },
    {
        "drug_a": "Tramadol",
        "drug_b": "Ondansetron",
        "type": "serotonin_increase",
        "mechanism": "Both agents affect serotonin pathways; combined use elevates serotonin syndrome risk",
        "severity": 0.35
    },
    {
        "drug_a": "Fluoxetine",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "SSRI plus MAOI causes dangerous serotonin accumulation — contraindicated combination",
        "severity": 0.95
    },
    {
        "drug_a": "Fluoxetine",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "Fluoxetine inhibits CYP2D6 and increases serotonin; tramadol adds serotonergic load",
        "severity": 0.65
    },
    {
        "drug_a": "Sertraline",
        "drug_b": "Lithium",
        "type": "serotonin_increase",
        "mechanism": "Lithium augments serotonergic transmission; combined with SSRI raises syndrome risk",
        "severity": 0.45
    },
    {
        "drug_a": "Tramadol",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "Tramadol serotonin reuptake inhibition combined with MAO inhibition — potentially fatal",
        "severity": 0.9
    },

    # === BLEEDING RISK CHAINS ===
    {
        "drug_a": "Warfarin",
        "drug_b": "Aspirin",
        "type": "bleeding_risk",
        "mechanism": "Anticoagulant plus antiplatelet synergistically impairs hemostasis",
        "severity": 0.7
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "NSAIDs inhibit platelet function and may displace warfarin from protein binding",
        "severity": 0.65
    },
    {
        "drug_a": "Aspirin",
        "drug_b": "Clopidogrel",
        "type": "bleeding_risk",
        "mechanism": "Dual antiplatelet therapy significantly increases bleeding risk",
        "severity": 0.55
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Fluoxetine",
        "type": "bleeding_risk",
        "mechanism": "SSRIs impair platelet aggregation and fluoxetine inhibits CYP2C9 warfarin metabolism",
        "severity": 0.6
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Sertraline",
        "type": "bleeding_risk",
        "mechanism": "SSRIs reduce platelet serotonin uptake impairing aggregation; additive with anticoagulant",
        "severity": 0.5
    },
    {
        "drug_a": "Clopidogrel",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "NSAID plus antiplatelet increases GI bleeding risk through dual hemostasis impairment",
        "severity": 0.5
    },

    # === QT PROLONGATION CHAINS ===
    {
        "drug_a": "Amiodarone",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Both prolong QT interval; combined use increases torsades de pointes risk",
        "severity": 0.7
    },
    {
        "drug_a": "Amiodarone",
        "drug_b": "Fluoxetine",
        "type": "qt_prolongation",
        "mechanism": "Additive QT prolongation from two QT-prolonging agents",
        "severity": 0.6
    },
    {
        "drug_a": "Ondansetron",
        "drug_b": "Fluoxetine",
        "type": "qt_prolongation",
        "mechanism": "Both agents independently prolong QT; combined effect is additive",
        "severity": 0.45
    },

    # === HYPERKALEMIA RISK ===
    {
        "drug_a": "Lisinopril",
        "drug_b": "Spironolactone",
        "type": "hyperkalemia_risk",
        "mechanism": "ACE inhibitor reduces aldosterone while spironolactone blocks its receptor — additive K+ retention",
        "severity": 0.6
    },
    {
        "drug_a": "Spironolactone",
        "drug_b": "Ibuprofen",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce renal blood flow compounding potassium-sparing diuretic retention risk",
        "severity": 0.5
    },

    # === CNS DEPRESSION ===
    {
        "drug_a": "Tramadol",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine causes synergistic respiratory depression",
        "severity": 0.8
    },
    {
        "drug_a": "Diazepam",
        "drug_b": "Amitriptyline",
        "type": "cns_depression",
        "mechanism": "Benzodiazepine plus tricyclic antidepressant produces additive sedation and respiratory risk",
        "severity": 0.55
    },

    # === HEPATOTOXICITY ===
    {
        "drug_a": "Methotrexate",
        "drug_b": "Ibuprofen",
        "type": "reduced_clearance",
        "mechanism": "NSAIDs reduce renal clearance of methotrexate leading to toxic accumulation",
        "severity": 0.75
    }
];
