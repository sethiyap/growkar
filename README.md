
<!-- README.md is generated from README.rmd. Please edit that file -->

# growkar <img src="hexasticker.jpg" align="right" height="180" alt="growkar hex sticker" />

`growkar` is an R package for microbial growth curve analysis from
optical density (OD) time-series data. It provides a tidy workflow for
converting input data, validating growth measurements, plotting growth
curves, estimating growth rate and doubling time, detecting exponential
phase, and fitting logistic or Gompertz growth models.

The package keeps the feel of the original `growkar` workflow while
introducing a tidyverse-friendly v2 design built around canonical input
columns: `sample`, `time`, and `od`.

## Installation

``` r
remotes::install_github("sethiyap/growkar")
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
p <- plot_growth_curve(tidy_data, average_replicates = TRUE)
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
  facet_col = "replicate"
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

sample_id <- unique(tidy_data$sample)[1]

gr <- compute_growth_rate(
  filter(tidy_data, sample == sample_id),
  method = "rolling_window"
)

gr
#> # A tibble: 1 × 6
#>   sample    mu start_time end_time r_squared method        
#>   <chr>  <dbl>      <dbl>    <dbl>     <dbl> <chr>         
#> 1 Cg_R1  0.576        4.5      6.5     1.000 rolling_window
```

## Compute doubling time

**What it does:** `compute_doubling_time()` calculates doubling time
from growth rate as `log(2) / mu`.

**Why use it:** It converts the estimated growth rate into a more
biologically interpretable measure of growth kinetics.

**Minimal example:**

``` r
compute_doubling_time(gr$mu)
#> [1] 1.204352
```

## Summarize growth metrics across samples

**What it does:** `summarize_growth_metrics()` computes growth rate and
doubling time across all samples.

**Why use it:** It is useful for comparing strains, conditions, or
replicates in one tidy summary table.

**Minimal example:**

``` r
metrics <- summarize_growth_metrics(tidy_data)
metrics
#> # A tibble: 9 × 7
#>   sample          mu start_time end_time r_squared method         doubling_time
#>   <chr>        <dbl>      <dbl>    <dbl>     <dbl> <chr>                  <dbl>
#> 1 Cg_R1     5.76e- 1        4.5      6.5     1.000 rolling_window          1.20
#> 2 Cg_R2     5.60e- 1        4.5      6.5     1.000 rolling_window          1.24
#> 3 Cg_R3     5.71e- 1        4.5      6.5     0.999 rolling_window          1.21
#> 4 CgFlu_R1  4.03e- 1        4.5      6.5     1.000 rolling_window          1.72
#> 5 CgFlu_R2  4.07e- 1        4.5      6.5     1.000 rolling_window          1.70
#> 6 CgFlu_R3  4.03e- 1        4.5      6.5     1.000 rolling_window          1.72
#> 7 YPD_R1   -2.78e-16       22       24       0.670 rolling_window         NA   
#> 8 YPD_R2   -2.78e-16       22       24       0.670 rolling_window         NA   
#> 9 YPD_R3    3.86e- 3       18       20       0.5   rolling_window        179.
```

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

phase_tbl
#> # A tibble: 45 × 4
#>    start_time end_time slope r_squared
#>         <dbl>    <dbl> <dbl>     <dbl>
#>  1        4.5      6.5 0.576     1.000
#>  2        4        6   0.551     0.997
#>  3        5        7   0.551     0.997
#>  4        3.5      5.5 0.490     0.990
#>  5        5.5      7.5 0.490     0.991
#>  6        6        8   0.414     0.987
#>  7        3        5   0.409     0.985
#>  8        6.5      8.5 0.334     0.983
#>  9        2.5      4.5 0.321     0.975
#> 10        7        9   0.260     0.973
#> # ℹ 35 more rows
```

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
#> $model
#> [1] "logistic"
#> 
#> $fit
#> Nonlinear regression model
#>   model: od ~ K/(1 + exp(-r * (time - t0)))
#>    data: data
#>      K      r     t0 
#> 2.0271 0.7772 6.9688 
#>  residual sum-of-squares: 0.06883
#> 
#> Algorithm "port", convergence message: relative convergence (4)
#> 
#> $coefficients
#>         K         r        t0 
#> 2.0271408 0.7772492 6.9688283 
#> 
#> $fitted
#> # A tibble: 49 × 2
#>     time .fitted
#>    <dbl>   <dbl>
#>  1   0   0.00897
#>  2   0.5 0.0132 
#>  3   1   0.0194 
#>  4   1.5 0.0285 
#>  5   2   0.0417 
#>  6   2.5 0.0610 
#>  7   3   0.0887 
#>  8   3.5 0.128  
#>  9   4   0.183  
#> 10   4.5 0.259  
#> # ℹ 39 more rows
#> 
#> $data
#> # A tibble: 49 × 5
#>    sample  time    od condition replicate
#>    <chr>  <dbl> <dbl> <chr>     <chr>    
#>  1 Cg_R1    0   0.115 Cg        R1       
#>  2 Cg_R1    0.5 0.116 Cg        R1       
#>  3 Cg_R1    1   0.118 Cg        R1       
#>  4 Cg_R1    1.5 0.121 Cg        R1       
#>  5 Cg_R1    2   0.126 Cg        R1       
#>  6 Cg_R1    2.5 0.136 Cg        R1       
#>  7 Cg_R1    3   0.149 Cg        R1       
#>  8 Cg_R1    3.5 0.172 Cg        R1       
#>  9 Cg_R1    4   0.206 Cg        R1       
#> 10 Cg_R1    4.5 0.258 Cg        R1       
#> # ℹ 39 more rows
#> 
#> $converged
#> [1] TRUE
#> 
#> $sample
#> [1] "Cg_R1"
#> 
#> $message
#> NULL
#> 
#> attr(,"class")
#> [1] "growkar_fit"
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

<img src="man/figures/README-unnamed-chunk-14-1.png" alt="" width="100%" />

``` r

metrics <- summarize_growth_metrics(tidy_data)
metrics
#> # A tibble: 9 × 7
#>   sample          mu start_time end_time r_squared method         doubling_time
#>   <chr>        <dbl>      <dbl>    <dbl>     <dbl> <chr>                  <dbl>
#> 1 Cg_R1     5.76e- 1        4.5      6.5     1.000 rolling_window          1.20
#> 2 Cg_R2     5.60e- 1        4.5      6.5     1.000 rolling_window          1.24
#> 3 Cg_R3     5.71e- 1        4.5      6.5     0.999 rolling_window          1.21
#> 4 CgFlu_R1  4.03e- 1        4.5      6.5     1.000 rolling_window          1.72
#> 5 CgFlu_R2  4.07e- 1        4.5      6.5     1.000 rolling_window          1.70
#> 6 CgFlu_R3  4.03e- 1        4.5      6.5     1.000 rolling_window          1.72
#> 7 YPD_R1   -2.78e-16       22       24       0.670 rolling_window         NA   
#> 8 YPD_R2   -2.78e-16       22       24       0.670 rolling_window         NA   
#> 9 YPD_R3    3.86e- 3       18       20       0.5   rolling_window        179.

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

<img src="man/figures/README-unnamed-chunk-14-2.png" alt="" width="100%" />

## Development status

The `tidy_v2` branch introduces tidy input handling and model fitting
while preserving legacy growth-rate logic through compatibility wrappers
where practical.

## Contributing and issues

Bug reports, feature requests, and suggestions are welcome at:

<https://github.com/sethiyap/growkar/issues>

## License

MIT License
