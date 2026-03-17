test_that("detect_exponential_phase returns ranked windows with metadata", {
  exp_data <- tibble::tibble(
    sample = "exp1",
    time = c(0, 0.7, 1.4, 2.8, 4.0, 5.3),
    od = 0.05 * exp(0.35 * c(0, 0.7, 1.4, 2.8, 4.0, 5.3))
  )

  windows <- detect_exponential_phase(exp_data, window_size = 4)

  expect_s3_class(windows, "tbl_df")
  expect_true(all(c("sample", "rank", "n_points", "selection_reason", "degraded") %in% names(windows)))
  expect_equal(unique(windows$sample), "exp1")
  expect_equal(windows$rank[[1]], 1L)
})

test_that("detect_exponential_phase degrades gracefully for sparse curves", {
  sparse_data <- tibble::tibble(
    sample = "sparse1",
    time = c(0, 2, 5),
    od = c(0.1, 0.2, 0.4)
  )

  windows <- detect_exponential_phase(sparse_data, window_size = 5)

  expect_equal(windows$selection_reason[[1]], "window_size_reduced")
  expect_true(isTRUE(windows$degraded[[1]]))
})

test_that("detect_exponential_phase returns fallback row when no positive OD remains", {
  zero_heavy <- tibble::tibble(
    sample = "zero1",
    time = c(0, 1, 2),
    od = c(0, 0, 0.01)
  )

  windows <- suppressWarnings(detect_exponential_phase(zero_heavy, min_od = 0.02))

  expect_true(all(is.na(windows$slope)))
  expect_equal(windows$selection_reason[[1]], "insufficient_positive_points")
})
