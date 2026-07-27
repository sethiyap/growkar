#' Extract Fitted Growth Parameters
#'
#' Extract fitted coefficients and model-derived quantities, such as the
#' asymptote and the model-based doubling time, from a [GrowthFit-class]
#' object.
#'
#' @param fit A [GrowthFit-class] object returned by [fit_growth_curve()].
#' @param ... Arguments passed to methods.
#'
#' @return A tibble with one row containing `sample`, `model`, `asymptote`,
#'   `r`, `t0`, and `doubling_time_model`.
#'
#' @examples
#' data(yeast_growth_data)
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' fit <- fit_growth_curve(dplyr::filter(tidy_growth, sample == sample_id))
#' extract_params(fit)
#' @export
methods::setGeneric(
  "extract_params",
  function(fit, ...) standardGeneric("extract_params")
)

#' Augment Observed Data with Fitted Values
#'
#' Return the observed data used for fitting together with the fitted values
#' from a [GrowthFit-class] object.
#'
#' @param fit A [GrowthFit-class] object returned by [fit_growth_curve()].
#' @param ... Arguments passed to methods.
#'
#' @return A tidy tibble containing the observed columns plus `.fitted`.
#'
#' @examples
#' data(yeast_growth_data)
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' fit <- fit_growth_curve(dplyr::filter(tidy_growth, sample == sample_id))
#' head(augment_growth_fit(fit))
#' @export
methods::setGeneric(
  "augment_growth_fit",
  function(fit, ...) standardGeneric("augment_growth_fit")
)

#' Accessors for `GrowthFit` Objects
#'
#' Extract individual components of a [GrowthFit-class] object. These
#' accessors are the supported interface; slots should not be accessed
#' directly with `@`.
#'
#' @param x A [GrowthFit-class] object.
#' @param ... Arguments passed to methods.
#'
#' @return
#' * `fit_sample()`: a character scalar naming the fitted sample.
#' * `fit_model()`: a character scalar naming the fitted model.
#' * `fit_status()`: a character scalar describing the fit outcome.
#' * `fit_converged()`: a logical scalar.
#' * `fit_data()`: a tibble of the observed data used for fitting.
#'
#' @examples
#' data(yeast_growth_data)
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' fit <- fit_growth_curve(dplyr::filter(tidy_growth, sample == sample_id))
#'
#' fit_sample(fit)
#' fit_model(fit)
#' fit_status(fit)
#' fit_converged(fit)
#' head(fit_data(fit))
#' @name GrowthFit-accessors
NULL

#' @rdname GrowthFit-accessors
#' @export
methods::setGeneric("fit_sample", function(x, ...) standardGeneric("fit_sample"))

#' @rdname GrowthFit-accessors
#' @export
methods::setGeneric("fit_model", function(x, ...) standardGeneric("fit_model"))

#' @rdname GrowthFit-accessors
#' @export
methods::setGeneric("fit_status", function(x, ...) standardGeneric("fit_status"))

#' @rdname GrowthFit-accessors
#' @export
methods::setGeneric("fit_converged", function(x, ...) standardGeneric("fit_converged"))

#' @rdname GrowthFit-accessors
#' @export
methods::setGeneric("fit_data", function(x, ...) standardGeneric("fit_data"))
