#' Plot a Fitted Growth Curve
#'
#' Overlay observed points and fitted values from a parametric growth model.
#'
#' @param fit A `growkar_fit` object, or growth curve data in tidy or wide
#'   format.
#' @param model Model type used when `fit` is raw data rather than a
#'   `growkar_fit` object.
#' @param select_replicates Optional character vector of replicate IDs to retain
#'   before fitting. When `NULL`, all replicates are retained.
#' @param average_replicates Logical; if `TRUE`, average replicate trajectories
#'   before fitting and plotting.
#' @param colour_col Name of the column mapped to colour when plotting from raw
#'   data.
#' @param facet_col Optional name of a column used for faceting when plotting
#'   from raw data.
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
#' tidy_growth <- as_tidy_growth_data(yeast_growth_data)
#' sample_id <- unique(tidy_growth$sample)[1]
#' fit <- fit_growth_curve(dplyr::filter(tidy_growth, sample == sample_id))
#' plot_fitted_curve(fit)
#' @export
plot_fitted_curve <- function(fit,
                              model = c("logistic", "gompertz"),
                              select_replicates = NULL,
                              average_replicates = FALSE,
                              colour_col = "sample",
                              facet_col = NULL,
                              palette_name = "all_colors",
                              custom_colors = NULL) {
  if (inherits(fit, "growkar_fit")) {
    augmented <- augment_growth_fit(fit)
    fit_colour <- if (!is.null(custom_colors)) {
      custom_colors[[1]]
    } else {
      select_palette(1, palette_name = palette_name)[[1]]
    }

    return(
      ggplot2::ggplot(augmented, ggplot2::aes(x = .data$time)) +
        ggplot2::geom_point(ggplot2::aes(y = .data$od), colour = fit_colour) +
        ggplot2::geom_line(ggplot2::aes(y = .data$.fitted), linewidth = 0.8, colour = fit_colour) +
        ggplot2::theme_bw() +
        ggplot2::theme(panel.grid.minor = ggplot2::element_blank()) +
        ggplot2::xlab("Time") +
        ggplot2::ylab("OD")
    )
  }

  model <- match.arg(model)
  data <- as_tidy_growth_data(fit)
  data <- validate_growth_data(data)

  if (!is.null(select_replicates)) {
    if (!"replicate" %in% names(data)) {
      stop(
        "`select_replicates` requires a `replicate` column or sample names that encode replicates.",
        call. = FALSE
      )
    }

    data <- dplyr::filter(data, .data$replicate %in% select_replicates)
    if (nrow(data) == 0L) {
      stop("No rows remain after filtering `select_replicates`.", call. = FALSE)
    }
  }

  if (isTRUE(average_replicates)) {
    data <- growkar_average_replicates(data) |>
      dplyr::mutate(od = .data$od_mean) |>
      dplyr::select(-dplyr::any_of(c("od_mean", "od_sd", "n")))
    data <- validate_growth_data(data)
  }

  if (isTRUE(average_replicates) && identical(facet_col, "replicate")) {
    warning(
      "`facet_col = \"replicate\"` is ignored when `average_replicates = TRUE` because replicates are averaged before fitting and plotting.",
      call. = FALSE
    )
    facet_col <- NULL
  }

  if (!colour_col %in% names(data)) {
    stop("`colour_col` must refer to a column in the plotting data.", call. = FALSE)
  }

  if (!is.null(facet_col) && !facet_col %in% names(data)) {
    stop("`facet_col` must refer to a column in the plotting data.", call. = FALSE)
  }

  fits <- fit_growth_plate(data, model = model)
  augmented <- purrr::map_dfr(fits$fit, augment_growth_fit)

  p <- ggplot2::ggplot(
    augmented,
    ggplot2::aes(x = .data$time, colour = .data[[colour_col]])
  ) +
    ggplot2::geom_point(ggplot2::aes(y = .data$od)) +
    ggplot2::geom_line(ggplot2::aes(y = .data$.fitted), linewidth = 0.8) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), legend.title = ggplot2::element_blank()) +
    ggplot2::xlab("Time") +
    ggplot2::ylab("OD")

  if (!is.null(facet_col)) {
    p <- p + ggplot2::facet_wrap(stats::as.formula(paste("~", facet_col)))
  }

  colour_values <- if (!is.null(custom_colors)) {
    custom_colors
  } else {
    select_palette(length(unique(augmented[[colour_col]])), palette_name = palette_name)
  }

  p + ggplot2::scale_colour_manual(values = colour_values)
}
