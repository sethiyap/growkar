
<!-- README.md is generated from README.Rmd. Please edit that file -->

# growkar <img src="hexasticker2.png" align="right" height="180" alt="growkar hex sticker" />

[![R-CMD-check](https://github.com/sethiyap/growkar/actions/workflows/R-CMD-check.yaml/badge.svg?branch=tidy-v2)](https://github.com/sethiyap/growkar/actions/workflows/R-CMD-check.yaml)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

`growkar` is an R package for microbial growth curve analysis from
optical density (OD) time-series data. It provides a tidy workflow for
converting input data, validating growth measurements, plotting growth
curves, estimating growth rate and doubling time, detecting exponential
phase, and fitting logistic or Gompertz growth models.

The package keeps the feel of the original `growkar` workflow while
introducing a tidyverse-friendly v2 design built around canonical input
columns: `sample`, `time`, and `od`.

Legacy wrapper functions remain available for older workflows, but new
analyses should prefer the tidy-v2 interface shown below.

## Installation

``` r
remotes::install_github("sethiyap/growkar", ref = "tidy-v2")
```

## Example dataset

``` r
library(growkar)
data(yeast_growth_data)

head(yeast_growth_data)
#> # A tibble: 6 × 10
#>    Time Cg_R1 Cg_R2 Cg_R3 CgFlu_R1 CgFlu_R2 CgFlu_R3 YPD_R1 YPD_R2 YPD_R3
#>   <dbl> <dbl> <dbl> <dbl>    <dbl>    <dbl>    <dbl>  <dbl>  <dbl>  <dbl>
#> 1   0   0.115 0.116 0.117    0.131    0.133    0.132  0.105  0.105  0.104
#> 2   0.5 0.116 0.118 0.117    0.132    0.133    0.134  0.104  0.104  0.104
#> 3   1   0.118 0.119 0.118    0.134    0.136    0.138  0.104  0.104  0.104
#> 4   1.5 0.121 0.123 0.121    0.139    0.142    0.144  0.104  0.104  0.104
#> 5   2   0.126 0.129 0.126    0.15     0.151    0.151  0.104  0.104  0.104
#> 6   2.5 0.136 0.139 0.136    0.165    0.168    0.166  0.104  0.104  0.104
```

## Convert data to tidy format

**What it does:** `as_tidy_growth_data()` converts growth data into the
canonical tidy format used throughout the package, with core columns
`sample`, `time`, and `od`.

**Why use it:** A standard tidy structure makes downstream validation,
visualization, empirical summaries, and model fitting easier and more
consistent.

**Minimal example:**

``` r
tidy_data <- as_tidy_growth_data(yeast_growth_data)
head(tidy_data)
#> # A tibble: 6 × 5
#>    time sample      od condition replicate
#>   <dbl> <chr>    <dbl> <chr>     <chr>    
#> 1     0 Cg_R1    0.115 Cg        R1       
#> 2     0 Cg_R2    0.116 Cg        R2       
#> 3     0 Cg_R3    0.117 Cg        R3       
#> 4     0 CgFlu_R1 0.131 CgFlu     R1       
#> 5     0 CgFlu_R2 0.133 CgFlu     R2       
#> 6     0 CgFlu_R3 0.132 CgFlu     R3
```

## Validate tidy input

**What it does:** `validate_growth_data()` checks that tidy growth data
has the required columns and valid values.

**Why use it:** It helps catch structural or value problems before
downstream analysis.

**Minimal example:**

``` r
validate_growth_data(tidy_data)
#> # A tibble: 441 × 5
#>     time sample      od condition replicate
#>    <dbl> <chr>    <dbl> <chr>     <chr>    
#>  1   0   Cg_R1    0.115 Cg        R1       
#>  2   0   Cg_R2    0.116 Cg        R2       
#>  3   0   Cg_R3    0.117 Cg        R3       
#>  4   0   CgFlu_R1 0.131 CgFlu     R1       
#>  5   0   CgFlu_R2 0.133 CgFlu     R2       
#>  6   0   CgFlu_R3 0.132 CgFlu     R3       
#>  7   0   YPD_R1   0.105 YPD       R1       
#>  8   0   YPD_R2   0.105 YPD       R2       
#>  9   0   YPD_R3   0.104 YPD       R3       
#> 10   0.5 Cg_R1    0.116 Cg        R1       
#> # ℹ 431 more rows
```

## Plot growth curves

**What it does:** `plot_growth_curve()` visualizes OD over time and
returns a `ggplot` object.

**Why use it:** It preserves the clear ggplot-style growth curve display
of the previous version of `growkar`, and it is useful for quick quality
control and for comparing growth patterns across samples. Because the
output is a `ggplot` object, users can further customize it with
`ggplot2`.

**Minimal example:**

``` r
p <- plot_growth_curve(
  tidy_data,
  average_replicates = TRUE,
  colour_col = "condition",
  palette_name = "Dark2"
)
p
```

<img src="man/figures/README-unnamed-chunk-5-1.png" alt="" width="100%" />

To view individual replicates as separate panels, use
`facet_col = "replicate"` with `average_replicates = FALSE`.

``` r
p_rep <- plot_growth_curve(
  tidy_data,
  average_replicates = FALSE,
  colour_col = "condition",
  facet_col = "replicate",
  palette_name = "Dark2"
)

p_rep
```

<img src="man/figures/README-unnamed-chunk-6-1.png" alt="" width="100%" />

## Estimate growth rate

**What it does:** `compute_growth_rate()` estimates the specific growth
rate from `log(od)` versus time. In the returned table, `mu` is the
estimated growth rate.

**Why use it:** It is useful for estimating exponential growth directly
from observed data, using methods such as `"rolling_window"`,
`"defined_interval"`, and `"rule_based"`.

Method options:

- `"rolling_window"` scans rolling windows across the time series and
  selects the window with the strongest positive log-linear slope.
- `"defined_interval"` fits the growth rate over a user-supplied start
  and end time interval.
- `"rule_based"` preserves the legacy `growkar` OD-doubling approach for
  defining the exponential phase.

**Minimal example:**

``` r
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(knitr)

sample_id <- unique(tidy_data$sample)[1]

gr <- compute_growth_rate(
  filter(tidy_data, sample == sample_id),
  method = "rolling_window"
)

knitr::kable(gr, digits = 3)
```

| sample | mu | start_time | end_time | r_squared | method | n_points | degraded | note |
|:---|---:|---:|---:|---:|:---|---:|:---|:---|
| Cg_R1 | 0.576 | 4.5 | 6.5 | 1 | rolling_window | 5 | FALSE | rolling_window_ranked |

## Compute doubling time

**What it does:** `compute_doubling_time()` calculates doubling time
from growth rate as `log(2) / mu`.

**Why use it:** It converts the estimated growth rate into a more
biologically interpretable measure of growth kinetics. This is the
low-level helper when you already have one or more growth-rate
estimates. For a combined table across all samples, use
`summarize_growth_metrics()`.

**Minimal example:**

``` r
doubling_time_tbl <- tibble::tibble(
  sample = gr$sample,
  growth_rate = gr$mu,
  doubling_time = compute_doubling_time(gr$mu)
)

knitr::kable(doubling_time_tbl, digits = 3)
```

| sample | growth_rate | doubling_time |
|:-------|------------:|--------------:|
| Cg_R1  |       0.576 |         1.204 |

## Summarize growth metrics across samples

**What it does:** `summarize_growth_metrics()` computes growth rate and
doubling time across all samples.

**Why use it:** It is useful for comparing strains, conditions, or
replicates in one tidy summary table. Internally, it derives doubling
time from the estimated growth rate using `compute_doubling_time()`.

**Minimal example:**

``` r
metrics <- summarize_growth_metrics(tidy_data)
#> Warning: Sample `YPD_R1`: Exponential phase detection did not yield a positive
#> growth slope (rolling_window_ranked).
#> Warning: Sample `YPD_R2`: Exponential phase detection did not yield a positive
#> growth slope (rolling_window_ranked).
knitr::kable(metrics, digits = 3)
```

| sample | mu | start_time | end_time | r_squared | method | n_points | degraded | note | doubling_time |
|:---|---:|---:|---:|---:|:---|---:|:---|:---|---:|
| Cg_R1 | 0.576 | 4.5 | 6.5 | 1.000 | rolling_window | 5 | FALSE | rolling_window_ranked | 1.204 |
| Cg_R2 | 0.560 | 4.5 | 6.5 | 1.000 | rolling_window | 5 | FALSE | rolling_window_ranked | 1.238 |
| Cg_R3 | 0.571 | 4.5 | 6.5 | 0.999 | rolling_window | 5 | FALSE | rolling_window_ranked | 1.214 |
| CgFlu_R1 | 0.403 | 4.5 | 6.5 | 1.000 | rolling_window | 5 | FALSE | rolling_window_ranked | 1.719 |
| CgFlu_R2 | 0.407 | 4.5 | 6.5 | 1.000 | rolling_window | 5 | FALSE | rolling_window_ranked | 1.702 |
| CgFlu_R3 | 0.403 | 4.5 | 6.5 | 1.000 | rolling_window | 5 | FALSE | rolling_window_ranked | 1.721 |
| YPD_R1 | NA | NA | NA | NA | rolling_window | 5 | FALSE | rolling_window_ranked | NA |
| YPD_R2 | NA | NA | NA | NA | rolling_window | 5 | FALSE | rolling_window_ranked | NA |
| YPD_R3 | 0.004 | 18.0 | 20.0 | 0.500 | rolling_window | 5 | FALSE | rolling_window_ranked | 179.350 |

## Detect exponential phase

**What it does:** `detect_exponential_phase()` identifies likely
exponential-phase windows automatically.

**Why use it:** It helps show which time interval is most consistent
with exponential growth and supports interpretation of the growth-rate
estimate.

**Minimal example:**

``` r
phase_tbl <- detect_exponential_phase(
  filter(tidy_data, sample == sample_id)
)

knitr::kable(head(phase_tbl), digits = 3)
```

| sample | rank | start_time | end_time | slope | r_squared | n_points | selection_reason | degraded |
|:---|---:|---:|---:|---:|---:|---:|:---|:---|
| Cg_R1 | 1 | 4.5 | 6.5 | 0.576 | 1.000 | 5 | rolling_window_ranked | FALSE |
| Cg_R1 | 2 | 4.0 | 6.0 | 0.551 | 0.997 | 5 | rolling_window_ranked | FALSE |
| Cg_R1 | 3 | 5.0 | 7.0 | 0.551 | 0.997 | 5 | rolling_window_ranked | FALSE |
| Cg_R1 | 4 | 3.5 | 5.5 | 0.490 | 0.990 | 5 | rolling_window_ranked | FALSE |
| Cg_R1 | 5 | 5.5 | 7.5 | 0.490 | 0.991 | 5 | rolling_window_ranked | FALSE |
| Cg_R1 | 6 | 6.0 | 8.0 | 0.414 | 0.987 | 5 | rolling_window_ranked | FALSE |

## Fit a growth model

**What it does:** `fit_growth_curve()` fits a logistic or Gompertz
growth model to one sample.

**Why use it:** It is useful when a smooth model-based summary of the
full growth curve is preferred over a purely empirical estimate.

**Minimal example:**

``` r
fit <- fit_growth_curve(
  filter(tidy_data, sample == sample_id),
  model = "logistic"
)

fit
#> <growkar_fit> sample=Cg_R1, model=logistic, status=converged, n_points=49
```

## Extract fitted parameters

**What it does:** `extract_params()` extracts fitted coefficients and
model-derived quantities such as the asymptote and model-based doubling
time.

**Why use it:** It is useful for reporting fitted summaries in a tidy
format.

**Minimal example:**

``` r
params <- extract_params(fit)
params
#> # A tibble: 1 × 6
#>   sample model    asymptote     r    t0 doubling_time_model
#>   <chr>  <chr>        <dbl> <dbl> <dbl>               <dbl>
#> 1 Cg_R1  logistic      2.03 0.777  6.97               0.892
```

## Plot fitted curves

**What it does:** `plot_fitted_curve()` overlays observed OD points and
the fitted growth model, and returns a `ggplot` object.

**Why use it:** It is useful for visually checking model fit quality.
Because the output is a `ggplot` object, users can further customize it
with `ggplot2`.

**Minimal example:**

``` r
pf <- plot_fitted_curve(fit)
pf
```

<img src="man/figures/README-unnamed-chunk-13-1.png" alt="" width="100%" />

To fit and view individual replicates as separate panels from raw data,
use `facet_col = "replicate"` with `average_replicates = FALSE`.

``` r
pf_rep <- plot_fitted_curve(
  tidy_data,
  model = "logistic",
  average_replicates = FALSE,
  colour_col = "condition",
  facet_col = "replicate",
  palette_name = "Dark2"
)

pf_rep
```

<img src="man/figures/README-unnamed-chunk-14-1.png" alt="" width="100%" />

## Migrating from legacy growkar

Legacy wrappers are still available for older scripts, but the
recommended workflow is now:

- `calculate_growth_rate()` -\> `compute_growth_rate()` or
  `summarize_growth_metrics()`
- `calculate_growthrate_from_defined_time()` -\>
  `compute_growth_rate(method = "defined_interval")`
- `calculate_growthrate_from_defined_logphase()` -\>
  `compute_growth_rate(method = "defined_interval")`

The legacy wrappers emit deprecation warnings and internally call the
tidy-v2 implementation.

## Workflow summary

A typical `growkar` v2 workflow is:

``` r
data(yeast_growth_data)

tidy_data <- as_tidy_growth_data(yeast_growth_data)
validate_growth_data(tidy_data)
#> # A tibble: 441 × 5
#>     time sample      od condition replicate
#>    <dbl> <chr>    <dbl> <chr>     <chr>    
#>  1   0   Cg_R1    0.115 Cg        R1       
#>  2   0   Cg_R2    0.116 Cg        R2       
#>  3   0   Cg_R3    0.117 Cg        R3       
#>  4   0   CgFlu_R1 0.131 CgFlu     R1       
#>  5   0   CgFlu_R2 0.133 CgFlu     R2       
#>  6   0   CgFlu_R3 0.132 CgFlu     R3       
#>  7   0   YPD_R1   0.105 YPD       R1       
#>  8   0   YPD_R2   0.105 YPD       R2       
#>  9   0   YPD_R3   0.104 YPD       R3       
#> 10   0.5 Cg_R1    0.116 Cg        R1       
#> # ℹ 431 more rows

plot_growth_curve(tidy_data)
```

<img src="man/figures/README-unnamed-chunk-15-1.png" alt="" width="100%" />

``` r

metrics <- summarize_growth_metrics(tidy_data)
#> Warning: Sample `YPD_R1`: Exponential phase detection did not yield a positive
#> growth slope (rolling_window_ranked).
#> Warning: Sample `YPD_R2`: Exponential phase detection did not yield a positive
#> growth slope (rolling_window_ranked).
metrics
#> # A tibble: 9 × 10
#>   sample         mu start_time end_time r_squared method n_points degraded note 
#>   <chr>       <dbl>      <dbl>    <dbl>     <dbl> <chr>     <int> <lgl>    <chr>
#> 1 Cg_R1     0.576          4.5      6.5     1.000 rolli…        5 FALSE    roll…
#> 2 Cg_R2     0.560          4.5      6.5     1.000 rolli…        5 FALSE    roll…
#> 3 Cg_R3     0.571          4.5      6.5     0.999 rolli…        5 FALSE    roll…
#> 4 CgFlu_R1  0.403          4.5      6.5     1.000 rolli…        5 FALSE    roll…
#> 5 CgFlu_R2  0.407          4.5      6.5     1.000 rolli…        5 FALSE    roll…
#> 6 CgFlu_R3  0.403          4.5      6.5     1.000 rolli…        5 FALSE    roll…
#> 7 YPD_R1   NA             NA       NA      NA     rolli…        5 FALSE    roll…
#> 8 YPD_R2   NA             NA       NA      NA     rolli…        5 FALSE    roll…
#> 9 YPD_R3    0.00386       18       20       0.5   rolli…        5 FALSE    roll…
#> # ℹ 1 more variable: doubling_time <dbl>

sample_id <- unique(tidy_data$sample)[1]

fit <- fit_growth_curve(
  filter(tidy_data, sample == sample_id),
  model = "logistic"
)

extract_params(fit)
#> # A tibble: 1 × 6
#>   sample model    asymptote     r    t0 doubling_time_model
#>   <chr>  <chr>        <dbl> <dbl> <dbl>               <dbl>
#> 1 Cg_R1  logistic      2.03 0.777  6.97               0.892
plot_fitted_curve(fit)
```

<img src="man/figures/README-unnamed-chunk-15-2.png" alt="" width="100%" />

## Development status

The `tidy_v2` branch introduces tidy input handling and model fitting
while preserving legacy growth-rate logic through compatibility wrappers
where practical.

## Contributing and issues

Bug reports, feature requests, and suggestions are welcome at:

<https://github.com/sethiyap/growkar/issues>

## License

MIT License
