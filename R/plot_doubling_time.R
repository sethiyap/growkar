#' Plot Doubling Time Summary
#'
#' Plot replicate-based doubling-time summaries as a bar chart with error bars
#' and optional p-value annotations.
#'
#' @param data Growth curve data in tidy or wide format.
#' @param comparison_col Column used to group replicate-level doubling times.
#'   Typical values are `"condition"` or `"sample"`.
#' @param compare_to Optional reference group used for p-value comparisons.
#' @param select_replicates Optional character vector of replicate IDs to retain
#'   before computing doubling times.
#' @param method Estimation method passed to `summarize_growth_metrics()`.
#' @param error Statistic used for error bars. One of `"se"` or `"sd"`.
#' @param pvalue_method Statistical test used when `compare_to` is supplied.
#'   One of `"t_test"` or `"wilcox"`.
#' @param palette_name Name of the qualitative palette used by
#'   `select_palette()`.
#' @param custom_colors Optional character vector of colours. When supplied,
#'   these user-defined colours are used instead of the selected palette.
#' @param ... Additional arguments passed to `summarize_growth_metrics()`.
#'
#' @return A `ggplot2` object.
#'
#' @examples
#' data(yeast_growth_data)
#' plot_doubling_time(
#'   yeast_growth_data,
#'   comparison_col = "condition",
#'   compare_to = "Cg",
#'   palette_name = "Dark2"
#' )
#' @export
plot_doubling_time <- function(data,
                               comparison_col = NULL,
                               compare_to = NULL,
                               select_replicates = NULL,
                               method = c("rolling_window", "defined_interval", "rule_based"),
                               error = c("se", "sd"),
                               pvalue_method = c("t_test", "wilcox"),
                               palette_name = "all_colors",
                               custom_colors = NULL,
                               ...) {
  method <- match.arg(method)
  error <- match.arg(error)
  pvalue_method <- match.arg(pvalue_method)

  tidy_data <- as_tidy_growth_data(data)
  tidy_data <- validate_growth_data(tidy_data)

  if (is.null(comparison_col)) {
    comparison_col <- if ("condition" %in% names(tidy_data)) "condition" else "sample"
  }

  summary_tbl <- summarize_growth_metrics(
    data = tidy_data,
    method = method,
    select_replicates = select_replicates,
    average_replicates = FALSE,
    comparison_col = comparison_col,
    compare_to = compare_to,
    error = error,
    pvalue_method = pvalue_method,
    ...
  )

  if (!comparison_col %in% names(summary_tbl)) {
    stop("`comparison_col` must be present in the summarized output.", call. = FALSE)
  }

  y_max <- max(summary_tbl$mean_doubling_time + dplyr::coalesce(summary_tbl$error_bar, 0), na.rm = TRUE)
  offset <- if (is.finite(y_max)) max(y_max * 0.08, 0.05) else 0.05

  p <- ggplot2::ggplot(
    summary_tbl,
    ggplot2::aes(x = .data[[comparison_col]], y = .data$mean_doubling_time, fill = .data[[comparison_col]])
  ) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = pmax(.data$mean_doubling_time - dplyr::coalesce(.data$error_bar, 0), 0),
        ymax = .data$mean_doubling_time + dplyr::coalesce(.data$error_bar, 0)
      ),
      width = 0.2
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "none"
    ) +
    ggplot2::xlab(comparison_col) +
    ggplot2::ylab("Doubling time")

  if (!is.null(compare_to)) {
    p <- p + ggplot2::geom_text(
      ggplot2::aes(
        y = .data$mean_doubling_time + dplyr::coalesce(.data$error_bar, 0) + offset,
        label = .data$p_value_label
      ),
      na.rm = TRUE,
      vjust = 0
    )
  }

  fill_values <- if (!is.null(custom_colors)) {
    custom_colors
  } else {
    select_palette(length(unique(summary_tbl[[comparison_col]])), palette_name = palette_name)
  }

  p + ggplot2::scale_fill_manual(values = fill_values)
}
