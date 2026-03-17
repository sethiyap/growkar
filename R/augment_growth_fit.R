#' Augment Observed Data with Fitted Values
#'
#' Return observed data together with fitted values from a `growkar_fit` object.
#'
#' @param fit A `growkar_fit` object.
#'
#' @return A tidy tibble containing observed and fitted values.
#'
#' @examples
#' data(yeast_growth_data)
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' fit <- fit_growth_curve(dplyr::filter(tidy_growth, sample == sample_id))
#' head(augment_growth_fit(fit))
#' @export
augment_growth_fit <- function(fit) {
  if (!inherits(fit, "growkar_fit")) {
    stop("`fit` must inherit from class `growkar_fit`.", call. = FALSE)
  }

  dplyr::left_join(fit$data, fit$fitted, by = "time")
}
