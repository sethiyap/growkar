#' Require the Optional Graphics Package
#'
#' `growkar` keeps its data-structure and analysis layers free of graphics
#' dependencies. `ggplot2` is declared in `Suggests` and checked at call time by
#' the `plot_*()` functions with [BiocBaseUtils::checkInstalled()], so the
#' infrastructure layer installs and runs without a graphics stack. Palettes
#' come from [grDevices::palette.colors()] in base R, so no colour package is
#' needed.
#'
#' @return `NULL`, invisibly, when `ggplot2` is installed. Otherwise
#'   `checkInstalled()` raises an error naming the missing package and the
#'   command that installs it.
#'
#' @keywords internal
#' @noRd
growkar_require_graphics <- function() {
  BiocBaseUtils::checkInstalled("ggplot2")
}
