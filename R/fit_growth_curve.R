#' Fit a Parametric Growth Model
#'
#' Fit a logistic or Gompertz growth model to a single sample.
#'
#' @param data Tidy growth data for one sample.
#' @param model Model type: `"logistic"` or `"gompertz"`.
#'
#' @return An object of class `growkar_fit`.
#' @export
fit_growth_curve <- function(data, model = c("logistic", "gompertz")) {
  model <- match.arg(model)
  data <- as_tidy_growth_data(data)
  data <- validate_growth_data(data)

  if (dplyr::n_distinct(data$sample) != 1L) {
    stop("`fit_growth_curve()` requires data for exactly one sample.", call. = FALSE)
  }

  data <- dplyr::arrange(data, .data$time)
  sample_id <- unique(data$sample)
  starts <- growkar_starting_values(data)

  formula <- switch(
    model,
    logistic = od ~ K / (1 + exp(-r * (time - t0))),
    gompertz = od ~ K * exp(-exp(-r * (time - t0)))
  )

  lower <- c(K = max(max(data$od, na.rm = TRUE), .Machine$double.eps), r = 1e-8, t0 = min(data$time))
  fit <- tryCatch(
    stats::nls(
      formula = formula,
      data = data,
      start = starts,
      algorithm = "port",
      lower = lower,
      control = stats::nls.control(warnOnly = TRUE)
    ),
    error = function(e) e
  )

  success <- inherits(fit, "nls")
  coefficients <- if (success) stats::coef(fit) else c(K = NA_real_, r = NA_real_, t0 = NA_real_)
  fitted_values <- if (success) {
    tibble::tibble(time = data$time, .fitted = as.numeric(stats::fitted(fit)))
  } else {
    tibble::tibble(time = data$time, .fitted = NA_real_)
  }

  structure(
    list(
      model = model,
      fit = if (success) fit else NULL,
      coefficients = coefficients,
      fitted = fitted_values,
      data = data,
      converged = success,
      sample = sample_id,
      message = if (success) NULL else conditionMessage(fit)
    ),
    class = "growkar_fit"
  )
}

growkar_starting_values <- function(data) {
  K <- max(data$od, na.rm = TRUE)
  slope_estimates <- diff(log(pmax(data$od, .Machine$double.eps))) / diff(data$time)
  slope_estimates <- slope_estimates[is.finite(slope_estimates)]
  r <- if (length(slope_estimates) == 0L) 0.1 else max(0.05, median(slope_estimates[slope_estimates > 0], na.rm = TRUE))
  if (!is.finite(r)) {
    r <- 0.1
  }

  midpoint <- K / 2
  t0_index <- which.min(abs(data$od - midpoint))
  t0 <- data$time[[t0_index]]

  c(K = K, r = r, t0 = t0)
}
