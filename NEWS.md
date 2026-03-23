# growkar 0.99.0

* Development version for tidy-v2 adds stronger input validation, more robust
  empirical growth summaries, safer model-fitting diagnostics, and improved
  Bioconductor-oriented package metadata and documentation.
* Plotting, fitted-curve visualization, and summary workflows gain cleaner
  replicate handling and more explicit palette/documentation support.
* Added `SummarizedExperiment` coercion so tidy growth data can interoperate
  with Bioconductor-style containers without replacing the tibble-first API.
* Removed the legacy wrapper API so the current tidy workflow is the only
  supported interface.
