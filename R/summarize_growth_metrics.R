#' Summarize Growth Metrics
#'
#' Compute growth rate and doubling time per sample.
#'
#' This is the convenience wrapper for obtaining both metrics across multiple
#' samples in one tidy table. Internally, doubling time is derived from the
#' estimated growth rate using `compute_doubling_time()`.
#'
#' @param data Growth curve data in tidy or wide format.
#' @param method Estimation method passed to `compute_growth_rate()`.
#' @param average_replicates Logical; if `TRUE`, average replicate trajectories
#'   before computing metrics. When `select_replicates` is `NULL`, all available
#'   replicates are averaged.
#' @param select_replicates Optional character vector of replicate IDs to retain
#'   before summarizing. When `NULL`, all replicates are retained.
#' @param comparison_col Optional column used to summarize replicate-level
#'   doubling times and compute group-wise statistics. Typical values are
#'   `"condition"` or `"sample"`.
#' @param compare_to Optional reference group in `comparison_col` used for
#'   doubling-time p-value comparisons.
#' @param error Statistic used for doubling-time error bars and summary output.
#'   One of `"se"` or `"sd"`.
#' @param pvalue_method Statistical test used when `compare_to` is supplied.
#'   One of `"t_test"` or `"wilcox"`.
#' @param p_adjust_method Multiple-testing adjustment applied to replicate-level
#'   p-values when `compare_to` is supplied. Defaults to `"BH"`. One of
#'   `"BH"`, `"none"`, `"bonferroni"`, `"holm"`, `"hochberg"`, `"hommel"`,
#'   `"BY"`, or `"fdr"`.
#' @param ... Additional arguments passed to `compute_growth_rate()`.
#'
#' @return A tidy tibble with one row per sample by default. When
#'   `comparison_col` is supplied, returns one row per comparison group with
#'   replicate-level doubling-time summary statistics and optional p-values.
#'
#' @examples
#' data(yeast_growth_data)
#' metrics <- summarize_growth_metrics(
#'   yeast_growth_data,
#'   method = "rolling_window",
#'   average_replicates = TRUE
#' )
#' head(metrics)
#' @export
summarize_growth_metrics <- function(data,
                                     method = c("rolling_window", "defined_interval", "rule_based"),
                                     average_replicates = FALSE,
                                     select_replicates = NULL,
                                     comparison_col = NULL,
                                     compare_to = NULL,
                                     error = c("se", "sd"),
                                     pvalue_method = c("t_test", "wilcox"),
                                     p_adjust_method = c("BH", "none", "bonferroni", "holm", "hochberg", "hommel", "BY", "fdr"),
                                     ...) {
  tidy_data <- as_tidy_growth_data(data)
  tidy_data <- validate_growth_data(tidy_data)
  error <- match.arg(error)
  pvalue_method <- match.arg(pvalue_method)
  p_adjust_method <- match.arg(p_adjust_method)

  if (!is.null(comparison_col)) {
    if (!comparison_col %in% names(tidy_data)) {
      stop("`comparison_col` must refer to a column in `data`.", call. = FALSE)
    }

    if (isTRUE(average_replicates)) {
      stop(
        "`average_replicates = TRUE` cannot be combined with `comparison_col` because replicate-level variation is required for doubling-time statistics.",
        call. = FALSE
      )
    }

    replicate_metrics <- compute_growth_rate(
      data = tidy_data,
      method = match.arg(method),
      select_replicates = select_replicates,
      average_replicates = FALSE,
      ...
    ) |>
      dplyr::mutate(doubling_time = compute_doubling_time(.data$mu))

    metadata <- tidy_data |>
      dplyr::distinct(.data$sample, .data[[comparison_col]])

    replicate_metrics <- dplyr::left_join(replicate_metrics, metadata, by = "sample")

    return(
      growkar_summarize_doubling_time_stats(
        replicate_metrics = replicate_metrics,
        comparison_col = comparison_col,
        compare_to = compare_to,
        error = error,
        pvalue_method = pvalue_method,
        p_adjust_method = p_adjust_method
      )
    )
  }

  metrics <- compute_growth_rate(
    data = tidy_data,
    method = match.arg(method),
    select_replicates = select_replicates,
    average_replicates = average_replicates,
    ...
  )

  dplyr::mutate(metrics, doubling_time = compute_doubling_time(.data$mu))
}

growkar_summarize_doubling_time_stats <- function(replicate_metrics,
                                                  comparison_col,
                                                  compare_to = NULL,
                                                  error = c("se", "sd"),
                                                  pvalue_method = c("t_test", "wilcox"),
                                                  p_adjust_method = c("BH", "none", "bonferroni", "holm", "hochberg", "hommel", "BY", "fdr")) {
  error <- match.arg(error)
  pvalue_method <- match.arg(pvalue_method)
  p_adjust_method <- match.arg(p_adjust_method)

  if (!is.null(compare_to) && !compare_to %in% replicate_metrics[[comparison_col]]) {
    stop("`compare_to` must match a value in `comparison_col`.", call. = FALSE)
  }

  summarized <- replicate_metrics |>
    dplyr::group_by(.data[[comparison_col]]) |>
    dplyr::summarise(
      mean_mu = mean(.data$mu, na.rm = TRUE),
      mean_doubling_time = mean(.data$doubling_time, na.rm = TRUE),
      sd_doubling_time = stats::sd(.data$doubling_time, na.rm = TRUE),
      n_replicates = sum(!is.na(.data$doubling_time)),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      error_bar = dplyr::if_else(
        .data$n_replicates > 1L,
        if (identical(error, "sd")) {
          .data$sd_doubling_time
        } else {
          .data$sd_doubling_time / sqrt(.data$n_replicates)
        },
        NA_real_
      )
    )

  pvalues <- growkar_compute_doubling_time_pvalues(
    replicate_metrics = replicate_metrics,
    comparison_col = comparison_col,
    compare_to = compare_to,
    pvalue_method = pvalue_method,
    p_adjust_method = p_adjust_method
  )

  dplyr::left_join(summarized, pvalues, by = comparison_col)
}

growkar_compute_doubling_time_pvalues <- function(replicate_metrics,
                                                  comparison_col,
                                                  compare_to = NULL,
                                                  pvalue_method = c("t_test", "wilcox"),
                                                  p_adjust_method = c("BH", "none", "bonferroni", "holm", "hochberg", "hommel", "BY", "fdr")) {
  pvalue_method <- match.arg(pvalue_method)
  p_adjust_method <- match.arg(p_adjust_method)
  groups <- unique(replicate_metrics[[comparison_col]])

  if (is.null(compare_to)) {
    out <- tibble::tibble(group = groups) |>
      dplyr::mutate(
        p_value = NA_real_,
        p_value_label = NA_character_
      )
    names(out)[names(out) == "group"] <- comparison_col
    return(out)
  }

  reference_values <- replicate_metrics |>
    dplyr::filter(.data[[comparison_col]] == compare_to) |>
    dplyr::pull("doubling_time")
  reference_values <- reference_values[is.finite(reference_values)]

  out <- purrr::map_dfr(groups, function(group_value) {
    if (identical(group_value, compare_to)) {
      return(tibble::tibble(
        group = group_value,
        p_value = NA_real_,
        p_value_adjusted = NA_real_,
        p_value_label = "ref"
      ))
    }

    group_values <- replicate_metrics |>
      dplyr::filter(.data[[comparison_col]] == group_value) |>
      dplyr::pull("doubling_time")
    group_values <- group_values[is.finite(group_values)]

    if (length(reference_values) < 2L || length(group_values) < 2L) {
      return(tibble::tibble(
        group = group_value,
        p_value = NA_real_,
        p_value_adjusted = NA_real_,
        p_value_label = NA_character_
      ))
    }

    test_result <- tryCatch(
      {
        if (identical(pvalue_method, "wilcox")) {
          stats::wilcox.test(group_values, reference_values)
        } else {
          stats::t.test(group_values, reference_values)
        }
      },
      error = function(e) NULL
    )

    p_value <- if (is.null(test_result)) NA_real_ else unname(test_result$p.value)
    tibble::tibble(
      group = group_value,
      p_value = p_value
    )
  })

  test_rows <- !is.na(out$p_value)
  out$p_value_adjusted <- NA_real_
  if (any(test_rows)) {
    out$p_value_adjusted[test_rows] <- stats::p.adjust(out$p_value[test_rows], method = p_adjust_method)
  }

  out$p_value_label <- purrr::map_chr(out$p_value_adjusted, growkar_pvalue_label)
  out$p_value_label[out$group %in% compare_to] <- "ref"

  names(out)[names(out) == "group"] <- comparison_col
  out
}

growkar_pvalue_label <- function(p_value) {
  if (is.na(p_value)) {
    return(NA_character_)
  }

  if (p_value <= 1e-04) {
    return("****")
  }
  if (p_value <= 1e-03) {
    return("***")
  }
  if (p_value <= 1e-02) {
    return("**")
  }
  if (p_value <= 5e-02) {
    return("*")
  }

  "ns"
}
