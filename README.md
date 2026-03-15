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

Approximate total runtime (after package installation): **~5–10 minutes**, dominated by the cluster-bootstrap in `04_analysis.R`.

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

A cleaned panel dataset of South African parliamentary electoral districts covering five national election periods from 1961 to 1987. The three post-1974 elections (1977, 1981, 1987) are collapsed to a single "1977+" period at the district level. The dataset was constructed from raw election returns and mine-location records originally collected by Wilse-Samson (2013). Raw source files are not included in this repository; the cleaned file is sufficient to reproduce all results.

Approximate size: 18 KB.

| Variable | Description |
|---|---|
| `electorald` | Electoral district name (character) |
| `year` | Election year (numeric; `NA` for the collapsed "1977+" period) |
| `period` | Ordered factor: `1961`, `1966`, `1970`, `1974`, `1977+` |
| `mine` | `1` = district contains at least one gold mine; `0` otherwise |
| `treat` | `1` = mining district × post-treatment period (1977+); `0` otherwise |
| `rightshare` | Right-wing (HNP) vote share |
| `leftshare` | Left/liberal vote share |
| `npshare` | National Party vote share |
| `rightshare_gain` | First difference of `rightshare` relative to the group mean in the prior period |
| `leftshare_gain` | First difference of `leftshare` |
| `npshare_gain` | First difference of `npshare` |

---

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
| `code/04_analysis.R` | Figures 4–5, all in-text numerical results | ~ 2 minutes and 13 seconds |

**`01_DID_cases.R`**  
Produces Figure 1. Illustrates the DID logic using two stylized cases (Cases 1 and 2) from Keele et al. (2019) and Rosenbaum (2017, pp. 164–165), displaying group-level trends on both the original scale and as gain scores across two pre-treatment periods and one post-treatment period.

**`02_sens_plot_cases.R`**  
Produces Figure 2. Compares pretrends-based and discordance-based identified sets for the ATT across values of the sensitivity parameter $M \in \{0, 0.5, 1, 1.5, 2\}$ for the two stylized cases.

**`03_figures.R`**  
Produces Figure 3. Plots average right-wing vote share trends for mining versus non-mining South African electoral districts, on both the original scale and as detrended (gain-score) series.

**`04_analysis.R`**  
Produces Figures 4–5 and all numerical results reported in Section 5. Sources each custom function individually from `code/custom_functions/`. Computes the DID point estimate and cluster-bootstrap CI; estimates discordance and pretrend-violation quantities; constructs ATT bounds and their bootstrap CIs via the intersection-union method; and computes sensitivity changepoint values of $M$ for both models. Uses $R = 10{,}000$ bootstrap replications by default. To run a quick check, set `R <- 1000` near the top of the script.

The key numerical results verified against the manuscript are printed to the console upon completion:

| Quantity | Expected value |
|---|---|
| ATT point estimate | 0.11 |
| Bootstrap SE | 0.02 |
| 95% CI | [0.07, 0.15] |
| Max discordance | 0.15 (exact: 0.147) |
| Max pretrend difference | 0.03 |
| Discordance changepoint, estimate | $M^* = 0.71$ |
| Discordance changepoint, CI-based | $M^* = 0.48$ |
| Pretrend changepoint, estimate | $M^* = 3.22$ |
| Pretrend changepoint, CI-based | $M^* = 2.98$ |

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
└── manuscript/                          # submitted paper source and compiled PDF
    ├── leavitt_did-discordance-sensitivity.tex
    ├── leavitt_did-discordance-sensitivity.bbl
    ├── leavitt_did-discordance-sensitivity.pdf
    ├── Bibliography.bib
    └── obs_study_style.sty
```

---

## References


Luke J. Keele, Dylan S. Small, Jesse Y. Hsu, and Colin B. Fogarty. Patterns of effects and sensitivity analysis for differences-in-differences. arXiv Preprint, https://arxiv.org/ pdf/1901.01869, February 2019.

Paul R. Rosenbaum. Observation and Experiment: An Introduction to Causal Inference. Harvard University Press, Cambridge, MA, 2017.

Wilse-Samson, L. (2013). Structural change and democratization: Evidence from rural apartheid. Unpublished working paper, https://www.columbia.edu/~lhw2110/wilse_samson_apartheid.pdf, November 2013.

---

## License

Code is released under the [MIT License](https://opensource.org/licenses/MIT).  
Data are provided for replication purposes only.
