#' Summarize Growth Metrics
#'
#' Compute growth rate and doubling time per sample.
#'
#' @param data Growth curve data in tidy or wide format.
#' @param method Estimation method passed to `compute_growth_rate()`.
#' @param ... Additional arguments passed to `compute_growth_rate()`.
#'
#' @return A tidy tibble with one row per sample.
#' @export
summarize_growth_metrics <- function(data,
                                     method = c("rolling_window", "defined_interval", "rule_based"),
                                     ...) {
  metrics <- compute_growth_rate(data = data, method = match.arg(method), ...)
  dplyr::mutate(metrics, doubling_time = compute_doubling_time(.data$mu))
}
