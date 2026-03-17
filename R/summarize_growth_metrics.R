#' Summarize Growth Metrics
#'
#' Compute growth rate and doubling time per sample.
#'
#' This is the convenience wrapper for obtaining both metrics across multiple
#' samples in one tidy table. Internally, doubling time is derived from the
#' estimated growth rate using `compute_doubling_time()`.
#'
#' @param data Growth curve data in tidy or wide format.
#' @param method Estimation method passed to `compute_growth_rate()`.
#' @param average_replicates Logical; if `TRUE`, average replicate trajectories
#'   before computing metrics. When `select_replicates` is `NULL`, all available
#'   replicates are averaged.
#' @param select_replicates Optional character vector of replicate IDs to retain
#'   before summarizing. When `NULL`, all replicates are retained.
#' @param ... Additional arguments passed to `compute_growth_rate()`.
#'
#' @return A tidy tibble with one row per sample.
#'
#' @examples
#' data(yeast_growth_data)
#' metrics <- summarize_growth_metrics(
#'   yeast_growth_data,
#'   method = "rolling_window",
#'   average_replicates = TRUE
#' )
#' head(metrics)
#' @export
summarize_growth_metrics <- function(data,
                                     method = c("rolling_window", "defined_interval", "rule_based"),
                                     average_replicates = FALSE,
                                     select_replicates = NULL,
                                     ...) {
  tidy_data <- as_tidy_growth_data(data)
  tidy_data <- validate_growth_data(tidy_data)

  metrics <- compute_growth_rate(
    data = tidy_data,
    method = match.arg(method),
    select_replicates = select_replicates,
    average_replicates = average_replicates,
    ...
  )

  dplyr::mutate(metrics, doubling_time = compute_doubling_time(.data$mu))
}
