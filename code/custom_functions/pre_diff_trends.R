# =============================================================================
# pre_diff_trends.R
#
# PURPOSE: Computes the absolute difference in pre-period trends between
#   treated and control groups (the DID of trends). Used to calibrate the
#   pretrends-based sensitivity model.
#
# DEPENDENCIES: dplyr, rlang
#
# SOURCED BY: code/04_analysis.R
# =============================================================================

# Arguments:
#   data           -- data frame in long format
#   outcome_var    -- name of the outcome variable (unquoted)
#   group_var      -- name of the binary treatment-group indicator (unquoted)
#   time_var       -- name of the period variable (unquoted, ordered factor)
#   pre_period     -- the pre-period to evaluate
#   use_gain_score -- if TRUE, compare gain scores directly (no re-differencing)

pre_diff_trends <- function(data, outcome_var, group_var, time_var,
                            pre_period, use_gain_score = FALSE) {

  outcome_var <- rlang::ensym(outcome_var)
  group_var   <- rlang::ensym(group_var)
  time_var    <- rlang::ensym(time_var)

  if (use_gain_score) {
    # Compare gain scores directly between treated and control in pre_period
    treated <- data |>
      dplyr::filter(!!group_var == 1, !!time_var == pre_period) |>
      dplyr::pull(!!outcome_var)
    control <- data |>
      dplyr::filter(!!group_var == 0, !!time_var == pre_period) |>
      dplyr::pull(!!outcome_var)

    diff_in_trends <- abs(mean(treated, na.rm = TRUE) - mean(control, na.rm = TRUE))

  } else {
    # Compute a pre-pre DID: change treated - change control from prior to pre_period
    period_levels <- levels(data[[rlang::as_string(time_var)]])
    pre_index     <- match(pre_period, period_levels)
    if (is.na(pre_index) || pre_index == 1)
      stop("Invalid pre_period or no earlier period available.")

    prior_period <- period_levels[pre_index - 1]

    treated_now   <- data |> dplyr::filter(!!group_var == 1, !!time_var == pre_period)   |> dplyr::pull(!!outcome_var)
    treated_prior <- data |> dplyr::filter(!!group_var == 1, !!time_var == prior_period) |> dplyr::pull(!!outcome_var)
    control_now   <- data |> dplyr::filter(!!group_var == 0, !!time_var == pre_period)   |> dplyr::pull(!!outcome_var)
    control_prior <- data |> dplyr::filter(!!group_var == 0, !!time_var == prior_period) |> dplyr::pull(!!outcome_var)

    treated_diff   <- mean(treated_now - mean(treated_prior, na.rm = TRUE), na.rm = TRUE)
    control_diff   <- mean(control_now - mean(control_prior, na.rm = TRUE), na.rm = TRUE)
    diff_in_trends <- abs(treated_diff - control_diff)
  }

  return(diff_in_trends)
}
