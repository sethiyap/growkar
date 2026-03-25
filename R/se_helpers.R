#' Compute and Store Growth Metrics
#'
#' Compute growth metrics for tidy, wide, or `SummarizedExperiment` input. When
#' `data` is a `SummarizedExperiment`, the resulting metrics table is stored in
#' `metadata(data)$growth_metrics`, and the updated object is returned.
#'
#' @inheritParams summarize_growth_metrics
#' @param store_metadata Logical; when `TRUE` and `data` is a
#'   `SummarizedExperiment`, store the derived metrics and analysis parameters
#'   in `metadata()`.
#'
#' @return A tidy tibble for non-`SummarizedExperiment` input, or an updated
#'   `SummarizedExperiment` when `data` is a `SummarizedExperiment`.
#'
#' @examples
#' data(yeast_growth_data)
#' se <- as_summarized_experiment(yeast_growth_data)
#' se <- growth_metrics(se, method = "rolling_window", average_replicates = TRUE)
#' S4Vectors::metadata(se)$growth_metrics
#' @export
growth_metrics <- function(data,
                           method = c("rolling_window", "defined_interval", "rule_based"),
                           average_replicates = FALSE,
                           select_replicates = NULL,
                           comparison_col = NULL,
                           compare_to = NULL,
                           error = c("se", "sd"),
                           pvalue_method = c("t_test", "wilcox"),
                           store_metadata = TRUE,
                           ...) {
  metrics_tbl <- summarize_growth_metrics(
    data = data,
    method = match.arg(method),
    average_replicates = average_replicates,
    select_replicates = select_replicates,
    comparison_col = comparison_col,
    compare_to = compare_to,
    error = match.arg(error),
    pvalue_method = match.arg(pvalue_method),
    ...
  )

  if (!inherits(data, "SummarizedExperiment") || !isTRUE(store_metadata)) {
    return(metrics_tbl)
  }

  growkar_store_se_metadata(
    data,
    growth_metrics = metrics_tbl,
    growth_metrics_parameters = list(
      method = method,
      average_replicates = average_replicates,
      select_replicates = select_replicates,
      comparison_col = comparison_col,
      compare_to = compare_to,
      error = error,
      pvalue_method = pvalue_method,
      extra_args = list(...)
    )
  )
}

#' Compute and Store Exponential-Phase Windows
#'
#' Detect exponential-phase windows for tidy, wide, or `SummarizedExperiment`
#' input. When `data` is a `SummarizedExperiment`, the detected windows are
#' stored in `metadata(data)$exponential_phase_windows`, and the updated object
#' is returned.
#'
#' @inheritParams detect_exponential_phase
#' @param store_metadata Logical; when `TRUE` and `data` is a
#'   `SummarizedExperiment`, store the detected windows and analysis parameters
#'   in `metadata()`.
#'
#' @return A tibble for non-`SummarizedExperiment` input, or an updated
#'   `SummarizedExperiment` when `data` is a `SummarizedExperiment`.
#'
#' @examples
#' data(yeast_growth_data)
#' se <- as_summarized_experiment(yeast_growth_data)
#' se <- phase_windows(se, average_replicates = TRUE)
#' S4Vectors::metadata(se)$exponential_phase_windows
#' @export
phase_windows <- function(data,
                          window_size = 4L,
                          min_od = 0.02,
                          average_replicates = FALSE,
                          select_replicates = NULL,
                          store_metadata = TRUE) {
  windows_tbl <- detect_exponential_phase(
    data = data,
    window_size = window_size,
    min_od = min_od,
    average_replicates = average_replicates,
    select_replicates = select_replicates
  )

  if (!inherits(data, "SummarizedExperiment") || !isTRUE(store_metadata)) {
    return(windows_tbl)
  }

  growkar_store_se_metadata(
    data,
    exponential_phase_windows = windows_tbl,
    exponential_phase_parameters = list(
      window_size = window_size,
      min_od = min_od,
      average_replicates = average_replicates,
      select_replicates = select_replicates
    )
  )
}

#' Fit and Store Growth Models
#'
#' Fit logistic or Gompertz growth models for tidy, wide, or
#' `SummarizedExperiment` input. When `data` is a `SummarizedExperiment`, fitted
#' model objects and extracted parameter summaries are stored in `metadata()`,
#' and the updated object is returned.
#'
#' @param data Growth curve data in tidy, wide, or `SummarizedExperiment`
#'   format.
#' @param model Model type: `"logistic"` or `"gompertz"`.
#' @param store_metadata Logical; when `TRUE` and `data` is a
#'   `SummarizedExperiment`, store fitted models and parameter summaries in
#'   `metadata()`.
#'
#' @return A tibble with fitted models for non-`SummarizedExperiment` input, or
#'   an updated `SummarizedExperiment` when `data` is a `SummarizedExperiment`.
#'
#' @examples
#' data(yeast_growth_data)
#' se <- as_summarized_experiment(yeast_growth_data)
#' se <- fit_growth_models(se, model = "logistic")
#' S4Vectors::metadata(se)$growth_model_parameters
#' @export
fit_growth_models <- function(data,
                              model = c("logistic", "gompertz"),
                              store_metadata = TRUE) {
  model <- match.arg(model)
  fit_tbl <- fit_growth_plate(data = data, model = model)

  if (!inherits(data, "SummarizedExperiment") || !isTRUE(store_metadata)) {
    return(fit_tbl)
  }

  param_tbl <- purrr::map_dfr(fit_tbl$fit, extract_params)

  growkar_store_se_metadata(
    data,
    growth_model_fits = fit_tbl,
    growth_model_parameters = param_tbl,
    growth_model_settings = list(model = model)
  )
}

growkar_store_se_metadata <- function(data, ...) {
  meta <- S4Vectors::metadata(data)
  additions <- list(...)

  for (name in names(additions)) {
    meta[[name]] <- additions[[name]]
  }

  S4Vectors::metadata(data) <- meta
  data
}
