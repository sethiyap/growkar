#' Plot Growth Curves
#'
#' Plot observed growth curves from growth data standardized internally to a
#' canonical `SummarizedExperiment`.
#'
#' @param data Growth curve data in tidy, wide, or `SummarizedExperiment`
#'   format.
#' @param average_replicates Logical; if `TRUE`, average replicate trajectories
#'   before plotting when a `replicate` column is available.
#' @param select_samples Optional character vector of sample IDs to retain
#'   before plotting. Use a length-one vector to plot a single sample.
#' @param colour_col Name of the column mapped to colour.
#' @param facet_col Optional name of a column used for faceting.
#' @param facet_by_sample Logical; if `TRUE`, facet by `sample`. When enabled,
#'   sample faceting takes precedence over `facet_col`, and replicate faceting
#'   is disabled.
#' @param palette_name Name of the qualitative palette used by
#'   `select_palette()`. Supported values include `"all_colors"` (combined
#'   palette), `"Accent"` (8), `"Dark2"` (8), `"Paired"` (12), `"Pastel1"` (9),
#'   `"Pastel2"` (8), `"Set1"` (9), `"Set2"` (8), and `"Set3"` (12).
#' @param custom_colors Optional character vector of colours. When supplied,
#'   these user-defined colours are used instead of the selected palette.
#'
#' @return A `ggplot2` object.
#'
#' @examples
#' data(yeast_growth_data)
#' plot_growth_curve(
#'   yeast_growth_data,
#'   average_replicates = TRUE,
#'   colour_col = "condition",
#'   palette_name = "Dark2"
#' )
#' @export
plot_growth_curve <- function(data,
                              average_replicates = FALSE,
                              select_samples = NULL,
                              colour_col = "sample",
                              facet_col = NULL,
                              facet_by_sample = FALSE,
                              palette_name = "all_colors",
                              custom_colors = NULL) {
  se <- growkar_as_se(data)
  tidy_data <- as_tidy_growth_data(se)
  tidy_data <- validate_growth_data(tidy_data)

  available_samples <- unique(as.character(tidy_data$sample))

  if (!is.null(select_samples)) {
    select_samples <- as.character(select_samples)
    missing_samples <- setdiff(select_samples, available_samples)
    if (length(missing_samples) > 0L) {
      stop(
        "`select_samples` contains sample(s) not present in `data`: ",
        paste(missing_samples, collapse = ", "),
        ". Available samples: ",
        paste(available_samples, collapse = ", "),
        call. = FALSE
      )
    }

    tidy_data <- dplyr::filter(tidy_data, .data$sample %in% select_samples)
  }

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

  if (isTRUE(facet_by_sample)) {
    if (identical(facet_col, "replicate")) {
      warning(
        "`facet_col = \"replicate\"` is ignored when `facet_by_sample = TRUE`.",
        call. = FALSE
      )
    }
    facet_col <- "sample"
  }

  plot_data <- if (isTRUE(average_replicates)) {
    growkar_average_replicates(tidy_data)
  } else {
    tidy_data
  }

  y_col <- if ("od_mean" %in% names(plot_data)) "od_mean" else "od"
  colour_levels <- growkar_plot_levels(plot_data[[colour_col]])
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
    growkar_named_colors(custom_colors, colour_levels)
  } else {
    select_palette(length(unique(plot_data[[colour_col]])), palette_name = palette_name)
  }

  p + ggplot2::scale_colour_manual(values = colour_values, breaks = colour_levels)
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

growkar_plot_levels <- function(x) {
  if (is.factor(x)) {
    return(levels(x)[levels(x) %in% as.character(unique(x))])
  }

  unique(as.character(x))
}

growkar_named_colors <- function(colors, levels) {
  if (is.null(names(colors))) {
    if (length(colors) < length(levels)) {
      return(colors)
    }

    stats::setNames(colors[seq_along(levels)], levels)
  } else {
    colors
  }
}
