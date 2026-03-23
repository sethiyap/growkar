test_that("as_summarized_experiment creates a SummarizedExperiment with od assay", {
  se <- as_summarized_experiment(yeast_growth_data)

  expect_s4_class(se, "SummarizedExperiment")
  expect_true("od" %in% SummarizedExperiment::assayNames(se))
  expect_equal(nrow(se), nrow(yeast_growth_data))
  expect_equal(ncol(se), ncol(yeast_growth_data) - 1L)
  expect_true(all(c("sample", "condition", "replicate") %in% names(SummarizedExperiment::colData(se))))
  expect_equal(SummarizedExperiment::rowData(se)$time, yeast_growth_data$Time)
})

test_that("as_tidy_growth_data round-trips SummarizedExperiment input", {
  se <- as_summarized_experiment(yeast_growth_data)

  tidy_from_se <- as_tidy_growth_data(se) |>
    dplyr::arrange(.data$sample, .data$time)
  tidy_direct <- as_tidy_growth_data(yeast_growth_data) |>
    dplyr::arrange(.data$sample, .data$time)

  expect_equal(tidy_from_se, tidy_direct)
})

test_that("as_summarized_experiment rejects conflicting sample metadata", {
  bad_data <- tibble::tibble(
    sample = c("A", "A", "B", "B"),
    time = c(0, 1, 0, 1),
    od = c(0.1, 0.2, 0.1, 0.2),
    condition = c("ctrl", "treated", "ctrl", "ctrl")
  )

  expect_error(
    as_summarized_experiment(bad_data),
    "Sample metadata must be unique per `sample`"
  )
})
