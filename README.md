# Overview

This document describes the replication materials for:

Leavitt, T. "Beyond Pretrends: A Discordance-Based Sensitivity Analysis for Difference-in-Differences." Accepted at *Observational Studies*.

---

## Computational Requirements

All replication code was run on a **2023 MacBook Pro (Apple M3 Max, 36 GB RAM)**  
using **macOS Sonoma 14.7.1**.

- **R version:** 4.4.2
- **Required R packages:**
  - `rlang` (v. 1.1.4)
  - `dplyr` (v. 1.1.4)
  - `tidyr` (v. 1.3.1)
  - `purrr` (v. 1.0.2)
  - `stringr` (v. 1.5.1)
  - `tibble` (v. 3.2.1)
  - `ggplot2` (v. 3.5.1)
  - `ggh4x` (v. 0.2.8)
  - `remotes` (used to install the specific package versions above)

The script **`install_packages.R`** uses the `remotes` package to install the exact versions of `rlang`, `dplyr`, `tidyr`, `purrr`, `stringr`, `tibble`, `ggplot2`, and `ggh4x` needed to reproduce the results.

Approximate total runtime (after package installation): **~4 minutes**, dominated by the two cluster bootstraps in `04_analysis.R` (10,000 replications each).

---

## Setup

### Step 1 — Open the R project

Open **`did-discordance-sensitivity.Rproj`** in RStudio. This sets the working directory to the project root automatically, so all relative file paths in the scripts resolve correctly.

Alternatively, set the working directory manually from any R session:

```r
setwd("/path/to/did-discordance-sensitivity")
```

### Step 2 — Install packages

Run the following once to install all required packages at the exact versions used in the replication:

```r
source("install_packages.R")
```

### Step 3 — Run the full replication

To reproduce all results in the manuscript, run:

```r
source("master.R")
```

from the project root. `master.R` calls `install_packages.R` and then sources the four analysis scripts in order. All file paths are relative to the project root; no manual changes to the working directory are required.

---

## Data

**File:** `data/wilse-samson_data.rds`

A cleaned panel dataset of South African parliamentary electoral districts covering five national election periods from 1961 to 1987. The three post-1974 elections (1977, 1981, 1987) are collapsed to a single "1977+" period at the district level. The file contains 167 districts; the analysis scripts keep the 153 that are observed in at least one pre-treatment election and drop the 14 that appear only in the 1977+ period (see Revision history). The dataset was constructed from raw election returns and mine-location records originally collected by Wilse-Samson (2013). Raw source files are not included in this repository; the cleaned file is sufficient to reproduce all results.

Approximate size: 18 KB.

| Variable | Description |
|---|---|
| `electorald` | Electoral district name (character) |
| `year` | Election year (numeric; `NA` for the collapsed "1977+" period) |
| `npshare` | National Party vote share |
| `leftshare` | Left/liberal vote share |
| `rightshare` | Right-wing (HNP) vote share |
| `mine` | `1` = district contains at least one gold mine; `0` otherwise |
| `treat` | `1` = mining district × post-treatment period (1977+); `0` otherwise |
| `period` | Election period (character): `"1961"`, `"1966"`, `"1970"`, `"1974"`, `"1977+"`; coerced to an ordered factor in the analysis scripts |
| `lag_mean_npshare` | Group mean of `npshare` in the immediately preceding period; `NA` for 1961 (no prior period) |
| `lag_mean_rightshare` | Group mean of `rightshare` in the immediately preceding period; `NA` for 1961 (no prior period) |
| `lag_mean_leftshare` | Group mean of `leftshare` in the immediately preceding period; `NA` for 1961 (no prior period) |
| `npshare_gain` | First difference of `npshare` relative to the group mean in the prior period; `NA` for 1961 (no prior period) |
| `rightshare_gain` | First difference of `rightshare` relative to the group mean in the prior period; `NA` for 1961 (no prior period) |
| `leftshare_gain` | First difference of `leftshare` relative to the group mean in the prior period; `NA` for 1961 (no prior period) |
## Code

All scripts are in `code/` and must be run from the project root (not from within `code/`). They are sourced in order by `master.R`.

### Custom Functions (`code/custom_functions/`)

Each function used by `04_analysis.R` lives in its own script. They are sourced individually in the order listed below.

**`DID_estimator.R`**  
Implements `DID_estimator()` — the difference-in-differences estimate of the ATT.

**`comp_abs_diff.R`**  
Implements `comp_abs_diff()` — the discordance between a candidate counterfactual imputation and the parallel-trends imputation (Section 4 of the manuscript).

**`pre_diff_trends.R`**  
Implements `pre_diff_trends()` — the absolute pre-period trend difference between treated and control groups (pretrends benchmark).

**`ATT_bounds_CI.R`**  
Implements `ATT_bounds_CI()` — the intersection-union CI for ATT bounds under a given sensitivity model.

**`changepoint_M.R`**  
Implements `changepoint_M()` — locates the value of M at which ATT bounds (or their CI) first contain zero. Designed for use with `uniroot()`. Depends on `ATT_bounds_CI()`, so `ATT_bounds_CI.R` must be sourced first.

### Replication Scripts (`code/`)

| Script | Manuscript output | Approx. runtime |
|---|---|---|
| `code/01_DID_cases.R` | Figure 1 | < 1 second |
| `code/02_sens_plot_cases.R` | Figure 2 | < 1 second |
| `code/03_figures.R` | Figure 3 | < 1 second |
| `code/04_analysis.R` | Figures 4–5, all in-text numerical results | ~ 4 minutes |

**`01_DID_cases.R`**  
Produces Figure 1. Illustrates the DID logic using two stylized cases (Cases 1 and 2) from Keele et al. (2019) and Rosenbaum (2017, pp. 164–165), displaying group-level trends on both the original scale and as gain scores across two pre-treatment periods and one post-treatment period.

**`02_sens_plot_cases.R`**  
Produces Figure 2. Compares pretrends-based and discordance-based identified sets for the ATT across values of the sensitivity parameter $M \in \{0, 0.5, 1, 1.5, 2\}$ for the two stylized cases. Each column has its own $y$-axis, centered on that case's ATT under parallel trends (30 for Case 1, 50 for Case 2) with a common span, so the bar widths are comparable across columns.

**`03_figures.R`**  
Produces Figure 3. Plots average right-wing vote share trends for mining versus non-mining South African electoral districts, on both the original scale and as detrended (gain-score) series.

**`04_analysis.R`**  
Produces Figures 4–5 and all numerical results reported in Section 7 (the application). Sources each custom function individually from `code/custom_functions/`. Computes the DID point estimate and cluster-bootstrap CI; estimates discordance and pretrend-violation quantities; constructs ATT bounds and their bootstrap CIs via the intersection-union method; and computes sensitivity changepoint values of $M$ for both models. Uses $R = 10{,}000$ bootstrap replications by default. To run a quick check, set `R <- 1000` near the top of the script.

The key numerical results verified against the manuscript are printed to the console upon completion:

| Quantity | Expected value |
|---|---|
| ATT point estimate | 0.11 |
| Bootstrap SE | 0.02 |
| 95% CI | [0.06, 0.15] |
| Max discordance | 0.15 (exact: 0.148) |
| Max pretrend difference | 0.03 |
| Discordance changepoint, estimate | $M^* = 0.71$ |
| Discordance changepoint, CI-based | $M^* = 0.41$ |
| Pretrend changepoint, estimate | $M^* = 3.20$ |
| Pretrend changepoint, CI-based | $M^* = 1.93$ |

---

## Output

Pre-built figures are included in `output/figures/` and correspond to the manuscript as follows:

| File | Manuscript location |
|---|---|
| `output/figures/DID_cases_1_2_plot.pdf` | Figure 1 |
| `output/figures/sens_plot_cases.pdf` | Figure 2 |
| `output/figures/wilse-samson_plot.pdf` | Figure 3 |
| `output/figures/sens_analysis.pdf` | Figure 4 |
| `output/figures/sens_analysis_comp.pdf` | Figure 5 |

---

## Repository Structure

```
did-discordance-sensitivity/
├── did-discordance-sensitivity.Rproj   # R project file (open this in RStudio)
├── master.R                             # sources install_packages.R then all scripts
├── install_packages.R                   # installs exact package versions via remotes
├── README.md
├── .gitignore
│
├── data/
│   └── wilse-samson_data.rds            # cleaned South Africa panel dataset
│
├── code/
│   ├── custom_functions/
│   │   ├── DID_estimator.R              # DID_estimator()
│   │   ├── comp_abs_diff.R              # comp_abs_diff()
│   │   ├── pre_diff_trends.R            # pre_diff_trends()
│   │   ├── ATT_bounds_CI.R              # ATT_bounds_CI()
│   │   └── changepoint_M.R             # changepoint_M()  (depends on ATT_bounds_CI)
│   ├── 01_DID_cases.R                   # Figure 1
│   ├── 02_sens_plot_cases.R             # Figure 2
│   ├── 03_figures.R                     # Figure 3
│   └── 04_analysis.R                    # Figures 4–5, all in-text numerical results
│
├── output/
│   └── figures/                         # pre-built PDFs of all manuscript figures
│       ├── DID_cases_1_2_plot.pdf
│       ├── sens_plot_cases.pdf
│       ├── wilse-samson_plot.pdf
│       ├── sens_analysis.pdf
│       └── sens_analysis_comp.pdf
│
└── manuscript/                          # accepted paper source (corrected at proof stage, October 2026) and compiled PDF
    ├── leavitt_did-discordance-sensitivity.tex
    ├── leavitt_did-discordance-sensitivity.bbl
    ├── leavitt_did-discordance-sensitivity.pdf
    ├── Bibliography.bib
    └── obs_study_style.sty
```

---

## Revision history

**October 2026 (page-proof stage).** Four corrections were made to the code while checking the proofs, and the manuscript's numbers and figures were updated to match:

1. `04_analysis.R`: the cluster bootstrap now carries duplicate districts (a district drawn *k* times appears *k* times); the earlier `filter(electorald %in% sampled_clusters)` kept each drawn district once.
2. `04_analysis.R`: the bootstrap for the pretrend violations recomputes the pre-period difference in trends from outcome levels within each resample (`use_gain_score = FALSE`), as the point estimate does; the earlier version compared stored gain scores that the resample did not update.
3. `03_figures.R` and `04_analysis.R`: the 14 districts that appear only in the 1977+ period are dropped before any computation (153 districts remain); they have no pre-period outcome and contributed nothing to the DID.
4. `02_sens_plot_cases.R`: the benchmark ATT for the stylized cases is computed per case (30 for Case 1, 50 for Case 2) instead of a hard-coded 10, and each column of Figure 2 has its own y-axis centered on that case's ATT with a common span.

The numbers in the table above and in the figures reflect these corrections (previously: 95% CI [0.07, 0.15], maximum discordance 0.147, CI-based changepoints 0.48 and 2.98, bounds-based pretrend changepoint 3.22).

## References

Luke J. Keele, Dylan S. Small, Jesse Y. Hsu, and Colin B. Fogarty. Patterns of effects and sensitivity analysis for differences-in-differences. arXiv Preprint, https://arxiv.org/pdf/1901.01869, February 2019.

Paul R. Rosenbaum. Observation and Experiment: An Introduction to Causal Inference. Harvard University Press, Cambridge, MA, 2017.

Wilse-Samson, L. (2013). Structural change and democratization: Evidence from rural apartheid. Unpublished working paper, https://www.columbia.edu/~lhw2110/wilse_samson_apartheid.pdf, November 2013.

---

## License

Code is released under the [MIT License](https://opensource.org/licenses/MIT).  
Data are provided for replication purposes only.
