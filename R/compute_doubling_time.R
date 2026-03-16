#' Compute Doubling Time
#'
#' Compute doubling time from a growth rate estimate.
#'
#' This is a low-level helper for converting one or more growth-rate estimates
#' into doubling times. For a convenience summary across all samples, use
#' `summarize_growth_metrics()`.
#'
#' @param mu Numeric vector of specific growth-rate estimates. In `growkar`,
#'   `mu` is the slope of `log(od)` versus time.
#'
#' @return A numeric vector equal to `log(2) / mu`, with `NA` returned when
#'   `mu <= 0`.
#' @export
compute_doubling_time <- function(mu) {
  ifelse(is.na(mu) | mu <= 0, NA_real_, log(2) / mu)
}
