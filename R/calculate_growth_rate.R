#' @title calculate_growth_rate
#' @description calculates growth rate and generation time by computing the
#'   log-phase start and end time.
#' @param dat_growth_curve a tibble, with first column as `Time` and after that
#'   columns as samples. If the samples have replicates mention them as
#'   `sampleName_replicate`, for example `CgFlu_R1` , `CgFlu_R2`, `CgFlu_R3`
#' @param average_replicates logical, to plot average and standard deviation of
#'   replicates, Default: FALSE
#' @param first_timepoint numeric, first time-point from where to calculate the
#'   lag-phase;, Default: 0
#' @param select_replicates a vector, define replicates to be selected to plot,
#'   it should be anything after `_`. for eg. if only replicate R1 and R2 need
#'   to be plotted from samples CgFlu_R1, CgFlu_R2; the vector should be
#'   `c("R1", "R2")`, Default: NULL
#' @param cells_at_OD_1 numeric, a mutplication factor to use absolute cell
#'   number at OD=1, for instance OD600=1 represents 3e+07 yeast cells. Default:
#'   3e+07
#' @return a table with growth rate (generations/hour) and generation time
#'   (minutes/generation)
#' @details Start and End-point are computed as; Start time-point: is time at which OD is appx
#'   double of the first-time point and end time-point: is time from which stationary
#'   phase is beginning.
#' @examples
#' \dontrun{
#' if(interactive()){
#'
#'  calculate_growth_rate(dat_growth_curve=yeast_growth_data, average_replicates = TRUE, select_replicates = c("R1", "R2", "R4"))
#'
#'   }
#' }
#' @seealso \code{\link[tidyr]{gather}},\code{\link[tidyr]{separate}}
#'   \code{\link[dplyr]{mutate}},\code{\link[dplyr]{filter}},\code{\link[dplyr]{group_by}},\code{\link[dplyr]{select}},\code{\link[dplyr]{join}},\code{\link[dplyr]{slice}},\code{\link[dplyr]{summarise}},\code{\link[dplyr]{bind}}
#'    \code{\link[forcats]{as_factor}}
#' @rdname calculate_growth_rate
#' @export
#' @importFrom tidyr gather separate
#' @importFrom dplyr mutate filter group_by select rename left_join slice
#'   summarise bind_cols
#' @importFrom forcats as_factor
#' @import magrittr
calculate_growth_rate <- function(dat_growth_curve, average_replicates=FALSE, first_timepoint=0, select_replicates=NULL, cells_at_OD_1=3e+07){

  dat_melt <- dat_growth_curve %>%
                            tidyr::gather(key="sample", value="OD", -Time) %>%
                            tidyr::separate(col = sample,into = c("condition","replicate"),sep="_") %>%
                            dplyr::mutate(condition=forcats::as_factor(condition))

        if(is.null(select_replicates)==FALSE){
                        dat_melt <- dat_melt %>%
                        dplyr::filter(replicate %in% select_replicates)
        }
        else{
          dat_melt <- dat_melt
        }

        multiplicative_factor <- log10(cells_at_OD_1)

  if(average_replicates==TRUE){

                summ_dat <- dat_melt %>%
                                    dplyr::group_by(.dots = c("Time", "condition"))  %>%
                                    dplyr::mutate( mean=mean(OD)) %>%
                                    dplyr::filter(replicate==min(replicate)) %>%
                                    dplyr::select(-c(replicate, OD)) %>%
                                    dplyr::rename(OD=mean)


              min_point   <- summ_dat %>%
                                        dplyr::group_by(condition) %>%
                                        dplyr::filter(Time==first_timepoint) %>%
                                        dplyr::rename(min=OD) %>%
                                        dplyr::select(-c(Time))

              min_logphase <- summ_dat %>%
                                        dplyr::left_join(min_point) %>%
                                        dplyr::group_by(condition) %>%
                                        dplyr::slice(which.min(abs(OD - (min)*2)))


              max_point   <- summ_dat %>%
                                        dplyr::group_by(condition) %>%
                                        dplyr::summarise(max = max(OD))


              max_logphase <- summ_dat %>%
                                        dplyr::left_join(max_point) %>%
                                        dplyr::group_by(condition) %>%
                                        dplyr::filter(OD >= floor(max*100)/100)  %>%
                                        dplyr::filter(Time==min(Time))



              growth_rate_dat <- dplyr::bind_cols(max_logphase, min_logphase) %>%
                                        dplyr::summarise(time_diff=abs(Time-Time1), OD_diff=abs(OD-OD1)*multiplicative_factor) %>%
                                        dplyr::mutate(growth_rate=OD_diff/time_diff, generation_time=(1/growth_rate)*60)

              logphase_summ <- dplyr::bind_cols(min_logphase,max_logphase) %>%
                                        dplyr::select(c(condition, Time, Time1)) %>%
                                        dplyr::rename(logphase_start=Time, logphase_end=Time1)

              growth_rate_summ <- dplyr::bind_cols(logphase_summ,growth_rate_dat) %>%
                                        dplyr::select(c(condition,logphase_start,logphase_end,growth_rate,generation_time)) %>%
                                        dplyr::mutate(growth_rate=round(growth_rate,3),generation_time=round(generation_time,3) )
  }

    else{
          min_point   <- dat_melt %>%
                              dplyr::group_by(condition, replicate) %>%
                              dplyr::filter(Time==first_timepoint) %>%
                              dplyr::rename(min=OD) %>%
                              dplyr::select(-c(Time))

          min_logphase <- dat_melt %>%
                              dplyr::left_join(min_point) %>%
                              dplyr::group_by(condition, replicate) %>%
                              dplyr::slice(which.min(abs(OD - (min)*2)))


          max_point   <- dat_melt %>%
                              dplyr::group_by(condition, replicate) %>%
                              dplyr::summarise(max = max(OD))

          max_logphase <- dat_melt %>%
                              dplyr::left_join(max_point) %>%
                              dplyr::group_by(condition, replicate) %>%
                              dplyr::filter(OD >= floor(max*100)/100)  %>%
                              dplyr::filter(Time==min(Time))

          growth_rate_dat <- dplyr::bind_cols(max_logphase, min_logphase) %>%
                                dplyr::summarise(time_diff=abs(Time-Time1), OD_diff=abs(OD-OD1)*multiplicative_factor) %>%
                                dplyr::mutate(growth_rate=OD_diff/time_diff, generation_time=(1/growth_rate)*60)

          logphase_summ <- dplyr::bind_cols(min_logphase,max_logphase) %>%
                                dplyr::select(c(condition,replicate, Time, Time1)) %>%
                                dplyr::rename(logphase_start=Time, logphase_end=Time1)

          growth_rate_summ <- dplyr::bind_cols(logphase_summ,growth_rate_dat) %>%
                                dplyr::select(c(condition,replicate, logphase_start,logphase_end,growth_rate,generation_time))%>%
                                dplyr::mutate(growth_rate=round(growth_rate,3),generation_time=round(generation_time,3) )
    }

  return(growth_rate_summ)
}

