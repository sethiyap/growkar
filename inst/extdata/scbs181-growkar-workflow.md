ScBS181 growkar workflow example
================

``` r
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "scbs181-growkar-workflow-files/figure-gfm/"
)

if (requireNamespace("pkgload", quietly = TRUE) && file.exists("DESCRIPTION")) {
  pkg_root <- "."
} else {
  candidates <- c(".", "..", "../..")
  match_idx <- which(file.exists(file.path(candidates, "DESCRIPTION")))
  pkg_root <- if (length(match_idx) > 0L) candidates[[match_idx[[1]]]] else NULL
}

if (!is.null(pkg_root) && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(pkg_root, export_all = FALSE, helpers = FALSE, quiet = TRUE)
}

library(growkar)
library(dplyr)
library(knitr)

sc_colors <- c("blue4", "#E41A1C", "gold", "black")
```

## Prepare data

This example reads `ScBS181_OD.txt`, converts it to the canonical tidy
format used by `growkar`, and validates the result.

``` r
sc_path <- if (file.exists("ScBS181_OD.txt")) {
  "ScBS181_OD.txt"
} else {
  system.file("extdata", "ScBS181_OD.txt", package = "growkar")
}

sc_raw <- read.delim(sc_path, check.names = FALSE)
tidy_sc <- as_tidy_growth_data(sc_raw)
validate_growth_data(tidy_sc)
#> # A tibble: 2,064 × 5
#>     time sample        od condition replicate
#>    <dbl> <chr>      <dbl> <chr>     <chr>    
#>  1     0 Sc(100)_1  0.095 Sc(100)   1        
#>  2     0 Sc(100)_2  0.099 Sc(100)   2        
#>  3     0 Sc(100)_3  0.099 Sc(100)   3        
#>  4     0 Sc(50)_1   0.106 Sc(50)    1        
#>  5     0 Sc(50)_2   0.106 Sc(50)    2        
#>  6     0 Sc(50)_3   0.11  Sc(50)    3        
#>  7     0 Sc(25)_1   0.107 Sc(25)    1        
#>  8     0 Sc(25)_2   0.106 Sc(25)    2        
#>  9     0 Sc(25)_3   0.107 Sc(25)    3        
#> 10     0 Sc(12.5)_1 0.105 Sc(12.5)  1        
#> # ℹ 2,054 more rows

sc_levels <- tidy_sc |>
  dplyr::distinct(condition) |>
  dplyr::mutate(
    concentration = as.numeric(sub("^Sc\\(([-0-9.]+)\\)$", "\\1", .data$condition))
  ) |>
  dplyr::arrange(.data$concentration) |>
  dplyr::pull(condition)

tidy_sc <- dplyr::mutate(
  tidy_sc,
  condition = factor(.data$condition, levels = sc_levels)
)

selected_conditions <- c("Sc(100)", "Sc(50)", "Sc(25)", "Sc(0)")

tidy_sc <- tidy_sc |>
  dplyr::filter(.data$condition %in% selected_conditions) |>
  dplyr::mutate(condition = factor(.data$condition, levels = selected_conditions))

head(tidy_sc)
#> # A tibble: 6 × 5
#>    time sample       od condition replicate
#>   <dbl> <chr>     <dbl> <fct>     <chr>    
#> 1     0 Sc(100)_1 0.095 Sc(100)   1        
#> 2     0 Sc(100)_2 0.099 Sc(100)   2        
#> 3     0 Sc(100)_3 0.099 Sc(100)   3        
#> 4     0 Sc(50)_1  0.106 Sc(50)    1        
#> 5     0 Sc(50)_2  0.106 Sc(50)    2        
#> 6     0 Sc(50)_3  0.11  Sc(50)    3
```

## Plot growth curves with averaged replicates

``` r
plot_growth_curve(
  tidy_sc,
  average_replicates = TRUE,
  colour_col = "condition",
  custom_colors = sc_colors
)
```

![](scbs181-growkar-workflow-files/figure-gfm/average-growth-curve-1.png)<!-- -->

## Summarize doubling time from averaged replicates

This summary computes doubling time from the averaged growth trajectory
for each condition using the rolling-window method.

``` r
dt_stats <- summarize_growth_metrics(
  tidy_sc,
  method = "rolling_window",
  average_replicates = TRUE
)

dt_stats <- dt_stats |>
  dplyr::mutate(sample = factor(.data$sample, levels = selected_conditions)) |>
  dplyr::arrange(.data$sample)

knitr::kable(dt_stats, digits = 3)
```

| sample | mu | start_time | end_time | r_squared | method | n_points | degraded | note | doubling_time |
|:---|---:|---:|---:|---:|:---|---:|:---|:---|---:|
| Sc(100) | 0.469 | 20.667 | 22.001 | 1 | rolling_window | 5 | FALSE | rolling_window_ranked | 1.479 |
| Sc(50) | 0.311 | 16.667 | 18.001 | 1 | rolling_window | 5 | FALSE | rolling_window_ranked | 2.227 |
| Sc(25) | 0.327 | 14.334 | 15.667 | 1 | rolling_window | 5 | FALSE | rolling_window_ranked | 2.117 |
| Sc(0) | 0.330 | 13.667 | 15.001 | 1 | rolling_window | 5 | FALSE | rolling_window_ranked | 2.103 |

## Plot averaged doubling time

``` r
ggplot2::ggplot(
  dt_stats,
  ggplot2::aes(x = .data$sample, y = .data$doubling_time, fill = .data$sample)
) +
  ggplot2::geom_col(width = 0.7) +
  ggplot2::scale_fill_manual(values = sc_colors) +
  ggplot2::theme_bw() +
  ggplot2::theme(legend.position = "none", panel.grid.minor = ggplot2::element_blank()) +
  ggplot2::labs(x = "Condition", y = "Doubling time")
```

![](scbs181-growkar-workflow-files/figure-gfm/doubling-time-plot-1.png)<!-- -->

## Rolling-window exponential phase in all averaged samples

This section shows the highest-ranked rolling-window exponential
interval for each averaged Sc condition and the mean start and end times
across all conditions.

``` r
phase_tbl <- detect_exponential_phase(
  tidy_sc,
  average_replicates = TRUE
) |>
  dplyr::mutate(sample = factor(.data$sample, levels = selected_conditions)) |>
  dplyr::arrange(.data$sample) |>
  dplyr::group_by(.data$sample) |>
  dplyr::slice_head(n = 1) |>
  dplyr::ungroup()

knitr::kable(phase_tbl, digits = 3)
```

| sample | start_time | end_time | slope | r_squared | n_points | selection_reason | degraded | rank |
|:---|---:|---:|---:|---:|---:|:---|:---|---:|
| Sc(100) | 20.667 | 22.001 | 0.469 | 1 | 5 | rolling_window_ranked | FALSE | 1 |
| Sc(50) | 16.667 | 18.001 | 0.311 | 1 | 5 | rolling_window_ranked | FALSE | 1 |
| Sc(25) | 14.334 | 15.667 | 0.327 | 1 | 5 | rolling_window_ranked | FALSE | 1 |
| Sc(0) | 13.667 | 15.001 | 0.330 | 1 | 5 | rolling_window_ranked | FALSE | 1 |

``` r

phase_average <- phase_tbl |>
  dplyr::summarise(
    mean_start_time = mean(.data$start_time, na.rm = TRUE),
    mean_end_time = mean(.data$end_time, na.rm = TRUE)
  )

knitr::kable(phase_average, digits = 3)
```

| mean_start_time | mean_end_time |
|----------------:|--------------:|
|          16.334 |        17.667 |
