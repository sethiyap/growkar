#' growkar: High-Throughput Microbial Phenotyping from Growth Assays
#'
#' `growkar` uses a single Bioconductor data container, the S4 class
#' [GrowthExperiment-class] (an extension of
#' [SummarizedExperiment::SummarizedExperiment]), and a single model-result
#' class, [GrowthFit-class]. Tidy manipulation and display of these objects are
#' delegated to `tidySummarizedExperiment` rather than reimplemented, and
#' graphing is provided by optional `plot_*()` helpers.
#'
#' @keywords internal
#' @import methods
#' @importFrom rlang .data
"_PACKAGE"
