#' @title select_palette
#' @description allows to select contrasting colors from 8 different palettes
#'   contributing a total of 75 colors
#' @param num_of_colors numeric, number of colors to be obtained from palette
#' @param palette_name character,name palettes Default: 'all_colors'
#' For individual palette;
#'  \itemize{
#'  \item {Accent: }{8}
#'  \item {Dark2: }{8}
#'  \item {Paired: }{12}
#'  \item {Pastel1: }{9}
#'  \item {Pastel2: }{8}
#'  \item {Set1: }{9}
#'  \item {Set2: }{8}
#'  \item {Set3: }{12} }
#' @return a vector of colors from selected palette
#' @details select_palette is particularly useful as individual palette from
#'   many color brewer packages contain less than 10 colors
#' @examples
#' \dontrun{
#' if(interactive()){
#'  # colors combined from all palettes
#'  select_palette(num_of_colors = 10)
#'
#'  # colors from Accent palette
#'  select_palette(num_of_colors = 4, palette_name = "Accent")
#'  }
#' }
#' @keywords internal
#' @importFrom RColorBrewer brewer.pal.info brewer.pal
#' @importFrom tibble rownames_to_column as_tibble
#' @importFrom dplyr filter mutate select slice pull
#' @importFrom purrr map2
#' @importFrom tidyr unnest
select_palette <- function(num_of_colors, palette_name="all_colors"){

    color_tibble <- RColorBrewer::brewer.pal.info %>%
                        tibble::rownames_to_column("rn") %>%
                        tibble::as_tibble() %>%
                        dplyr::filter(category== "qual") %>%
                        dplyr::mutate(colors = purrr::map2(maxcolors, rn, ~ RColorBrewer::brewer.pal(..1, ..2))) %>%
                        tidyr::unnest(colors)

    if(palette_name == "all_colors"){

          color_vector <- color_tibble %>%
                            dplyr::select(colors) %>% dplyr::slice(1:num_of_colors) %>%
                            dplyr::pull()
    }
    else{

        color_vector <- color_tibble %>%
                          dplyr::filter(rn %in% palette_name) %>%
                          dplyr::select(colors) %>% dplyr::slice(1:num_of_colors) %>%
                          dplyr::pull()

    }

    return(color_vector)

}
