# growkar 0.99.4

* The introductory vignette no longer guards its plotting chunks with a flag
  defined in an earlier chunk. `R CMD build` also tangles each vignette, and
  during tangling the chunk code is not evaluated, so `eval = has_graphics`
  could not be resolved and reported an error for every guarded chunk. The
  `ggplot2` availability check is now written inline in the chunk options,
  which resolves both when the vignette is woven and when it is tangled.

# growkar 0.99.3

Changes made in response to the second round of Bioconductor package review
(issue #4227).

## Reuse of existing Bioconductor infrastructure

* Added `BiocBaseUtils` to `Imports` and replaced the package's own helpers
  with its equivalents.
* Removed the internal `growkar_require_suggested()`. The `plot_*()` functions
  and `select_palette()` now check their optional graphics dependencies with
  `BiocBaseUtils::checkInstalled()`.
* Removed the internal `growkar_numeric_or_na()`. Scalar arguments are now
  validated with `BiocBaseUtils::isScalarNumber()`,
  `BiocBaseUtils::isScalarCharacter()`, and `BiocBaseUtils::isTRUEorFALSE()`
  in `as_tidy_growth_data()`, `detect_exponential_phase()`,
  `compute_growth_rate()`, `summarize_growth_metrics()`,
  `validate_growth_data()`, `validate_growth_experiment()`, and the
  `store_metadata` arguments of `growth_metrics()`, `phase_windows()`, and
  `fit_growth_models()`.
* `validate_growth_data()` no longer coerces `min_points_per_sample` with
  `as.integer()`; a non-scalar or non-numeric value is now an error.

## Removed code that duplicated available functionality

* `select_palette()` no longer assembles its palettes from `RColorBrewer`. The
  eight qualitative palettes it offers are shipped by base R and are returned by
  [grDevices::palette.colors()] with identical colour values, so `RColorBrewer`
  has been dropped from `Suggests` altogether. The `plot_*()` functions now
  check only for `ggplot2`, and `palette_name` still accepts the same names
  (`"Dark2"`, `"Set1"`, and so on).
* Each analysis result is now written to `metadata()` under exactly one key.
  `fit_growth_models()` previously stored its fits and parameters twice (as
  `model_fits`/`growth_model_fits` and `model_parameters`/
  `growth_model_parameters`), and every analysis duplicated its settings into
  both `analysis_params` and its own `*_parameters` entry. The `model_fits`,
  `model_parameters`, and `analysis_params` keys have been removed; the
  documented `growth_*` and `exponential_phase_*` keys are unchanged.
* `validate_growth_experiment()` now calls `methods::validObject()` instead of
  repeating the checks already performed by the `GrowthExperiment` validity
  method. It checks only the finiteness requirement that the class itself does
  not impose.
* Replaced the superseded `purrr::map_dfr()` with `purrr::list_rbind()` at all
  six call sites.

## No coercion on the user's behalf

* `SummarizedExperiment` input must now carry numeric time values in
  `rowData(se)$time`. The previous fallback, which silently coerced assay row
  names (or the tidyomics `.feature` labels) to numeric, has been removed; the
  error message shows how to set the column explicitly. Coercion of character
  values is now confined to `as_tidy_growth_data()`, the import adapter for
  vendor plate-reader exports, where non-numeric entries are expected and
  dropped rows are reported with a warning.

## tidySummarizedExperiment conventions

* Removed the internal `growkar_tidy_from_summarized_experiment()`. Conversion
  of a `GrowthExperiment` to long form is now a short adapter over
  `tidySummarizedExperiment`'s own `as_tibble()` output, reading the `.feature`
  and `.sample` labels directly.
* `as_tidy_growth_data()` recognises `.sample` and `.feature` as column
  aliases, so tibbles obtained from a `SummarizedExperiment` with the tidyomics
  verbs can be passed back to `growkar` unchanged.
* Removed the `loadNamespace()` call on `tidySummarizedExperiment`, which is an
  `Imports` dependency. Its namespace, and therefore its `as_tibble()` method,
  is now loaded through a regular `importFrom()` directive. The vignette no
  longer guards the tidyomics section behind an availability check.

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
