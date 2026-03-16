test_that("legacy wrappers return legacy-style columns", {
  expect_warning(
    legacy <- calculate_growth_rate(growkar::yeast_growth_data, average_replicates = FALSE),
    "deprecated"
  )

  expect_true(all(c("condition", "replicate", "time1", "time2", "growth_rate", "doubling_time") %in% names(legacy)))
})
