#' @keywords internal
print.growkar_fit <- function(x, ...) {
  status <- if (isTRUE(x$converged)) "converged" else "failed"
  cat("<growkar_fit>", x$sample, "-", x$model, "model", "(", status, ")\n")
  invisible(x)
}
