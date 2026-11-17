# Replication package: A comment on Beattie, Poretlli and Woodman (2025)

Replication materials for the Institute for Replication (I4R) comment on:

> Beattie, S., Poretlli, N., & Woodman, T. (2025). What determines performance satisfaction in mountain ultra marathon runners? An exploration of coping, resilience, and mental toughness. *International Journal of Sport and Exercise Psychology*. https://doi.org/10.1080/1612197X.2025.2570196

Author of the replication: Sumit Mishra, Krea University
Deposit DOI: [10.5281/zenodo.24246040](https://doi.org/10.5281/zenodo.24246040)

## Overview

The code reproduces every quantitative result in the replication report. It is organised in three parts:

1. **Replication of the paper's material**: Tables 1–2 and Figures 1–5 of the original article.
2. **Verification of the I4R AI-generated report** (Barbarioli et al., 2026): the claims in its Sections 3–10.
3. **Independent analyses**: small-sample diagnostics, Bayesian analysis and further robustness checks.

## Report

The replication report is in `report/`: the PDF (`Mishra_2026_I4R_Beattie_Poretlli_Woodman_2025.pdf`) and its Typst source (`writeup.typ`, `references.bib`; compile with `typst compile writeup.typ`).

## Data availability statement

| File | Description | Source | Access | Licence | Provided |
|---|---|---|---|---|---|
| `data/Madiera data 2024.sav` | SPSS file, 49 rows (one blank) × 16 variables: five scale scores (performance satisfaction, MTI, BRS, CD-RISC, coping effectiveness) and eleven coping-frequency ratings | Authors' OSF repository, DOI 10.17605/OSF.IO/24EMA | Public | Redistribution permitted | Yes |

The file contains no names, identifiers, dates or demographic variables. It holds scale scores only; the item-level responses, demographics and qualitative answers were not deposited by the original authors.

## Computational requirements

- **R 4.6.1** (all results). Packages: tidyverse, data.table, haven, fixest, modelsummary, tsibble, rstanarm, posterior, bayesplot (loaded with `pacman::p_load`), and sandwich, lmtest, MASS, nlme and pwr (called directly). Install `pacman` first; it installs the packages it loads if they are missing. Exact versions used are in `output/sessionInfo.txt`.
- **Stata 19.5** was used only for an independent cross-check of key results; it is not needed to reproduce anything.
- Runtime: about 11 minutes in total on a standard laptop (Part 1 under a minute, Part 2 about 5 minutes, Part 3 about 6 minutes). No special hardware.
- Random seeds: 20261113 throughout; 62 for the second bootstrap of the mental-toughness interaction.

## Instructions

From the `replication_package/` folder, run:

```
Rscript run_all.R
```

This runs the three scripts in order and saves each one's full output to `output/logs/`. Each script can also be run on its own, from the same folder. R prints three warnings that exact p-values cannot be computed with ties (for the Spearman and Kendall correlations); these are expected with 1–5 ratings and do not affect the results.

| Script | Contents |
|---|---|
| `scripts/R/sm_1_paper_replication.R` | Part 1: the paper's Tables 1–2 and Figures 1–5 |
| `scripts/R/sm_2_i4r_verification.R` | Part 2: the I4R report's claims, by its section numbers |
| `scripts/R/sm_3_own_work.R` | Part 3: independent analyses |

## Map from report tables to code

Table numbers are those in the compiled replication report.

| Report table | Content | Script and section |
|---|---|---|
| Table 1 | Computational reproducibility | Assessment of the package (no code) |
| Table 2 | Replication documentation | Assessment of the package (no code) |
| Table 3 | MTI interaction, original, rescaled, capped and dropped scores | `sm_2`, Section 6 |
| Table 4 | Published results and their replication | `sm_1`: Table 1, Table 2, Figure 1, Figures 2–3, Figure 4 and Figure 5 blocks |
| Table 5 | Tests of the group difference in coping-frequency trends | `sm_2`, Section 3; `sm_3`, Sections 4.2–4.3 |
| Table 6 | Interaction under five inference methods | `sm_2`, Section 4 |
| Table 7 | Further robustness checks | `sm_3`, Sections 1.2 and 3.1–3.3 |
| Table 8 | Coping frequency–satisfaction correlation under alternatives | `sm_2`, Section 5 |
| Table 9 | Minor issues | `sm_2`, Sections 6–9 |
| Text only | Bayesian bootstrap and MCMC; joint test, joint model and summary index | `sm_3`, Sections 2.1–2.3 and 3.1 |

## Known discrepancies

- The I4R report gives an AIC gap of 77.5 between compound-symmetry and AR(1) models; this package obtains 69–72, depending on how time is entered. The report's own model specification was not available.
- Permutation and bootstrap results depend on the random seed and differ slightly from the I4R report's values.

## Use of AI

Claude Code (Anthropic; model Claude Opus 5.5) was used as an assistant during this replication: to draft and test R code, to check results against the original article and the I4R AI-generated report, and to suggest wording and table layouts. Every result in the report was run and checked by the author, and key results were reproduced independently in Stata. The author wrote the report and is responsible for its content.

## Licence

Code: MIT licence (see `LICENSE`). Data: the original authors' OSF deposit, redistributed here; see the data availability statement above.

## References

Barbarioli, B., Aparicio, J. P., Brodeur, A., Abdul Baki, G., Fazio, L., & Valenta, D. (2026). *Multi-agent reproducibility auditing with verifiable evidence* (Working paper). SSRN. https://ssrn.com/abstract=7651342
