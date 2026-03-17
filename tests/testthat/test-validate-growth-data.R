test_that("valid tidy data passes validation", {
  tidy_data <- as_tidy_growth_data(growkar::yeast_growth_data)

  expect_s3_class(validate_growth_data(tidy_data), "tbl_df")
})

test_that("missing required column fails validation", {
  bad_data <- tibble::tibble(sample = "a", time = 0)

  expect_error(validate_growth_data(bad_data), "Missing required columns")
})

test_that("duplicate sample-time rows fail validation", {
  bad_data <- tibble::tibble(
    sample = c("a", "a"),
    time = c(0, 0),
    od = c(0.1, 0.2)
  )

  expect_error(validate_growth_data(bad_data), "Duplicate")
})

test_that("decreasing time within sample fails validation", {
  bad_data <- tibble::tibble(
    sample = c("a", "a", "a"),
    time = c(0, 2, 1),
    od = c(0.1, 0.2, 0.3)
  )

  expect_error(validate_growth_data(bad_data), "strictly increasing")
})

test_that("flat but valid data passes validation", {
  flat_data <- tibble::tibble(
    sample = rep(c("a", "b"), each = 3),
    time = rep(c(0, 1, 2), times = 2),
    od = rep(0.2, 6)
  )

  expect_s3_class(validate_growth_data(flat_data), "tbl_df")
})

test_that("negative OD fails by default and passes when allowed", {
  bad_data <- tibble::tibble(
    sample = c("a", "a"),
    time = c(0, 1),
    od = c(0.1, -0.2)
  )

  expect_error(validate_growth_data(bad_data), "Negative")
  expect_s3_class(validate_growth_data(bad_data, allow_negative_od = TRUE), "tbl_df")
})

test_that("NA in key columns fails validation", {
  bad_data <- tibble::tibble(
    sample = c("a", NA),
    time = c(0, 1),
    od = c(0.1, 0.2)
  )

  expect_error(validate_growth_data(bad_data), "must not contain missing values")
})

test_that("non-finite values fail validation", {
  bad_data <- tibble::tibble(
    sample = c("a", "a"),
    time = c(0, Inf),
    od = c(0.1, NaN)
  )

  expect_error(validate_growth_data(bad_data), "finite numeric values")
})

test_that("zero OD warns only when requested", {
  zero_data <- tibble::tibble(
    sample = c("a", "a"),
    time = c(0, 1),
    od = c(0, 0.1)
  )

  expect_no_warning(validate_growth_data(zero_data))
  expect_warning(validate_growth_data(zero_data, warn_zero_od = TRUE), "Zero `od` values")
})

test_that("minimum points per sample is enforced", {
  bad_data <- tibble::tibble(
    sample = c("a", "b", "b"),
    time = c(0, 0, 1),
    od = c(0.1, 0.2, 0.3)
  )

  expect_error(
    validate_growth_data(bad_data, min_points_per_sample = 2),
    "at least 2 point"
  )
})
