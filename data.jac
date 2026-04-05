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
    {
        "drug_a": "Naproxen",
        "drug_b": "Lisinopril",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce renal prostaglandin synthesis, blunting ACE inhibitor renal protection",
        "severity": 0.55
    },
    {
        "drug_a": "Naproxen",
        "drug_b": "Furosemide",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce diuretic efficacy and worsen renal perfusion when combined with loop diuretics",
        "severity": 0.5
    },
    {
        "drug_a": "Naproxen",
        "drug_b": "Metformin",
        "type": "additive_kidney_stress",
        "mechanism": "NSAIDs impair renal clearance of metformin, increasing lactic acidosis risk",
        "severity": 0.5
    },
    {
        "drug_a": "Losartan",
        "drug_b": "Ibuprofen",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs blunt ARB renal protective effects and reduce GFR",
        "severity": 0.55
    },
    {
        "drug_a": "Losartan",
        "drug_b": "Furosemide",
        "type": "additive_hypotension",
        "mechanism": "ARB plus loop diuretic causes excessive hypotension and renal hypoperfusion",
        "severity": 0.4
    },
    {
        "drug_a": "Losartan",
        "drug_b": "Spironolactone",
        "type": "hyperkalemia_risk",
        "mechanism": "ARB reduces aldosterone while spironolactone blocks its receptor — additive K+ retention",
        "severity": 0.6
    },
    {
        "drug_a": "Losartan",
        "drug_b": "Metformin",
        "type": "additive_kidney_stress",
        "mechanism": "Both drugs depend on renal clearance; combined use in renal impairment raises toxicity",
        "severity": 0.35
    },
    {
        "drug_a": "Hydrochlorothiazide",
        "drug_b": "Lisinopril",
        "type": "additive_hypotension",
        "mechanism": "Thiazide plus ACE inhibitor causes first-dose hypotension and electrolyte imbalance",
        "severity": 0.4
    },
    {
        "drug_a": "Hydrochlorothiazide",
        "drug_b": "Ibuprofen",
        "type": "reduces_kidney_function",
        "mechanism": "NSAIDs reduce thiazide diuretic efficacy and impair renal function",
        "severity": 0.45
    },
    {
        "drug_a": "Hydrochlorothiazide",
        "drug_b": "Lithium",
        "type": "reduced_clearance",
        "mechanism": "Thiazides reduce lithium renal clearance causing toxic accumulation",
        "severity": 0.7
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
    {
        "drug_a": "Escitalopram",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "SSRI plus serotonergic opioid causes additive serotonin accumulation",
        "severity": 0.6
    },
    {
        "drug_a": "Escitalopram",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "SSRI plus MAOI causes dangerous serotonin accumulation — contraindicated",
        "severity": 0.95
    },
    {
        "drug_a": "Escitalopram",
        "drug_b": "Lithium",
        "type": "serotonin_increase",
        "mechanism": "Lithium augments serotonergic transmission; combined with SSRI raises syndrome risk",
        "severity": 0.45
    },
    {
        "drug_a": "Venlafaxine",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "SNRI plus serotonergic opioid causes additive serotonin and norepinephrine accumulation",
        "severity": 0.65
    },
    {
        "drug_a": "Venlafaxine",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "SNRI plus MAOI causes severe serotonin syndrome — contraindicated combination",
        "severity": 0.95
    },
    {
        "drug_a": "Venlafaxine",
        "drug_b": "Lithium",
        "type": "serotonin_increase",
        "mechanism": "Lithium augments serotonergic transmission; combined with SNRI raises syndrome risk",
        "severity": 0.45
    },
    {
        "drug_a": "Duloxetine",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "SNRI plus serotonergic opioid causes additive serotonin accumulation",
        "severity": 0.6
    },
    {
        "drug_a": "Duloxetine",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "SNRI plus MAOI — contraindicated due to severe serotonin syndrome risk",
        "severity": 0.95
    },
    {
        "drug_a": "Trazodone",
        "drug_b": "Sertraline",
        "type": "serotonin_increase",
        "mechanism": "Trazodone serotonin reuptake inhibition adds to SSRI serotonergic effect",
        "severity": 0.5
    },
    {
        "drug_a": "Trazodone",
        "drug_b": "Fluoxetine",
        "type": "serotonin_increase",
        "mechanism": "Fluoxetine inhibits CYP2D6, raising trazodone levels; both increase serotonin",
        "severity": 0.55
    },
    {
        "drug_a": "Trazodone",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "Both agents inhibit serotonin reuptake; combined use elevates syndrome risk",
        "severity": 0.55
    },
    {
        "drug_a": "Linezolid",
        "drug_b": "Sertraline",
        "type": "serotonin_increase",
        "mechanism": "Linezolid is a reversible MAOI; combined with SSRI causes serotonin syndrome",
        "severity": 0.85
    },
    {
        "drug_a": "Linezolid",
        "drug_b": "Fluoxetine",
        "type": "serotonin_increase",
        "mechanism": "Linezolid MAOI activity plus SSRI serotonin reuptake inhibition — high syndrome risk",
        "severity": 0.85
    },
    {
        "drug_a": "Linezolid",
        "drug_b": "Tramadol",
        "type": "serotonin_increase",
        "mechanism": "Linezolid MAOI activity combined with tramadol serotonergic effects",
        "severity": 0.8
    },
    {
        "drug_a": "Dextromethorphan",
        "drug_b": "Sertraline",
        "type": "serotonin_increase",
        "mechanism": "DXM sigma-1 agonism and serotonin reuptake inhibition adds to SSRI serotonergic load",
        "severity": 0.5
    },
    {
        "drug_a": "Dextromethorphan",
        "drug_b": "Fluoxetine",
        "type": "serotonin_increase",
        "mechanism": "Fluoxetine inhibits CYP2D6 metabolism of DXM, raising levels; both increase serotonin",
        "severity": 0.6
    },
    {
        "drug_a": "Dextromethorphan",
        "drug_b": "MAOIs",
        "type": "serotonin_increase",
        "mechanism": "DXM plus MAOI causes severe serotonin syndrome — contraindicated",
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
    {
        "drug_a": "Warfarin",
        "drug_b": "Naproxen",
        "type": "bleeding_risk",
        "mechanism": "NSAIDs inhibit platelet function and may displace warfarin from protein binding",
        "severity": 0.65
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Omeprazole",
        "type": "reduced_clearance",
        "mechanism": "Omeprazole inhibits CYP2C19, potentially increasing warfarin levels and INR",
        "severity": 0.35
    },
    {
        "drug_a": "Clopidogrel",
        "drug_b": "Omeprazole",
        "type": "reduced_clearance",
        "mechanism": "Omeprazole inhibits CYP2C19 activation of clopidogrel, reducing antiplatelet effect",
        "severity": 0.55
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Amoxicillin",
        "type": "bleeding_risk",
        "mechanism": "Amoxicillin disrupts gut flora reducing vitamin K production, potentiating warfarin",
        "severity": 0.45
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Ciprofloxacin",
        "type": "bleeding_risk",
        "mechanism": "Ciprofloxacin inhibits CYP1A2 warfarin metabolism and disrupts vitamin K gut flora",
        "severity": 0.6
    },
    {
        "drug_a": "Warfarin",
        "drug_b": "Metronidazole",
        "type": "bleeding_risk",
        "mechanism": "Metronidazole inhibits CYP2C9 metabolism of warfarin, significantly raising INR",
        "severity": 0.7
    },
    {
        "drug_a": "Apixaban",
        "drug_b": "Aspirin",
        "type": "bleeding_risk",
        "mechanism": "Direct oral anticoagulant plus antiplatelet increases major bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Apixaban",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "NSAID impairs platelet function adding to DOAC anticoagulation effect",
        "severity": 0.55
    },
    {
        "drug_a": "Apixaban",
        "drug_b": "Clopidogrel",
        "type": "bleeding_risk",
        "mechanism": "Triple antithrombotic risk — DOAC plus antiplatelet significantly raises bleeding",
        "severity": 0.6
    },
    {
        "drug_a": "Rivaroxaban",
        "drug_b": "Aspirin",
        "type": "bleeding_risk",
        "mechanism": "Direct oral anticoagulant plus antiplatelet increases major bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Rivaroxaban",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "NSAID impairs platelet function adding to DOAC anticoagulation effect",
        "severity": 0.55
    },
    {
        "drug_a": "Rivaroxaban",
        "drug_b": "Clopidogrel",
        "type": "bleeding_risk",
        "mechanism": "DOAC plus antiplatelet significantly raises major bleeding risk",
        "severity": 0.6
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
    {
        "drug_a": "Amiodarone",
        "drug_b": "Ciprofloxacin",
        "type": "qt_prolongation",
        "mechanism": "Both prolong QT interval; fluoroquinolone adds to amiodarone QT effect",
        "severity": 0.65
    },
    {
        "drug_a": "Ciprofloxacin",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Fluoroquinolone plus 5-HT3 antagonist causes additive QT prolongation",
        "severity": 0.5
    },
    {
        "drug_a": "Amiodarone",
        "drug_b": "Escitalopram",
        "type": "qt_prolongation",
        "mechanism": "Escitalopram prolongs QT; additive risk with amiodarone",
        "severity": 0.6
    },
    {
        "drug_a": "Escitalopram",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Both agents prolong QT interval; combined use raises torsades risk",
        "severity": 0.45
    },
    {
        "drug_a": "Methadone",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Methadone prolongs QT; additive effect with ondansetron QT prolongation",
        "severity": 0.6
    },
    {
        "drug_a": "Methadone",
        "drug_b": "Amiodarone",
        "type": "qt_prolongation",
        "mechanism": "Both significantly prolong QT; combination is high risk for torsades de pointes",
        "severity": 0.8
    },
    {
        "drug_a": "Methadone",
        "drug_b": "Fluoxetine",
        "type": "qt_prolongation",
        "mechanism": "Fluoxetine inhibits CYP2D6 raising methadone levels; both prolong QT",
        "severity": 0.6
    },
    {
        "drug_a": "Azithromycin",
        "drug_b": "Amiodarone",
        "type": "qt_prolongation",
        "mechanism": "Macrolide plus amiodarone causes additive QT prolongation",
        "severity": 0.6
    },
    {
        "drug_a": "Azithromycin",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Macrolide plus ondansetron causes additive QT prolongation risk",
        "severity": 0.45
    },
    {
        "drug_a": "Haloperidol",
        "drug_b": "Amiodarone",
        "type": "qt_prolongation",
        "mechanism": "Both significantly prolong QT; high risk for torsades de pointes",
        "severity": 0.75
    },
    {
        "drug_a": "Haloperidol",
        "drug_b": "Ondansetron",
        "type": "qt_prolongation",
        "mechanism": "Additive QT prolongation from antipsychotic and antiemetic",
        "severity": 0.5
    },
    {
        "drug_a": "Haloperidol",
        "drug_b": "Ciprofloxacin",
        "type": "qt_prolongation",
        "mechanism": "Antipsychotic plus fluoroquinolone causes additive QT prolongation",
        "severity": 0.5
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
    {
        "drug_a": "Lisinopril",
        "drug_b": "Trimethoprim",
        "type": "hyperkalemia_risk",
        "mechanism": "Trimethoprim blocks ENaC channels like amiloride; combined with ACEi causes dangerous hyperkalemia",
        "severity": 0.6
    },
    {
        "drug_a": "Spironolactone",
        "drug_b": "Trimethoprim",
        "type": "hyperkalemia_risk",
        "mechanism": "Both agents retain potassium through different mechanisms; additive hyperkalemia risk",
        "severity": 0.55
    },
    {
        "drug_a": "Losartan",
        "drug_b": "Trimethoprim",
        "type": "hyperkalemia_risk",
        "mechanism": "Trimethoprim potassium retention adds to ARB aldosterone suppression",
        "severity": 0.55
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
    {
        "drug_a": "Oxycodone",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine causes synergistic respiratory depression — FDA black box warning",
        "severity": 0.85
    },
    {
        "drug_a": "Oxycodone",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine causes synergistic respiratory depression — FDA black box warning",
        "severity": 0.85
    },
    {
        "drug_a": "Oxycodone",
        "drug_b": "Gabapentin",
        "type": "cns_depression",
        "mechanism": "Opioid plus gabapentinoid increases respiratory depression risk",
        "severity": 0.6
    },
    {
        "drug_a": "Tramadol",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine causes synergistic respiratory depression",
        "severity": 0.8
    },
    {
        "drug_a": "Tramadol",
        "drug_b": "Gabapentin",
        "type": "cns_depression",
        "mechanism": "Opioid plus gabapentinoid increases respiratory depression and sedation risk",
        "severity": 0.55
    },
    {
        "drug_a": "Methadone",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine causes synergistic respiratory depression — high fatality risk",
        "severity": 0.9
    },
    {
        "drug_a": "Methadone",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Opioid plus benzodiazepine causes synergistic respiratory depression — high fatality risk",
        "severity": 0.9
    },
    {
        "drug_a": "Methadone",
        "drug_b": "Gabapentin",
        "type": "cns_depression",
        "mechanism": "Opioid plus gabapentinoid increases respiratory depression risk",
        "severity": 0.6
    },
    {
        "drug_a": "Alprazolam",
        "drug_b": "Amitriptyline",
        "type": "cns_depression",
        "mechanism": "Benzodiazepine plus TCA produces additive sedation and anticholinergic effects",
        "severity": 0.55
    },
    {
        "drug_a": "Gabapentin",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Gabapentinoid plus benzodiazepine produces additive CNS and respiratory depression",
        "severity": 0.5
    },
    {
        "drug_a": "Gabapentin",
        "drug_b": "Alprazolam",
        "type": "cns_depression",
        "mechanism": "Gabapentinoid plus benzodiazepine produces additive CNS and respiratory depression",
        "severity": 0.5
    },
    {
        "drug_a": "Pregabalin",
        "drug_b": "Oxycodone",
        "type": "cns_depression",
        "mechanism": "Gabapentinoid plus opioid causes additive respiratory depression",
        "severity": 0.6
    },
    {
        "drug_a": "Pregabalin",
        "drug_b": "Diazepam",
        "type": "cns_depression",
        "mechanism": "Gabapentinoid plus benzodiazepine causes additive CNS depression",
        "severity": 0.5
    },

    # === HEPATOTOXICITY / REDUCED CLEARANCE ===
    {
        "drug_a": "Methotrexate",
        "drug_b": "Ibuprofen",
        "type": "reduced_clearance",
        "mechanism": "NSAIDs reduce renal clearance of methotrexate leading to toxic accumulation",
        "severity": 0.75
    },
    {
        "drug_a": "Methotrexate",
        "drug_b": "Naproxen",
        "type": "reduced_clearance",
        "mechanism": "NSAIDs reduce renal clearance of methotrexate leading to toxic accumulation",
        "severity": 0.75
    },
    {
        "drug_a": "Methotrexate",
        "drug_b": "Trimethoprim",
        "type": "reduced_clearance",
        "mechanism": "Trimethoprim inhibits renal tubular secretion of methotrexate causing toxic buildup",
        "severity": 0.7
    },
    {
        "drug_a": "Acetaminophen",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Chronic acetaminophen use increases INR by inhibiting vitamin K-dependent clotting factor synthesis",
        "severity": 0.4
    },
    {
        "drug_a": "Acetaminophen",
        "drug_b": "Isoniazid",
        "type": "hepatotoxicity",
        "mechanism": "Isoniazid induces CYP2E1 increasing hepatotoxic NAPQI metabolite from acetaminophen",
        "severity": 0.65
    },
    {
        "drug_a": "Simvastatin",
        "drug_b": "Amiodarone",
        "type": "reduced_clearance",
        "mechanism": "Amiodarone inhibits CYP3A4 raising simvastatin levels; high rhabdomyolysis risk",
        "severity": 0.7
    },
    {
        "drug_a": "Simvastatin",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin strongly inhibits CYP3A4, dramatically increasing statin levels and myopathy risk",
        "severity": 0.75
    },
    {
        "drug_a": "Atorvastatin",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits CYP3A4 raising atorvastatin levels; increased myopathy risk",
        "severity": 0.6
    },

    # === DIGOXIN TOXICITY ===
    {
        "drug_a": "Digoxin",
        "drug_b": "Amiodarone",
        "type": "reduced_clearance",
        "mechanism": "Amiodarone inhibits P-glycoprotein and renal clearance of digoxin, doubling levels",
        "severity": 0.75
    },
    {
        "drug_a": "Digoxin",
        "drug_b": "Clarithromycin",
        "type": "reduced_clearance",
        "mechanism": "Clarithromycin inhibits P-glycoprotein and eliminates gut flora that inactivate digoxin",
        "severity": 0.7
    },
    {
        "drug_a": "Digoxin",
        "drug_b": "Furosemide",
        "type": "additive_kidney_stress",
        "mechanism": "Furosemide-induced hypokalemia potentiates digoxin toxicity on cardiac conduction",
        "severity": 0.6
    },
    {
        "drug_a": "Digoxin",
        "drug_b": "Hydrochlorothiazide",
        "type": "additive_kidney_stress",
        "mechanism": "Thiazide-induced hypokalemia and hypomagnesemia potentiate digoxin cardiac toxicity",
        "severity": 0.55
    },
    {
        "drug_a": "Digoxin",
        "drug_b": "Verapamil",
        "type": "reduced_clearance",
        "mechanism": "Verapamil inhibits P-glycoprotein reducing digoxin clearance; additive bradycardia",
        "severity": 0.7
    },

    # === DIABETES / HYPOGLYCEMIA ===
    {
        "drug_a": "Metformin",
        "drug_b": "Glipizide",
        "type": "additive_hypoglycemia",
        "mechanism": "Sulfonylurea stimulates insulin secretion; combined with metformin increases hypoglycemia risk",
        "severity": 0.45
    },
    {
        "drug_a": "Glipizide",
        "drug_b": "Fluoxetine",
        "type": "additive_hypoglycemia",
        "mechanism": "SSRIs can increase insulin sensitivity and enhance sulfonylurea hypoglycemic effect",
        "severity": 0.4
    },
    {
        "drug_a": "Glipizide",
        "drug_b": "Ciprofloxacin",
        "type": "additive_hypoglycemia",
        "mechanism": "Fluoroquinolones can cause dysglycemia; combined with sulfonylurea worsens hypoglycemia",
        "severity": 0.5
    },
    {
        "drug_a": "Insulin",
        "drug_b": "Glipizide",
        "type": "additive_hypoglycemia",
        "mechanism": "Dual insulin-stimulating therapy significantly increases severe hypoglycemia risk",
        "severity": 0.6
    },
    {
        "drug_a": "Insulin",
        "drug_b": "Ciprofloxacin",
        "type": "additive_hypoglycemia",
        "mechanism": "Fluoroquinolones cause dysglycemia; combined with insulin increases hypoglycemia risk",
        "severity": 0.45
    },

    # === ANTICHOLINERGIC BURDEN ===
    {
        "drug_a": "Amitriptyline",
        "drug_b": "Diphenhydramine",
        "type": "anticholinergic_burden",
        "mechanism": "TCA plus antihistamine causes additive anticholinergic effects — confusion, urinary retention, delirium",
        "severity": 0.55
    },
    {
        "drug_a": "Amitriptyline",
        "drug_b": "Oxybutynin",
        "type": "anticholinergic_burden",
        "mechanism": "Dual high-anticholinergic agents cause severe dry mouth, constipation, cognitive impairment",
        "severity": 0.6
    },
    {
        "drug_a": "Diphenhydramine",
        "drug_b": "Oxybutynin",
        "type": "anticholinergic_burden",
        "mechanism": "Both high-anticholinergic agents; combined use raises delirium risk especially in elderly",
        "severity": 0.5
    },
    {
        "drug_a": "Haloperidol",
        "drug_b": "Amitriptyline",
        "type": "anticholinergic_burden",
        "mechanism": "Antipsychotic plus TCA causes additive anticholinergic toxicity and QT prolongation",
        "severity": 0.55
    },

    # === CALCIUM CHANNEL BLOCKER INTERACTIONS ===
    {
        "drug_a": "Verapamil",
        "drug_b": "Metoprolol",
        "type": "additive_hypotension",
        "mechanism": "Non-dihydropyridine CCB plus beta-blocker causes severe bradycardia and heart block",
        "severity": 0.75
    },
    {
        "drug_a": "Diltiazem",
        "drug_b": "Metoprolol",
        "type": "additive_hypotension",
        "mechanism": "Non-dihydropyridine CCB plus beta-blocker causes severe bradycardia and AV block",
        "severity": 0.7
    },
    {
        "drug_a": "Amlodipine",
        "drug_b": "Simvastatin",
        "type": "reduced_clearance",
        "mechanism": "Amlodipine inhibits CYP3A4 raising simvastatin levels; increased myopathy risk",
        "severity": 0.5
    },

    # === CORTICOSTEROID INTERACTIONS ===
    {
        "drug_a": "Prednisone",
        "drug_b": "Ibuprofen",
        "type": "bleeding_risk",
        "mechanism": "Corticosteroid plus NSAID dramatically increases GI ulceration and bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Prednisone",
        "drug_b": "Naproxen",
        "type": "bleeding_risk",
        "mechanism": "Corticosteroid plus NSAID dramatically increases GI ulceration and bleeding risk",
        "severity": 0.6
    },
    {
        "drug_a": "Prednisone",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Corticosteroids increase warfarin effect and add GI bleeding risk",
        "severity": 0.5
    },
    {
        "drug_a": "Prednisone",
        "drug_b": "Metformin",
        "type": "reduced_clearance",
        "mechanism": "Corticosteroids raise blood glucose counteracting metformin; may require dose adjustment",
        "severity": 0.4
    },
    {
        "drug_a": "Prednisone",
        "drug_b": "Insulin",
        "type": "reduced_clearance",
        "mechanism": "Corticosteroids significantly raise blood glucose requiring insulin dose increases",
        "severity": 0.45
    },

    # === THYROID INTERACTIONS ===
    {
        "drug_a": "Levothyroxine",
        "drug_b": "Omeprazole",
        "type": "reduced_clearance",
        "mechanism": "PPIs reduce gastric acid needed for levothyroxine absorption, reducing efficacy",
        "severity": 0.35
    },
    {
        "drug_a": "Levothyroxine",
        "drug_b": "Warfarin",
        "type": "bleeding_risk",
        "mechanism": "Thyroid hormone increases catabolism of vitamin K clotting factors, potentiating warfarin",
        "severity": 0.4
    }
];
