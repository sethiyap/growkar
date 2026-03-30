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

test_that("plot_growth_curve preserves input condition order after averaging", {
  dd <- read.delim(
    system.file("extdata", "dose_response_BS181_20Dec24_Cdk7Tag.txt", package = "growkar"),
    check.names = FALSE
  )
  se <- methods::as(as_growkar(as_tidy_growth_data(dd)), "SummarizedExperiment")
  se_KN99 <- se[, grepl("^KN99", SummarizedExperiment::colData(se)$sample)]

  p <- plot_growth_curve(
    se_KN99,
    average_replicates = TRUE,
    colour_col = "condition"
  )

  expect_equal(
    levels(p$data$condition),
    c("KN99(100)", "KN99(50)", "KN99(25)", "KN99(12.5)", "KN99(6.25)", "KN99(3.125)", "KN99(1.56)", "KN99(0)")
  )
})

test_that("plot_growth_curve_facets facets by sample family when condition is available", {
  dd <- read.delim(
    system.file("extdata", "dose_response_BS181_20Dec24_Cdk7Tag.txt", package = "growkar"),
    check.names = FALSE
  )
  p <- plot_growth_curve_facets(dd)

  expect_s3_class(p, "ggplot")
  expect_match(rlang::expr_text(p$facet$params$facets), "facet_sample")
  expect_true(all(c("KN99", "CM2444", "CM2446", "CM2448") %in% unique(p$data$facet_sample)))
  expect_false("replicate" %in% names(p$data))
  expect_true(all(c("od_mean", "od_sd") %in% names(p$data)))
  expect_true("facet_colour" %in% names(p$data))
  expect_equal(
    levels(p$data$facet_sample),
    c("KN99", "CM2444", "CM2446", "CM2448")
  )
  expect_equal(
    levels(p$data$facet_colour),
    c("100", "50", "25", "12.5", "6.25", "3.125", "1.56", "0")
  )
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
  expect_equal(as.character(sort(unique(p$data$facet_sample))), c("A", "B"))
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
