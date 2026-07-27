test_that("GrowthExperiment is an S4 extension of SummarizedExperiment", {
  ge <- GrowthExperiment(yeast_growth_data)

  expect_s4_class(ge, "GrowthExperiment")
  expect_true(is(ge, "SummarizedExperiment"))
  expect_true(isVirtualClass("GrowthExperiment") ||
    "SummarizedExperiment" %in% is(ge))
  expect_true(methods::validObject(ge))
})

test_that("as(x, 'GrowthExperiment') coercion works in both directions", {
  ge <- as(yeast_growth_data, "GrowthExperiment")
  expect_s4_class(ge, "GrowthExperiment")

  se <- as(ge, "SummarizedExperiment")
  expect_s4_class(se, "SummarizedExperiment")

  round_trip <- as(se, "GrowthExperiment")
  expect_s4_class(round_trip, "GrowthExperiment")
  expect_equal(
    SummarizedExperiment::assay(round_trip, "od"),
    SummarizedExperiment::assay(ge, "od")
  )
})

test_that("GrowthExperiment validity rejects objects without an od assay", {
  se <- SummarizedExperiment::SummarizedExperiment(
    assays = list(counts = matrix(1, 1, 1)),
    rowData = S4Vectors::DataFrame(time = 0)
  )

  expect_error(
    methods::new("GrowthExperiment", se),
    "must contain an assay named `od`"
  )
})

test_that("as_summarized_experiment() has been removed", {
  expect_false(exists("as_summarized_experiment", where = asNamespace("growkar"), inherits = FALSE))
})

test_that("GrowthExperiment creates a SummarizedExperiment with od assay", {
  se <- GrowthExperiment(yeast_growth_data)

  expect_s4_class(se, "SummarizedExperiment")
  expect_true("od" %in% SummarizedExperiment::assayNames(se))
  expect_equal(nrow(se), nrow(yeast_growth_data))
  expect_equal(ncol(se), ncol(yeast_growth_data) - 1L)
  expect_true(all(c("sample", "condition", "replicate") %in% names(SummarizedExperiment::colData(se))))
  expect_equal(SummarizedExperiment::rowData(se)$time, yeast_growth_data$Time)
  expect_true("growkar_schema" %in% names(S4Vectors::metadata(se)))
})

test_that("as_tidy_growth_data round-trips SummarizedExperiment input", {
  se <- GrowthExperiment(yeast_growth_data)

  tidy_from_se <- as_tidy_growth_data(se) |>
    dplyr::arrange(.data$sample, .data$time)
  tidy_direct <- as_tidy_growth_data(yeast_growth_data) |>
    dplyr::arrange(.data$sample, .data$time)

  expect_equal(tidy_from_se, tidy_direct)
})

test_that("GrowthExperiment attaches precomputed metrics to metadata", {
  metrics <- tibble::tibble(
    sample = c("Cg_R1", "Cg_R2"),
    doubling_time = c(1.1, 1.2)
  )
  se <- GrowthExperiment(yeast_growth_data, metrics = metrics)

  expect_s4_class(se, "SummarizedExperiment")
  expect_true("od" %in% SummarizedExperiment::assayNames(se))
  expect_true("growth_metrics" %in% names(S4Vectors::metadata(se)))
  expect_equal(S4Vectors::metadata(se)$growth_metrics, metrics)
  expect_true("growkar_schema" %in% names(S4Vectors::metadata(se)))
})

test_that("growth_metrics stores derived summaries in SummarizedExperiment metadata", {
  se <- GrowthExperiment(yeast_growth_data)
  se <- growth_metrics(se, method = "rolling_window", average_replicates = TRUE)

  expect_s4_class(se, "SummarizedExperiment")
  expect_true("growth_metrics" %in% names(S4Vectors::metadata(se)))
  expect_true("growth_metrics_parameters" %in% names(S4Vectors::metadata(se)))
  expect_s3_class(S4Vectors::metadata(se)$growth_metrics, "tbl_df")
})

test_that("phase_windows stores exponential-phase windows in SummarizedExperiment metadata", {
  se <- GrowthExperiment(yeast_growth_data)
  se <- suppressWarnings(phase_windows(se, average_replicates = TRUE))

  expect_s4_class(se, "SummarizedExperiment")
  expect_true("exponential_phase_windows" %in% names(S4Vectors::metadata(se)))
  expect_true("exponential_phase_parameters" %in% names(S4Vectors::metadata(se)))
  expect_s3_class(S4Vectors::metadata(se)$exponential_phase_windows, "tbl_df")
})

test_that("fit_growth_models stores fitted models and parameters in SummarizedExperiment metadata", {
  se <- GrowthExperiment(yeast_growth_data)
  se <- fit_growth_models(se, model = "logistic")

  expect_s4_class(se, "SummarizedExperiment")
  expect_true("growth_model_fits" %in% names(S4Vectors::metadata(se)))
  expect_true("growth_model_parameters" %in% names(S4Vectors::metadata(se)))
  expect_s3_class(S4Vectors::metadata(se)$growth_model_fits, "tbl_df")
  expect_s3_class(S4Vectors::metadata(se)$growth_model_parameters, "tbl_df")
})

test_that("plot_growth_curve accepts SummarizedExperiment input", {
  skip_if_no_graphics()
  se <- GrowthExperiment(yeast_growth_data)
  p <- plot_growth_curve(se, average_replicates = TRUE, colour_col = "condition")

  expect_s3_class(p, "ggplot")
})

test_that("plot_growth_curve_facets accepts SummarizedExperiment input", {
  skip_if_no_graphics()
  se <- GrowthExperiment(yeast_growth_data)
  p <- plot_growth_curve_facets(se)

  expect_s3_class(p, "ggplot")
})

test_that("accessor helpers expose canonical SummarizedExperiment components", {
  se <- GrowthExperiment(yeast_growth_data)
  se <- fit_growth_models(se, model = "logistic")

  expect_true(is.matrix(growth_assay(se)))
  expect_s3_class(timepoints(se), "tbl_df")
  expect_s3_class(sample_data(se), "tbl_df")
  expect_s3_class(growth_model_fits(se), "tbl_df")
})

test_that("growth metrics agree across wide, tidy, and SummarizedExperiment inputs", {
  tidy_data <- as_tidy_growth_data(yeast_growth_data)
  se <- GrowthExperiment(yeast_growth_data)

  from_wide <- summarize_growth_metrics(
    yeast_growth_data,
    method = "rolling_window",
    average_replicates = TRUE
  ) |>
    dplyr::arrange(.data$sample)

  from_tidy <- summarize_growth_metrics(
    tidy_data,
    method = "rolling_window",
    average_replicates = TRUE
  ) |>
    dplyr::arrange(.data$sample)

  from_se <- summarize_growth_metrics(
    se,
    method = "rolling_window",
    average_replicates = TRUE
  ) |>
    dplyr::arrange(.data$sample)

  expect_equal(from_wide, from_tidy)
  expect_equal(from_tidy, from_se)
})

test_that("GrowthExperiment rejects conflicting sample metadata", {
  bad_data <- tibble::tibble(
    sample = c("A", "A", "B", "B"),
    time = c(0, 1, 0, 1),
    od = c(0.1, 0.2, 0.1, 0.2),
    condition = c("ctrl", "treated", "ctrl", "ctrl")
  )

  expect_error(
    GrowthExperiment(bad_data),
    "Sample metadata must be unique per `sample`"
  )
})
