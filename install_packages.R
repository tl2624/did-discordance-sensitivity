# =============================================================================
# install_packages.R
#
# Installs the exact package versions required to reproduce the analysis.
# Run this script once before executing any other script in the repo.
#
# The script uses the `remotes` package to install specific versions from CRAN.
# Requires an internet connection and standard R build tools:
#   - Windows: Rtools (https://cran.r-project.org/bin/windows/Rtools/)
#   - macOS:   Xcode command-line tools (`xcode-select --install`)
#
# Built and tested under R 4.4.2.
# =============================================================================

## Install remotes (used to install specific package versions)
install.packages("remotes")   # ensures remotes is available

## Install the exact package versions used in the replication
remotes::install_version("rlang",   version = "1.1.4", upgrade = "never")
remotes::install_version("cli",     version = "3.6.3", upgrade = "never")
remotes::install_version("glue",    version = "1.8.0", upgrade = "never")
remotes::install_version("vctrs",   version = "0.6.5", upgrade = "never")

remotes::install_version("tibble",  version = "3.2.1", upgrade = "never")
remotes::install_version("dplyr",   version = "1.1.4", upgrade = "never")
remotes::install_version("tidyr",   version = "1.3.1", upgrade = "never")
remotes::install_version("purrr",   version = "1.0.2", upgrade = "never")
remotes::install_version("stringr", version = "1.5.1", upgrade = "never")
remotes::install_version("ggplot2", version = "3.5.1", upgrade = "never")
remotes::install_version("ggh4x",   version = "0.2.8", upgrade = "never")