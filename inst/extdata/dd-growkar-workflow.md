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

## Coerce to SummarizedExperiment

`growkar` can also package the processed data into a lightweight
`growkar_data` object and coerce it into a `SummarizedExperiment` for
Bioconductor-oriented workflows.

``` r
growkar_obj <- as_growkar(tidy_dd)
se <- methods::as(growkar_obj, "SummarizedExperiment")
se
#> class: SummarizedExperiment 
#> dim: 87 24 
#> metadata(1): growth_metrics
#> assays(1): od
#> rownames(87): 0 0.333333333333333 ... 28.3336111111111 28.6669444444444
#> rowData names(1): time
#> colnames(24): H2O2(0.135mM)_1 H2O2(0.135mM)_2 ... H2O2(8.8mM)_2
#>   H2O2(8.8mM)_3
#> colData names(3): sample condition replicate
```

## Plot growth curves with averaged replicates

This plot uses the averaged replicate trajectories for each condition
and returns a `ggplot2` object that can be customized further if needed.

``` r
plot_growth_curve(
  tidy_dd,
  average_replicates = TRUE,
  colour_col = "condition",
  palette_name = "Dark2"
)
```

![](dd-growkar-workflow-files/figure-gfm/average-growth-curve-1.png)<!-- -->

## Summarize doubling time with H2O2(0mM) as the reference

This summary compares replicate-level doubling times for each condition
against `H2O2(0mM)` using the rule-based exponential interval.

``` r
dt_stats <- summarize_growth_metrics(
  tidy_dd,
  method = "rule_based",
  comparison_col = "condition",
  compare_to = "H2O2(0mM)"
)
#> Warning: Sample `H2O2(4.4mM)_1`: Rule-based growth estimation did not yield a
#> positive growth slope.
#> Warning: Sample `H2O2(4.4mM)_2`: Rule-based growth estimation did not yield a
#> positive growth slope.
#> Warning: Sample `H2O2(4.4mM)_3`: Rule-based growth estimation did not yield a
#> positive growth slope.
#> Warning: Sample `H2O2(8.8mM)_1`: Rule-based growth estimation did not yield a
#> positive growth slope.
#> Warning: Sample `H2O2(8.8mM)_2`: Rule-based growth estimation did not yield a
#> positive growth slope.
#> Warning: Sample `H2O2(8.8mM)_3`: Rule-based growth estimation did not yield a
#> positive growth slope.

dt_stats <- dplyr::arrange(dt_stats, .data$condition)

knitr::kable(dt_stats, digits = 3)
```

| condition | mean_mu | mean_doubling_time | sd_doubling_time | n_replicates | error_bar | p_value | p_value_label |
|:---|---:|---:|---:|---:|---:|---:|:---|
| H2O2(0mM) | 0.176 | 3.998 | 0.665 | 3 | 0.384 | 1.000 | ref |
| H2O2(0.135mM) | 0.200 | 3.533 | 0.576 | 3 | 0.333 | 0.412 | ns |
| H2O2(0.275mM) | 0.185 | 3.783 | 0.480 | 3 | 0.277 | 0.676 | ns |
| H2O2(0.55mM) | 0.165 | 4.207 | 0.241 | 3 | 0.139 | 0.651 | ns |
| H2O2(1.1mM) | 0.179 | 3.883 | 0.185 | 3 | 0.107 | 0.796 | ns |
| H2O2(2.2mM) | 0.276 | 2.522 | 0.165 | 3 | 0.095 | 0.054 | ns |
| H2O2(4.4mM) | NaN | NaN | NA | 0 | NA | NA | NA |
| H2O2(8.8mM) | NaN | NaN | NA | 0 | NA | NA | NA |

## Plot doubling time comparisons

This plot shows mean doubling time with error bars and comparison
brackets against `H2O2(0mM)` using the rule-based exponential interval.

``` r
plot_doubling_time(
  tidy_dd,
  comparison_col = "condition",
  compare_to = "H2O2(0mM)",
  method = "rule_based",
  palette_name = "Dark2"
)
#> Warning: Sample `H2O2(4.4mM)_1`: Rule-based growth estimation did not yield a
#> positive growth slope.
#> Warning: Sample `H2O2(4.4mM)_2`: Rule-based growth estimation did not yield a
#> positive growth slope.
#> Warning: Sample `H2O2(4.4mM)_3`: Rule-based growth estimation did not yield a
#> positive growth slope.
#> Warning: Sample `H2O2(8.8mM)_1`: Rule-based growth estimation did not yield a
#> positive growth slope.
#> Warning: Sample `H2O2(8.8mM)_2`: Rule-based growth estimation did not yield a
#> positive growth slope.
#> Warning: Sample `H2O2(8.8mM)_3`: Rule-based growth estimation did not yield a
#> positive growth slope.
#> Warning: Removed 2 rows containing missing values or values outside the scale range
#> (`geom_col()`).
```

![](dd-growkar-workflow-files/figure-gfm/doubling-time-plot-1.png)<!-- -->
