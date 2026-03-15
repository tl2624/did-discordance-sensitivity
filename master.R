# =============================================================================
# master.R
#
# Reproduces all figures and numerical results reported in:
#
#   Leavitt, T. "Beyond Pretrends: A Discordance-Based Sensitivity Analysis
#   for Difference-in-Differences." Accepted at Observational Studies.
#
# USAGE
#   Open did-discordance-sensitivity.Rproj in RStudio (this sets the working
#   directory to the project root automatically), then run:
#
#       source("master.R")
#
#   Or from the terminal at the project root:
#
#       Rscript master.R
#
# FIRST RUN
#   Install all required packages by running install_packages.R once before
#   running this file:
#
#       source("install_packages.R")
#
# RUNTIME (approximate, on a 2023 MacBook Pro M3 Max, 36 GB RAM)
#   install_packages.R:    ~ 65 seconds  (first run only)
#   01_DID_cases.R:        ~ 1 second
#   02_sens_plot_cases.R:  ~ 0.33 seconds
#   03_figures.R:          ~ 0.13 seconds
#   04_analysis.R:         ~ 2 minutes and 13 seconds (10,000 bootstrap replications)
#   Total (after install): ~ 2 minutes and 14 seconds
# =============================================================================

## Clear the R environment
rm(list = ls())

# Install packages -----------------------------------------------------------

source("install_packages.R")

# Stylized cases (Figures 1-2) -----------------------------------------------

source("code/01_DID_cases.R")             ## -> output/figures/DID_cases_1_2_plot.pdf  [Figure 1]

source("code/02_sens_plot_cases.R")       ## -> output/figures/sens_plot_cases.pdf      [Figure 2]

# South Africa application (Figures 3-5 + all in-text numbers) ---------------

source("code/03_figures.R")               ## -> output/figures/wilse-samson_plot.pdf   [Figure 3]

system.time(source("code/04_analysis.R")) ## -> output/figures/sens_analysis.pdf        [Figure 4]
                                          ## -> output/figures/sens_analysis_comp.pdf   [Figure 5]
