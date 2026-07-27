#' Fit a Parametric Growth Model
#'
#' Fit a logistic or Gompertz growth model to a single sample.
#'
#' @param data Growth curve data for one sample in tidy, wide, or
#'   `SummarizedExperiment` format.
#' @param model Model type: `"logistic"` or `"gompertz"`.
#'
#' @return A [GrowthFit-class] object. Failed fits return the same class with
#'   `converged = FALSE` and a `status` slot describing the failure, so that
#'   plate-wide fitting is not aborted by a single problematic sample.
#'
#' @examples
#' data(yeast_growth_data)
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' fit <- fit_growth_curve(
#'   dplyr::filter(tidy_growth, sample == sample_id),
#'   model = "logistic"
#' )
#' fit
#' @export
fit_growth_curve <- function(data, model = c("logistic", "gompertz")) {
  model <- match.arg(model)
  se <- growkar_as_se(data)
  data <- as_tidy_growth_data(se)
  data <- validate_growth_data(data, min_points_per_sample = 2L)

  if (dplyr::n_distinct(data$sample) != 1L) {
    stop("`fit_growth_curve()` requires data for exactly one sample.", call. = FALSE)
  }

  data <- dplyr::arrange(data, .data$time)
  sample_id <- unique(data$sample)
  n_points <- nrow(data)

  if (n_points < 4L) {
    return(growkar_failed_fit(
      data = data,
      model = model,
      sample_id = sample_id,
      status = "insufficient_points",
      message = "At least four observations are recommended for model fitting."
    ))
  }

  if (all(abs(data$od - data$od[[1]]) < sqrt(.Machine$double.eps))) {
    return(growkar_failed_fit(
      data = data,
      model = model,
      sample_id = sample_id,
      status = "flat_curve",
      message = "Model fitting requires variation in `od`."
    ))
  }

  starts <- growkar_starting_values(data)

  formula <- switch(
    model,
    logistic = od ~ K / (1 + exp(-r * (time - t0))),
    gompertz = od ~ K * exp(-exp(-r * (time - t0)))
  )

  lower <- c(K = max(max(data$od, na.rm = TRUE), .Machine$double.eps), r = 1e-8, t0 = min(data$time))

  # `nls()` emits warnings for the numerically difficult curves this package is
  # designed to tolerate (near-singular gradients, step-halving). With
  # `warnOnly = TRUE` it still returns a usable object in those cases, so we
  # capture the warning text and carry it in the fit's `message` field instead
  # of discarding it, and reserve `tryCatch(error =)` for genuine failures.
  fit_state <- new.env(parent = emptyenv())
  fit_state$warning <- NULL
  fit <- tryCatch(
    withCallingHandlers(
      stats::nls(
        formula = formula,
        data = data,
        start = starts,
        algorithm = "port",
        lower = lower,
        control = stats::nls.control(warnOnly = TRUE)
      ),
      warning = function(w) {
        fit_state$warning <- conditionMessage(w)
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )

  if (!inherits(fit, "nls")) {
    return(growkar_failed_fit(
      data = data,
      model = model,
      sample_id = sample_id,
      status = "fit_failed",
      message = conditionMessage(fit),
      starting_values = starts,
      bounds = lower
    ))
  }

  fitted_values <- tibble::tibble(time = data$time, .fitted = as.numeric(stats::fitted(fit)))
  residuals <- data$od - fitted_values$.fitted
  rss <- sum(residuals^2, na.rm = TRUE)

  # AIC/BIC are undefined for some degenerate converged fits; NA is the
  # documented result rather than an error condition to propagate.
  info_criterion <- function(stat) {
    tryCatch(stat(fit), error = function(e) NA_real_)
  }

  new_growth_fit(
    sample = sample_id,
    model = model,
    fit = fit,
    coefficients = stats::coef(fit),
    fitted = fitted_values,
    residuals = residuals,
    rss = rss,
    aic = info_criterion(stats::AIC),
    bic = info_criterion(stats::BIC),
    data = data,
    converged = TRUE,
    status = "converged",
    message = if (is.null(fit_state$warning)) NA_character_ else fit_state$warning,
    n_points = n_points,
    starting_values = starts,
    bounds = lower
  )
}

growkar_starting_values <- function(data) {
  K <- max(data$od, na.rm = TRUE)
  slope_estimates <- diff(log(pmax(data$od, .Machine$double.eps))) / diff(data$time)
  slope_estimates <- slope_estimates[is.finite(slope_estimates)]
  r <- if (length(slope_estimates) == 0L) 0.1 else max(0.05, stats::median(slope_estimates[slope_estimates > 0], na.rm = TRUE))
  if (!is.finite(r)) {
    r <- 0.1
  }

  midpoint <- K / 2
  t0_index <- which.min(abs(data$od - midpoint))
  t0 <- data$time[[t0_index]]

  c(K = K, r = r, t0 = t0)
}

growkar_failed_fit <- function(data,
                               model,
                               sample_id,
                               status,
                               message,
                               starting_values = c(K = NA_real_, r = NA_real_, t0 = NA_real_),
                               bounds = c(K = NA_real_, r = NA_real_, t0 = NA_real_)) {
  fitted_values <- tibble::tibble(time = data$time, .fitted = NA_real_)

  new_growth_fit(
    sample = sample_id,
    model = model,
    fit = NULL,
    coefficients = c(K = NA_real_, r = NA_real_, t0 = NA_real_),
    fitted = fitted_values,
    residuals = rep(NA_real_, nrow(data)),
    rss = NA_real_,
    aic = NA_real_,
    bic = NA_real_,
    data = data,
    converged = FALSE,
    status = status,
    message = message,
    n_points = nrow(data),
    starting_values = starting_values,
    bounds = bounds
  )
}
