#' growkar: High-Throughput Microbial Phenotyping from Growth Assays
#'
#' `growkar` uses a single Bioconductor data container, the S4 class
#' [GrowthExperiment-class] (an extension of
#' [SummarizedExperiment::SummarizedExperiment]), and a single model-result
#' class, [GrowthFit-class]. Tidy manipulation and display of these objects are
#' delegated to `tidySummarizedExperiment` rather than reimplemented, and
#' graphing is provided by optional `plot_*()` helpers.
#'
#' Scalar argument checks and optional-package checks are taken from
#' `BiocBaseUtils` rather than reimplemented.
#'
#' The import from `tidySummarizedExperiment` is deliberate: that package
#' registers the `as_tibble()` method used to convert a `GrowthExperiment` to
#' long form, and importing one of its exports loads its namespace (and hence
#' registers those methods) whenever `growkar` is loaded.
#'
#' @keywords internal
#' @import methods
#' @importFrom rlang .data
#' @importFrom tidySummarizedExperiment unnest_summarized_experiment
"_PACKAGE"
