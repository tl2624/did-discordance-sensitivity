# =============================================================================
# 04_analysis.R
#
# PURPOSE: Reproduce all numerical results and Figures 4 and 5 in the
#   manuscript, for the South Africa application (Section 5).
#
#   This script:
#     (1) Computes the DID point estimate of the ATT and a cluster-bootstrap
#         standard error / 95% CI.
#     (2) Computes discordance values across all group x pre-period pairs.
#     (3) Computes pretrend trend-violation quantities for each pre-period.
#     (4) Runs a cluster-bootstrap to obtain the sampling distribution of
#         discordance and pretrend quantities (needed for CIs on ATT bounds).
#     (5) Computes sensitivity changepoint values of M for both models.
#     (6) Produces Figure 4 (discordance-based sensitivity) and
#         Figure 5 (comparison of both sensitivity approaches).
#
# CUSTOM FUNCTIONS (sourced below):
#   code/custom_functions/DID_estimator.R  --  DID_estimator()
#   code/custom_functions/comp_abs_diff.R  --  comp_abs_diff()
#   code/custom_functions/pre_diff_trends.R -- pre_diff_trends()
#   code/custom_functions/ATT_bounds_CI.R  --  ATT_bounds_CI()
#   code/custom_functions/changepoint_M.R  --  changepoint_M()
#
# DATA: data/wilse-samson_data.rds
#
# OUTPUT:
#   output/figures/sens_analysis.pdf       [Figure 4]
#   output/figures/sens_analysis_comp.pdf  [Figure 5]
#
# VERIFIED MANUSCRIPT RESULTS (Section 5):
#   ATT point estimate:          0.11
#   Bootstrap SE:                0.02
#   95% CI:                      [0.07, 0.15]
#   Max discordance:             0.15  (exact: 0.147)
#   Max pretrend difference:     0.03
#   Discordance changepoint (bounds):  M* = 0.71
#   Discordance changepoint (CI):      M* = 0.48
#   Pretrend changepoint (bounds):     M* = 3.22
#   Pretrend changepoint (CI):         M* = 2.98
#
# RUNTIME: ~5-10 minutes (10,000 bootstrap draws).
#   Set R <- 1000 for a quick check run.
#
# NOTE: Run from the repo root directory.
# =============================================================================

rm(list = ls())
library(dplyr)    # filter, mutate, group_by, summarise, bind_rows
library(tibble)   # tibble()
library(rlang)    # ensym(), as_string() -- tidy evaluation in custom functions
library(ggplot2)  # all plotting

# Source custom estimator and inference functions
source("code/custom_functions/DID_estimator.R")   # DID_estimator()
source("code/custom_functions/comp_abs_diff.R")    # comp_abs_diff()
source("code/custom_functions/pre_diff_trends.R")  # pre_diff_trends()
source("code/custom_functions/ATT_bounds_CI.R")    # ATT_bounds_CI()
source("code/custom_functions/changepoint_M.R")    # changepoint_M()  (depends on ATT_bounds_CI)

set.seed(482045732)   # global seed for reproducibility

# -----------------------------------------------------------------------------
# 1. Load and prepare data
# -----------------------------------------------------------------------------

collapsed_data <- readRDS("data/wilse-samson_data.rds")

# Restore ordered factor on election period
period_levels  <- c("1961", "1966", "1970", "1974", "1977+")
collapsed_data <- collapsed_data |>
  mutate(period = factor(period, levels = period_levels, ordered = TRUE))

# Unique cluster IDs for the cluster bootstrap (cluster = electoral district)
clusters <- unique(collapsed_data$electorald)

# Number of bootstrap replications
R <- 10^4

# =============================================================================
# SECTION 2: DID POINT ESTIMATE AND BOOTSTRAP CI
# =============================================================================

# Point estimate of the ATT via DID
# Manuscript result: ATT = 0.11
DID_est <- DID_estimator(
  data           = collapsed_data,
  outcome_var    = rightshare,
  group_var      = mine,
  time_var       = period,
  pre_period     = "1974",
  post_period    = "1977+",
  use_gain_score = FALSE
)

cat("DID point estimate:", round(DID_est, 2), "\n")  # expected: 0.11

# Cluster bootstrap for SE and 95% percentile CI
# Manuscript results: SE = 0.02, 95% CI = [0.07, 0.15]
boot_dids <- rep(NA_real_, R)

for (r in seq_len(R)) {
  # Sample electoral districts with replacement
  sampled_clusters <- sample(clusters, size = length(clusters), replace = TRUE)
  boot_data        <- filter(collapsed_data, electorald %in% sampled_clusters)

  boot_dids[r] <- DID_estimator(
    data           = boot_data,
    outcome_var    = rightshare,
    group_var      = mine,
    time_var       = period,
    pre_period     = "1974",
    post_period    = "1977+",
    use_gain_score = FALSE
  )
}

cat("Bootstrap SE:", round(sd(boot_dids), 2), "\n")        # expected: 0.02
cat("95% CI: [",
    round(quantile(boot_dids, 0.025), 2), ",",
    round(quantile(boot_dids, 0.975), 2), "]\n")           # expected: [0.07, 0.15]

# =============================================================================
# SECTION 3: DISCORDANCE-BASED SENSITIVITY
# =============================================================================

# Evaluate discordance for all group x pre-period combinations.
# group in {0 (control), 1 (treated)};
# pre-period in pre-treatment periods with a lag available (exclude 1961).
group_values <- 0:1

# Pre-treatment periods for mining (treated) units, excluding the earliest
pre_periods <- sort(unique(
  collapsed_data$period[collapsed_data$mine == 1 & collapsed_data$treat == 0]
))[-1]

combo_grid  <- expand.grid(group = group_values, period = pre_periods,
                           stringsAsFactors = FALSE)
combo_names <- paste0(combo_grid$group, "-", combo_grid$period)

est_discords <- setNames(numeric(nrow(combo_grid)), combo_names)

for (j in seq_len(nrow(combo_grid))) {
  est_discords[j] <- comp_abs_diff(
    data           = collapsed_data,
    outcome_var    = rightshare,
    group_var      = mine,
    time_var       = period,
    pre_period     = combo_grid$period[j],
    post_period    = "1977+",
    group_value    = combo_grid$group[j],
    use_gain_score = FALSE
  )
}

cat("Max discordance:", round(max(est_discords), 2), "\n")  # expected: 0.15 (exact: 0.147)
cat("Discordance-based ATT bounds at M=1: [",
    round(DID_est - max(est_discords), 2), ",",
    round(DID_est + max(est_discords), 2), "]\n")           # expected: [-0.04, 0.26]

# =============================================================================
# SECTION 4: PRETRENDS-BASED SENSITIVITY
# =============================================================================

# Absolute difference in pre-period trends for each pre-period
# Manuscript result: max pretrend difference = 0.03
pretrend_periods <- sort(unique(
  collapsed_data$period[collapsed_data$mine == 1 & collapsed_data$treat == 0]
))[-1]

pretrend_diffs <- setNames(numeric(length(pretrend_periods)), pretrend_periods)

for (j in seq_along(pretrend_periods)) {
  pretrend_diffs[j] <- pre_diff_trends(
    data           = collapsed_data,
    outcome_var    = rightshare,
    group_var      = mine,
    time_var       = period,
    pre_period     = pretrend_periods[j],
    use_gain_score = FALSE
  )
}

cat("Max pretrend difference:", round(max(pretrend_diffs), 2), "\n")  # expected: 0.03

# =============================================================================
# SECTION 5: CLUSTER BOOTSTRAP FOR SENSITIVITY QUANTITIES
# =============================================================================

# Bootstrap distributions of discordance and pretrend quantities are needed
# to construct CIs on ATT bounds via the Berger-Boos intersection-union method.

# Storage matrices: rows = bootstrap draws, columns = group-period combinations
boot_discords_mat <- matrix(NA, nrow = R, ncol = nrow(combo_grid),
                            dimnames = list(NULL, combo_names))
boot_pretrend_mat <- matrix(NA, nrow = R, ncol = length(pretrend_periods),
                            dimnames = list(NULL, pretrend_periods))

set.seed(482045732)

for (r in seq_len(R)) {
  sampled_clusters <- sample(clusters, size = length(clusters), replace = TRUE)
  boot_data        <- filter(collapsed_data, electorald %in% sampled_clusters)

  # Discordance: one estimate per group x pre-period combination
  for (j in seq_len(nrow(combo_grid))) {
    boot_discords_mat[r, j] <- comp_abs_diff(
      data           = boot_data,
      outcome_var    = rightshare,
      group_var      = mine,
      time_var       = period,
      pre_period     = combo_grid$period[j],
      post_period    = "1977+",
      group_value    = combo_grid$group[j],
      use_gain_score = FALSE
    )
  }

  # Pretrend violations: one estimate per pre-period
  for (j in seq_along(pretrend_periods)) {
    boot_pretrend_mat[r, j] <- pre_diff_trends(
      data           = boot_data,
      outcome_var    = rightshare,
      group_var      = mine,
      time_var       = period,
      pre_period     = pretrend_periods[j],
      use_gain_score = TRUE   # compare gain scores directly in pre-periods
    )
  }
}

# =============================================================================
# SECTION 6: SENSITIVITY CHANGEPOINTS
# =============================================================================

# ---- Discordance-based changepoints ----------------------------------------
# Manuscript results: bounds M* = 0.71, CI M* = 0.48

# Estimated: M at which sample bounds first include 0
cp_bounds <- uniroot(changepoint_M, interval = c(0, 5),
                     DID_est      = DID_est,
                     est_discords = est_discords,
                     type         = "bounds")$root

# CI-based: M at which 95% CI on bounds first includes 0
cp_ci <- uniroot(changepoint_M, interval = c(0, 5),
                 boot_dids         = boot_dids,
                 boot_discords_mat = boot_discords_mat,
                 alpha             = 0.05,
                 type              = "ci")$root

cat("Discordance-based changepoints:\n")
cat("  Estimated M*:", round(cp_bounds, 2), "\n")  # expected: 0.71
cat("  CI-based M*:        ", round(cp_ci, 2), "\n")       # expected: 0.48

# ---- Pretrends-based changepoints ------------------------------------------
# Manuscript results: bounds M* = 3.22, CI M* = 2.98

cp_bounds_pt <- uniroot(changepoint_M, interval = c(0, 6),
                        DID_est      = DID_est,
                        est_discords = pretrend_diffs,
                        type         = "bounds")$root

cp_ci_pt <- uniroot(changepoint_M, interval = c(0, 5),
                    boot_dids         = boot_dids,
                    boot_discords_mat = boot_pretrend_mat,
                    alpha             = 0.05,
                    type              = "ci")$root

cat("Pretrends-based changepoints:\n")
cat("  Estimated M*:", round(cp_bounds_pt, 2), "\n")  # expected: 3.22
cat("  CI-based M*:        ", round(cp_ci_pt, 2), "\n")       # expected: 2.98

# =============================================================================
# SECTION 7: BUILD PLOT DATA
# =============================================================================

# Full grid of M values to evaluate
Ms <- seq(0, 6, by = 0.5)

# ---- Discordance-based (displayed at M <= 2 in Figure 4) -------------------

ATT_bounds_discord    <- lapply(Ms, function(M) c(DID_est - M * max(est_discords),
                                                   DID_est + M * max(est_discords)))
CI_ATT_bounds_discord <- lapply(Ms, function(M) ATT_bounds_CI(boot_dids,
                                                               boot_discords_mat,
                                                               M = M))

plot_data_discord <- tibble(
  M         = Ms,
  ATT_lower = sapply(ATT_bounds_discord,    `[`, 1),
  ATT_upper = sapply(ATT_bounds_discord,    `[`, 2),
  CI_lower  = sapply(CI_ATT_bounds_discord, `[`, 1),
  CI_upper  = sapply(CI_ATT_bounds_discord, `[`, 2)
) |>
  mutate(
    ATT_mid = (ATT_lower + ATT_upper) / 2,
    CI_mid  = (CI_lower  + CI_upper)  / 2
  )

# Subset to M <= 2 for the main discordance figure (Figure 4)
plot_data_discord_subset <- filter(plot_data_discord,
                                   M %in% seq(0, 2, by = 0.5))

# ---- Pretrends-based (full range M = 0-6 for Figure 5) --------------------

ATT_bounds_pretrend    <- lapply(Ms, function(M) c(DID_est - M * max(pretrend_diffs),
                                                    DID_est + M * max(pretrend_diffs)))
CI_ATT_bounds_pretrend <- lapply(Ms, function(M) ATT_bounds_CI(boot_dids,
                                                                boot_pretrend_mat,
                                                                M = M))

plot_data_pretrend <- tibble(
  M         = Ms,
  ATT_lower = sapply(ATT_bounds_pretrend,    `[`, 1),
  ATT_upper = sapply(ATT_bounds_pretrend,    `[`, 2),
  CI_lower  = sapply(CI_ATT_bounds_pretrend, `[`, 1),
  CI_upper  = sapply(CI_ATT_bounds_pretrend, `[`, 2)
) |>
  mutate(
    ATT_mid = (ATT_lower + ATT_upper) / 2,
    CI_mid  = (CI_lower  + CI_upper)  / 2
  )

# ---- Shared y-axis limits across Figures 4 and 5 --------------------------

all_y_vals <- c(
  plot_data_discord_subset$ATT_lower, plot_data_discord_subset$ATT_upper,
  plot_data_discord_subset$CI_lower,  plot_data_discord_subset$CI_upper,
  plot_data_pretrend$ATT_lower,       plot_data_pretrend$ATT_upper,
  plot_data_pretrend$CI_lower,        plot_data_pretrend$CI_upper
)
y_min <- floor(min(all_y_vals)   * 10) / 10
y_max <- ceiling(max(all_y_vals) * 10) / 10

# =============================================================================
# SECTION 8: FIGURE 4 -- Discordance-based sensitivity (M <= 2)
# =============================================================================

p_discord <- ggplot(
  data    = plot_data_discord_subset,
  mapping = aes(x = factor(M))
) +
  # 95% CI on the ATT bounds (gray error bars)
  geom_errorbar(
    aes(ymin = CI_lower, ymax = CI_upper, color = "95% CI"),
    width = 0.05, linewidth = 0.8
  ) +
  # Sample ATT bounds (black; collapsed to point at M = 0)
  geom_errorbar(
    data = filter(plot_data_discord_subset, M != 0),
    aes(ymin = ATT_lower, ymax = ATT_upper, color = "ATT bounds"),
    width = 0.05, linewidth = 1.1
  ) +
  # DID point estimate (same value at every M)
  geom_point(
    aes(y = ATT_mid, color = "ATT bounds"),
    shape = 16, size = 2.5
  ) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_manual(
    values = c("ATT bounds" = "black", "95% CI" = "gray50"),
    name   = ""
  ) +
  scale_y_continuous(limits = c(y_min, y_max)) +
  labs(x = "M", y = NULL) +
  theme_minimal(base_size = 14) +
  theme(
    panel.grid      = element_blank(),
    axis.text.x     = element_text(vjust = 0.5, hjust = 1),
    legend.position = "bottom"
  )

# Save  ->  Figure 4 in the manuscript
ggsave(
  filename = "output/figures/sens_analysis.pdf",   # Figure 4
  plot     = p_discord,
  width    = 6.5,
  height   = 4.5,
  units    = "in",
  dpi      = 600,
  device   = cairo_pdf
)

# =============================================================================
# SECTION 9: FIGURE 5 -- Combined comparison of both sensitivity models
# =============================================================================

# Combine both methods into one data frame with a method label
plot_data_combined <- bind_rows(
  plot_data_discord  |> filter(M %in% 0:6) |>
    mutate(method = "Discordance-based sensitivity analysis"),
  plot_data_pretrend |> filter(M %in% 0:6) |>
    mutate(method = "Pretrends-based sensitivity analysis")
) |>
  mutate(
    method = factor(method, levels = c("Discordance-based sensitivity analysis",
                                       "Pretrends-based sensitivity analysis")),
    M      = factor(M, levels = as.character(0:6))
  )

# Recompute shared y-axis limits for the combined plot
all_y_comb <- c(plot_data_combined$CI_lower,  plot_data_combined$CI_upper,
                plot_data_combined$ATT_lower, plot_data_combined$ATT_upper)
y_min_comb <- floor(min(all_y_comb)   * 10) / 10
y_max_comb <- ceiling(max(all_y_comb) * 10) / 10

p_comp <- ggplot(
  data    = plot_data_combined,
  mapping = aes(x = M)
) +
  # 95% CI (gray)
  geom_errorbar(
    aes(ymin = CI_lower, ymax = CI_upper, color = "95% CI"),
    width = 0.05, linewidth = 0.8
  ) +
  geom_point(
    aes(y = CI_mid, color = "95% CI"),
    shape = 21, fill = "white", size = 1.5, stroke = 0.6
  ) +
  # ATT bounds (black; skip M = 0 where bounds collapse to point)
  geom_errorbar(
    data = filter(plot_data_combined, M != "0"),
    aes(ymin = ATT_lower, ymax = ATT_upper, color = "ATT bounds"),
    width = 0.05, linewidth = 1.1
  ) +
  geom_point(
    aes(y = ATT_mid, color = "ATT bounds"),
    shape = 16, size = 1.5
  ) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  # Facet by sensitivity model
  facet_wrap(~ method, nrow = 2) +
  scale_color_manual(
    values = c("ATT bounds" = "black", "95% CI" = "gray50"),
    name   = ""
  ) +
  scale_y_continuous(limits = c(y_min_comb, y_max_comb)) +
  labs(x = "M", y = NULL) +
  theme_minimal(base_size = 14) +
  theme(
    panel.grid      = element_blank(),
    strip.text      = element_text(size = 14),
    axis.text.x     = element_text(vjust = 0.5, hjust = 1),
    legend.position = "bottom"
  )

# Save  ->  Figure 5 in the manuscript
ggsave(
  filename = "output/figures/sens_analysis_comp.pdf",   # Figure 5
  plot     = p_comp,
  width    = 6.5,
  height   = 4.5,
  units    = "in",
  dpi      = 600,
  device   = cairo_pdf
)

cat("\nDone. Figures saved to output/figures/.\n")