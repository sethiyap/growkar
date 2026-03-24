#' Create a `growkar_data` Object
#'
#' Wrap tidy growth data and optional derived metrics in a lightweight
#' `growkar_data` object. This makes it easy to preserve a processed tidy
#' representation while supporting coercion into Bioconductor containers such as
#' `SummarizedExperiment`.
#'
#' @param data Growth curve data in tidy or wide format.
#' @param metrics Optional tibble of sample-level metrics to attach as object
#'   metadata.
#' @param sample_col Name of the sample column for long-form input.
#' @param time_col Name of the time column.
#' @param od_col Name of the optical density column.
#' @param sample_sep Separator used to infer metadata columns from sample names.
#'
#' @return A list with class `growkar_data` containing `processed_data`,
#'   `sample_info`, and `metrics`.
#'
#' @examples
#' data(yeast_growth_data)
#' growkar_obj <- as_growkar(yeast_growth_data)
#' methods::as(growkar_obj, "SummarizedExperiment")
#' @export
as_growkar <- function(data,
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

  structure(
    list(
      processed_data = tidy_data,
      sample_info = growkar_sample_metadata(tidy_data),
      metrics = if (is.null(metrics)) tibble::tibble() else tibble::as_tibble(metrics)
    ),
    class = "growkar_data"
  )
}

methods::setOldClass(c("growkar_data", "list"))

methods::setAs(
  "growkar_data",
  "SummarizedExperiment",
  function(from) {
    growkar_build_summarized_experiment(
      tidy_data = from$processed_data,
      metadata = list(growth_metrics = from$metrics)
    )
  }
)
