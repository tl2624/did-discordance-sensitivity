# =============================================================================
# DID_estimator.R
#
# PURPOSE: Computes the difference-in-differences (DID) estimate of the ATT.
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
#   pre_period     -- value of time_var for the last pre-treatment period
#   post_period    -- value of time_var for the post-treatment period
#   use_gain_score -- if TRUE, outcome is already a gain score; compare
#                     post-period group means directly (no re-differencing)

DID_estimator <- function(data, outcome_var, group_var, time_var,
                          pre_period, post_period, use_gain_score = FALSE) {

  outcome_var <- rlang::ensym(outcome_var)
  group_var   <- rlang::ensym(group_var)
  time_var    <- rlang::ensym(time_var)

  if (use_gain_score) {
    # Outcome is already a first difference; simply compare post-period means
    post_treated <- data |>
      dplyr::filter(!!group_var == 1, !!time_var == post_period) |>
      dplyr::pull(!!outcome_var)
    post_control <- data |>
      dplyr::filter(!!group_var == 0, !!time_var == post_period) |>
      dplyr::pull(!!outcome_var)

    est <- mean(post_treated, na.rm = TRUE) - mean(post_control, na.rm = TRUE)

  } else {
    # Standard DID: (post_treated - pre_treated) - (post_control - pre_control)
    post_treated <- data |> dplyr::filter(!!group_var == 1, !!time_var == post_period) |> dplyr::pull(!!outcome_var)
    pre_treated  <- data |> dplyr::filter(!!group_var == 1, !!time_var == pre_period)  |> dplyr::pull(!!outcome_var)
    post_control <- data |> dplyr::filter(!!group_var == 0, !!time_var == post_period) |> dplyr::pull(!!outcome_var)
    pre_control  <- data |> dplyr::filter(!!group_var == 0, !!time_var == pre_period)  |> dplyr::pull(!!outcome_var)

    est <- mean(post_treated - mean(pre_treated, na.rm = TRUE), na.rm = TRUE) -
           mean(post_control - mean(pre_control, na.rm = TRUE), na.rm = TRUE)
  }

  return(est)
}
