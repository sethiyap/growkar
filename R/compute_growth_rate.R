#' Compute Growth Rate
#'
#' Estimate per-sample growth rate from tidy growth data.
#'
#' @param data Growth curve data in tidy or wide format.
#' @param method Estimation method. One of `"rolling_window"`,
#'   `"defined_interval"`, or `"rule_based"`.
#' @param interval Interval definition for `defined_interval`. Supply either a
#'   numeric vector of length two or a data frame whose first three columns are
#'   sample, start time, and end time.
#' @param average_replicates Logical; if `TRUE`, average replicates before
#'   estimation when replicate metadata are available.
#' @param window_size Rolling window size for `rolling_window`.
#' @param min_od Minimum OD retained when fitting log-linear models.
#' @param first_timepoint Reference time used by the legacy `"rule_based"`
#'   method.
#'
#' @return A tibble with `sample`, `mu`, `start_time`, `end_time`, `r_squared`,
#'   and `method`.
#' @export
compute_growth_rate <- function(data,
                                method = c("rolling_window", "defined_interval", "rule_based"),
                                interval = NULL,
                                average_replicates = FALSE,
                                window_size = 5,
                                min_od = 0.02,
                                first_timepoint = NULL) {
  method <- match.arg(method)
  tidy_data <- as_tidy_growth_data(data)
  tidy_data <- validate_growth_data(tidy_data)

  if (isTRUE(average_replicates)) {
    tidy_data <- growkar_average_replicates(tidy_data) |>
      dplyr::mutate(od = .data$od_mean) |>
      dplyr::select(-dplyr::any_of(c("od_mean", "od_sd", "n")))
    tidy_data <- validate_growth_data(tidy_data)
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
    return(tibble::tibble(
      sample = sample_id,
      mu = NA_real_,
      start_time = NA_real_,
      end_time = NA_real_,
      r_squared = NA_real_,
      method = "rolling_window"
    ))
  }

  best <- windows[1, , drop = FALSE]
  tibble::tibble(
    sample = sample_id,
    mu = best$slope,
    start_time = best$start_time,
    end_time = best$end_time,
    r_squared = best$r_squared,
    method = "rolling_window"
  )
}

compute_growth_rate_defined_interval <- function(data, interval, min_od) {
  sample_id <- unique(data$sample)
  bounds <- growkar_resolve_interval(interval, sample_id)
  subset_data <- data |>
    dplyr::filter(.data$time >= bounds[1], .data$time <= bounds[2], .data$od > min_od) |>
    dplyr::arrange(.data$time)

  if (nrow(subset_data) < 2L) {
    return(tibble::tibble(
      sample = sample_id,
      mu = NA_real_,
      start_time = bounds[1],
      end_time = bounds[2],
      r_squared = NA_real_,
      method = "defined_interval"
    ))
  }

  fit <- stats::lm(log(od) ~ time, data = subset_data)
  summary_fit <- suppressWarnings(summary(fit))

  tibble::tibble(
    sample = sample_id,
    mu = unname(stats::coef(fit)[["time"]]),
    start_time = bounds[1],
    end_time = bounds[2],
    r_squared = unname(summary_fit$r.squared),
    method = "defined_interval"
  )
}

compute_growth_rate_rule_based <- function(data, first_timepoint = NULL) {
  sample_id <- unique(data$sample)
  data <- data |>
    dplyr::arrange(.data$time) |>
    dplyr::filter(.data$od > 0)

  if (nrow(data) < 3L) {
    return(tibble::tibble(
      sample = sample_id,
      mu = NA_real_,
      start_time = NA_real_,
      end_time = NA_real_,
      r_squared = NA_real_,
      method = "rule_based"
    ))
  }

  reference_time <- if (is.null(first_timepoint)) min(data$time) else first_timepoint
  reference_index <- which.min(abs(data$time - reference_time))
  od0 <- data$od[[reference_index]]

  if (!is.finite(od0) || od0 <= 0) {
    return(tibble::tibble(
      sample = sample_id,
      mu = NA_real_,
      start_time = NA_real_,
      end_time = NA_real_,
      r_squared = NA_real_,
      method = "rule_based"
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

  tibble::tibble(
    sample = sample_id,
    mu = mu,
    start_time = t1,
    end_time = t2,
    r_squared = NA_real_,
    method = "rule_based"
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

    names(interval)[1:3] <- c("sample", "start_time", "end_time")
    match_row <- interval[interval$sample %in% sample_id, , drop = FALSE]
    if (nrow(match_row) == 0L) {
      stop("No interval found for sample `", sample_id, "`.", call. = FALSE)
    }

    return(as.numeric(match_row[1, c("start_time", "end_time")]))
  }

  stop("Unsupported `interval` specification.", call. = FALSE)
}
