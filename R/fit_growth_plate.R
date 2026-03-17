#' Fit Growth Models Across a Plate
#'
#' Split tidy growth data by sample and fit a parametric model to each sample.
#'
#' @param data Growth curve data in tidy or wide format.
#' @param model Model type: `"logistic"` or `"gompertz"`.
#'
#' @return A tibble with `sample` and a list-column of `growkar_fit` objects.
#'
#' @examples
#' fits <- fit_growth_plate(yeast_growth_data, model = "logistic")
#' fits
#' @export
fit_growth_plate <- function(data, model = c("logistic", "gompertz")) {
  model <- match.arg(model)
  data <- as_tidy_growth_data(data)
  data <- validate_growth_data(data)

  samples <- split(data, data$sample)
  tibble::tibble(
    sample = names(samples),
    fit = unname(purrr::map(samples, fit_growth_curve, model = model))
  )
}
