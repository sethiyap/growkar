#' Validate Canonical Growth Data
#'
#' Validate tidy growth data before downstream analysis.
#'
#' @param data A data frame containing at least `sample`, `time`, and `od`.
#' @param allow_negative_od Logical; if `FALSE`, negative optical density values
#'   are rejected.
#'
#' @return The validated tibble, invisibly identical in content to the input
#'   after coercion to tibble.
#' @export
validate_growth_data <- function(data, allow_negative_od = FALSE) {
  data <- tibble::as_tibble(data)
  required_cols <- c("sample", "time", "od")

  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0L) {
    stop(
      "Missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  if (!is.numeric(data$time)) {
    stop("`time` must be numeric.", call. = FALSE)
  }

  if (!is.numeric(data$od)) {
    stop("`od` must be numeric.", call. = FALSE)
  }

  if (anyNA(data$sample) || anyNA(data$time) || anyNA(data$od)) {
    stop("`sample`, `time`, and `od` must not contain missing values.", call. = FALSE)
  }

  if (!allow_negative_od && any(data$od < 0, na.rm = TRUE)) {
    stop("Negative `od` values are not allowed by default.", call. = FALSE)
  }

  if (anyDuplicated(data[c("sample", "time")]) > 0L) {
    stop("Duplicate `sample`-`time` rows are not allowed.", call. = FALSE)
  }

  data
}
