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

# The coercion methods below are documented by the `GrowthExperiment-coerce`
# topic above; `setAs()` calls carry no object for roxygen2 to attach a block to.
methods::setAs("data.frame", "GrowthExperiment", function(from) {
  GrowthExperiment(from)
})

methods::setAs("matrix", "GrowthExperiment", function(from) {
  GrowthExperiment(as.data.frame(from))
})

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
