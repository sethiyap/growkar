#' @title select_palette
#' @description allows to select contrasting colors from 8 different palettes
#'   contributing a total of 74 colors
#' @param num_of_colors numeric, number of colors to be obtained from palette
#' @param palette_name character,name palettes Default: 'all_colors'
#'   Supported individual palettes are:
#'   \itemize{
#'   \item `Accent` (8)
#'   \item `Dark2` (8)
#'   \item `Paired` (12)
#'   \item `Pastel1` (9)
#'   \item `Pastel2` (8)
#'   \item `Set1` (9)
#'   \item `Set2` (8)
#'   \item `Set3` (12)
#'   }
#' @return a vector of colors from selected palette
#' @details select_palette is particularly useful as individual palette from
#'   many color palettes contain less than 10 colors. The palettes themselves
#'   come from [grDevices::palette.colors()], which ships with R, so no colour
#'   package is needed.
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
select_palette <- function(num_of_colors, palette_name = "all_colors") {
  palettes <- growkar_qualitative_palettes()

  requested <- if (identical(palette_name, "all_colors")) {
    names(palettes)
  } else {
    intersect(names(palettes), palette_name)
  }

  color_vector <- unlist(
    lapply(requested, function(name) {
      grDevices::palette.colors(
        n = palettes[[name]]$n,
        palette = palettes[[name]]$grDevices_name
      )
    }),
    use.names = FALSE
  )

  color_vector[seq_len(min(num_of_colors, length(color_vector)))]
}

# The qualitative palettes are those carried by grDevices, which are identical
# to the ColorBrewer qualitative sets of the same names. `select_palette()`
# keeps the compact `Dark2`-style spelling as its public argument; the names
# under which `grDevices::palette.colors()` knows them are spelled with a space.
growkar_qualitative_palettes <- function() {
  list(
    Accent = list(grDevices_name = "Accent", n = 8L),
    Dark2 = list(grDevices_name = "Dark 2", n = 8L),
    Paired = list(grDevices_name = "Paired", n = 12L),
    Pastel1 = list(grDevices_name = "Pastel 1", n = 9L),
    Pastel2 = list(grDevices_name = "Pastel 2", n = 8L),
    Set1 = list(grDevices_name = "Set 1", n = 9L),
    Set2 = list(grDevices_name = "Set 2", n = 8L),
    Set3 = list(grDevices_name = "Set 3", n = 12L)
  )
}
