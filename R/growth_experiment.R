#' Growth Assay Matrix
#'
#' Access the canonical OD assay from a `SummarizedExperiment`.
#'
#' @param x A `SummarizedExperiment` compatible with `growkar`.
#'
#' @return A numeric matrix with time points in rows and samples in columns.
#'
#' @examples
#' data(yeast_growth_data)
#' se <- as_summarized_experiment(yeast_growth_data)
#' growth_assay(se)
#' @export
growth_assay <- function(x) {
  se <- growkar_as_se(x)
  SummarizedExperiment::assay(se, "od")
}

#' Timepoint Metadata
#'
#' Access timepoint metadata from a `SummarizedExperiment`.
#'
#' @param x A `SummarizedExperiment` compatible with `growkar`.
#'
#' @return A tibble containing `rowData(x)`.
#'
#' @examples
#' data(yeast_growth_data)
#' se <- as_summarized_experiment(yeast_growth_data)
#' timepoints(se)
#' @export
timepoints <- function(x) {
  se <- growkar_as_se(x)
  tibble::as_tibble(as.data.frame(SummarizedExperiment::rowData(se)))
}

#' Sample Metadata
#'
#' Access sample-level metadata from a `SummarizedExperiment`.
#'
#' @param x A `SummarizedExperiment` compatible with `growkar`.
#'
#' @return A tibble containing `colData(x)`.
#'
#' @examples
#' data(yeast_growth_data)
#' se <- as_summarized_experiment(yeast_growth_data)
#' sample_data(se)
#' @export
sample_data <- function(x) {
  se <- growkar_as_se(x)
  tibble::as_tibble(as.data.frame(SummarizedExperiment::colData(se)))
}

#' Stored Growth Model Fits
#'
#' Retrieve fitted growth model objects stored in `metadata()`.
#'
#' @param x A `SummarizedExperiment` compatible with `growkar`.
#'
#' @return A tibble of stored model fits, or `NULL` if no fits have been stored.
#'
#' @examples
#' data(yeast_growth_data)
#' se <- as_summarized_experiment(yeast_growth_data)
#' se <- fit_growth_models(se, model = "logistic")
#' growth_model_fits(se)
#' @export
growth_model_fits <- function(x) {
  se <- growkar_as_se(x)
  meta <- S4Vectors::metadata(se)
  if ("model_fits" %in% names(meta)) {
    meta$model_fits
  } else {
    meta$growth_model_fits
  }
}

growkar_as_se <- function(data) {
  if (inherits(data, "SummarizedExperiment")) {
    return(validate_growth_experiment(growkar_normalize_se(data)))
  }

  validate_growth_experiment(as_summarized_experiment(data))
}

growkar_normalize_se <- function(se) {
  assay_names <- SummarizedExperiment::assayNames(se)

  if (!"od" %in% assay_names) {
    if (length(assay_names) == 0L) {
      stop("`SummarizedExperiment` input must contain at least one assay.", call. = FALSE)
    }

    se <- SummarizedExperiment::SummarizedExperiment(
      assays = list(od = SummarizedExperiment::assay(se, assay_names[[1]])),
      rowData = SummarizedExperiment::rowData(se),
      colData = SummarizedExperiment::colData(se),
      metadata = S4Vectors::metadata(se)
    )
  }

  time_df <- as.data.frame(SummarizedExperiment::rowData(se))
  if (!"time" %in% names(time_df)) {
    time_values <- suppressWarnings(as.numeric(rownames(SummarizedExperiment::assay(se, "od"))))
    if (anyNA(time_values)) {
      stop(
        "`SummarizedExperiment` input must provide numeric time values in `rowData(se)$time` or assay row names.",
        call. = FALSE
      )
    }

    SummarizedExperiment::rowData(se)$time <- time_values
  }

  meta <- S4Vectors::metadata(se)
  meta$growkar_schema <- list(
    assay = "od",
    rows = "timepoints",
    columns = "samples"
  )
  S4Vectors::metadata(se) <- meta

  se
}

#' Validate a Growth `SummarizedExperiment`
#'
#' Check that a `SummarizedExperiment` follows the canonical `growkar` layout.
#'
#' @param x A `SummarizedExperiment`.
#' @param require_finite Logical; if `TRUE`, reject non-finite assay values and
#'   time values.
#'
#' @return The validated `SummarizedExperiment`.
#'
#' @examples
#' data(yeast_growth_data)
#' se <- as_summarized_experiment(yeast_growth_data)
#' validate_growth_experiment(se)
#' @export
validate_growth_experiment <- function(x, require_finite = TRUE) {
  if (!inherits(x, "SummarizedExperiment")) {
    stop("`x` must be a `SummarizedExperiment`.", call. = FALSE)
  }

  assay_names <- SummarizedExperiment::assayNames(x)
  if (!"od" %in% assay_names) {
    stop("`x` must contain an assay named `od`.", call. = FALSE)
  }

  od <- SummarizedExperiment::assay(x, "od")
  time_values <- SummarizedExperiment::rowData(x)$time

  if (!is.numeric(time_values)) {
    stop("`rowData(x)$time` must be numeric.", call. = FALSE)
  }

  if (isTRUE(require_finite) && any(!is.finite(time_values))) {
    stop("`rowData(x)$time` must contain only finite numeric values.", call. = FALSE)
  }

  if (!is.numeric(od)) {
    stop("`assay(x, \"od\")` must be numeric.", call. = FALSE)
  }

  if (nrow(od) != length(time_values)) {
    stop("`assay(x, \"od\")` rows must match the length of `rowData(x)$time`.", call. = FALSE)
  }

  if (isTRUE(require_finite) && any(!is.finite(od))) {
    stop("`assay(x, \"od\")` must contain only finite numeric values.", call. = FALSE)
  }

  x
}
