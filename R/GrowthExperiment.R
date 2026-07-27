#' Construct a `GrowthExperiment`
#'
#' Build a [GrowthExperiment-class] object, the canonical `growkar` container,
#' from tidy or wide growth curve data. `GrowthExperiment` extends
#' [SummarizedExperiment::SummarizedExperiment], so the result can be used
#' directly by any Bioconductor package.
#'
#' The resulting object stores time points in `rowData(x)$time`, sample-level
#' metadata in `colData(x)`, optical density measurements in
#' `assay(x, "od")`, and derived results in `metadata(x)`.
#'
#' Coercion methods are also provided, so `as(x, "GrowthExperiment")` works for
#' a `data.frame`, `tibble`, `matrix`, or existing `SummarizedExperiment`, and
#' `as(x, "SummarizedExperiment")` is available in the other direction. Use the
#' constructor when you need to control column-name resolution; use `as()` for
#' the default behaviour.
#'
#' @param data Growth curve data in tidy or wide format, or a
#'   `SummarizedExperiment`.
#' @param metrics Optional data frame of precomputed sample-level metrics to
#'   store in `metadata(x)$growth_metrics`. Metrics computed by `growkar`
#'   itself are normally attached with [growth_metrics()] instead.
#' @param sample_col Name of the sample column for long-form input.
#' @param time_col Name of the time column.
#' @param od_col Name of the optical density column.
#' @param sample_sep Separator used to infer metadata columns from sample names.
#'
#' @return A [GrowthExperiment-class] object with one assay named `od`.
#'
#' @seealso [GrowthExperiment-class]
#'
#' @examples
#' data(yeast_growth_data)
#'
#' ge <- GrowthExperiment(yeast_growth_data)
#' ge
#'
#' # Equivalent, using standard coercion.
#' as(yeast_growth_data, "GrowthExperiment")
#' @export
GrowthExperiment <- function(data,
                             metrics = NULL,
                             sample_col = "sample",
                             time_col = "time",
                             od_col = "od",
                             sample_sep = "_") {
  tidy_data <- as_tidy_growth_data(
    data = data,
    sample_col = sample_col,
    time_col = time_col,
    od_col = od_col,
    sample_sep = sample_sep
  )
  tidy_data <- validate_growth_data(tidy_data)

  extra_metadata <- if (is.null(metrics)) {
    list()
  } else {
    list(growth_metrics = tibble::as_tibble(metrics))
  }

  growkar_build_summarized_experiment(tidy_data, metadata = extra_metadata)
}

#' Coerce to a `GrowthExperiment`
#'
#' Standard S4 coercion methods for [GrowthExperiment-class]. Coercion in the
#' opposite direction, `as(x, "SummarizedExperiment")`, is inherited from the
#' class hierarchy and always available.
#'
#' @param from A `data.frame`, `matrix`, or `SummarizedExperiment` to coerce.
#'
#' @return A [GrowthExperiment-class] object.
#'
#' @name GrowthExperiment-coerce
#'
#' @examples
#' data(yeast_growth_data)
#'
#' ge <- as(yeast_growth_data, "GrowthExperiment")
#' ge
#'
#' se <- as(ge, "SummarizedExperiment")
#' as(se, "GrowthExperiment")
NULL

#' @rdname GrowthExperiment-coerce
methods::setAs("data.frame", "GrowthExperiment", function(from) {
  GrowthExperiment(from)
})

#' @rdname GrowthExperiment-coerce
methods::setAs("matrix", "GrowthExperiment", function(from) {
  GrowthExperiment(as.data.frame(from))
})

#' @rdname GrowthExperiment-coerce
methods::setAs("SummarizedExperiment", "GrowthExperiment", function(from) {
  methods::new("GrowthExperiment", growkar_normalize_se(from))
})

growkar_build_summarized_experiment <- function(tidy_data, metadata = list()) {
  sample_metadata <- growkar_sample_metadata(tidy_data)
  timepoints <- sort(unique(tidy_data$time))
  samples <- sample_metadata$sample

  assay_tbl <- tidy_data |>
    dplyr::select("sample", "time", "od") |>
    tidyr::pivot_wider(
      names_from = "sample",
      values_from = "od"
    ) |>
    dplyr::arrange(.data$time)

  assay_mat <- assay_tbl |>
    dplyr::select(-"time") |>
    as.matrix()

  storage.mode(assay_mat) <- "double"
  colnames(assay_mat) <- names(assay_tbl)[names(assay_tbl) != "time"]
  rownames(assay_mat) <- as.character(assay_tbl$time)
  assay_mat <- assay_mat[, samples, drop = FALSE]

  row_data <- S4Vectors::DataFrame(time = timepoints, row.names = as.character(timepoints))
  col_data <- S4Vectors::DataFrame(
    growkar_ordered_coldata(sample_metadata),
    row.names = sample_metadata$sample
  )

  schema_meta <- list(
    growkar_schema = list(
      assay = "od",
      rows = "timepoints",
      columns = "samples"
    )
  )

  se <- SummarizedExperiment::SummarizedExperiment(
    assays = list(od = assay_mat),
    rowData = row_data,
    colData = col_data,
    metadata = utils::modifyList(schema_meta, metadata)
  )

  methods::new("GrowthExperiment", se)
}

growkar_ordered_coldata <- function(sample_metadata) {
  sample_metadata[] <- lapply(names(sample_metadata), function(column_name) {
    column <- sample_metadata[[column_name]]

    if (identical(column_name, "sample") || !is.character(column)) {
      return(column)
    }

    stats::setNames(
      list(factor(column, levels = unique(column))),
      column_name
    )[[1]]
  })

  sample_metadata
}

growkar_sample_metadata <- function(data) {
  meta_cols <- setdiff(names(data), c("sample", "time", "od"))
  metadata <- data |>
    dplyr::select(dplyr::all_of(c("sample", meta_cols))) |>
    dplyr::distinct()

  duplicated_samples <- metadata$sample[duplicated(metadata$sample)]
  if (length(duplicated_samples) > 0L) {
    stop(
      "Sample metadata must be unique per `sample`. Conflicting metadata found for: ",
      paste(utils::head(unique(duplicated_samples), 5L), collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  metadata
}

# Long-form representation of a SummarizedExperiment.
#
# The transformation itself is delegated to tidySummarizedExperiment, whose
# `as_tibble()` method returns one row per feature/sample pair with rowData and
# colData columns joined on. This function only renames the tidyomics
# `.feature`/`.sample` columns to the canonical `time`/`sample`/`od` schema
# used by growkar's import adapter, so no tidy transformation logic is
# reimplemented here.
growkar_tidy_from_summarized_experiment <- function(data) {
  assay_names <- SummarizedExperiment::assayNames(data)
  if (length(assay_names) == 0L) {
    stop("`data` must contain at least one assay.", call. = FALSE)
  }

  assay_name <- if ("od" %in% assay_names) "od" else assay_names[[1]]

  # tidySummarizedExperiment registers the `as_tibble()` method that performs
  # the SE -> long transformation; loading its namespace makes that method
  # available for dispatch below.
  loadNamespace("tidySummarizedExperiment")

  # tidySummarizedExperiment internally calls purrr::when(), which is
  # lifecycle-deprecated upstream. Muffle only that specific upstream
  # deprecation so it does not surface on every conversion; all other
  # conditions propagate normally.
  tidy_data <- withCallingHandlers(
    tibble::as_tibble(data),
    warning = function(w) {
      if (grepl("when()", conditionMessage(w), fixed = TRUE)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  # `.feature` and `.sample` are the tidyomics row and column identifiers.
  time_values <- if ("time" %in% names(tidy_data)) {
    tidy_data$time
  } else {
    growkar_numeric_or_na(tidy_data$.feature)
  }

  if (anyNA(time_values)) {
    stop(
      "`SummarizedExperiment` input must provide numeric time values in ",
      "`rowData(data)$time` or row names.",
      call. = FALSE
    )
  }

  sample_values <- if ("sample" %in% names(tidy_data)) {
    as.character(tidy_data$sample)
  } else {
    as.character(tidy_data$.sample)
  }

  extra_cols <- setdiff(
    names(tidy_data),
    c(".feature", ".sample", "sample", "time", assay_names)
  )

  out <- tibble::tibble(
    time = as.numeric(time_values),
    sample = sample_values,
    od = as.numeric(tidy_data[[assay_name]])
  )

  for (column_name in extra_cols) {
    column <- tidy_data[[column_name]]
    out[[column_name]] <- if (is.factor(column)) as.character(column) else column
  }

  # tidyomics returns sample-major rows; growkar's import adapter returns
  # time-major rows. Reorder so both entry points agree.
  sample_levels <- colnames(data)
  if (is.null(sample_levels)) {
    sample_levels <- unique(out$sample)
  }

  out[order(out$time, match(out$sample, sample_levels)), , drop = FALSE]
}
