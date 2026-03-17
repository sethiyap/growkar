test_that("legacy wrappers return legacy-style columns", {
  expect_warning(
    legacy <- withCallingHandlers(
      calculate_growth_rate(growkar::yeast_growth_data, average_replicates = FALSE),
      warning = function(w) {
        if (!grepl("deprecated", conditionMessage(w), ignore.case = TRUE)) {
          invokeRestart("muffleWarning")
        }
      }
    ),
    "deprecated"
  )

  expect_true(all(c("condition", "replicate", "time1", "time2", "growth_rate", "doubling_time") %in% names(legacy)))
})

test_that("defined-interval legacy wrappers still work and warn", {
  subset_data <- tibble::as_tibble(growkar::yeast_growth_data)[, c("Time", "Cg_R1", "Cg_R2")]
  interval_tbl <- tibble::tibble(
    sample = c("Cg_R1", "Cg_R2"),
    start_time = c(4, 4),
    end_time = c(6, 6)
  )

  expect_warning(
    legacy_time <- withCallingHandlers(
      calculate_growthrate_from_defined_time(
        subset_data,
        logphase_tibble = interval_tbl,
        select_replicates = c("R1", "R2")
      ),
      warning = function(w) {
        if (!grepl("deprecated", conditionMessage(w), ignore.case = TRUE)) {
          invokeRestart("muffleWarning")
        }
      }
    ),
    "deprecated"
  )

  expect_warning(
    legacy_logphase <- withCallingHandlers(
      calculate_growthrate_from_defined_logphase(
        subset_data,
        logphase_tibble = interval_tbl,
        select_replicates = c("R1", "R2")
      ),
      warning = function(w) {
        if (!grepl("deprecated", conditionMessage(w), ignore.case = TRUE)) {
          invokeRestart("muffleWarning")
        }
      }
    ),
    "deprecated"
  )

  expect_true(all(c("condition", "replicate", "time1", "time2", "growth_rate", "doubling_time") %in% names(legacy_time)))
  expect_equal(names(legacy_time), names(legacy_logphase))
})
