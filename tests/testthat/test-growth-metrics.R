test_that("detect_exponential_phase finds positive slope windows", {
  exp_data <- tibble::tibble(
    sample = "exp1",
    time = 0:7,
    od = 0.05 * exp(0.4 * (0:7))
  )

  windows <- detect_exponential_phase(exp_data, window_size = 4)

  expect_s3_class(windows, "tbl_df")
  expect_gt(nrow(windows), 0)
  expect_gt(windows$slope[[1]], 0)
})

test_that("compute_growth_rate supports rolling and rule-based methods", {
  tidy_data <- as_tidy_growth_data(growkar::yeast_growth_data)

  rolling <- compute_growth_rate(tidy_data, method = "rolling_window")
  rule_based <- compute_growth_rate(tidy_data, method = "rule_based")

  expect_true(all(c("sample", "mu", "start_time", "end_time", "r_squared", "method") %in% names(rolling)))
  expect_equal(sort(unique(rolling$sample)), sort(unique(tidy_data$sample)))
  expect_equal(unique(rule_based$method), "rule_based")
})

test_that("summarize_growth_metrics adds doubling time", {
  metrics <- summarize_growth_metrics(growkar::yeast_growth_data, method = "rule_based")

  expect_true("doubling_time" %in% names(metrics))
  expect_equal(
    nrow(metrics),
    length(unique(as_tidy_growth_data(growkar::yeast_growth_data)$sample))
  )
})
