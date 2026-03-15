# =============================================================================
# comp_abs_diff.R
#
# PURPOSE: Computes the discordance between a candidate counterfactual
#   imputation (from a specified group x pre-period) and the parallel-trends
#   imputation (control group's post-period gain). See Section 4 of the
#   manuscript.
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
#   pre_period     -- the pre-period whose gain serves as the candidate
#                    counterfactual imputation
#   post_period    -- value of time_var for the post-treatment period
#   group_value    -- which group's pre-period gain to compare against (0 or 1)
#   use_gain_score -- if TRUE, pre-period gain scores are already in the data

comp_abs_diff <- function(data, outcome_var, group_var, time_var,
                          pre_period, post_period, group_value,
                          use_gain_score = FALSE) {

  outcome_var <- rlang::ensym(outcome_var)
  group_var   <- rlang::ensym(group_var)
  time_var    <- rlang::ensym(time_var)

  if (use_gain_score) {
    # Candidate imputation: pre-period gain for the specified group
    comparison   <- data |>
      dplyr::filter(!!group_var == group_value, !!time_var == pre_period) |>
      dplyr::pull(!!outcome_var)
    # Parallel-trends imputation: post-period gain for the control group
    control_post <- data |>
      dplyr::filter(!!group_var == 0, !!time_var == post_period) |>
      dplyr::pull(!!outcome_var)

    est <- abs(mean(comparison, na.rm = TRUE) - mean(control_post, na.rm = TRUE))

  } else {
    # Compute period-over-period changes internally from levels
    period_levels <- levels(data[[rlang::as_string(time_var)]])
    pre_index     <- match(pre_period, period_levels)
    if (is.na(pre_index) || pre_index == 1)
      stop("Invalid pre_period or no earlier period available.")

    # Gain for the candidate group from the period before pre_period to pre_period
    comparison_pre   <- data |>
      dplyr::filter(!!group_var == group_value, !!time_var == pre_period) |>
      dplyr::pull(!!outcome_var)
    comparison_prior <- data |>
      dplyr::filter(!!group_var == group_value, !!time_var == period_levels[pre_index - 1]) |>
      dplyr::pull(!!outcome_var)

    # Control group gain from the period before post_period to post_period
    post_index   <- match(post_period, period_levels)
    control_post <- data |>
      dplyr::filter(!!group_var == 0, !!time_var == post_period) |>
      dplyr::pull(!!outcome_var)
    control_pre  <- data |>
      dplyr::filter(!!group_var == 0, !!time_var == period_levels[post_index - 1]) |>
      dplyr::pull(!!outcome_var)

    comparison_diff <- mean(comparison_pre - mean(comparison_prior, na.rm = TRUE), na.rm = TRUE)
    control_diff    <- mean(control_post   - mean(control_pre,  na.rm = TRUE),     na.rm = TRUE)

    est <- abs(comparison_diff - control_diff)
  }

  return(est)
}
