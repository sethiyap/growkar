#' Coerce Growth Data to Canonical Tidy Format
#'
#' Convert growth data into a tidy adapter representation.
#'
#' Convert growth curve data supplied in either wide or long form into a tidy
#' representation for inspection, import convenience, and interoperability.
#' Within `growkar`, the canonical analysis container is
#' `SummarizedExperiment`; tidy data are supported as a user-facing adapter
#' layer.
#'
#' Wide input is expected to contain time in the first column and sample names
#' in the remaining column names. Tidy input is expected to contain at least
#' `sample`, `time`, and `od`. When replicate identifiers are encoded in sample
#' names, use a consistent suffix such as `_R1` or `_1` so replicate metadata
#' can be inferred reliably. Common machine-exported column labels such as
#' `Time [s]`, `Time [h]`, `Sample`, `Well`, `OD600`, `OD 600`, and
#' `Absorbance 600` are detected automatically where possible, which helps
#' when importing exports from Agilent microplate readers, BioTek Cytation
#' instruments, LogPhase 600, and similar OD600-based plate-reader workflows.
#'
#' @param data A data frame, tibble, `SummarizedExperiment`, `growkar_data`
#'   object, or object coercible to a tibble.
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
#'
#' se <- as_summarized_experiment(yeast_growth_data)
#' head(as_tidy_growth_data(se))
#' @export
as_tidy_growth_data <- function(data,
                                sample_col = "sample",
                                time_col = "time",
                                od_col = "od",
                                sample_sep = "_") {
  if (inherits(data, "SummarizedExperiment")) {
    return(growkar_tidy_from_summarized_experiment(data))
  }

  if (inherits(data, "growkar_data")) {
    return(tibble::as_tibble(data$processed_data))
  }

  data <- tibble::as_tibble(data)
  resolved_time_col <- growkar_resolve_column_name(names(data), time_col, growkar_time_aliases())
  resolved_sample_col <- growkar_resolve_column_name(names(data), sample_col, growkar_sample_aliases())
  resolved_od_col <- growkar_resolve_column_name(names(data), od_col, growkar_od_aliases())

  if (!is.null(resolved_sample_col) &&
      !is.null(resolved_time_col) &&
      !is.null(resolved_od_col)) {
    extra_cols <- setdiff(names(data), c(resolved_sample_col, resolved_time_col, resolved_od_col))
    tidy_data <- dplyr::transmute(
      data,
      sample = as.character(.data[[resolved_sample_col]]),
      time = .data[[resolved_time_col]],
      od = .data[[resolved_od_col]],
      !!!rlang::syms(extra_cols)
    )
  } else {
    if (is.null(resolved_time_col)) {
      names(data)[1] <- "time"
    } else {
      names(data)[names(data) == resolved_time_col] <- "time"
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
  tidy_data <- growkar_normalize_machine_export(tidy_data)

  metadata <- growkar_infer_sample_metadata(tidy_data$sample, sample_sep = sample_sep)
  metadata_cols <- setdiff(names(metadata), names(tidy_data))
  if (length(metadata_cols) > 0L) {
    tidy_data <- dplyr::bind_cols(tidy_data, metadata[metadata_cols])
  }

  tidy_data
}

growkar_resolve_column_name <- function(column_names, requested, aliases = character()) {
  if (requested %in% column_names) {
    return(requested)
  }

  matches <- aliases[aliases %in% column_names]
  if (length(matches) > 0L) {
    return(matches[[1]])
  }

  NULL
}

growkar_time_aliases <- function() {
  c(
    "time", "Time", "TIME", "Time [s]", "Time [sec]", "Time (s)",
    "Time [h]", "Time [hr]", "Time (h)", "Elapsed Time", "Elapsed time",
    "Kinetic Time", "Kinetic Time [s]", "Hours", "hours"
  )
}

growkar_sample_aliases <- function() {
  c("sample", "Sample", "SAMPLE", "well", "Well", "WELL", "Well ID", "well_id")
}

growkar_od_aliases <- function() {
  c(
    "od", "OD", "Od", "OD600", "OD 600", "OD_600", "OD(600)",
    "Absorbance 600", "Absorbance_600", "A600", "LogPhase 600",
    "LogPhase_600", "logphase_600"
  )
}

growkar_normalize_machine_export <- function(data) {
  parsed_time <- growkar_parse_time_values(data$time)
  dropped_rows <- sum(is.na(parsed_time) & !is.na(data$time))

  if (dropped_rows > 0L) {
    warning(
      "Dropped ", dropped_rows,
      " row(s) with non-numeric time values, which can occur in instrument export headers.",
      call. = FALSE
    )
  }

  data <- data[!is.na(parsed_time), , drop = FALSE]
  data$time <- parsed_time[!is.na(parsed_time)]
  data$od <- growkar_parse_numeric_values(data$od)
  data
}

growkar_parse_time_values <- function(x) {
  if (is.numeric(x)) {
    return(as.numeric(x))
  }

  x <- trimws(as.character(x))
  hms_pattern <- "^[0-9]{1,2}:[0-9]{2}:[0-9]{2}$"
  out <- rep(NA_real_, length(x))

  hms_idx <- grepl(hms_pattern, x)
  if (any(hms_idx)) {
    parts <- strsplit(x[hms_idx], ":", fixed = TRUE)
    out[hms_idx] <- vapply(parts, function(part) {
      as.numeric(part[[1]]) + as.numeric(part[[2]]) / 60 + as.numeric(part[[3]]) / 3600
    }, numeric(1))
  }

  numeric_idx <- !hms_idx
  if (any(numeric_idx)) {
    out[numeric_idx] <- growkar_parse_numeric_values(x[numeric_idx])
  }

  out
}

growkar_parse_numeric_values <- function(x) {
  if (is.numeric(x)) {
    return(as.numeric(x))
  }

  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  x <- sub(",", ".", x, fixed = TRUE)

  suppressWarnings(as.numeric(x))
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
