#' Compute Doubling Time
#'
#' Compute doubling time from a growth rate estimate.
#'
#' @param mu Numeric vector of growth-rate estimates.
#'
#' @return A numeric vector equal to `log(2) / mu`, with `NA` returned when
#'   `mu <= 0`.
#' @export
compute_doubling_time <- function(mu) {
  ifelse(is.na(mu) | mu <= 0, NA_real_, log(2) / mu)
}
