#' Compute Growth Rate
#'
#' Estimate per-sample growth rate from tidy growth data.
#'
#' The returned `mu` column is the specific growth rate, estimated as the slope
#' of `log(od)` versus time over the selected interval or window.
#'
#' Available methods:
#' \itemize{
#'   \item `rolling_window`: scans rolling windows across the time series and
#'   selects the window with the strongest positive log-linear slope.
#'   \item `defined_interval`: fits the growth rate over a user-supplied start
#'   and end time interval.
#'   \item `rule_based`: uses OD-doubling heuristics to anchor the exponential
#'   interval from the observed curve.
#' }
#'
#' @param data Growth curve data in tidy or wide format.
#' @param method Estimation method. One of `"rolling_window"`,
#'   `"defined_interval"`, or `"rule_based"`.
#' @param interval Interval definition for `defined_interval`. Supply either a
#'   numeric vector of length two or a data frame whose first three columns are
#'   sample, start time, and end time.
#' @param select_replicates Optional character vector of replicate IDs to retain
#'   before estimation. When `NULL`, all replicates are retained.
#' @param average_replicates Logical; if `TRUE`, average replicates before
#'   estimation when replicate metadata are available.
#' @param window_size Rolling window size for `rolling_window`.
#' @param min_od Minimum OD retained when fitting log-linear models.
#' @param first_timepoint Reference time used by the `"rule_based"` method.
#'
#' @return A tibble with `sample`, `mu`, `start_time`, `end_time`, `r_squared`,
#'   and `method`. Here `mu` is the estimated specific growth rate. Additional
#'   diagnostic columns describe the number of points used and whether the
#'   estimate required degraded fallback behavior.
#'
#' @examples
#' data(yeast_growth_data)
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' compute_growth_rate(
#'   dplyr::filter(tidy_growth, sample == sample_id),
#'   method = "rolling_window"
#' )
#' @export
compute_growth_rate <- function(data,
                                method = c("rolling_window", "defined_interval", "rule_based"),
                                interval = NULL,
                                select_replicates = NULL,
                                average_replicates = FALSE,
                                window_size = 5,
                                min_od = 0.02,
                                first_timepoint = NULL) {
  method <- match.arg(method)
  tidy_data <- as_tidy_growth_data(data)
  tidy_data <- validate_growth_data(tidy_data, warn_zero_od = TRUE)

  if (!is.null(select_replicates)) {
    if (!"replicate" %in% names(tidy_data)) {
      stop(
        "`select_replicates` requires a `replicate` column or sample names that encode replicates.",
        call. = FALSE
      )
    }

    tidy_data <- dplyr::filter(tidy_data, .data$replicate %in% select_replicates)
    if (nrow(tidy_data) == 0L) {
      stop("No rows remain after filtering `select_replicates`.", call. = FALSE)
    }
  }

  if (isTRUE(average_replicates)) {
    tidy_data <- growkar_average_replicates(tidy_data) |>
      dplyr::mutate(od = .data$od_mean) |>
      dplyr::select(-dplyr::any_of(c("od_mean", "od_sd", "n")))
    tidy_data <- validate_growth_data(tidy_data, warn_zero_od = TRUE)
  }

  sample_list <- split(tidy_data, tidy_data$sample)
  results <- purrr::map_dfr(sample_list, function(sample_data) {
    switch(
      method,
      rolling_window = compute_growth_rate_rolling_window(
        sample_data,
        window_size = window_size,
        min_od = min_od
      ),
      defined_interval = compute_growth_rate_defined_interval(
        sample_data,
        interval = interval,
        min_od = min_od
      ),
      rule_based = compute_growth_rate_rule_based(
        sample_data,
        first_timepoint = first_timepoint
      )
    )
  })

  tibble::as_tibble(results)
}

compute_growth_rate_rolling_window <- function(data, window_size, min_od) {
  windows <- detect_exponential_phase(data, window_size = window_size, min_od = min_od)
  sample_id <- unique(data$sample)

  if (nrow(windows) == 0L) {
    growkar_warn_metric(sample_id, "Exponential phase could not be detected.")
    return(growkar_metric_result(sample_id, method = "rolling_window", note = "no_candidate_windows"))
  }

  best <- windows[1, , drop = FALSE]
  if (is.na(best$slope) || best$slope <= 0) {
    growkar_warn_metric(sample_id, paste0("Exponential phase detection did not yield a positive growth slope (", best$selection_reason, ")."))
    return(growkar_metric_result(
      sample_id,
      method = "rolling_window",
      n_points = best$n_points,
      degraded = best$degraded,
      note = best$selection_reason
    ))
  }

  growkar_metric_result(
    sample_id,
    mu = best$slope,
    start_time = best$start_time,
    end_time = best$end_time,
    r_squared = best$r_squared,
    method = "rolling_window",
    n_points = best$n_points,
    degraded = best$degraded,
    note = best$selection_reason
  )
}

compute_growth_rate_defined_interval <- function(data, interval, min_od) {
  sample_id <- unique(data$sample)
  bounds <- growkar_resolve_interval(interval, sample_id)
  interval_data <- data |>
    dplyr::filter(.data$time >= bounds[1], .data$time <= bounds[2]) |>
    dplyr::arrange(.data$time)

  if (nrow(interval_data) < 2L) {
    growkar_warn_metric(sample_id, "Defined interval contains fewer than two observations.")
    return(growkar_metric_result(
      sample_id,
      method = "defined_interval",
      start_time = bounds[1],
      end_time = bounds[2],
      n_points = nrow(interval_data),
      degraded = TRUE,
      note = "insufficient_interval_points"
    ))
  }

  subset_data <- dplyr::filter(interval_data, .data$od > min_od)

  if (nrow(subset_data) < 2L) {
    growkar_warn_metric(sample_id, "Defined interval does not contain enough positive OD values for log-based fitting.")
    return(growkar_metric_result(
      sample_id,
      method = "defined_interval",
      start_time = bounds[1],
      end_time = bounds[2],
      n_points = nrow(subset_data),
      degraded = TRUE,
      note = "insufficient_positive_points_in_interval"
    ))
  }

  fit_summary <- growkar_fit_log_linear(subset_data)
  if (!fit_summary$success || fit_summary$slope <= 0) {
    growkar_warn_metric(sample_id, "Defined interval did not yield a positive growth slope.")
    return(growkar_metric_result(
      sample_id,
      method = "defined_interval",
      start_time = bounds[1],
      end_time = bounds[2],
      n_points = nrow(subset_data),
      degraded = TRUE,
      note = fit_summary$note
    ))
  }

  growkar_metric_result(
    sample_id,
    mu = fit_summary$slope,
    start_time = bounds[1],
    end_time = bounds[2],
    r_squared = fit_summary$r_squared,
    method = "defined_interval",
    n_points = nrow(subset_data),
    degraded = FALSE,
    note = "defined_interval_fit"
  )
}

compute_growth_rate_rule_based <- function(data, first_timepoint = NULL) {
  sample_id <- unique(data$sample)
  data <- data |>
    dplyr::arrange(.data$time) |>
    dplyr::filter(.data$od > 0)

  if (nrow(data) < 3L) {
    growkar_warn_metric(sample_id, "Rule-based growth estimation requires at least three positive observations.")
    return(growkar_metric_result(
      sample_id,
      method = "rule_based",
      n_points = nrow(data),
      degraded = TRUE,
      note = "insufficient_positive_points"
    ))
  }

  reference_time <- if (is.null(first_timepoint)) min(data$time) else first_timepoint
  reference_index <- which.min(abs(data$time - reference_time))
  od0 <- data$od[[reference_index]]

  if (!is.finite(od0) || od0 <= 0) {
    growkar_warn_metric(sample_id, "Rule-based growth estimation could not identify a valid starting OD.")
    return(growkar_metric_result(
      sample_id,
      method = "rule_based",
      n_points = nrow(data),
      degraded = TRUE,
      note = "invalid_reference_od"
    ))
  }

  first_phase_index <- which.min(abs(data$od - (od0 * 2)))
  od1 <- data$od[[first_phase_index]]
  second_phase_index <- which.min(abs(data$od - (od1 * 2)))

  t1 <- data$time[[first_phase_index]]
  t2 <- data$time[[second_phase_index]]
  od2 <- data$od[[second_phase_index]]

  mu <- if (t2 > t1 && od1 > 0 && od2 > 0) {
    (log(od2) - log(od1)) / (t2 - t1)
  } else {
    NA_real_
  }

  if (is.na(mu) || mu <= 0) {
    growkar_warn_metric(sample_id, "Rule-based growth estimation did not yield a positive growth slope.")
    return(growkar_metric_result(
      sample_id,
      method = "rule_based",
      start_time = t1,
      end_time = t2,
      n_points = nrow(data),
      degraded = TRUE,
      note = "non_positive_growth"
    ))
  }

  growkar_metric_result(
    sample_id,
    mu = mu,
    start_time = t1,
    end_time = t2,
    method = "rule_based",
    n_points = nrow(data),
    degraded = FALSE,
    note = "rule_based_od_doubling"
  )
}

growkar_resolve_interval <- function(interval, sample_id) {
  if (is.null(interval)) {
    stop("`interval` must be supplied for `method = \"defined_interval\"`.", call. = FALSE)
  }

  if (is.numeric(interval) && length(interval) == 2L) {
    return(as.numeric(interval))
  }

  if (is.data.frame(interval)) {
    interval <- tibble::as_tibble(interval)
    if (ncol(interval) < 3L) {
      stop("Interval data frames must have at least three columns.", call. = FALSE)
    }

    names(interval)[seq_len(3)] <- c("sample", "start_time", "end_time")
    match_row <- interval[interval$sample %in% sample_id, , drop = FALSE]
    if (nrow(match_row) == 0L) {
      stop("No interval found for sample `", sample_id, "`.", call. = FALSE)
    }

    return(as.numeric(match_row[1, c("start_time", "end_time")]))
  }

  stop("Unsupported `interval` specification.", call. = FALSE)
}

growkar_fit_log_linear <- function(data) {
  if (nrow(data) < 2L) {
    return(list(success = FALSE, slope = NA_real_, r_squared = NA_real_, note = "insufficient_points"))
  }

  if (all(abs(data$od - data$od[[1]]) < sqrt(.Machine$double.eps))) {
    return(list(success = FALSE, slope = 0, r_squared = NA_real_, note = "flat_curve"))
  }

  fit <- tryCatch(stats::lm(log(od) ~ time, data = data), error = function(e) e)
  if (inherits(fit, "error")) {
    return(list(success = FALSE, slope = NA_real_, r_squared = NA_real_, note = "log_linear_fit_failed"))
  }

  summary_fit <- suppressWarnings(summary(fit))
  list(
    success = TRUE,
    slope = unname(stats::coef(fit)[["time"]]),
    r_squared = unname(summary_fit$r.squared),
    note = "log_linear_fit"
  )
}

growkar_metric_result <- function(sample,
                                  mu = NA_real_,
                                  start_time = NA_real_,
                                  end_time = NA_real_,
                                  r_squared = NA_real_,
                                  method,
                                  n_points = NA_integer_,
                                  degraded = FALSE,
                                  note = NA_character_) {
  tibble::tibble(
    sample = sample,
    mu = mu,
    start_time = start_time,
    end_time = end_time,
    r_squared = r_squared,
    method = method,
    n_points = as.integer(n_points),
    degraded = degraded,
    note = note
  )
}

growkar_warn_metric <- function(sample_id, message_text) {
  warning("Sample `", sample_id, "`: ", message_text, call. = FALSE)
}
