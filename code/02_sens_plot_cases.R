# =============================================================================
# 02_sens_plot_cases.R
#
# PURPOSE: Produce Figure 2 in the manuscript.
#   Compares the pretrends-based and discordance-based sensitivity bounds for
#   the two stylized cases introduced in Figure 1. For each case and each
#   sensitivity model, plots the identified set for the ATT as a function of
#   the sensitivity parameter M in {0, 0.5, 1, 1.5, 2}.
#
# OUTPUT: output/figures/sens_plot_cases.pdf  [Figure 2]
#
# NOTE: Run from the repo root directory.
# =============================================================================

rm(list = ls())
library(dplyr)    # filter, mutate, group_by, arrange, ungroup, distinct, if_else
library(tidyr)    # expand_grid, pivot_longer, pivot_wider
library(purrr)    # map_dfr
library(tibble)   # tibble()
library(stringr)  # str_detect()
library(ggplot2)  # all plotting

# -----------------------------------------------------------------------------
# 1. Reconstruct the stylized outcome data
#    (same setup as 01_DID_cases.R)
# -----------------------------------------------------------------------------

treated_vals <- c(10, 20, 60)

control_vals_list <- list(
  "Case 1" = c(5, 15, 25),
  "Case 2" = c(5, 15, 5)
)

# Stack all cases into one tidy data frame with group, time, and outcomes
df <- map_dfr(
  .x = names(control_vals_list),
  .f = function(case) {
    tibble(
      Case    = case,
      Time    = 1:3,
      Treated = treated_vals,
      Control = control_vals_list[[case]]
    )
  }
)

# -----------------------------------------------------------------------------
# 2. Compute gain scores (period-over-period changes)
# -----------------------------------------------------------------------------

gain_df <- df |>
  group_by(Case) |>
  arrange(Time) |>
  mutate(
    Treated_gain = Treated - lag(Treated),  # NA for Time == 1
    Control_gain = Control - lag(Control)
  ) |>
  ungroup()

# -----------------------------------------------------------------------------
# 3. Compute sensitivity quantities for each case
#
#    delta  (pretrends-based): absolute difference in gain scores between
#            treated and control in the *last pre-period* (Time == 2)
#
#    error  (discordance-based): maximum absolute difference between the
#            control group's post-period gain and any other observed gain,
#            taken over all group × pre-period combinations
# -----------------------------------------------------------------------------

sensitivity_df <- gain_df |>
  filter(Time %in% c(1, 2, 3)) |>
  group_by(Case) |>
  mutate(
    # Pretrends delta: |treated gain - control gain| at Time 2
    delta = ifelse(
      Time == 2,
      abs(Treated_gain - Control_gain),
      NA_real_
    ),
    # Discordance error: max absolute deviation of any gain from the
    # control-group post-period gain (control gain at Time 3)
    error = ifelse(
      Time %in% c(2, 3),
      max(
        abs(Treated_gain[Time == 1] - Control_gain[Time == 3]),
        abs(Treated_gain[Time == 2] - Control_gain[Time == 3]),
        abs(Control_gain[Time == 1] - Control_gain[Time == 3]),
        abs(Control_gain[Time == 2] - Control_gain[Time == 3]),
        na.rm = TRUE
      ),
      NA_real_
    )
  ) |>
  dplyr::select(Case, Time, delta, error) |>
  ungroup()

# -----------------------------------------------------------------------------
# 4. Build the sensitivity plot data
#    For each M and each case, compute the upper and lower ATT bounds
#    under both the pretrends-based and discordance-based models.
#
#    Benchmark: post-treatment gain under exact parallel trends = 10
#    (i.e., the ATT point estimate when M = 0)
#
#    The worst-case delta and error are taken across all cases/periods,
#    making the calibration common across cases for comparability.
# -----------------------------------------------------------------------------

Ms <- c(0, 0.5, 1, 1.5, 2)   # sensitivity parameter grid
standard_post_gain <- 10       # ATT under exact parallel trends

# Take the worst-case sensitivity quantity across all cases
common_delta <- max(sensitivity_df$delta, na.rm = TRUE)  # pretrends benchmark
common_error <- max(sensitivity_df$error, na.rm = TRUE)  # discordance benchmark

# For each M x case combination, form bounds for both models
sensitivity_plot_data <- expand_grid(M = Ms, sensitivity_df) |>
  mutate(
    post_gain = standard_post_gain,

    # Pretrends-based bounds: apply only to Case 3 (the case with pre-trend violation)
    # Case 1 and Case 2 satisfy pretrends, so their bounds are point-identified at M=0
    bound_lower     = if_else(Case == "Case 3",
                              standard_post_gain - M * common_delta,
                              standard_post_gain),
    bound_upper     = if_else(Case == "Case 3",
                              standard_post_gain + M * common_delta,
                              standard_post_gain),

    # Discordance-based bounds: apply to Cases 2 and 3 (non-trivial discordance)
    bound_lower_alt = if_else(Case != "Case 1",
                              standard_post_gain - M * common_error,
                              standard_post_gain),
    bound_upper_alt = if_else(Case != "Case 1",
                              standard_post_gain + M * common_error,
                              standard_post_gain)
  ) |>
  # Reshape to long on bound type, then separate model and side
  pivot_longer(
    cols      = starts_with("bound_"),
    names_to  = "bound_type",
    values_to = "value"
  ) |>
  mutate(
    model      = if_else(str_detect(bound_type, "alt"),
                         "Discordance-based", "Pretrends-based"),
    bound_side = if_else(str_detect(bound_type, "lower"), "lower", "upper")
  ) |>
  distinct(Case, M, post_gain, model, bound_side, value) |>
  pivot_wider(names_from = bound_side, values_from = value) |>
  mutate(
    model     = factor(model, levels = c("Discordance-based", "Pretrends-based")),
    post_gain = as.numeric(post_gain)
  )

# Restrict to Cases 1 and 2 (the two cases shown in the manuscript)
plot_data <- sensitivity_plot_data |>
  filter(Case %in% c("Case 1", "Case 2")) |>
  filter(!is.na(lower) & !is.na(upper)) |>
  droplevels()

# Compute y-axis and x-axis limits with slight padding
y_limits <- c(min(plot_data$lower, na.rm = TRUE) - 1,
              max(plot_data$upper, na.rm = TRUE) + 1)
x_limits <- c(min(plot_data$M) - 0.1, max(plot_data$M) + 0.1)

# -----------------------------------------------------------------------------
# 5. Plot  (Figure 2)
#    Faceted by sensitivity model (rows) x case (columns).
#    Each panel shows the ATT point estimate (dot) and identified set
#    (vertical bar) as M increases.
# -----------------------------------------------------------------------------

p <- ggplot(data = plot_data) +
  # Identified set for ATT: vertical error bar spanning [lower, upper]
  geom_errorbar(
    aes(x = M, ymin = lower, ymax = upper),
    width     = 0.1,
    linewidth = 0.9,
    color     = "black"
  ) +
  # ATT point estimate (M = 0: parallel trends holds exactly)
  geom_point(
    aes(y = post_gain, x = M),
    size  = 3,
    color = "black"
  ) +
  # Reference line at the point estimate
  geom_hline(
    aes(yintercept = post_gain),
    color     = "gray60",
    linewidth = 0.4
  ) +
  # Facets: rows = model, columns = case
  facet_grid(model ~ Case, scales = "fixed") +
  scale_x_continuous(
    limits = x_limits,
    breaks = seq(0, 2, by = 0.5)
  ) +
  scale_y_continuous(
    limits = y_limits,
    breaks = seq(-30, 50, by = 20)
  ) +
  labs(x = "M", y = "ATT") +
  theme_minimal(base_size = 12) +
  theme(
    legend.position   = "none",
    panel.grid        = element_blank(),
    panel.border      = element_rect(color = "black", fill = NA, linewidth = 0.8),
    strip.background  = element_rect(fill = "gray90", color = "black"),
    strip.text        = element_text(face = "bold"),
    axis.ticks.x      = element_line(),
    axis.ticks.y      = element_line(),
    axis.ticks.length = unit(0.2, "cm"),
    axis.title.y      = element_text(face = "bold"),
    axis.title.x      = element_text(face = "bold")
  )

# -----------------------------------------------------------------------------
# 6. Save  ->  Figure 2 in the manuscript
# -----------------------------------------------------------------------------

ggsave(
  filename = "output/figures/sens_plot_cases.pdf",   # Figure 2
  plot     = p,
  width    = 6.5,
  height   = 4.5,
  units    = "in",
  dpi      = 600,
  device   = cairo_pdf
)
