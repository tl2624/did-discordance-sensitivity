# =============================================================================
# ATT_bounds_CI.R
#
# PURPOSE: Computes a bootstrap confidence interval for the lower and upper
#   ATT bounds using the Berger-Boos intersection-union procedure.
#
# METHOD: For a given M, bootstrap ATT bounds are formed for each nuisance
#   (discordance or pretrend) column. The intersection-union step takes the
#   smallest lower-quantile and largest upper-quantile across all columns,
#   yielding a valid CI that guards against the unknown identity of the
#   maximally discordant group-period pair.
#
# REFERENCE: Berger, R. L., and Boos, D. D. (1994). P values maximized over
#   a confidence set for the nuisance parameter. Journal of the American
#   Statistical Association, 89(427), 1012-1016.
#
# SOURCED BY: code/04_analysis.R
# =============================================================================

# Arguments:
#   did      -- numeric vector of bootstrap DID estimates (length R)
#   discords -- numeric matrix of bootstrap nuisance quantities (R x K);
#               columns correspond to group-period combinations
#   M        -- sensitivity parameter (scalar >= 0)
#   alpha    -- significance level; default 0.05 gives a 95% CI
#
# Returns a length-2 vector: c(lower_bound, upper_bound)

ATT_bounds_CI <- function(did, discords, M = 1, alpha = 0.05) {

  # Bootstrap upper and lower ATT bounds for each nuisance column (R x K)
  boot_UB <- did + M * discords
  boot_LB <- did - M * discords

  # Column-wise quantiles: (1-alpha/2) for upper, (alpha/2) for lower
  UB_quants <- apply(boot_UB, 2, quantile, probs = 1 - alpha / 2, na.rm = TRUE)
  LB_quants <- apply(boot_LB, 2, quantile, probs = alpha / 2,     na.rm = TRUE)

  # Intersection-union: most conservative CI across all nuisance columns
  c(min(LB_quants), max(UB_quants))
}
