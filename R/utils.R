#' Require an Optional Package
#'
#' `growkar` keeps its data-structure and analysis layers free of graphics
#' dependencies. Graphing packages are declared in `Suggests` and checked at
#' call time by the `plot_*()` functions, so the infrastructure layer installs
#' and runs without a graphics stack.
#'
#' @param package Name of the suggested package.
#' @param whom Name of the calling function, used in the error message.
#'
#' @return `TRUE`, invisibly, if `package` is available; otherwise an error is
#'   thrown.
#'
#' @keywords internal
#' @noRd
growkar_require_suggested <- function(package, whom) {
  if (requireNamespace(package, quietly = TRUE)) {
    return(invisible(TRUE))
  }

  stop(
    "`", whom, "()` requires the suggested package `", package, "`.\n",
    "Install it with: install.packages(\"", package, "\")",
    call. = FALSE
  )
}

growkar_require_graphics <- function(whom) {
  growkar_require_suggested("ggplot2", whom)
  growkar_require_suggested("RColorBrewer", whom)
}

#' Coerce to Numeric, Treating Uncoercible Values as Missing
#'
#' Plate-reader exports routinely interleave non-numeric rows (instrument
#' headers, blank cells, `"OVRFLW"` markers) with numeric measurements.
#' `as.numeric()` signals a "NAs introduced by coercion" warning for these,
#' which is expected rather than exceptional: the caller inspects the resulting
#' `NA`s and either drops those rows with a count-reporting warning of its own
#' or raises a specific error.
#'
#' This helper makes that intent explicit. Rather than wrapping call sites in
#' `suppressWarnings()`, it catches only the coercion warning by class and lets
#' any other condition propagate, so genuine problems are never masked.
#'
#' @param x A vector to coerce.
#'
#' @return A numeric vector the same length as `x`, with `NA` for elements that
#'   could not be coerced.
#'
#' @keywords internal
#' @noRd
growkar_numeric_or_na <- function(x) {
  if (is.numeric(x)) {
    return(as.numeric(x))
  }

  withCallingHandlers(
    as.numeric(x),
    warning = function(w) {
      if (grepl("NAs introduced by coercion", conditionMessage(w), fixed = TRUE)) {
        invokeRestart("muffleWarning")
      }
    }
  )
}
