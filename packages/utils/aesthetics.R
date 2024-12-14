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
    # Dependencies
    box::use(
        ggplot2[element_blank, element_line, element_rect, element_text, margin, theme],
    )

    theme(
        axis.text = element_text(color = "#d1d5db", size = 9),
        axis.text.x = element_text(margin = margin(5, 0, 5, 0)),
        axis.text.y = element_text(margin = margin(0, 5, 0, 5)),
        axis.ticks = element_line(color = "#fff", linewidth = 0.1),
        axis.title = element_text(color = "#fff", size = 10),
        legend.background = element_blank(),
        legend.position = if (show_legend) "right" else "none",
        legend.text = element_text(color = "#d1d5db"),
        legend.title = element_text(color = "#fff"),
        panel.background = element_blank(),
        panel.border = element_rect(fill = NA, color = "#e5e7eb91", linewidth = 0.2),
        panel.grid.major = element_line(color = "#e5e7eb54", linetype = 2, linewidth = 0.1),
        panel.grid.minor = element_line(color = "#e5e7eb54", linetype = 2, linewidth = 0.1),
        plot.background = element_rect(fill = "#030712", linewidth = 0),
        plot.caption = element_text(color = "#d1d5db", size = 8),
        plot.margin = margin(5, 15, 5, 10),
        plot.subtitle = element_text(color = "#d1d5db", size = 10, margin = margin(0, 0, 10, 0)),
        plot.title = element_text(color = "#fff", face = "bold", size = 14, margin = margin(5, 0, 5, 0)),
        strip.background = element_rect(fill = "#1d1f27", color = "#e5e7eb91", linewidth = 0.1),
        strip.text = element_text(color = "#fff")
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
