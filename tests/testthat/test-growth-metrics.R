test_that("detect_exponential_phase finds positive slope windows", {
  exp_data <- tibble::tibble(
    sample = "exp1",
    time = 0:7,
    od = 0.05 * exp(0.4 * (0:7))
  )

  windows <- detect_exponential_phase(exp_data, window_size = 4)

  expect_s3_class(windows, "tbl_df")
  expect_gt(nrow(windows), 0)
  expect_true("sample" %in% names(windows))
  expect_equal(unique(windows$sample), "exp1")
  expect_gt(windows$slope[[1]], 0)
})

test_that("compute_growth_rate supports rolling and rule-based methods", {
  tidy_data <- as_tidy_growth_data(yeast_growth_data)

  rolling <- suppressWarnings(compute_growth_rate(tidy_data, method = "rolling_window"))
  rule_based <- suppressWarnings(compute_growth_rate(tidy_data, method = "rule_based"))

  expect_true(all(c("sample", "mu", "start_time", "end_time", "r_squared", "method") %in% names(rolling)))
  expect_equal(sort(unique(rolling$sample)), sort(unique(tidy_data$sample)))
  expect_equal(unique(rule_based$method), "rule_based")
})

test_that("compute_growth_rate can filter selected replicates", {
  metrics <- suppressWarnings(compute_growth_rate(
    yeast_growth_data,
    method = "rule_based",
    select_replicates = c("R1", "R2")
  ))

  expect_equal(sort(metrics$sample), sort(c("Cg_R1", "Cg_R2", "CgFlu_R1", "CgFlu_R2", "YPD_R1", "YPD_R2")))
})

test_that("compute_growth_rate can average selected replicates", {
  metrics <- suppressWarnings(compute_growth_rate(
    yeast_growth_data,
    method = "rolling_window",
    select_replicates = c("R1", "R2"),
    average_replicates = TRUE
  ))

  expect_equal(sort(metrics$sample), sort(c("Cg", "CgFlu", "YPD")))
})

test_that("summarize_growth_metrics adds doubling time", {
  metrics <- suppressWarnings(summarize_growth_metrics(yeast_growth_data, method = "rule_based"))

  expect_true("doubling_time" %in% names(metrics))
  expect_equal(
    nrow(metrics),
    length(unique(as_tidy_growth_data(yeast_growth_data)$sample))
  )
})

test_that("summarize_growth_metrics can filter selected replicates", {
  metrics <- suppressWarnings(summarize_growth_metrics(
    yeast_growth_data,
    method = "rule_based",
    select_replicates = c("R1", "R2")
  ))

  expect_equal(sort(metrics$sample), sort(c("Cg_R1", "Cg_R2", "CgFlu_R1", "CgFlu_R2", "YPD_R1", "YPD_R2")))
})

test_that("summarize_growth_metrics can average selected replicates", {
  metrics <- suppressWarnings(summarize_growth_metrics(
    yeast_growth_data,
    method = "rolling_window",
    average_replicates = TRUE,
    select_replicates = c("R1", "R2")
  ))

  expect_equal(sort(metrics$sample), sort(c("Cg", "CgFlu", "YPD")))
  expect_true(all(c("mu", "doubling_time") %in% names(metrics)))
})

test_that("summarize_growth_metrics averages all replicates when requested", {
  metrics <- suppressWarnings(summarize_growth_metrics(
    yeast_growth_data,
    method = "rolling_window",
    average_replicates = TRUE
  ))

  expect_equal(sort(metrics$sample), sort(c("Cg", "CgFlu", "YPD")))
})

test_that("summarize_growth_metrics can compute doubling-time statistics by condition", {
  stats_tbl <- suppressWarnings(summarize_growth_metrics(
    yeast_growth_data,
    method = "rolling_window",
    comparison_col = "condition",
    compare_to = "Cg"
  ))

  expect_true(all(c(
    "condition",
    "mean_mu",
    "mean_doubling_time",
    "sd_doubling_time",
    "n_replicates",
    "error_bar",
    "p_value",
    "p_value_label"
  ) %in% names(stats_tbl)))
  expect_true("ref" %in% stats_tbl$p_value_label)
})

test_that("summarize_growth_metrics can restrict doubling-time statistics to selected replicates", {
  stats_tbl <- suppressWarnings(summarize_growth_metrics(
    yeast_growth_data,
    method = "rolling_window",
    comparison_col = "condition",
    compare_to = "Cg",
    select_replicates = c("R1", "R2")
  ))

  expect_true(all(stats_tbl$n_replicates <= 2))
})

test_that("summarize_growth_metrics errors when replicate statistics average replicates", {
  expect_error(
    summarize_growth_metrics(
      yeast_growth_data,
      comparison_col = "condition",
      average_replicates = TRUE
    ),
    "cannot be combined"
  )
})
