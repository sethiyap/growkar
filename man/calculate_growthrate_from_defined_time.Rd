% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calculate_growthrate_from_defined_logphase.R
\name{calculate_growthrate_from_defined_time}
\alias{calculate_growthrate_from_defined_time}
\title{calculate_growthrate_from_defined_time}
\usage{
calculate_growthrate_from_defined_time(
  dat_growth_curve,
  logphase_tibble,
  average_replicates = FALSE,
  select_replicates = NULL
)
}
\arguments{
\item{dat_growth_curve}{a tibble, with first column as `Time` and after that
columns as samples. Samples should be named as `sampleName_replicate`, for
example `CgFlu_R1` , `CgFlu_R2`, `CgFlu_R3`. If data does not contain
replicates then sample name should be `CgFlu_R1`, `Cg_R1`, `YPD_R1` The
function assumes that data contains OD values in increasing order.}

\item{logphase_tibble}{a tibble, containing pre-defined logphase start and
end time point. It must contain three columns with first column of
condition or sample and second and third column of start and end. The
condition column must match with sample names of `dat_growth_curve`}

\item{average_replicates}{logical, to calculate growth rates as average of
replicates, Default: FALSE}

\item{select_replicates}{a vector, define replicates to be selected to plot,
it should be anything after `_`. for eg. if only replicate R1 and R2 need
to be plotted from samples CgFlu_R1, CgFlu_R2; the vector should be
`c("R1", "R2")`, Default: NULL}

\item{cells_at_OD_1}{numeric, a mutplication factor to use absolute cell
number at OD=1, for instance OD600=1 represents 3e+07 yeast cells. Default: 3e+07}
}
\value{
a tibble, containing growth rate (generation/hour) and generation
  time or doubling time (minutes/generation)
}
\description{
calculates growth rate and generation time from user-defined
  log-phase start and end time.
}
\details{
User defined start and end logphase time-points are used to compute
  growth_rate. For average of replicates, mean of OD and time-points is
  computed.
}
\examples{
\dontrun{
if(interactive()){

 # Load logphase start-end from local file
 logphase_dat <- system.file("extdata", "logphase_for_replicates.txt", package = "growkar")
 logphase_tibble <- readr::read_delim(logphase_dat, delim="\t", col_names = TRUE)

 # Compute growth_rate
 calculate_growthrate_from_defined_time(dat_growth_curve = growkar::yeast_growth_data,logphase_tibble = logphase_tibble, average_replicates = TRUE)

 }
}
}
