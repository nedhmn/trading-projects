# ---------------------------------------------------------------------------- #
# File: src\utils.R
# Description: Global utilities
# ---------------------------------------------------------------------------- #

#' nedhmn_theme
#'
#' @description
#' Custom ggplot2 theme for nedhmn.me
#'
#' @param show_legend Boolean on whether to show the legend
#'
#' @export
nedhmn_theme <- function(show_legend = FALSE) {
    ggplot2::theme(
        axis.text = ggplot2::element_text(color = "#d1d5db", size = 9),
        axis.text.x = ggplot2::element_text(margin = ggplot2::margin(5, 0, 5, 0)),
        axis.text.y = ggplot2::element_text(margin = ggplot2::margin(0, 5, 0, 5)),
        axis.ticks = ggplot2::element_line(color = "#fff", linewidth = 0.1),
        axis.title = ggplot2::element_text(color = "#fff", size = 10),
        legend.background = ggplot2::element_blank(),
        legend.position = if (show_legend) "right" else "none",
        legend.text = ggplot2::element_text(color = "#d1d5db"),
        legend.title = ggplot2::element_text(color = "#fff"),
        panel.background = ggplot2::element_blank(),
        panel.border = ggplot2::element_rect(fill = NA, color = "#e5e7eb91", linewidth = 0.2),
        panel.grid.major = ggplot2::element_line(color = "#e5e7eb54", linetype = 2, linewidth = 0.1),
        panel.grid.minor = ggplot2::element_line(color = "#e5e7eb54", linetype = 2, linewidth = 0.1),
        plot.background = ggplot2::element_rect(fill = "#030712", linewidth = 0),
        plot.caption = ggplot2::element_text(color = "#d1d5db", size = 8),
        plot.margin = ggplot2::margin(5, 15, 5, 10),
        plot.subtitle = ggplot2::element_text(color = "#d1d5db", size = 10, margin = ggplot2::margin(0, 0, 10, 0)),
        plot.title = ggplot2::element_text(color = "#fff", face = "bold", size = 14, margin = ggplot2::margin(5, 0, 5, 0)),
        strip.background = ggplot2::element_rect(fill = "#1d1f27", color = "#e5e7eb91", linewidth = 0.1),
        strip.text = ggplot2::element_text(color = "#fff")
    )
}

#' nedhmn_palette
#'
#' @description
#' Color palette for ggplot2 series to go
#' with nedhmn.me
#'
#' @export
nedhmn_palette <- c("#14b8a6", "#A614B8", "#B8A614", "#B81414")
