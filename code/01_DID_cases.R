# =============================================================================
# 01_DID_cases.R
#
# PURPOSE: Produce Figure 1 in the manuscript.
#   Illustrates the logic of difference-in-differences (DID) using two
#   stylized cases from Keele et al. (2019) and Rosenbaum (2017, pp. 164–165).
#   Each case shows treated and control group trends across two pre-treatment
#   periods and one post-treatment period, displayed both on the original
#   outcome scale (top row) and as gain scores / detrended outcomes (bottom row).
#
# OUTPUT: output/figures/DID_cases_1_2_plot.pdf  [Figure 1]
#
# NOTE: Run from the repo root directory.
# =============================================================================

rm(list = ls())
library(dplyr)    # filter, mutate, bind_rows, group_by, arrange, ungroup
library(purrr)    # imap_dfr
library(ggplot2)  # all plotting
library(ggh4x)    # facet_grid2(), facetted_pos_scales()

# -----------------------------------------------------------------------------
# 1. Define stylized data
# -----------------------------------------------------------------------------

# Treated group outcomes are fixed across all cases
treated_vals <- c(10, 20, 60)   # periods 1, 2, 3

# Control group outcomes differ by case
control_vals_list <- list(
  "Case 1" = c(5, 15, 25),  # parallel pre-trends, parallel counterfactual
  "Case 2" = c(5, 15, 5)    # parallel pre-trends, non-parallel counterfactual
)

# -----------------------------------------------------------------------------
# 2. Build tidy dataset for plotting
#    For each case, stack the raw (original-scale) outcomes and gain scores
#    (period-over-period change) into a single data frame.
# -----------------------------------------------------------------------------

build_case <- function(control_vals, label) {

  # Original-scale outcomes for both groups across 3 periods
  raw <- data.frame(
    treat     = rep(c("Control", "Treated"), each = 3),
    mean_y    = c(control_vals, treated_vals),
    Period    = rep(1:3, times = 2),
    case      = label,
    row_group = "Original"
  )

  # Gain scores: change from the immediately preceding period
  # Period 1 is set to NA (no prior period to difference against)
  gain <- raw |>
    group_by(treat) |>
    arrange(treat, Period) |>
    mutate(
      mean_y    = mean_y - lag(mean_y),            # first difference
      mean_y    = ifelse(Period == 1, NA, mean_y), # no baseline gain
      row_group = "Detrended",
      case      = label
    ) |>
    ungroup()

  bind_rows(raw, gain)
}

# Apply to each case and combine into one tidy data frame
all_data <- imap_dfr(control_vals_list, build_case)

# Set factor levels to control panel and legend ordering
all_data <- all_data |>
  mutate(
    case      = factor(case, levels = c("Case 1", "Case 2")),
    treat     = factor(treat, levels = c("Treated", "Control")),
    row_group = factor(row_group, levels = c("Original", "Detrended"))
  )

# -----------------------------------------------------------------------------
# 3. Plot  (Figure 1)
#    Two-row by two-column facet grid:
#      rows    = Original outcome | Gain score (Detrended)
#      columns = Case 1           | Case 2
#    Per-row y-axis scales are set independently via facetted_pos_scales().
# -----------------------------------------------------------------------------

p <- ggplot(
  data    = all_data,
  mapping = aes(x = Period, y = mean_y, group = treat)
) +
  geom_line(
    aes(linetype = treat),
    linewidth = 0.9,
    color     = "black",
    na.rm     = TRUE
  ) +
  geom_point(
    aes(shape = treat),
    size  = 2.3,
    color = "black",
    fill  = "white",   # hollow circle for Control
    na.rm = TRUE
  ) +
  scale_linetype_manual(values = c("solid", "dashed")) + # Treated solid, Control dashed
  scale_shape_manual(values = c(16, 1)) +                # Treated filled, Control hollow
  scale_x_continuous(
    breaks = 1:3,
    labels = c("Before", "Before", "After")
  ) +
  # facet_grid2 from ggh4x enables facetted_pos_scales() below
  facet_grid2(
    rows   = vars(row_group),
    cols   = vars(case),
    scales = "free_y"
  ) +
  # Set y-axis limits and breaks independently per row
  facetted_pos_scales(
    y = list(
      row_group == "Original"  ~ scale_y_continuous(
        breaks = c(0, 20, 40, 60),
        limits = c(0, 60)
      ),
      row_group == "Detrended" ~ scale_y_continuous(
        breaks = c(-20, 0, 20, 40),
        limits = c(-20, 40)
      )
    )
  ) +
  labs(
    x = "Period",
    y = "Average outcome"
  ) +
  theme_bw(base_size = 10) +
  theme(
    axis.ticks.y    = element_line(),
    axis.text.x     = element_text(size = 7, angle = 90),
    axis.title.y    = element_text(face = "bold"),
    axis.title.x    = element_text(face = "bold"),
    strip.text.x    = element_text(size = 9, face = "bold"),
    strip.text.y    = element_text(size = 9, face = "bold"),
    legend.position = "bottom",
    legend.title    = element_blank(),
    panel.grid      = element_blank(),
    panel.border    = element_rect(color = "black", fill = NA)
  )

# -----------------------------------------------------------------------------
# 4. Save  ->  Figure 1 in the manuscript
# -----------------------------------------------------------------------------

ggsave(
  filename = "output/figures/DID_cases_1_2_plot.pdf",   # Figure 1
  plot     = p,
  width    = 6.5,
  height   = 4.5,
  units    = "in",
  dpi      = 600,
  device   = cairo_pdf
)
