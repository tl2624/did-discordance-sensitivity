# =============================================================================
# changepoint_M.R
#
# PURPOSE: Locates the value of M at which the ATT bounds (or their CI) first
#   contain zero -- i.e., the minimum sensitivity to violations of parallel
#   trends sufficient to explain away the estimated effect.
#
# USAGE: Designed for use with uniroot(). Returns a signed scalar:
#   positive  -- bounds / CI do not yet contain 0
#   zero      -- bounds / CI exactly touch 0  (this is the root = changepoint)
#   negative  -- bounds / CI contain 0  (effect is no longer distinguishable)
#
# DEPENDENCY: ATT_bounds_CI()  (source ATT_bounds_CI.R before this file)
#
# SOURCED BY: code/04_analysis.R
# =============================================================================

# Arguments:
#   M                 -- sensitivity parameter value to evaluate
#   boot_dids         -- bootstrap DID vector (required when type = "ci")
#   boot_discords_mat -- bootstrap nuisance matrix (required when type = "ci")
#   DID_est           -- point estimate of DID (required when type = "bounds")
#   est_discords      -- named vector of observed discordance values
#                        (required when type = "bounds")
#   alpha             -- significance level for CI (default 0.05)
#   type              -- "ci" for CI-based changepoint;
#                        "bounds" for point-identified changepoint

changepoint_M <- function(M, boot_dids = NULL, boot_discords_mat = NULL,
                          DID_est = NULL, est_discords = NULL,
                          alpha = 0.05, type = c("ci", "bounds")) {

  type <- match.arg(type)

  bounds <- if (type == "ci") {
    ATT_bounds_CI(did      = boot_dids,
                  discords = boot_discords_mat,
                  M        = M,
                  alpha    = alpha)
  } else {
    c(DID_est - M * max(est_discords),
      DID_est + M * max(est_discords))
  }

  # Signed: negative when bounds straddle zero
  min(abs(bounds)) * sign(bounds[1] * bounds[2])
}
