test_that("fit_growth_curve returns a growkar_fit object", {
  logistic_data <- tibble::tibble(
    sample = "fit1",
    time = seq(0, 8, by = 0.5)
  )
  logistic_data$od <- 1.2 / (1 + exp(-0.8 * (logistic_data$time - 4)))

  fit <- fit_growth_curve(logistic_data, model = "logistic")

  expect_s3_class(fit, "growkar_fit")
  expect_true(is.logical(fit$converged))
  expect_equal(fit$sample, "fit1")
  expect_equal(fit$status, "converged")
  expect_equal(fit$n_points, nrow(logistic_data))
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

  expect_s3_class(fit, "growkar_fit")
  expect_equal(fit$model_name, "gompertz")
})

test_that("fit_growth_curve returns failed fit objects for insufficient data", {
  sparse_data <- tibble::tibble(
    sample = "sparse_fit",
    time = c(0, 1, 2),
    od = c(0.1, 0.2, 0.25)
  )

  fit <- fit_growth_curve(sparse_data, model = "logistic")

  expect_s3_class(fit, "growkar_fit")
  expect_false(fit$converged)
  expect_equal(fit$status, "insufficient_points")
  expect_true(all(is.na(fit$fitted$.fitted)))
})

test_that("fit_growth_curve handles flat data cleanly", {
  flat_data <- tibble::tibble(
    sample = "flat_fit",
    time = 0:5,
    od = rep(0.2, 6)
  )

  fit <- fit_growth_curve(flat_data, model = "logistic")

  expect_false(fit$converged)
  expect_equal(fit$status, "flat_curve")
})

test_that("summary and print methods handle failed fits", {
  sparse_data <- tibble::tibble(
    sample = "summary_fail",
    time = c(0, 1, 2),
    od = c(0.1, 0.12, 0.13)
  )

  fit <- fit_growth_curve(sparse_data, model = "logistic")

  expect_no_error(print(fit))
  expect_s3_class(summary(fit), "tbl_df")
})

test_that("plot_fitted_curve supports data input with selected replicates", {
  p <- plot_fitted_curve(
    growkar::yeast_growth_data,
    model = "logistic",
    select_replicates = c("R1", "R2")
  )

  expect_s3_class(p, "ggplot")
})

test_that("plot_fitted_curve supports averaging selected replicates", {
  p <- plot_fitted_curve(
    growkar::yeast_growth_data,
    model = "logistic",
    select_replicates = c("R1", "R2"),
    average_replicates = TRUE,
    colour_col = "condition"
  )

  expect_s3_class(p, "ggplot")
})

test_that("plot_fitted_curve warns when faceting by replicate after averaging", {
  expect_warning(
    p <- plot_fitted_curve(
      growkar::yeast_growth_data,
      model = "logistic",
      average_replicates = TRUE,
      colour_col = "condition",
      facet_col = "replicate"
    ),
    "ignored"
  )

  expect_s3_class(p, "ggplot")
})
