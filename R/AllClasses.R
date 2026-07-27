#' @import methods
#' @importClassesFrom SummarizedExperiment SummarizedExperiment
NULL

#' Growth Assay Experiment
#'
#' `GrowthExperiment` is the data container used throughout `growkar`. It is an
#' S4 class that directly extends
#' [SummarizedExperiment::SummarizedExperiment], adding a validity method that
#' enforces the canonical growth-assay layout:
#'
#' * an assay named `od` holding optical density measurements, with timepoints
#'   in rows and samples in columns;
#' * a numeric `time` column in `rowData()`;
#' * sample annotations in `colData()`;
#' * derived results (growth metrics, exponential-phase windows, model fits) in
#'   `metadata()`.
#'
#' Because the class extends `SummarizedExperiment`, every method written for
#' `SummarizedExperiment` — including subsetting, `assay()`, `rowData()`,
#' `colData()`, `metadata()`, and the tidyomics verbs provided by
#' `tidySummarizedExperiment` — applies unchanged, and
#' `as(x, "SummarizedExperiment")` is always available for handing objects to
#' other Bioconductor packages.
#'
#' Construct objects with [GrowthExperiment()], or coerce with
#' `as(x, "GrowthExperiment")` from a `data.frame`, `tibble`, `matrix`, or
#' existing `SummarizedExperiment`.
#'
#' @return A `GrowthExperiment` object.
#'
#' @seealso [GrowthExperiment()], [validate_growth_experiment()]
#'
#' @examples
#' data(yeast_growth_data)
#'
#' ge <- GrowthExperiment(yeast_growth_data)
#' ge
#'
#' # Standard coercion in both directions.
#' se <- as(ge, "SummarizedExperiment")
#' identical(ge, as(se, "GrowthExperiment"))
#'
#' # Inherited SummarizedExperiment methods apply unchanged.
#' SummarizedExperiment::assayNames(ge)
#' dim(ge[, 1:3])
#' @export
methods::setClass("GrowthExperiment", contains = "SummarizedExperiment")

methods::setValidity("GrowthExperiment", function(object) {
  problems <- character()

  if (!"od" %in% SummarizedExperiment::assayNames(object)) {
    return("`GrowthExperiment` must contain an assay named `od`.")
  }

  od <- SummarizedExperiment::assay(object, "od")
  time_values <- SummarizedExperiment::rowData(object)$time

  if (is.null(time_values) || !is.numeric(time_values)) {
    problems <- c(problems, "`rowData(object)$time` must be present and numeric.")
  } else if (nrow(od) != length(time_values)) {
    problems <- c(
      problems,
      "`assay(object, \"od\")` must have one row per value of `rowData(object)$time`."
    )
  }

  if (!is.numeric(od)) {
    problems <- c(problems, "`assay(object, \"od\")` must be numeric.")
  }

  if (length(problems) == 0L) TRUE else problems
})

methods::setOldClass("nls")
methods::setOldClass(c("tbl_df", "tbl", "data.frame"))
# readr returns spec_tbl_df; register its hierarchy so the data.frame coercion
# method to GrowthExperiment is inherited for reader-produced tibbles too.
methods::setOldClass(c("spec_tbl_df", "tbl_df", "tbl", "data.frame"))

#' @rdname GrowthFit-class
#' @name nlsOrNULL-class
#' @keywords internal
methods::setClassUnion("nlsOrNULL", c("nls", "NULL"))

#' Parametric Growth Model Fit
#'
#' A formal S4 representation of a parametric growth model fitted to a single
#' sample by [fit_growth_curve()]. `growkar` uses
#' [SummarizedExperiment::SummarizedExperiment] as its only data container; the
#' `GrowthFit` class represents a *model result*, not assay data, and is stored
#' in `metadata()` alongside the experiment it was derived from.
#'
#' Fits that fail are returned as valid `GrowthFit` objects with
#' `converged = FALSE` and a `status` slot describing the failure, so that
#' plate-wide fitting never aborts on a single problematic sample.
#'
#' @slot sample Character scalar identifying the fitted sample.
#' @slot model Character scalar naming the model, `"logistic"` or
#'   `"gompertz"`.
#' @slot fit The underlying [stats::nls()] object, or `NULL` when the fit
#'   failed.
#' @slot coefficients Named numeric vector of fitted coefficients `K`, `r`,
#'   and `t0`.
#' @slot fitted A `data.frame` with columns `time` and `.fitted`.
#' @slot residuals Numeric vector of observed minus fitted values.
#' @slot rss Residual sum of squares.
#' @slot aic Akaike information criterion.
#' @slot bic Bayesian information criterion.
#' @slot data A `data.frame` of the observed data used for fitting.
#' @slot converged Logical scalar indicating whether the fit converged.
#' @slot status Character scalar describing the fit outcome, one of
#'   `"converged"`, `"insufficient_points"`, `"flat_curve"`, or
#'   `"fit_failed"`.
#' @slot message Character scalar with a diagnostic message, or `NA` when the
#'   fit converged.
#' @slot n_points Integer number of observations used for fitting.
#' @slot starting_values Named numeric vector of starting values.
#' @slot bounds Named numeric vector of lower bounds.
#'
#' @return An object of class `GrowthFit`.
#'
#' @seealso [fit_growth_curve()], [extract_params()],
#'   [augment_growth_fit()]
#'
#' @examples
#' data(yeast_growth_data)
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' fit <- fit_growth_curve(dplyr::filter(tidy_growth, sample == sample_id))
#' fit
#' isVirtualClass("GrowthFit")
#' @export
methods::setClass(
  "GrowthFit",
  slots = c(
    sample = "character",
    model = "character",
    fit = "nlsOrNULL",
    coefficients = "numeric",
    fitted = "data.frame",
    residuals = "numeric",
    rss = "numeric",
    aic = "numeric",
    bic = "numeric",
    data = "data.frame",
    converged = "logical",
    status = "character",
    message = "character",
    n_points = "integer",
    starting_values = "numeric",
    bounds = "numeric"
  ),
  prototype = methods::prototype(
    sample = NA_character_,
    model = NA_character_,
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
    bounds = c(K = NA_real_, r = NA_real_, t0 = NA_real_)
  )
)

methods::setValidity("GrowthFit", function(object) {
  problems <- character()

  scalar_slots <- c(
    "sample", "model", "rss", "aic", "bic",
    "converged", "status", "message", "n_points"
  )
  for (slot_name in scalar_slots) {
    if (length(methods::slot(object, slot_name)) != 1L) {
      problems <- c(problems, paste0("`", slot_name, "` must be a length-one vector."))
    }
  }

  if (!all(c("K", "r", "t0") %in% names(object@coefficients))) {
    problems <- c(problems, "`coefficients` must be named with `K`, `r`, and `t0`.")
  }

  if (!all(c("time", ".fitted") %in% names(object@fitted))) {
    problems <- c(problems, "`fitted` must contain columns `time` and `.fitted`.")
  }

  if (nrow(object@fitted) != length(object@residuals)) {
    problems <- c(problems, "`fitted` and `residuals` must have the same length.")
  }

  if (!is.na(object@n_points) && object@n_points < 0L) {
    problems <- c(problems, "`n_points` must be non-negative.")
  }

  if (length(problems) == 0L) TRUE else problems
})
