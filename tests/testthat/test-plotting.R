test_that("plot_growth_curve warns when faceting by replicate after averaging", {
  expect_warning(
    p <- plot_growth_curve(
      yeast_growth_data,
      average_replicates = TRUE,
      colour_col = "condition",
      facet_col = "replicate"
    ),
    "ignored"
  )

  expect_s3_class(p, "ggplot")
})

test_that("plot_growth_curve can facet by sample and ignore replicate faceting", {
  expect_warning(
    p <- plot_growth_curve(
      yeast_growth_data,
      facet_col = "replicate",
      facet_by_sample = TRUE
    ),
    "ignored when `facet_by_sample = TRUE`"
  )

  expect_s3_class(p, "ggplot")
  expect_match(rlang::expr_text(p$facet$params$facets), "sample")
})

test_that("plot_growth_curve can restrict plotting to selected samples", {
  p <- plot_growth_curve(
    yeast_growth_data,
    select_samples = "Cg_R1"
  )

  expect_s3_class(p, "ggplot")
  expect_equal(unique(as.character(p$data$sample)), "Cg_R1")
})

test_that("plot_growth_curve reports available samples for invalid selections", {
  expect_error(
    plot_growth_curve(
      yeast_growth_data,
      select_samples = "missing_sample"
    ),
    "Available samples:"
  )
})

test_that("plot_doubling_time returns a ggplot for replicate-based summaries", {
  p <- suppressWarnings(plot_doubling_time(
    yeast_growth_data,
    comparison_col = "condition",
    compare_to = "Cg",
    select_replicates = c("R1", "R2"),
    palette_name = "Dark2"
  ))

  expect_s3_class(p, "ggplot")
})

test_that("plot_doubling_time can exclude selected groups from the plot", {
  p <- suppressWarnings(plot_doubling_time(
    yeast_growth_data,
    comparison_col = "condition",
    compare_to = "Cg",
    exclude_groups = "YPD",
    select_replicates = c("R1", "R2"),
    palette_name = "Dark2"
  ))

  expect_s3_class(p, "ggplot")
})

test_that("plot_doubling_time supports averaged replicate summaries", {
  p <- suppressWarnings(plot_doubling_time(
    yeast_growth_data,
    average_replicates = TRUE,
    palette_name = "Dark2"
  ))

  expect_s3_class(p, "ggplot")
})
