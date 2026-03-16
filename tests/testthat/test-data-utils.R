test_that("as_tidy_growth_data converts wide data to canonical tidy format", {
  tidy_data <- as_tidy_growth_data(growkar::yeast_growth_data)

  expect_s3_class(tidy_data, "tbl_df")
  expect_true(all(c("sample", "time", "od") %in% names(tidy_data)))
  expect_true(all(c("condition", "replicate") %in% names(tidy_data)))
  expect_equal(
    nrow(tidy_data),
    (ncol(growkar::yeast_growth_data) - 1) * nrow(growkar::yeast_growth_data)
  )
})

test_that("validate_growth_data rejects duplicate sample-time rows", {
  bad_data <- tibble::tibble(
    sample = c("a", "a"),
    time = c(0, 0),
    od = c(0.1, 0.2)
  )

  expect_error(validate_growth_data(bad_data), "Duplicate")
})

test_that("validate_growth_data rejects negative od by default", {
  bad_data <- tibble::tibble(
    sample = c("a", "a"),
    time = c(0, 1),
    od = c(0.1, -0.2)
  )

  expect_error(validate_growth_data(bad_data), "Negative")
})
