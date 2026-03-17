#' @export
#' @keywords internal
print.growkar_fit <- function(x, ...) {
  line <- paste0(
    "<growkar_fit> sample=", x$sample,
    ", model=", x$model_name,
    ", status=", x$status,
    ", n_points=", x$n_points
  )
  writeLines(line)
  invisible(x)
}

#' @export
#' @keywords internal
summary.growkar_fit <- function(object, ...) {
  tibble::tibble(
    sample = object$sample,
    model = object$model_name,
    converged = object$converged,
    status = object$status,
    message = if (is.null(object$message)) NA_character_ else object$message,
    n_points = object$n_points,
    rss = object$rss,
    aic = object$aic,
    bic = object$bic
  )
}
