# growkar 0.99.2

Changes made in response to the Bioconductor package review (issue #4227).

## Single class system (S4)

* Added the S4 class `GrowthExperiment`, which extends
  `SummarizedExperiment` with a validity method enforcing the canonical
  growth-assay layout. It is now the only data container in the package.
* Removed the `growkar_data` S3 class and its constructor `as_growkar()`, along
  with the `setOldClass()`/`setAs()` pair used to coerce it. It duplicated the
  container constructor and was the source of the S3/S4 tension noted in review.
* Replaced `as_summarized_experiment()` with the S4 constructor
  `GrowthExperiment()` and standard coercion `as(x, "GrowthExperiment")`. The
  constructor carries a `metrics` argument, preserving the only capability that
  was unique to `as_growkar()`. `as(x, "SummarizedExperiment")` is available in
  the other direction.
* Converted the `growkar_fit` S3 class to the formal S4 class `GrowthFit`, with
  a validity method, `show()`, `summary()`, `coef()`, `fitted()`,
  `residuals()`, and `nobs()` methods, and the new accessors `fit_sample()`,
  `fit_model()`, `fit_status()`, `fit_converged()`, and `fit_data()`.
* `extract_params()` and `augment_growth_fit()` are now S4 generics with
  methods for `GrowthFit`.
* The package now defines no S3 classes and registers no S3 methods.

## Dependency separation

* Moved `ggplot2` and `RColorBrewer` from `Imports` to `Suggests`. The
  data-structure and analysis layers install and run without a graphics stack;
  the `plot_*()` functions check for the suggested packages at call time and
  raise an informative error when they are unavailable.

## tidyomics interoperability

* Added `tidySummarizedExperiment` to `Suggests` and documented tidy
  manipulation and display of `growkar` objects through the tidyomics stack
  rather than reimplementing those transformations.
* Repositioned `as_tidy_growth_data()` explicitly as an import adapter for
  vendor plate-reader exports, which tidyomics does not cover.
* Fixed a malformed code chunk in the introductory vignette.

# growkar 0.99.0

* Refactored the package around `SummarizedExperiment` as the canonical data
  model for microbial growth phenotyping workflows.
* Added SE-native accessor and analysis helpers, including
  `growth_assay()`, `timepoints()`, `sample_data()`, `growth_metrics()`,
  `phase_windows()`, and `fit_growth_models()`.
* Standardized metadata conventions for derived summaries, exponential-phase
  windows, model fits, and analysis parameters stored in `metadata(se)`.
* Updated core analysis and plotting functions so tidy and wide inputs are
  standardized into the canonical `SummarizedExperiment` representation before
  downstream analysis.
* Added `plot_growth_curve_facets()` for averaged, sample-family faceted growth
  curve visualization in multi-sample datasets.
* Reworked the README, vignette, examples, and package metadata to present
  `growkar` as a Bioconductor-native package for high-throughput microbial
  growth phenotyping.
