#' Detect Candidate Exponential-Phase Windows
#'
#' Identify rolling windows with the strongest evidence for exponential growth.
#' For multi-sample input, detection is performed separately for each sample.
#' When `average_replicates = TRUE`, replicate trajectories are averaged first
#' and exponential-phase detection is then run on the averaged curves.
#'
#' @param data Growth data for one sample or multiple samples in tidy, wide, or
#'   `SummarizedExperiment` format.
#' @param select_replicates Optional character vector of replicate IDs to retain
#'   before detection. When `NULL`, all replicates are retained.
#' @param average_replicates Logical; if `TRUE`, average replicate trajectories
#'   before detection when replicate metadata are available.
#' @param window_size Number of observations in each rolling window.
#' @param min_od Minimum OD retained for log-linear fitting.
#'
#' @return A tibble with `sample`, `start_time`, `end_time`, `slope`, and
#'   `r_squared`, ranked by highest positive slope and then `r_squared`. The
#'   returned tibble also includes `rank`, `n_points`, `selection_reason`, and
#'   `degraded` metadata describing how the candidate windows were selected. For
#'   multi-sample input, windows are returned for each sample. Here
#'   `degraded = TRUE` indicates that detection required fallback behavior, such
#'   as reducing the requested window size or returning a placeholder result
#'   because too few usable observations were available.
#'
#' @examples
#' data(yeast_growth_data)
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' phase_tbl <- detect_exponential_phase(dplyr::filter(tidy_growth, sample == sample_id))
#' head(phase_tbl)
#' averaged_phase_tbl <- detect_exponential_phase(
#'   tidy_growth,
#'   average_replicates = TRUE
#' )
#' head(averaged_phase_tbl)
#' @export
detect_exponential_phase <- function(data,
                                     select_replicates = NULL,
                                     average_replicates = FALSE,
                                     window_size = 5,
                                     min_od = 0.02) {
  data <- as_tidy_growth_data(data)
  data <- validate_growth_data(data, warn_zero_od = TRUE)

  if (!is.null(select_replicates)) {
    if (!"replicate" %in% names(data)) {
      stop(
        "`select_replicates` requires a `replicate` column or sample names that encode replicates.",
        call. = FALSE
      )
    }

    data <- dplyr::filter(data, .data$replicate %in% select_replicates)
    if (nrow(data) == 0L) {
      stop("No rows remain after filtering `select_replicates`.", call. = FALSE)
    }
  }

  if (isTRUE(average_replicates)) {
    data <- growkar_average_replicates(data) |>
      dplyr::mutate(od = .data$od_mean) |>
      dplyr::select(-dplyr::any_of(c("od_mean", "od_sd", "n")))
    data <- validate_growth_data(data, warn_zero_od = TRUE)
  }

  sample_list <- split(data, data$sample)
  purrr::map_dfr(sample_list, detect_exponential_phase_single_sample, window_size = window_size, min_od = min_od)
}

detect_exponential_phase_single_sample <- function(data, window_size = 5, min_od = 0.02) {
  sample_id <- unique(data$sample)

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
