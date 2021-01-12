#' @title calculate_growth_rate
#' @description calculates growth rate and generation time by computing the
#'   log-phase start and end time.
#' @param dat_growth_curve a tibble, with first column as `Time` and after that
#'   columns as samples. Samples should be named as `sampleName_replicate`, for
#'   example `CgFlu_R1` , `CgFlu_R2`, `CgFlu_R3`. If data does not contain
#'   replicates then sample name should be `CgFlu_R1`, `Cg_R1`, `YPD_R1` The
#'   function assumes that data contains OD values in increasing order.
#' @param average_replicates logical, to calculate growth rates as average of
#'   replicates, Default: FALSE
#' @param first_timepoint numeric, first time-point from where to calculate the
#'   lag-phase;, Default: 0
#' @param select_replicates a vector, define replicates to be selected to plot,
#'   it should be anything after `_`. for eg. if only replicate R1 and R2 need
#'   to be plotted from samples CgFlu_R1, CgFlu_R2; the vector should be
#'   `c("R1", "R2")`, Default: NULL
#' @param end_timepoint numeric, end time-point to be considered. Specifically
#'   useful for appropriate growth curve calculation when the stationary phase
#'   OD is very fluctuating.  Default:NULL (end-timepoint from data)
#' @return a tibble, containing growth rate (generation/hour) and generation
#'   time or doubling time (minutes/generation)
#' @details Start and End-point are computed as; Start time-point: is time at
#'   which OD is appx double of the first-time point and end time-point: is time
#'   from which stationary phase is beginning.
#' @examples
#' \dontrun{
#' if(interactive()){
#'
#'  calculate_growth_rate(dat_growth_curve=yeast_growth_data, average_replicates = TRUE, select_replicates = c("R1", "R2", "R4"))
#'
#'   }
#' }
#' @rdname calculate_growth_rate
#' @export
#' @importFrom tidyr gather separate
#' @importFrom dplyr mutate filter group_by select rename left_join slice
#'   summarise bind_cols all_of
#' @importFrom forcats as_factor
#' @import magrittr
calculate_growth_rate <- function(dat_growth_curve, average_replicates=FALSE, first_timepoint=0, select_replicates=NULL, end_timepoint=NULL){

  column1 <- dat_growth_curve %>% colnames() %>% .[1]

  dat_growth_curve <- dat_growth_curve %>%
    dplyr::rename(Time= dplyr::all_of(column1))

  if(is.null(end_timepoint)==FALSE){
    dat_growth_curve <- dat_growth_curve %>%
      dplyr::filter(Time <= end_timepoint)
  }
  else{
    dat_growth_curve <- dat_growth_curve
  }

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
      dplyr::slice(which.min(abs(OD - (min)*2))) %>% # find the point most near to double of min OD
      dplyr::rename(Time1=Time, condition1=condition, OD1=OD)

    max_point <- min_logphase %>%
                    dplyr::select(condition1, OD1) %>%
                    dplyr::rename(condition=condition1)

    max_logphase <- summ_dat %>%
                      dplyr::left_join(max_point) %>%
                      dplyr::group_by(condition) %>%
                      dplyr::slice(which.min(abs(OD - (OD1)*2))) %>%
                      dplyr::select(Time, condition, OD) %>%
                      dplyr::rename(Time2=Time, OD2=OD)

    growth_rate_dat <- dplyr::bind_cols(max_logphase, min_logphase) %>%
                            dplyr::mutate(Time1=ifelse(Time1>Time2, 0,Time1),
                                          Time2=ifelse(Time2 <= Time1,0,Time2)) %>%
                            dplyr::summarise(time_diff=abs(Time2-Time1), OD_diff=2.303*(log10(OD2)-log10(OD1))) %>%
                            dplyr::mutate(growth_rate=OD_diff/time_diff, generation_time=(log10(2)/growth_rate)*60)

    logphase_summ <- dplyr::bind_cols(max_logphase,min_logphase) %>%
                            dplyr::mutate(Time1=ifelse(Time1>Time2, 0,Time1),
                                          Time2=ifelse(Time2 <= Time1,0,Time2 )) %>%
                            dplyr::select(c(condition, Time2, Time1)) %>%
                            dplyr::rename(time1=Time1, time2=Time2, condition1=condition)

    growth_rate_summ <- dplyr::bind_cols(logphase_summ,growth_rate_dat) %>%
                                dplyr::select(c(condition1,time1,time2,growth_rate,generation_time)) %>%
                                dplyr::mutate(growth_rate=round(growth_rate,3),generation_time=round(generation_time,3))%>%
                                dplyr::rename(condition=condition1)
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
      dplyr::slice(which.min(abs(OD - (min)*2))) %>%
      dplyr::rename(Time1=Time, condition1=condition, replicate1=replicate, OD1=OD)

    max_point <- min_logphase %>%
      dplyr::select(condition1, replicate1, OD1,) %>%
      dplyr::rename(condition=condition1)

    max_logphase <- dat_melt %>%
      dplyr::left_join(max_point) %>%
      dplyr::group_by(condition, replicate) %>%
      dplyr::slice(which.min(abs(OD - (OD1)*2))) %>%
      dplyr::select(Time, condition, OD) %>%
      dplyr::rename(Time2=Time, OD2=OD)


    growth_rate_dat <- dplyr::bind_cols(max_logphase, min_logphase) %>%
      dplyr::mutate(Time1=ifelse(Time1>Time2, 0,Time1),
                    Time2=ifelse(Time2 <= Time1,0,Time2 )) %>%
      dplyr::summarise(time_diff=abs(Time2-Time1), OD_diff=2.303*(log10(OD2)-log10(OD1))) %>%
      dplyr::mutate(growth_rate=OD_diff/time_diff, generation_time=(log10(2)/growth_rate)*60)

    logphase_summ <- dplyr::bind_cols(max_logphase, min_logphase) %>%
      dplyr::mutate(Time1=ifelse(Time1>Time2, 0,Time1),
                    Time2=ifelse(Time2 <= Time1,0,Time2 )) %>%
      dplyr::select(c(condition,replicate,  Time1,Time2)) %>%
      dplyr::rename(time1=Time1, time2=Time2, condition1=condition, replicate1=replicate)

    growth_rate_summ <- dplyr::bind_cols(logphase_summ,growth_rate_dat) %>%
      dplyr::select(c(condition1,replicate1, time1,time2,growth_rate,generation_time))%>%
      dplyr::mutate(growth_rate=round(growth_rate,3),generation_time=round(generation_time,3) )
  }

  return(growth_rate_summ)
}

