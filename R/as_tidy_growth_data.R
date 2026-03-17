#' Coerce Growth Data to Canonical Tidy Format
#'
#' Convert growth curve data supplied in either wide or long form into the
#' canonical tidy representation used throughout `growkar`.
#'
#' @param data A data frame, tibble, or object coercible to a tibble.
#' @param sample_col Name of the sample column for long-form input.
#' @param time_col Name of the time column.
#' @param od_col Name of the optical density column.
#' @param sample_sep Separator used to infer metadata columns from sample names
#'   in wide data or in long data when `sample` is present.
#'
#' @return A tibble containing at least `sample`, `time`, and `od`. Additional
#'   metadata columns are preserved where available.
#'
#' @examples
#' data(yeast_growth_data)
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' head(tidy_growth)
#' @export
as_tidy_growth_data <- function(data,
                                sample_col = "sample",
                                time_col = "time",
                                od_col = "od",
                                sample_sep = "_") {
  data <- tibble::as_tibble(data)

  if (all(c(sample_col, time_col, od_col) %in% names(data))) {
    extra_cols <- setdiff(names(data), c(sample_col, time_col, od_col))
    tidy_data <- dplyr::transmute(
      data,
      sample = as.character(.data[[sample_col]]),
      time = .data[[time_col]],
      od = .data[[od_col]],
      !!!rlang::syms(extra_cols)
    )
  } else {
    if (!time_col %in% names(data)) {
      names(data)[1] <- "time"
    } else {
      names(data)[names(data) == time_col] <- "time"
    }

    if (!"time" %in% names(data)) {
      stop("`data` must contain a time column.", call. = FALSE)
    }

    value_cols <- setdiff(names(data), "time")
    if (length(value_cols) == 0L) {
      stop("`data` must contain at least one sample column.", call. = FALSE)
    }

    tidy_data <- tidyr::pivot_longer(
      data = data,
      cols = dplyr::all_of(value_cols),
      names_to = "sample",
      values_to = "od"
    )
  }

  tidy_data <- tibble::as_tibble(tidy_data)

  metadata <- growkar_infer_sample_metadata(tidy_data$sample, sample_sep = sample_sep)
  metadata_cols <- setdiff(names(metadata), names(tidy_data))
  if (length(metadata_cols) > 0L) {
    tidy_data <- dplyr::bind_cols(tidy_data, metadata[metadata_cols])
  }

  tidy_data
}

growkar_infer_sample_metadata <- function(sample, sample_sep = "_") {
  sample <- as.character(sample)
  parts <- strsplit(sample, split = sample_sep, fixed = TRUE)
  part_lengths <- lengths(parts)

  out <- tibble::tibble()
  if (length(parts) == 0L || any(part_lengths < 2L) || length(unique(part_lengths)) != 1L) {
    return(out)
  }

  if (unique(part_lengths) == 2L) {
    out <- tibble::tibble(
      condition = vapply(parts, `[`, character(1), 1),
      replicate = vapply(parts, `[`, character(1), 2)
    )
  }

  if (unique(part_lengths) >= 3L) {
    out <- tibble::tibble(
      condition = vapply(parts, `[`, character(1), 1),
      plate = vapply(
        parts,
        function(x) paste(x[2:(length(x) - 1L)], collapse = sample_sep),
        character(1)
      ),
      replicate = vapply(parts, function(x) x[[length(x)]], character(1))
    )
  }

  out
}
