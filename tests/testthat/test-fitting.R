test_that("fit_growth_curve returns a GrowthFit S4 object", {
  logistic_data <- tibble::tibble(
    sample = "fit1",
    time = seq(0, 8, by = 0.5)
  )
  logistic_data$od <- 1.2 / (1 + exp(-0.8 * (logistic_data$time - 4)))

  fit <- fit_growth_curve(logistic_data, model = "logistic")

  expect_s4_class(fit, "GrowthFit")
  expect_true(methods::validObject(fit))
  expect_true(is.logical(fit_converged(fit)))
  expect_equal(fit_sample(fit), "fit1")
  expect_equal(fit_status(fit), "converged")
  expect_equal(fit_model(fit), "logistic")
  expect_equal(nobs(fit), nrow(logistic_data))
})

test_that("GrowthFit supports the standard modelling generics", {
  logistic_data <- tibble::tibble(
    sample = "fit_generics",
    time = seq(0, 8, by = 0.5)
  )
  logistic_data$od <- 1.2 / (1 + exp(-0.8 * (logistic_data$time - 4)))

  fit <- fit_growth_curve(logistic_data, model = "logistic")

  expect_named(coef(fit), c("K", "r", "t0"))
  expect_length(fitted(fit), nrow(logistic_data))
  expect_length(residuals(fit), nrow(logistic_data))
  expect_s3_class(fit_data(fit), "tbl_df")
})

test_that("growkar exposes no S3 class for growth data or model fits", {
  logistic_data <- tibble::tibble(
    sample = "fit_s3",
    time = seq(0, 8, by = 0.5)
  )
  logistic_data$od <- 1.2 / (1 + exp(-0.8 * (logistic_data$time - 4)))

  fit <- fit_growth_curve(logistic_data, model = "logistic")

  expect_true(isVirtualClass("GrowthFit") || methods::is(fit, "GrowthFit"))
  expect_false(is.list(fit))
  expect_false(exists("as_growkar", where = asNamespace("growkar"), inherits = FALSE))
})

test_that("extract_params and augment_growth_fit return tidy tibbles", {
  logistic_data <- tibble::tibble(
    sample = "fit2",
    time = seq(0, 8, by = 0.5)
  )
  logistic_data$od <- 1.1 / (1 + exp(-0.7 * (logistic_data$time - 3.5)))

  fit <- fit_growth_curve(logistic_data, model = "logistic")
  params <- extract_params(fit)
  augmented <- augment_growth_fit(fit)

  expect_s3_class(params, "tbl_df")
  expect_true(all(c("sample", "model", "asymptote", "r", "t0", "doubling_time_model") %in% names(params)))
  expect_s3_class(augmented, "tbl_df")
  expect_true(".fitted" %in% names(augmented))
})

test_that("fit_growth_curve supports Gompertz fits", {
  gompertz_data <- tibble::tibble(
    sample = "fit_gompertz",
    time = seq(0, 8, by = 0.5)
  )
  gompertz_data$od <- 1.3 * exp(-exp(-0.8 * (gompertz_data$time - 4)))

  fit <- fit_growth_curve(gompertz_data, model = "gompertz")

  expect_s4_class(fit, "GrowthFit")
  expect_equal(fit_model(fit), "gompertz")
})

test_that("fit_growth_curve returns failed fit objects for insufficient data", {
  sparse_data <- tibble::tibble(
    sample = "sparse_fit",
    time = c(0, 1, 2),
    od = c(0.1, 0.2, 0.25)
  )

  fit <- fit_growth_curve(sparse_data, model = "logistic")

  expect_s4_class(fit, "GrowthFit")
  expect_true(methods::validObject(fit))
  expect_false(fit_converged(fit))
  expect_equal(fit_status(fit), "insufficient_points")
  expect_true(all(is.na(fitted(fit))))
})

test_that("fit_growth_curve handles flat data cleanly", {
  flat_data <- tibble::tibble(
    sample = "flat_fit",
    time = 0:5,
    od = rep(0.2, 6)
  )

  fit <- fit_growth_curve(flat_data, model = "logistic")

  expect_false(fit_converged(fit))
  expect_equal(fit_status(fit), "flat_curve")
})

test_that("summary and show methods handle failed fits", {
  sparse_data <- tibble::tibble(
    sample = "summary_fail",
    time = c(0, 1, 2),
    od = c(0.1, 0.12, 0.13)
  )

  fit <- fit_growth_curve(sparse_data, model = "logistic")

  expect_output(show(fit), "<GrowthFit>")
  expect_s3_class(summary(fit), "tbl_df")
})

test_that("fit_growth_plate returns a list-column of GrowthFit objects", {
  fits <- fit_growth_plate(yeast_growth_data, model = "logistic")

  expect_s3_class(fits, "tbl_df")
  expect_true(all(vapply(fits$fit, methods::is, logical(1), "GrowthFit")))
})
