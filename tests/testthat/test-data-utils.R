test_that("as_tidy_growth_data converts wide data to canonical tidy format", {
  tidy_data <- as_tidy_growth_data(yeast_growth_data)

  expect_s3_class(tidy_data, "tbl_df")
  expect_true(all(c("sample", "time", "od") %in% names(tidy_data)))
  expect_true(all(c("condition", "replicate") %in% names(tidy_data)))
  expect_equal(
    nrow(tidy_data),
    (ncol(yeast_growth_data) - 1) * nrow(yeast_growth_data)
  )
})
