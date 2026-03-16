#' Augment Observed Data with Fitted Values
#'
#' Return observed data together with fitted values from a `growkar_fit` object.
#'
#' @param fit A `growkar_fit` object.
#'
#' @return A tidy tibble containing observed and fitted values.
#' @export
augment_growth_fit <- function(fit) {
  if (!inherits(fit, "growkar_fit")) {
    stop("`fit` must inherit from class `growkar_fit`.", call. = FALSE)
  }

  dplyr::left_join(fit$data, fit$fitted, by = "time")
}
