data("yeast_growth_data", package = "growkar", envir = environment())

# Graphing is optional in growkar: ggplot2 and RColorBrewer live in Suggests.
skip_if_no_graphics <- function() {
  testthat::skip_if_not_installed("ggplot2")
  testthat::skip_if_not_installed("RColorBrewer")
}
