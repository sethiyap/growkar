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
