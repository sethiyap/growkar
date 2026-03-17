#' Detect Candidate Exponential-Phase Windows
#'
#' Identify rolling windows with the strongest evidence for exponential growth
#' in a single sample.
#'
#' @param data Tidy growth data for one sample.
#' @param window_size Number of observations in each rolling window.
#' @param min_od Minimum OD retained for log-linear fitting.
#'
#' @return A tibble with `sample`, `start_time`, `end_time`, `slope`, and
#'   `r_squared`, ranked by highest positive slope and then `r_squared`. The
#'   returned tibble also includes `rank`, `n_points`, `selection_reason`, and
#'   `degraded` metadata describing how the candidate windows were selected.
#' @export
detect_exponential_phase <- function(data, window_size = 5, min_od = 0.02) {
  data <- as_tidy_growth_data(data)
  data <- validate_growth_data(data, warn_zero_od = TRUE)
  sample_id <- unique(data$sample)

  if (dplyr::n_distinct(data$sample) != 1L) {
    stop("`detect_exponential_phase()` requires data for exactly one sample.", call. = FALSE)
  }

  data <- data |>
    dplyr::arrange(.data$time) |>
    dplyr::filter(.data$od > min_od)

  if (nrow(data) < 2L) {
    return(growkar_phase_fallback(
      sample_id = sample_id,
      n_points = nrow(data),
      selection_reason = "insufficient_positive_points"
    ))
  }

  effective_window_size <- min(window_size, nrow(data))
  selection_reason <- if (effective_window_size < window_size) {
    "window_size_reduced"
  } else {
    "rolling_window_ranked"
  }

  windows <- purrr::map_dfr(seq_len(nrow(data) - effective_window_size + 1L), function(i) {
    indices <- i:(i + effective_window_size - 1L)
    window_data <- data[indices, , drop = FALSE]
    fit_summary <- growkar_fit_log_linear(window_data)

    if (!fit_summary$success) {
      return(growkar_phase_fallback(
        sample_id = sample_id,
        n_points = nrow(window_data),
        selection_reason = fit_summary$note
      ))
    }

    tibble::tibble(
      sample = sample_id,
      start_time = min(window_data$time),
      end_time = max(window_data$time),
      slope = fit_summary$slope,
      r_squared = fit_summary$r_squared,
      n_points = nrow(window_data),
      selection_reason = selection_reason,
      degraded = selection_reason != "rolling_window_ranked"
    )
  })

  windows |>
    dplyr::arrange(dplyr::desc(.data$slope > 0), dplyr::desc(.data$slope), dplyr::desc(.data$r_squared)) |>
    dplyr::mutate(rank = dplyr::row_number(), .before = "start_time")
}

growkar_phase_fallback <- function(sample_id, n_points, selection_reason) {
  tibble::tibble(
    sample = sample_id,
    rank = 1L,
    start_time = NA_real_,
    end_time = NA_real_,
    slope = NA_real_,
    r_squared = NA_real_,
    n_points = as.integer(n_points),
    selection_reason = selection_reason,
    degraded = TRUE
  )
}
