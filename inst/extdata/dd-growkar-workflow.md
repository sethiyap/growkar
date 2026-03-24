CnH2O2 growkar workflow example
================

``` r
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "dd-growkar-workflow-files/figure-gfm/"
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
```

## Prepare data

This example reads `CnH2O2_OD.txt`, converts it to the canonical tidy
format used by `growkar`, and validates the result.

``` r
dd_path <- if (file.exists("CnH2O2_OD.txt")) {
  "CnH2O2_OD.txt"
} else {
  system.file("extdata", "CnH2O2_OD.txt", package = "growkar")
}

dd <- read.delim(dd_path, check.names = FALSE)
tidy_dd <- as_tidy_growth_data(dd)
validate_growth_data(tidy_dd)
#> # A tibble: 2,088 × 5
#>     time sample           od condition   replicate
#>    <dbl> <chr>         <dbl> <chr>       <chr>    
#>  1     0 H2O2(8.8mM)_1 0.094 H2O2(8.8mM) 1        
#>  2     0 H2O2(8.8mM)_2 0.102 H2O2(8.8mM) 2        
#>  3     0 H2O2(8.8mM)_3 0.102 H2O2(8.8mM) 3        
#>  4     0 H2O2(4.4mM)_1 0.091 H2O2(4.4mM) 1        
#>  5     0 H2O2(4.4mM)_2 0.102 H2O2(4.4mM) 2        
#>  6     0 H2O2(4.4mM)_3 0.109 H2O2(4.4mM) 3        
#>  7     0 H2O2(2.2mM)_1 0.091 H2O2(2.2mM) 1        
#>  8     0 H2O2(2.2mM)_2 0.103 H2O2(2.2mM) 2        
#>  9     0 H2O2(2.2mM)_3 0.102 H2O2(2.2mM) 3        
#> 10     0 H2O2(1.1mM)_1 0.09  H2O2(1.1mM) 1        
#> # ℹ 2,078 more rows

h2o2_levels <- tidy_dd |>
  dplyr::distinct(condition) |>
  dplyr::mutate(
    concentration_mM = as.numeric(sub("^H2O2\\(([-0-9.]+)mM\\)$", "\\1", .data$condition))
  ) |>
  dplyr::arrange(.data$concentration_mM) |>
  dplyr::pull(condition)

tidy_dd <- dplyr::mutate(
  tidy_dd,
  condition = factor(.data$condition, levels = h2o2_levels)
)

averaged_dd <- tidy_dd |>
  dplyr::group_by(.data$condition, .data$time) |>
  dplyr::summarise(od = mean(.data$od, na.rm = TRUE), .groups = "drop") |>
  dplyr::rename(sample = .data$condition)
#> Warning: Use of .data in tidyselect expressions was deprecated in tidyselect 1.2.0.
#> ℹ Please use `"condition"` instead of `.data$condition`
#> This warning is displayed once per session.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
#> generated.

head(tidy_dd)
#> # A tibble: 6 × 5
#>    time sample           od condition   replicate
#>   <dbl> <chr>         <dbl> <fct>       <chr>    
#> 1     0 H2O2(8.8mM)_1 0.094 H2O2(8.8mM) 1        
#> 2     0 H2O2(8.8mM)_2 0.102 H2O2(8.8mM) 2        
#> 3     0 H2O2(8.8mM)_3 0.102 H2O2(8.8mM) 3        
#> 4     0 H2O2(4.4mM)_1 0.091 H2O2(4.4mM) 1        
#> 5     0 H2O2(4.4mM)_2 0.102 H2O2(4.4mM) 2        
#> 6     0 H2O2(4.4mM)_3 0.109 H2O2(4.4mM) 3
```

## Plot growth curves with averaged replicates

This plot uses the averaged replicate trajectories for each condition
and returns a `ggplot2` object that can be customized further if needed.

``` r
plot_growth_curve(
  averaged_dd,
  average_replicates = FALSE,
  colour_col = "sample",
  palette_name = "Dark2"
)
```

![](dd-growkar-workflow-files/figure-gfm/average-growth-curve-1.png)<!-- -->

## Summarize doubling time with H2O2(0mM) as the reference

This summary compares replicate-level doubling times for each condition
against `H2O2(0mM)`.

``` r
dt_stats <- summarize_growth_metrics(
  tidy_dd,
  method = "rolling_window",
  comparison_col = "condition",
  compare_to = "H2O2(0mM)"
)

dt_stats <- dplyr::arrange(dt_stats, .data$condition)

knitr::kable(dt_stats, digits = 3)
```

| condition | mean_mu | mean_doubling_time | sd_doubling_time | n_replicates | error_bar | p_value | p_value_label |
|:---|---:|---:|---:|---:|---:|---:|:---|
| H2O2(0mM) | 0.292 | 2.388 | 0.253 | 3 | 0.146 | 1.000 | ref |
| H2O2(0.135mM) | 0.272 | 2.594 | 0.415 | 3 | 0.240 | 0.511 | ns |
| H2O2(0.275mM) | 0.270 | 2.597 | 0.366 | 3 | 0.212 | 0.466 | ns |
| H2O2(0.55mM) | 0.285 | 2.451 | 0.229 | 3 | 0.132 | 0.765 | ns |
| H2O2(1.1mM) | 0.297 | 2.355 | 0.252 | 3 | 0.146 | 0.882 | ns |
| H2O2(2.2mM) | 0.315 | 2.204 | 0.077 | 3 | 0.045 | 0.335 | ns |
| H2O2(4.4mM) | 0.019 | 53.331 | 30.353 | 3 | 17.524 | 0.101 | ns |
| H2O2(8.8mM) | 0.049 | 60.095 | 50.447 | 3 | 29.126 | 0.186 | ns |

## Plot doubling time comparisons

This plot shows mean doubling time with error bars and comparison
brackets against `H2O2(0mM)`.

``` r
plot_doubling_time(
  tidy_dd,
  comparison_col = "condition",
  compare_to = "H2O2(0mM)",
  palette_name = "Dark2"
)
```

![](dd-growkar-workflow-files/figure-gfm/doubling-time-plot-1.png)<!-- -->

## Detect exponential phase in all averaged samples

This section inspects the highest-ranked candidate exponential windows
across all averaged H2O2 conditions.

``` r
phase_tbl <- dplyr::bind_rows(
  lapply(split(averaged_dd, averaged_dd$sample), detect_exponential_phase)
)

phase_tbl <- phase_tbl |>
  dplyr::group_by(.data$sample) |>
  dplyr::slice_head(n = 3) |>
  dplyr::ungroup()

knitr::kable(phase_tbl, digits = 3)
```

| sample | rank | start_time | end_time | slope | r_squared | n_points | selection_reason | degraded |
|:---|---:|---:|---:|---:|---:|---:|:---|:---|
| H2O2(0.135mM) | 1 | 14.000 | 15.334 | 0.266 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(0.135mM) | 2 | 14.334 | 15.667 | 0.262 | 0.999 | 5 | rolling_window_ranked | FALSE |
| H2O2(0.135mM) | 3 | 13.667 | 15.000 | 0.262 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(0.275mM) | 1 | 14.000 | 15.334 | 0.269 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(0.275mM) | 2 | 14.334 | 15.667 | 0.264 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(0.275mM) | 3 | 13.667 | 15.000 | 0.261 | 0.999 | 5 | rolling_window_ranked | FALSE |
| H2O2(0.55mM) | 1 | 14.667 | 16.000 | 0.282 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(0.55mM) | 2 | 15.000 | 16.334 | 0.282 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(0.55mM) | 3 | 14.334 | 15.667 | 0.277 | 0.999 | 5 | rolling_window_ranked | FALSE |
| H2O2(0mM) | 1 | 13.667 | 15.000 | 0.288 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(0mM) | 2 | 14.000 | 15.334 | 0.288 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(0mM) | 3 | 14.334 | 15.667 | 0.288 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(1.1mM) | 1 | 16.000 | 17.334 | 0.294 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(1.1mM) | 2 | 16.334 | 17.667 | 0.294 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(1.1mM) | 3 | 16.667 | 18.000 | 0.288 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(2.2mM) | 1 | 27.000 | 28.334 | 0.313 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(2.2mM) | 2 | 27.334 | 28.667 | 0.313 | 1.000 | 5 | rolling_window_ranked | FALSE |
| H2O2(2.2mM) | 3 | 26.667 | 28.000 | 0.308 | 0.999 | 5 | rolling_window_ranked | FALSE |
| H2O2(4.4mM) | 1 | 13.334 | 14.667 | 0.013 | 0.493 | 5 | rolling_window_ranked | FALSE |
| H2O2(4.4mM) | 2 | 21.667 | 23.000 | 0.011 | 0.500 | 5 | rolling_window_ranked | FALSE |
| H2O2(4.4mM) | 3 | 12.667 | 14.000 | 0.010 | 0.470 | 5 | rolling_window_ranked | FALSE |
| H2O2(8.8mM) | 1 | 15.334 | 16.667 | 0.044 | 0.740 | 5 | rolling_window_ranked | FALSE |
| H2O2(8.8mM) | 2 | 15.000 | 16.334 | 0.027 | 0.477 | 5 | rolling_window_ranked | FALSE |
| H2O2(8.8mM) | 3 | 15.667 | 17.000 | 0.018 | 0.128 | 5 | rolling_window_ranked | FALSE |

## Fit and plot one representative growth curve

This section fits a logistic model to the averaged `H2O2(0mM)` curve and
overlays observed and fitted values.

``` r
fit <- averaged_dd |>
  filter(sample == "H2O2(0mM)") |>
  fit_growth_curve(model = "logistic")

extract_params(fit)
#> # A tibble: 1 × 6
#>   sample    model    asymptote     r    t0 doubling_time_model
#>   <chr>     <chr>        <dbl> <dbl> <dbl>               <dbl>
#> 1 H2O2(0mM) logistic      1.85 0.357  16.4                1.94
```

``` r
plot_fitted_curve(fit)
```

![](dd-growkar-workflow-files/figure-gfm/plot-fit-1.png)<!-- -->
