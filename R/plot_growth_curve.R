


dat_growth_curve <- readr::read_delim(pipe("pbpaste"), delim="\t",col_names = TRUE)


#' plot_growth_curve
#'
#' @param dat_growth_curve
#' @param average_replicates
#'
#' @return
#' @export
#'
#' @examples
#'
plot_growth_curve <- function(dat_growth_curve, average_replicates=FALSE){

        library(magrittr)

         dat_melt <- dat_growth_curve %>%
                          tidyr::gather(key="sample", value="OD", -Time) %>%
                          tidyr::separate(col = sample,into = c("condition","replicate"),sep="_")

  if (average_replicates==TRUE){

    summ_dat <- dat_melt %>%
                    dplyr::mutate(condition=forcats::as_factor(condition)) %>%
                    dplyr::group_by(.dots = c("Time", "condition"))  %>%
                    dplyr::mutate(sd = sd(OD), mean=mean(OD)) %>%
                    dplyr::filter(replicate==min(replicate)) %>%
                    dplyr::select(-c(replicate))


    gg_growth <- ggplot2::ggplot(summ_dat,ggplot2::aes(Time, mean, color=condition)) +
                    ggplot2::geom_point()+
                    ggplot2::geom_line(lwd=0.8)+
                    ggplot2::geom_errorbar(ggplot2::aes(ymin=mean-sd, ymax=mean+sd),
                                  width=.2,position=ggplot2::position_dodge(0.05))
  }

        else{

          summ_dat <- dat_melt %>%
                      dplyr::mutate(condition=forcats::as_factor(condition))

          gg_growth <- ggplot2::ggplot(summ_dat,ggplot2::aes(Time, OD, color=condition))+
                          ggplot2::geom_point()+
                          ggplot2::geom_line(lwd=0.8)+
                          ggplot2::facet_grid(~replicate)+
                          ggplot2::ylab("OD600")

        }

         gg_growth <- gg_growth +
                      ggplot2::theme(panel.grid = ggplot2::element_blank(),axis.text = ggplot2::element_text(color="black", size=12))+
                      ggplot2::theme_bw()+
                      ggplot2::xlab("Time (in hours)")

         return(gg_growth)



}
