# =============================================================================
# 03_figures.R
#
# PURPOSE: Produce Figure 3 in the manuscript.
#   Plots average right-wing vote share trends across mining and non-mining
#   electoral districts before and after the 1974-1977 labor shock in
#   South African gold mines (Wilse-Samson 2013).
#   Two-panel figure: original scale (top) and detrended / gain scores (bottom).
#
# DATA: data/wilse-samson_data.rds
#   Cleaned panel of South African electoral districts, 1961-1987.
#   Unit of observation: electoral district x election period.
#
# OUTPUT: output/figures/wilse-samson_plot.pdf  [Figure 3]
#
# NOTE: Run from the repo root directory.
# =============================================================================

rm(list = ls())
library(dplyr)    # mutate, group_by, summarise, select
library(tidyr)    # pivot_longer
library(ggplot2)  # all plotting

# -----------------------------------------------------------------------------
# 1. Load data
# -----------------------------------------------------------------------------

# Cleaned panel dataset (see data/wilse-samson_data.rds for variable descriptions)
collapsed_data <- readRDS("data/wilse-samson_data.rds")

# Restore ordered factor levels for election periods
period_levels <- c("1961", "1966", "1970", "1974", "1977+")
collapsed_data <- collapsed_data |>
  mutate(period = factor(period, levels = period_levels, ordered = TRUE))

# -----------------------------------------------------------------------------
# 2. Aggregate to group-period means
#    For each election period, compute the average right-wing vote share
#    (and gain score) separately for mining and non-mining districts.
# -----------------------------------------------------------------------------

trend_data <- collapsed_data |>
  mutate(
    mine = factor(mine,
                  levels = c(0, 1),
                  labels = c("Non-Mining Districts", "Mining Districts"))
  ) |>
  group_by(period, mine) |>
  summarise(
    rightshare_mean      = mean(rightshare,      na.rm = TRUE), # original-scale avg vote share
    rightshare_gain_mean = mean(rightshare_gain, na.rm = TRUE), # gain-score (detrended) avg
    .groups = "drop"
  ) |>
  mutate(period = factor(period, levels = period_levels))

# -----------------------------------------------------------------------------
# 3. Pivot to long format for a single faceted plot
#    Two series per group: original scale and detrended (gain score).
# -----------------------------------------------------------------------------

trend_data_long <- trend_data |>
  select(period, mine, rightshare_mean, rightshare_gain_mean) |>
  pivot_longer(
    cols      = c(rightshare_mean, rightshare_gain_mean),
    names_to  = "series",
    values_to = "value"
  ) |>
  mutate(
    series = factor(
      series,
      levels = c("rightshare_mean", "rightshare_gain_mean"),
      labels = c("Original Outcome", "Detrended Outcome")
    )
  )

# -----------------------------------------------------------------------------
# 4. Plot  (Figure 3)
#    Two-panel figure sharing x-axis (election period) but with free y-scales.
#    A vertical grey line marks the start of the treatment period (after 1974).
# -----------------------------------------------------------------------------

p <- ggplot(
  data    = trend_data_long,
  mapping = aes(x = period, y = value, group = mine)
) +
  # Vertical line separating pre- and post-treatment periods
  geom_vline(xintercept = 4.5, linetype = "solid", color = "gray60") +

  # Trend lines by group
  geom_line(
    aes(linetype = mine),
    linewidth = 0.9,
    color     = "black",
    na.rm     = TRUE
  ) +

  # Points by group
  geom_point(
    aes(shape = mine),
    size  = 2.3,
    color = "black",
    fill  = "white",  # hollow point for Non-Mining
    na.rm = TRUE
  ) +

  scale_linetype_manual(values = c("solid", "dotdash")) +
  scale_shape_manual(values = c(16, 1)) +

  # Shared y-axis covers both the original and detrended series range
  scale_y_continuous(
    limits = c(-0.05, 0.25),
    breaks = seq(-0.05, 0.25, by = 0.05)
  ) +

  labs(
    x        = "Period",
    y        = NULL,   # facet strip labels serve as y-axis titles
    linetype = NULL,
    shape    = NULL
  ) +

  # Top panel: original scale; bottom panel: detrended
  facet_wrap(
    ~ series,
    ncol     = 1,
    scales   = "free_y",
    labeller = labeller(series = c(
      "Original Outcome"  = "Average Right-Wing Vote Share",
      "Detrended Outcome" = "Average Detrended Right-Wing Vote Share"
    ))
  ) +

  theme_bw(base_size = 10) +
  theme(
    axis.text.x     = element_text(size = 7, angle = 90),
    axis.title.y    = element_text(face = "bold"),
    axis.title.x    = element_text(face = "bold", size = 9),
    legend.position = "bottom",
    legend.title    = element_blank(),
    panel.grid      = element_blank(),
    panel.border    = element_rect(color = "black", fill = NA),
    strip.text      = element_text(face = "bold")
  )

# -----------------------------------------------------------------------------
# 5. Save  ->  Figure 3 in the manuscript
# -----------------------------------------------------------------------------

ggsave(
  filename = "output/figures/wilse-samson_plot.pdf",   # Figure 3
  plot     = p,
  width    = 6.5,
  height   = 4.5,
  units    = "in",
  dpi      = 600,
  device   = cairo_pdf
)
