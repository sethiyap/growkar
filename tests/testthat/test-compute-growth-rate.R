test_that("compute_growth_rate handles irregular intervals", {
  irregular <- tibble::tibble(
    sample = "irr1",
    time = c(0, 0.5, 1.5, 3, 5),
    od = 0.08 * exp(0.4 * c(0, 0.5, 1.5, 3, 5))
  )

  result <- compute_growth_rate(irregular, method = "rolling_window", window_size = 4)

  expect_s3_class(result, "tbl_df")
  expect_false(is.na(result$mu[[1]]))
  expect_false(result$degraded[[1]])
})

test_that("compute_growth_rate returns NA with warning for flat curves", {
  flat <- tibble::tibble(
    sample = "flat1",
    time = 0:4,
    od = rep(0.2, 5)
  )

  expect_warning(
    result <- compute_growth_rate(flat, method = "rolling_window", window_size = 4),
    "positive growth slope"
  )

  expect_true(is.na(result$mu[[1]]))
  expect_true(result$degraded[[1]])
})

test_that("compute_growth_rate returns NA with warning for insufficient points", {
  sparse <- tibble::tibble(
    sample = c("a", "a"),
    time = c(0, 1),
    od = c(0.1, 0.2)
  )

  expect_warning(
    result <- compute_growth_rate(sparse, method = "rule_based"),
    "requires at least three positive observations"
  )

  expect_true(is.na(result$mu[[1]]))
  expect_equal(result$note[[1]], "insufficient_positive_points")
})

test_that("compute_growth_rate warns and returns NA when defined interval is unusable", {
  zero_heavy <- tibble::tibble(
    sample = "zero2",
    time = c(0, 1, 2, 3),
    od = c(0.01, 0.01, 0.03, 0.04)
  )

  expect_warning(
    result <- compute_growth_rate(
      zero_heavy,
      method = "defined_interval",
      interval = c(0, 1.5),
      min_od = 0.02
    ),
    "enough positive OD values"
  )

  expect_true(is.na(result$mu[[1]]))
  expect_true(result$degraded[[1]])
})

test_that("compute_growth_rate supports one defined interval for all samples", {
  tidy_data <- as_tidy_growth_data(yeast_growth_data) |>
    dplyr::filter(.data$condition %in% c("Cg", "CgFlu"))

  result <- compute_growth_rate(
    tidy_data,
    method = "defined_interval",
    interval = c(2, 6)
  )

  expect_s3_class(result, "tbl_df")
  expect_true(all(result$method == "defined_interval"))
  expect_true(all(result$start_time == 2))
  expect_true(all(result$end_time == 6))
})

test_that("compute_growth_rate supports per-sample interval tables", {
  tidy_data <- as_tidy_growth_data(yeast_growth_data)
  samples <- unique(tidy_data$sample)[1:2]

  interval_tbl <- tibble::tibble(
    sample = samples,
    start_time = c(2, 3),
    end_time = c(5, 6)
  )

  result <- compute_growth_rate(
    dplyr::filter(tidy_data, sample %in% samples),
    method = "defined_interval",
    interval = interval_tbl
  )

  expect_equal(result$start_time, c(2, 3))
  expect_equal(result$end_time, c(5, 6))
})
