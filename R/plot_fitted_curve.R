#' Plot a Fitted Growth Curve
#'
#' Overlay observed points and fitted values from a parametric growth model.
#'
#' @param fit A `growkar_fit` object.
#'
#' @return A `ggplot2` object.
#' @export
plot_fitted_curve <- function(fit) {
  augmented <- augment_growth_fit(fit)

  ggplot2::ggplot(augmented, ggplot2::aes(x = .data$time)) +
    ggplot2::geom_point(ggplot2::aes(y = .data$od)) +
    ggplot2::geom_line(ggplot2::aes(y = .data$.fitted), linewidth = 0.8, colour = "#0072B2") +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank()) +
    ggplot2::xlab("Time") +
    ggplot2::ylab("OD")
}
