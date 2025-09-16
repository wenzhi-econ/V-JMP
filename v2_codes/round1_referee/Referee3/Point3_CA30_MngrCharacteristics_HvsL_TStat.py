#!python 3
"""
This file replicates the manager comparion table except reporting t-statistics in col (3).

RA: WWZ
Time: 2025-08-08
"""

import numpy as np
import pandas as pd
import pyfixest as pf

from pathlib import Path

path_input_data = (
    Path(__file__).parents[3]
    / "data"
    / "b_temp_data"
    / "DescTab0201_SummaryStatistics_MngrHvsL.dta"
)
path_output_table = (
    Path(__file__).parents[3]
    / "v2_output"
    / "e_round1_referees"
    / "CA30_SummaryStatistics_MngrHvsL_TStat.tex"
)
print(path_input_data)
print(path_output_table)

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 1. process the data
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

data = pd.read_stata(path_input_data)
data = data.sort_values(["IDlse", "YearMonth"])
data["YearMonth"] = data["YearMonth"].dt.to_period("M")
data["CA30"] = data["CA30"].astype("Int32")
data["occurrence"] = data.groupby("IDlse").cumcount() + 1

demo_data = data.loc[(data["occurrence"] == 1)]

post_prom_data = data.loc[(data["Post_Promotion"] == 1)]
post_prom_data = post_prom_data.groupby("IDlse")[
    ["CA30", "PayGrowth", "VPA", "LineManager", "WLAgg3"]
].agg({"CA30": "mean", "PayGrowth": "mean", "VPA": "mean", "LineManager": "mean", "WLAgg3": "max"})
post_prom_data["CA30"] = post_prom_data["CA30"].astype("Int64")
post_prom_data["WLAgg3"] = post_prom_data["WLAgg3"].astype("Int64")
for var in ["PayGrowth", "VPA", "LineManager"]:
    post_prom_data[var] = post_prom_data[var].astype(pd.Float64Dtype())

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 2. store results to be reported in the table
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??


def store_results_as_string(data: pd.DataFrame, outcome: str) -> str:
    """
    This function stores relevant statistics into two strings to be written to a tex file.
    """
    reg = pf.feols(f"{outcome} ~ CA30", data=data, vcov="HC1")
    reg.summary()
    if reg.pvalue()["CA30"] < 0.01:
        diff_mean = f"${reg.coef()["CA30"]:.3f}^{{***}}$"
    elif reg.pvalue()["CA30"] < 0.05 and reg.pvalue()["CA30"] >= 0.01:
        diff_mean = f"${reg.coef()["CA30"]:.3f}^{{**}}$"
    elif reg.pvalue()["CA30"] < 0.1 and reg.pvalue()["CA30"] >= 0.05:
        diff_mean = f"${reg.coef()["CA30"]:.3f}^{{*}}$"
    elif reg.pvalue()["CA30"] >= 0.1:
        diff_mean = f"${reg.coef()["CA30"]:.3f}$"
    diff_t = f"({reg.tstat()["CA30"]:<.3f})"
    l_mean = f"{data.loc[(data["CA30"] == 0), outcome].mean():.3f}"
    l_std = f"({data.loc[(data["CA30"] == 0), outcome].std():.3f})"
    h_mean = f"{data.loc[(data["CA30"] == 1), outcome].mean():.3f}"
    h_std = f"({data.loc[(data["CA30"] == 1), outcome].std():.3f})"

    line1 = "&" + f"{l_mean:<25}" + "&" + f"{h_mean:<25}" + "&" + f"{diff_mean:<25}" + "\\\\"
    line2 = "&" + f"{l_std:<25}" + "&" + f"{h_std:<25}" + "&" + f"{diff_t:<25}" + "\\\\"
    return (line1, line2)


# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 3. obtain the statistics
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

panels = {
    "Panel (a): demographics": ["Female", "MBA", "Econ", "Sci", "Hum", "Other", "MidCareerHire"],
    "Panel (b): performance after high-flyer status is determined": [
        "PayGrowth",
        "WLAgg3",
        "VPA",
        "LineManager",
    ],
}

post_prom_vars = set(["PayGrowth", "WLAgg3", "VPA", "LineManager"])

results = {}
for panel, outcomes in panels.items():
    for outcome in outcomes:
        data_used = post_prom_data if outcome in post_prom_vars else demo_data
        results[outcome] = store_results_as_string(data=data_used, outcome=outcome)

outcome_labels = {
    "Female": "Female",
    "MBA": "MBA",
    "Econ": "Econ, Business, and Admin",
    "Sci": "Sci, Tech, Engin, and Math",
    "Hum": "Social Sciences and Humanities",
    "Other": "Other Educ",
    "MidCareerHire": "Mid career hire",
    "PayGrowth": "Monthly salary growth",
    "WLAgg3": "Promotion work-level 3",
    "VPA": "Perf. rating (1-150)",
    "LineManager": "Effective leader (survey)",
}

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 4. output to the tex file
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

with open(path_output_table, "w") as f:
    f.write("\\begin{tabular}{lccc} \n")
    f.write("\\toprule \n")
    f.write("\\toprule \n")
    f.write(
        "Variable & \\multicolumn{1}{c}{Low-flyers} & \\multicolumn{1}{c}{High-flyers} & \\multicolumn{1}{c}{\\shortstack{Difference \\\\ t-statistic}} \\\\ \n"
    )
    f.write(
        "& \\multicolumn{1}{c}{(1)} & \\multicolumn{1}{c}{(2)} & \\multicolumn{1}{c}{(3)} \\\\ \n"
    )
    f.write("\\midrule \n")
    for panel, outcomes in panels.items():
        f.write(f"\\multicolumn{{4}}{{l}}{{\\textit{{{panel}}}}} \\\\ [+7pt] \n")
        for outcome in outcomes:
            f.write(f"{outcome_labels[outcome]}")
            f.write(f"{results[outcome][0]} \n")
            f.write(f"{results[outcome][1]} \n")
        f.write("\\midrule \n")
    f.write("Observations & 24,506 & 8,692 & 33,198 \\\\")
    f.write("\\bottomrule \\bottomrule \n")
    f.write("\\end{tabular} \n")
