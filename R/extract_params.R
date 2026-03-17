#' Extract Fitted Parameters
#'
#' Extract coefficients and derived doubling time from a `growkar_fit` object.
#'
#' @param fit A `growkar_fit` object returned by `fit_growth_curve()`.
#'
#' @return A tibble of fitted parameters.
#'
#' @examples
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' fit <- fit_growth_curve(dplyr::filter(tidy_growth, sample == sample_id))
#' extract_params(fit)
#' @export
extract_params <- function(fit) {
  if (!inherits(fit, "growkar_fit")) {
    stop("`fit` must inherit from class `growkar_fit`.", call. = FALSE)
  }

  tibble::tibble(
    sample = fit$sample,
    model = fit$model,
    asymptote = unname(fit$coefficients[["K"]]),
    r = unname(fit$coefficients[["r"]]),
    t0 = unname(fit$coefficients[["t0"]]),
    doubling_time_model = compute_doubling_time(unname(fit$coefficients[["r"]]))
  )
}
