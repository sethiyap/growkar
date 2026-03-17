#' Validate Canonical Growth Data
#'
#' Validate tidy growth data before downstream analysis.
#'
#' @param data A data frame containing at least `sample`, `time`, and `od`.
#' @param allow_negative_od Logical; if `FALSE`, negative optical density values
#'   are rejected.
#' @param require_increasing_time Logical; if `TRUE`, `time` must be strictly
#'   increasing within each sample.
#' @param min_points_per_sample Minimum number of rows required within each
#'   sample.
#' @param warn_zero_od Logical; if `TRUE`, emit a warning when zero OD values
#'   are present.
#' @param require_finite Logical; if `TRUE`, reject non-finite numeric values in
#'   `time` or `od`.
#'
#' @return The validated tibble after coercion to tibble.
#'
#' @examples
#' tidy_data <- as_tidy_growth_data(yeast_growth_data)
#' validate_growth_data(tidy_data)
#' @export
validate_growth_data <- function(data,
                                 allow_negative_od = FALSE,
                                 require_increasing_time = TRUE,
                                 min_points_per_sample = 2L,
                                 warn_zero_od = FALSE,
                                 require_finite = TRUE) {
  data <- tibble::as_tibble(data)
  validate_required_columns(data)
  validate_column_types(data)
  validate_finite_values(data, require_finite = require_finite)
  validate_missing_key_values(data)
  validate_non_negative_od(data, allow_negative_od = allow_negative_od)
  validate_duplicate_sample_time(data)
  validate_time_order(data, require_increasing_time = require_increasing_time)
  validate_min_points_per_sample(data, min_points_per_sample = min_points_per_sample)
  warn_zero_od_values(data, warn_zero_od = warn_zero_od)

  data
}

validate_required_columns <- function(data) {
  required_cols <- c("sample", "time", "od")
  missing_cols <- setdiff(required_cols, names(data))

  if (length(missing_cols) > 0L) {
    stop(
      "Missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }
}

validate_column_types <- function(data) {
  if (!is.numeric(data$time)) {
    stop("`time` must be numeric.", call. = FALSE)
  }

  if (!is.numeric(data$od)) {
    stop("`od` must be numeric.", call. = FALSE)
  }
}

validate_missing_key_values <- function(data) {
  missing_rows <- which(is.na(data$sample) | is.na(data$time) | is.na(data$od))
  if (length(missing_rows) > 0L) {
    stop(
      "`sample`, `time`, and `od` must not contain missing values. First problematic row: ",
      missing_rows[[1]],
      ".",
      call. = FALSE
    )
  }
}

validate_finite_values <- function(data, require_finite) {
  if (!isTRUE(require_finite)) {
    return(invisible(NULL))
  }

  bad_rows <- which(!is.finite(data$time) | !is.finite(data$od))
  if (length(bad_rows) > 0L) {
    bad_samples <- unique(as.character(data$sample[bad_rows]))
    stop(
      "`time` and `od` must contain only finite numeric values. Problematic sample(s): ",
      paste(utils::head(bad_samples, 5L), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
}

validate_non_negative_od <- function(data, allow_negative_od) {
  if (isTRUE(allow_negative_od)) {
    return(invisible(NULL))
  }

  bad_rows <- which(data$od < 0)
  if (length(bad_rows) > 0L) {
    bad_samples <- unique(as.character(data$sample[bad_rows]))
    stop(
      "Negative `od` values are not allowed by default. Problematic sample(s): ",
      paste(utils::head(bad_samples, 5L), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
}

validate_duplicate_sample_time <- function(data) {
  duplicate_rows <- duplicated(data[c("sample", "time")]) | duplicated(data[c("sample", "time")], fromLast = TRUE)
  if (any(duplicate_rows)) {
    duplicate_keys <- unique(data[duplicate_rows, c("sample", "time"), drop = FALSE])
    stop(
      "Duplicate `sample`-`time` rows are not allowed. First duplicate key: sample = `",
      duplicate_keys$sample[[1]],
      "`, time = ",
      duplicate_keys$time[[1]],
      ".",
      call. = FALSE
    )
  }
}

validate_time_order <- function(data, require_increasing_time) {
  if (!isTRUE(require_increasing_time)) {
    return(invisible(NULL))
  }

  bad_samples <- data |>
    dplyr::group_by(.data$sample) |>
    dplyr::summarise(
      is_increasing = all(diff(.data$time) > 0),
      .groups = "drop"
    ) |>
    dplyr::filter(!.data$is_increasing) |>
    dplyr::pull(.data$sample)

  if (length(bad_samples) > 0L) {
    stop(
      "`time` must be strictly increasing within each sample. Problematic sample(s): ",
      paste(utils::head(bad_samples, 5L), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
}

validate_min_points_per_sample <- function(data, min_points_per_sample) {
  min_points_per_sample <- as.integer(min_points_per_sample)
  if (is.na(min_points_per_sample) || min_points_per_sample < 1L) {
    stop("`min_points_per_sample` must be a positive integer.", call. = FALSE)
  }

  bad_samples <- data |>
    dplyr::count(.data$sample, name = "n_points") |>
    dplyr::filter(.data$n_points < min_points_per_sample)

  if (nrow(bad_samples) > 0L) {
    sample_labels <- paste0(bad_samples$sample, " (n=", bad_samples$n_points, ")")
    stop(
      "Each sample must contain at least ",
      min_points_per_sample,
      " point(s). Problematic sample(s): ",
      paste(utils::head(sample_labels, 5L), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
}

warn_zero_od_values <- function(data, warn_zero_od) {
  if (!isTRUE(warn_zero_od)) {
    return(invisible(NULL))
  }

  zero_samples <- unique(as.character(data$sample[data$od == 0]))
  if (length(zero_samples) > 0L) {
    warning(
      "Zero `od` values detected. Log-based downstream methods may omit or degrade these observations. Sample(s): ",
      paste(utils::head(zero_samples, 5L), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
}
