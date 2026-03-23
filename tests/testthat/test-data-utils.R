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

test_that("as_tidy_growth_data detects common machine-export column aliases", {
  machine_long <- tibble::tibble(
    Sample = c("A_R1", "A_R1", "A_R2", "A_R2"),
    `Time [h]` = c("0:00:00", "0:30:00", "0:00:00", "0:30:00"),
    OD600 = c("0.10", "0.20", "0.11", "0.21")
  )

  tidy_data <- as_tidy_growth_data(machine_long)

  expect_true(all(c("sample", "time", "od") %in% names(tidy_data)))
  expect_equal(sort(unique(tidy_data$time)), c(0, 0.5))
  expect_equal(tidy_data$od, c(0.10, 0.20, 0.11, 0.21))
})

test_that("as_tidy_growth_data detects wide machine-export time aliases", {
  machine_wide <- tibble::tibble(
    `Time [h]` = c("0:00:00", "1:00:00"),
    A_R1 = c(0.10, 0.20),
    A_R2 = c(0.11, 0.21)
  )

  tidy_data <- as_tidy_growth_data(machine_wide)

  expect_equal(sort(unique(tidy_data$time)), c(0, 1))
  expect_equal(sort(unique(tidy_data$sample)), c("A_R1", "A_R2"))
})
