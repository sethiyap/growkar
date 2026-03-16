#' Detect Candidate Exponential-Phase Windows
#'
#' Identify rolling windows with the strongest evidence for exponential growth
#' in a single sample.
#'
#' @param data Tidy growth data for one sample.
#' @param window_size Number of observations in each rolling window.
#' @param min_od Minimum OD retained for log-linear fitting.
#'
#' @return A tibble with `start_time`, `end_time`, `slope`, and `r_squared`,
#'   ranked by highest positive slope and then `r_squared`.
#' @export
detect_exponential_phase <- function(data, window_size = 5, min_od = 0.02) {
  data <- as_tidy_growth_data(data)
  data <- validate_growth_data(data)

  if (dplyr::n_distinct(data$sample) != 1L) {
    stop("`detect_exponential_phase()` requires data for exactly one sample.", call. = FALSE)
  }

  data <- data |>
    dplyr::arrange(.data$time) |>
    dplyr::filter(.data$od > min_od)

  if (nrow(data) < window_size) {
    return(tibble::tibble(
      start_time = numeric(),
      end_time = numeric(),
      slope = numeric(),
      r_squared = numeric()
    ))
  }

  windows <- purrr::map_dfr(seq_len(nrow(data) - window_size + 1L), function(i) {
    window_data <- data[i:(i + window_size - 1L), , drop = FALSE]
    fit <- stats::lm(log(od) ~ time, data = window_data)
    summary_fit <- suppressWarnings(summary(fit))

    tibble::tibble(
      start_time = min(window_data$time),
      end_time = max(window_data$time),
      slope = unname(stats::coef(fit)[["time"]]),
      r_squared = unname(summary_fit$r.squared)
    )
  })

  windows |>
    dplyr::arrange(dplyr::desc(.data$slope > 0), dplyr::desc(.data$slope), dplyr::desc(.data$r_squared))
}
