#' Optical Density (OD600) of growing yeast cells
#'
#' A dataset containing the time-interval and OD600 of growing yeast cells recorded upto 24 hours.
#'
#' @format A data frame with 49 rows and 6 variables:
#' \describe{
#'   \item{Time}{Time, time-interval at which OD600 was recorded}
#'   \item{Cg_R1, Cg_R2, Cg_R3}{Optical Density (OD600) of yeast cells, at each time-interval}
#'   \item{CgFlu_R1, CgFlu_R2, CgFlu_R3}{Optical Density (OD600) of yeast cells treated with fluconazole, at each time-interval}
#'   \item{YPD_R1, YPD_R2, YPD_R3}{Optical Density (OD600) of medium without cells as control, at each time-interval}
#'   ...
#' }
"yeast_growth_data"
