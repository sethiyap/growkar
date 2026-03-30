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

test_that("plot_growth_curve_facets facets by sample family when condition is available", {
  dd <- read.delim(
    testthat::test_path("../../inst/extdata/dose_response_BS181_20Dec24_Cdk7Tag.txt"),
    check.names = FALSE
  )
  p <- plot_growth_curve_facets(dd)

  expect_s3_class(p, "ggplot")
  expect_match(rlang::expr_text(p$facet$params$facets), "facet_sample")
  expect_true(all(c("KN99", "CM2444", "CM2446", "CM2448") %in% unique(p$data$facet_sample)))
  expect_false("replicate" %in% names(p$data))
  expect_true(all(c("od_mean", "od_sd") %in% names(p$data)))
  expect_true("facet_colour" %in% names(p$data))
  expect_equal(sort(unique(p$data$facet_colour)), c("0", "1.56", "100", "12.5", "25", "3.125", "50", "6.25"))
})

test_that("plot_growth_curve_facets uses sample facets when condition is absent", {
  tidy_no_condition <- tibble::tibble(
    time = rep(c(0, 1, 2), 2),
    sample = rep(c("A", "B"), each = 3),
    od = c(0.10, 0.15, 0.21, 0.08, 0.12, 0.18)
  )

  p <- plot_growth_curve_facets(tidy_no_condition)

  expect_s3_class(p, "ggplot")
  expect_match(rlang::expr_text(p$facet$params$facets), "facet_sample")
  expect_equal(sort(unique(p$data$facet_sample)), c("A", "B"))
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

test_that("plot_doubling_time bracket annotations follow plotted factor order", {
  summary_tbl <- tibble::tibble(
    condition = factor(
      c("KN99(0)", "KN99(1.56)", "KN99(100)"),
      levels = c("KN99(100)", "KN99(1.56)", "KN99(0)")
    ),
    mean_doubling_time = c(2.6, 2.4, 72.8),
    error_bar = c(0.02, 0.2, 0.4),
    p_value_label = c("ref", "ns", "****")
  )

  ann <- growkar_bracket_annotations(
    summary_tbl = summary_tbl,
    comparison_col = "condition",
    compare_to = "KN99(0)",
    offset = 1
  )

  expect_equal(ann$x_ref, 3)
  expect_equal(ann$x_group, 1)
})
