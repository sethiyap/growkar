#' Plot Growth Curves
#'
#' Plot observed growth curves from tidy or wide input data.
#'
#' @param data Growth curve data in tidy or wide format.
#' @param average_replicates Logical; if `TRUE`, average replicate trajectories
#'   before plotting when a `replicate` column is available.
#' @param colour_col Name of the column mapped to colour.
#' @param facet_col Optional name of a column used for faceting.
#' @param palette_name Name of the qualitative palette used by
#'   `select_palette()`. Supported values include `"all_colors"` (combined
#'   palette), `"Accent"` (8), `"Dark2"` (8), `"Paired"` (12), `"Pastel1"` (9),
#'   `"Pastel2"` (8), `"Set1"` (9), `"Set2"` (8), and `"Set3"` (12).
#' @param custom_colors Optional character vector of colours. When supplied,
#'   these user-defined colours are used instead of the selected palette.
#'
#' @return A `ggplot2` object.
#' @export
plot_growth_curve <- function(data,
                              average_replicates = FALSE,
                              colour_col = "sample",
                              facet_col = NULL,
                              palette_name = "all_colors",
                              custom_colors = NULL) {
  tidy_data <- as_tidy_growth_data(data)
  tidy_data <- validate_growth_data(tidy_data)

  if (!colour_col %in% names(tidy_data)) {
    stop("`colour_col` must refer to a column in `data`.", call. = FALSE)
  }

  if (!is.null(facet_col) && !facet_col %in% names(tidy_data)) {
    stop("`facet_col` must refer to a column in `data`.", call. = FALSE)
  }

  if (isTRUE(average_replicates) && identical(facet_col, "replicate")) {
    warning(
      "`facet_col = \"replicate\"` is ignored when `average_replicates = TRUE` because replicates are averaged before plotting.",
      call. = FALSE
    )
    facet_col <- NULL
  }

  plot_data <- if (isTRUE(average_replicates)) {
    growkar_average_replicates(tidy_data)
  } else {
    tidy_data
  }

  y_col <- if ("od_mean" %in% names(plot_data)) "od_mean" else "od"
  p <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = .data$time, y = .data[[y_col]], colour = .data[[colour_col]])
  ) +
    ggplot2::geom_point() +
    ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.title = ggplot2::element_blank()
    ) +
    ggplot2::xlab("Time") +
    ggplot2::ylab(if (y_col == "od_mean") "Mean OD" else "OD")

  if ("od_sd" %in% names(plot_data)) {
    p <- p + ggplot2::geom_errorbar(
      ggplot2::aes(ymin = .data$od_mean - .data$od_sd, ymax = .data$od_mean + .data$od_sd),
      width = 0.15
    )
  }

  if (!is.null(facet_col)) {
    p <- p + ggplot2::facet_wrap(stats::as.formula(paste("~", facet_col)))
  }

  colour_values <- if (!is.null(custom_colors)) {
    custom_colors
  } else {
    select_palette(length(unique(plot_data[[colour_col]])), palette_name = palette_name)
  }

  p + ggplot2::scale_colour_manual(values = colour_values)
}

growkar_average_replicates <- function(data) {
  group_cols <- unique(c(
    "time",
    if ("condition" %in% names(data)) "condition",
    setdiff(names(data), c("sample", "time", "od", "replicate"))
  ))

  if (length(setdiff(group_cols, "time")) == 0L) {
    return(data)
  }

  averaged <- data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) |>
    dplyr::summarise(
      od_mean = mean(.data$od, na.rm = TRUE),
      od_sd = stats::sd(.data$od, na.rm = TRUE),
      n = dplyr::n(),
      .groups = "drop"
    )

  if (!"sample" %in% names(averaged)) {
    if ("condition" %in% names(averaged)) {
      averaged$sample <- averaged$condition
    } else {
      averaged$sample <- "average"
    }
  }

  averaged
}
