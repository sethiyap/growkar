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
* Reworked the README, vignette, examples, and package metadata to present
  `growkar` as a Bioconductor-native package for high-throughput microbial
  growth phenotyping.
