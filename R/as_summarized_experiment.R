#' Build the Canonical `SummarizedExperiment` Growth Container
#'
#' Convert tidy or wide growth curve data into the canonical
#' `SummarizedExperiment::SummarizedExperiment` used internally by `growkar`,
#' with an `od` assay.
#'
#' The resulting object stores time points in `rowData(se)$time`, sample-level
#' metadata in `colData(se)`, and optical density measurements in
#' `assay(se, "od")`.
#'
#' @param data Growth curve data in tidy or wide format.
#' @param sample_col Name of the sample column for long-form input.
#' @param time_col Name of the time column.
#' @param od_col Name of the optical density column.
#' @param sample_sep Separator used to infer metadata columns from sample names.
#'
#' @return A `SummarizedExperiment` object with one assay named `od`.
#'
#' @examples
#' data(yeast_growth_data)
#' se <- as_summarized_experiment(yeast_growth_data)
#' se
#'
#' growkar_obj <- as_growkar(yeast_growth_data)
#' methods::as(growkar_obj, "SummarizedExperiment")
#' @export
as_summarized_experiment <- function(data,
                                     sample_col = "sample",
                                     time_col = "time",
                                     od_col = "od",
                                     sample_sep = "_") {
  tidy_data <- as_tidy_growth_data(
    data = data,
    sample_col = sample_col,
    time_col = time_col,
    od_col = od_col,
    sample_sep = sample_sep
  )
  tidy_data <- validate_growth_data(tidy_data)

  growkar_build_summarized_experiment(tidy_data)
}

growkar_build_summarized_experiment <- function(tidy_data, metadata = list()) {
  sample_metadata <- growkar_sample_metadata(tidy_data)
  timepoints <- sort(unique(tidy_data$time))
  samples <- sample_metadata$sample

  assay_tbl <- tidy_data |>
    dplyr::select("sample", "time", "od") |>
    tidyr::pivot_wider(
      names_from = "sample",
      values_from = "od"
    ) |>
    dplyr::arrange(.data$time)

  assay_mat <- assay_tbl |>
    dplyr::select(-"time") |>
    as.matrix()

  storage.mode(assay_mat) <- "double"
  colnames(assay_mat) <- names(assay_tbl)[names(assay_tbl) != "time"]
  rownames(assay_mat) <- as.character(assay_tbl$time)
  assay_mat <- assay_mat[, samples, drop = FALSE]

  row_data <- S4Vectors::DataFrame(time = timepoints, row.names = as.character(timepoints))
  col_data <- S4Vectors::DataFrame(sample_metadata, row.names = sample_metadata$sample)

  schema_meta <- list(
    growkar_schema = list(
      assay = "od",
      rows = "timepoints",
      columns = "samples"
    )
  )

  SummarizedExperiment::SummarizedExperiment(
    assays = list(od = assay_mat),
    rowData = row_data,
    colData = col_data,
    metadata = utils::modifyList(schema_meta, metadata)
  )
}

growkar_sample_metadata <- function(data) {
  meta_cols <- setdiff(names(data), c("sample", "time", "od"))
  metadata <- data |>
    dplyr::select(dplyr::all_of(c("sample", meta_cols))) |>
    dplyr::distinct()

  duplicated_samples <- metadata$sample[duplicated(metadata$sample)]
  if (length(duplicated_samples) > 0L) {
    stop(
      "Sample metadata must be unique per `sample`. Conflicting metadata found for: ",
      paste(utils::head(unique(duplicated_samples), 5L), collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  metadata |>
    dplyr::arrange(.data$sample)
}

growkar_tidy_from_summarized_experiment <- function(data) {
  assay_names <- SummarizedExperiment::assayNames(data)
  assay_name <- if ("od" %in% assay_names) "od" else assay_names[[1]]

  if (is.null(assay_name) || length(assay_name) == 0L) {
    stop("`data` must contain at least one assay.", call. = FALSE)
  }

  assay_mat <- SummarizedExperiment::assay(data, assay_name)
  time_df <- as.data.frame(SummarizedExperiment::rowData(data))
  col_df <- as.data.frame(SummarizedExperiment::colData(data))

  if ("time" %in% names(time_df)) {
    time_values <- time_df$time
  } else {
    time_values <- rownames(assay_mat)
  }

  time_values <- suppressWarnings(as.numeric(time_values))
  if (anyNA(time_values)) {
    stop("`SummarizedExperiment` input must provide numeric time values in `rowData(data)$time` or row names.", call. = FALSE)
  }

  tidy_data <- tibble::as_tibble(assay_mat, .name_repair = "minimal") |>
    dplyr::mutate(time = time_values, .before = 1) |>
    tidyr::pivot_longer(
      cols = -"time",
      names_to = "sample",
      values_to = "od"
    )

  if (nrow(col_df) > 0L) {
    col_df$sample <- if ("sample" %in% names(col_df)) {
      as.character(col_df$sample)
    } else {
      colnames(assay_mat)
    }

    tidy_data <- dplyr::left_join(
      tidy_data,
      tibble::as_tibble(col_df),
      by = "sample"
    )
  }

  tibble::as_tibble(tidy_data)
}
