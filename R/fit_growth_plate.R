#' Fit Growth Models Across a Plate
#'
#' Split tidy growth data by sample and fit a parametric model to each sample.
#'
#' @param data Growth curve data in tidy, wide, or `SummarizedExperiment`
#'   format.
#' @param model Model type: `"logistic"` or `"gompertz"`.
#'
#' @return A tibble with `sample` and a list-column of `growkar_fit` objects.
#'
#' @examples
#' data(yeast_growth_data)
#' fits <- fit_growth_plate(yeast_growth_data, model = "logistic")
#' fits
#' @export
fit_growth_plate <- function(data, model = c("logistic", "gompertz")) {
  model <- match.arg(model)
  se <- growkar_as_se(data)
  data <- as_tidy_growth_data(se)
  data <- validate_growth_data(data)

  sample_levels <- unique(as.character(data$sample))
  samples <- split(data, factor(data$sample, levels = sample_levels))
  tibble::tibble(
    sample = names(samples),
    fit = unname(purrr::map(samples, fit_growth_curve, model = model))
  )
}
