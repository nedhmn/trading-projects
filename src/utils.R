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
nedhmn_theme <- function(show_legend = FALSE) {
    # Dependencies
    box::use(
        ggplot2[theme],
    )

    theme(
        plot.title = element_text(color = "#fff"),
        plot.subtitle = element_text(color = "#d1d5db"),
        plot.background = element_rect(fill = "#030712", linewidth = 0),
        panel.background = element_blank(),
        panel.grid.major = element_line(color = "#e5e7eb54", linewidth = 0.1),
        panel.grid.minor = element_line(color = "#e5e7eb54", linewidth = 0.1),
        axis.line = element_line(color = "#e5e7eb54", linewidth = 0.1),
        axis.ticks = element_line(color = "#e5e7eb54", linewidth = 0.1),
        axis.title = element_text(color = "#fff"),
        axis.text = element_text(color = "#d1d5db"),
        legend.background = element_blank(),
        legend.title = element_text(color = "#fff"),
        legend.text = element_text(color = "#d1d5db"),
        legend.position = if (show_legend) "right" else "none"
    )
}
