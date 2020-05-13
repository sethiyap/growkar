#' @title calculate_growthrate_from_defined_logphase
#' @description calculates growth rate and generation time from user-defined
#'   log-phase start and end time.
#' @param dat_growth_curve a tibble, with first column as `Time` and after that
#'   columns as samples. Samples should be named as `sampleName_replicate`, for
#'   example `CgFlu_R1` , `CgFlu_R2`, `CgFlu_R3`. If data does not contain
#'   replicates then sample name should be `CgFlu_R1`, `Cg_R1`, `YPD_R1` The
#'   function assumes that data contains OD values in increasing order.
#' @param logphase_tibble a tibble, containing pre-defined logphase start and
#'   end time point. It must contain three columns with first column of
#'   condition or sample and second and third column of start and end. The
#'   condition column must match with sample names of `dat_growth_curve`
#' @param average_replicates logical, to calculate growth rates as average of
#'   replicates, Default: FALSE
#' @param select_replicates  a vector, define replicates to be selected to plot,
#'   it should be anything after `_`. for eg. if only replicate R1 and R2 need
#'   to be plotted from samples CgFlu_R1, CgFlu_R2; the vector should be
#'   `c("R1", "R2")`, Default: NULL
#' @param cells_at_OD_1 numeric, a mutplication factor to use absolute cell
#'   number at OD=1, for instance OD600=1 represents 3e+07 yeast cells. Default: 3e+07
#' @return a tibble, containing growth rate (generation/hour) and generation
#'   time or doubling time (minutes/generation)
#' @details User defined start and end logphase time-points are used to compute
#'   growth_rate. For average of replicates, mean of OD and time-points is
#'   computed.
#' @examples
#' \dontrun{
#' if(interactive()){
#'
#'  # Load logphase start-end from local file
#'  logphase_dat <- system.file("extdata", "logphase_for_replicates.txt", package = "growkar")
#'  logphase_tibble <- readr::read_delim(logphase_dat, delim="\t", col_names = TRUE)
#'
#'  # Compute growth_rate
#'  calculate_growthrate_from_defined_logphase(dat_growth_curve = growkar::yeast_growth_data,logphase_tibble = logphase_tibble, average_replicates = TRUE)
#'
#'  }
#' }
#' @rdname calculate_growthrate_from_defined_logphase
#' @export
#' @importFrom dplyr rename mutate select pull left_join filter bind_cols
#'   group_by summarise
#' @importFrom tidyr gather separate
#' @importFrom forcats as_factor
calculate_growthrate_from_defined_logphase <- function(dat_growth_curve, logphase_tibble, average_replicates=FALSE, select_replicates=NULL,cells_at_OD_1=3e+07){

        multiplicative_factor <- log10(cells_at_OD_1)
        column1 <- dat_growth_curve %>% colnames() %>% .[1]

        dat_growth_curve <- dat_growth_curve %>%
                                dplyr::rename(Time= column1)

        dat_melt <- dat_growth_curve %>%
                                tidyr::gather(key="sample", value="OD", -Time) %>%
                                tidyr::separate(col = sample,into = c("condition","replicate"),sep="_") %>%
                                dplyr::mutate(condition=forcats::as_factor(condition))

        dat_colnames <- dat_growth_curve %>%
                              dplyr::select(-c(column1)) %>%
                              colnames()

         if(all(dat_colnames %in% (logphase_tibble %>%dplyr::pull(1)))){

          logphase_cols <- logphase_tibble %>% colnames()

          logphase_tibble <- logphase_tibble %>%
                                  dplyr::rename(condition=logphase_cols[1],
                                  start=logphase_cols[2], end=logphase_cols[3]) %>%
                                  tidyr::separate(col = condition,into = c("condition","replicate"),sep="_")

          min_logphase <- dat_melt %>%
                                  dplyr::left_join(logphase_tibble) %>%
                                  dplyr::select(-c("end")) %>%
                                  dplyr::filter(Time == start)

          max_logphase <- dat_melt %>%
                                dplyr::left_join(logphase_tibble) %>%
                                dplyr::select(-c("start")) %>%
                                dplyr::filter(Time == end)

          dat_melt <- dplyr::bind_cols(min_logphase, max_logphase)

        } else {

          stop("Column names from dat_growth_curve does not match with logphase_tibble conditions!!")

        }

        if(is.null(select_replicates)==FALSE){

            dat_melt <- dat_melt %>%
                        dplyr::filter(replicate %in% select_replicates)
        } else{

            dat_melt <- dat_melt

        }


        if(average_replicates==TRUE){

          summ_dat <- dat_melt %>%
                            dplyr::select(c(condition,start, end, OD, OD1)) %>%
                            dplyr::group_by(condition) %>%
                            dplyr::summarise(start=mean(start), end=mean(end),
                                             OD_start=mean(OD), OD_end=mean(OD1),
                                             time_diff=abs(end-start), OD_diff=abs(OD_end-OD_start)*multiplicative_factor) %>%
                           dplyr::mutate(growth_rate=OD_diff/time_diff, generation_time=(1/growth_rate)*60,
                                         start=round(start,3), end=round(end,3),
                                         growth_rate=round(growth_rate,3), generation_time=round(generation_time,3)) %>%
                            dplyr::select(c(condition, start, end, growth_rate, generation_time))

        } else{

          summ_dat <- dat_melt %>%
                            dplyr::select(c(condition,replicate, start, end, OD, OD1)) %>%
                            dplyr::mutate(time_diff=abs(end-start), OD_diff=abs(OD1-OD)*multiplicative_factor) %>%
                            dplyr::mutate(growth_rate=OD_diff/time_diff, generation_time=(1/growth_rate)*60,
                                          growth_rate=round(growth_rate,3), generation_time=round(generation_time,3)) %>%
                            dplyr::select(c(condition, replicate, start, end, growth_rate, generation_time))

        }

        return(summ_dat)

}
