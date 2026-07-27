#' @importFrom stats coef fitted residuals nobs
NULL

new_growth_fit <- function(sample,
                           model,
                           fit = NULL,
                           coefficients = c(K = NA_real_, r = NA_real_, t0 = NA_real_),
                           fitted = data.frame(time = numeric(0), .fitted = numeric(0)),
                           residuals = numeric(0),
                           rss = NA_real_,
                           aic = NA_real_,
                           bic = NA_real_,
                           data = data.frame(),
                           converged = FALSE,
                           status = NA_character_,
                           message = NA_character_,
                           n_points = 0L,
                           starting_values = c(K = NA_real_, r = NA_real_, t0 = NA_real_),
                           bounds = c(K = NA_real_, r = NA_real_, t0 = NA_real_)) {
  methods::new(
    "GrowthFit",
    sample = as.character(sample),
    model = as.character(model),
    fit = fit,
    coefficients = coefficients,
    fitted = as.data.frame(fitted),
    residuals = as.numeric(residuals),
    rss = as.numeric(rss),
    aic = as.numeric(aic),
    bic = as.numeric(bic),
    data = as.data.frame(data),
    converged = as.logical(converged),
    status = as.character(status),
    message = if (is.null(message)) NA_character_ else as.character(message),
    n_points = as.integer(n_points),
    starting_values = starting_values,
    bounds = bounds
  )
}

#' Display a `GrowthFit` Object
#'
#' Compact one-line summary of a fitted growth model.
#'
#' @param object A [GrowthFit-class] object.
#'
#' @return `object`, invisibly. Called for its side effect of printing.
#'
#' @examples
#' data(yeast_growth_data)
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' fit <- fit_growth_curve(dplyr::filter(tidy_growth, sample == sample_id))
#' fit
#' @rdname show-methods
#' @export
methods::setMethod("show", "GrowthFit", function(object) {
  cat(
    "<GrowthFit> sample=", object@sample,
    ", model=", object@model,
    ", status=", object@status,
    ", n_points=", object@n_points,
    "\n",
    sep = ""
  )
  invisible(object)
})

#' Summarize a `GrowthFit` Object
#'
#' Tabular summary of fit status and goodness-of-fit statistics.
#'
#' @param object A [GrowthFit-class] object.
#' @param ... Unused, present for generic compatibility.
#'
#' @return A one-row tibble with `sample`, `model`, `converged`, `status`,
#'   `message`, `n_points`, `rss`, `aic`, and `bic`.
#'
#' @examples
#' data(yeast_growth_data)
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' fit <- fit_growth_curve(dplyr::filter(tidy_growth, sample == sample_id))
#' summary(fit)
#' @rdname summary-methods
#' @export
methods::setMethod("summary", "GrowthFit", function(object, ...) {
  tibble::tibble(
    sample = object@sample,
    model = object@model,
    converged = object@converged,
    status = object@status,
    message = object@message,
    n_points = object@n_points,
    rss = object@rss,
    aic = object@aic,
    bic = object@bic
  )
})

#' Model Components of a `GrowthFit` Object
#'
#' Methods for the standard modelling generics [stats::coef()],
#' [stats::fitted()], [stats::residuals()], and [stats::nobs()].
#'
#' @param object A [GrowthFit-class] object.
#' @param ... Unused, present for generic compatibility.
#'
#' @return
#' * `coef()`: a named numeric vector of fitted coefficients.
#' * `fitted()`: a numeric vector of fitted optical densities.
#' * `residuals()`: a numeric vector of observed minus fitted values.
#' * `nobs()`: an integer count of observations used for fitting.
#'
#' @examples
#' data(yeast_growth_data)
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' fit <- fit_growth_curve(dplyr::filter(tidy_growth, sample == sample_id))
#'
#' coef(fit)
#' head(fitted(fit))
#' head(residuals(fit))
#' nobs(fit)
#' @name GrowthFit-model-methods
NULL

#' @rdname GrowthFit-model-methods
#' @export
methods::setMethod("coef", "GrowthFit", function(object, ...) object@coefficients)

#' @rdname GrowthFit-model-methods
#' @export
methods::setMethod("fitted", "GrowthFit", function(object, ...) object@fitted$.fitted)

#' @rdname GrowthFit-model-methods
#' @export
methods::setMethod("residuals", "GrowthFit", function(object, ...) object@residuals)

#' @rdname GrowthFit-model-methods
#' @export
methods::setMethod("nobs", "GrowthFit", function(object, ...) object@n_points)

#' @rdname GrowthFit-accessors
#' @export
methods::setMethod("fit_sample", "GrowthFit", function(x, ...) x@sample)

#' @rdname GrowthFit-accessors
#' @export
methods::setMethod("fit_model", "GrowthFit", function(x, ...) x@model)

#' @rdname GrowthFit-accessors
#' @export
methods::setMethod("fit_status", "GrowthFit", function(x, ...) x@status)

#' @rdname GrowthFit-accessors
#' @export
methods::setMethod("fit_converged", "GrowthFit", function(x, ...) x@converged)

#' @rdname GrowthFit-accessors
#' @export
methods::setMethod("fit_data", "GrowthFit", function(x, ...) tibble::as_tibble(x@data))

#' @rdname extract_params
#' @export
methods::setMethod("extract_params", "GrowthFit", function(fit, ...) {
  coefficients <- fit@coefficients

  tibble::tibble(
    sample = fit@sample,
    model = fit@model,
    asymptote = unname(coefficients[["K"]]),
    r = unname(coefficients[["r"]]),
    t0 = unname(coefficients[["t0"]]),
    doubling_time_model = compute_doubling_time(unname(coefficients[["r"]]))
  )
})

#' @rdname augment_growth_fit
#' @export
methods::setMethod("augment_growth_fit", "GrowthFit", function(fit, ...) {
  dplyr::left_join(
    tibble::as_tibble(fit@data),
    tibble::as_tibble(fit@fitted),
    by = "time"
  )
})
