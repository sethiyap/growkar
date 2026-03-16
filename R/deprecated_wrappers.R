#' Deprecated Wrapper for Rule-Based Growth Rate
#'
#' @param dat_growth_curve Growth curve data in the legacy wide format.
#' @param average_replicates Logical; average replicates before estimation.
#' @param first_timepoint Reference time used to define the first doubling.
#' @param select_replicates Optional replicate IDs to retain.
#' @param end_timepoint Optional maximum time value to retain.
#'
#' @return A tibble compatible with the legacy `growkar` output.
#' @export
calculate_growth_rate <- function(dat_growth_curve,
                                  average_replicates = FALSE,
                                  first_timepoint = 0,
                                  select_replicates = NULL,
                                  end_timepoint = NULL) {
  lifecycle::deprecate_warn("2.0.0", "calculate_growth_rate()", "compute_growth_rate()")

  tidy_data <- as_tidy_growth_data(dat_growth_curve)
  if (!is.null(end_timepoint)) {
    tidy_data <- dplyr::filter(tidy_data, .data$time <= end_timepoint)
  }
  if (!is.null(select_replicates) && "replicate" %in% names(tidy_data)) {
    tidy_data <- dplyr::filter(tidy_data, .data$replicate %in% select_replicates)
  }

  metrics <- compute_growth_rate(
    tidy_data,
    method = "rule_based",
    average_replicates = average_replicates,
    first_timepoint = first_timepoint
  )

  growkar_format_legacy_metrics(metrics, tidy_data, average_replicates = average_replicates)
}

#' Deprecated Wrapper for Defined-Interval Growth Rate
#'
#' @param dat_growth_curve Growth curve data in the legacy wide format.
#' @param logphase_tibble A data frame whose first three columns contain sample,
#'   start time, and end time.
#' @param average_replicates Logical; average replicates before estimation.
#' @param select_replicates Optional replicate IDs to retain.
#'
#' @return A tibble compatible with the legacy `growkar` output.
#' @export
calculate_growthrate_from_defined_logphase <- function(dat_growth_curve,
                                                       logphase_tibble,
                                                       average_replicates = FALSE,
                                                       select_replicates = NULL) {
  lifecycle::deprecate_warn(
    "2.0.0",
    "calculate_growthrate_from_defined_logphase()",
    "compute_growth_rate(method = \"defined_interval\")"
  )

  tidy_data <- as_tidy_growth_data(dat_growth_curve)
  if (!is.null(select_replicates) && "replicate" %in% names(tidy_data)) {
    tidy_data <- dplyr::filter(tidy_data, .data$replicate %in% select_replicates)
  }

  metrics <- compute_growth_rate(
    tidy_data,
    method = "defined_interval",
    interval = logphase_tibble,
    average_replicates = average_replicates
  )

  growkar_format_legacy_metrics(metrics, tidy_data, average_replicates = average_replicates)
}

#' @rdname calculate_growthrate_from_defined_logphase
#' @export
calculate_growthrate_from_defined_time <- function(dat_growth_curve,
                                                   logphase_tibble,
                                                   average_replicates = FALSE,
                                                   select_replicates = NULL) {
  lifecycle::deprecate_warn(
    "2.0.0",
    "calculate_growthrate_from_defined_time()",
    "compute_growth_rate(method = \"defined_interval\")"
  )

  calculate_growthrate_from_defined_logphase(
    dat_growth_curve = dat_growth_curve,
    logphase_tibble = logphase_tibble,
    average_replicates = average_replicates,
    select_replicates = select_replicates
  )
}

growkar_format_legacy_metrics <- function(metrics, tidy_data, average_replicates) {
  meta_cols <- if (isTRUE(average_replicates)) {
    unique(c("sample", intersect("condition", names(tidy_data))))
  } else {
    unique(c("sample", intersect(c("condition", "replicate"), names(tidy_data))))
  }
  metadata <- tidy_data |>
    dplyr::distinct(dplyr::across(dplyr::all_of(meta_cols)))

  out <- dplyr::left_join(metrics, metadata, by = "sample") |>
    dplyr::mutate(
      growth_rate = round(.data$mu, 3),
      doubling_time = round(compute_doubling_time(.data$mu) * 60, 3),
      time1 = .data$start_time,
      time2 = .data$end_time
    )

  if (isTRUE(average_replicates)) {
    if ("condition" %in% names(out)) {
      return(dplyr::select(out, .data$condition, .data$time1, .data$time2, .data$growth_rate, .data$doubling_time))
    }

    return(dplyr::select(out, .data$sample, .data$time1, .data$time2, .data$growth_rate, .data$doubling_time))
  }

  if (all(c("condition", "replicate") %in% names(out))) {
    return(dplyr::select(out, .data$condition, .data$replicate, .data$time1, .data$time2, .data$growth_rate, .data$doubling_time))
  }

  dplyr::select(out, .data$sample, .data$time1, .data$time2, .data$growth_rate, .data$doubling_time)
}
