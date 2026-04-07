# R/plot_utils.R — shared Plotly helpers and expand-modal logic

library(shiny)
library(bslib)
library(plotly)

# ---------- Shared hover label style ----------
ODC_HL <- list(
  bgcolor     = "#1f2937",
  bordercolor = "transparent",
  font        = list(family = "'Inter', sans-serif", color = "#fff", size = 12)
)

# ---------- Transparent-background Plotly layout with Inter font ----------
odc_layout <- function(p, ...) {
  p %>%
    layout(
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor  = "rgba(0,0,0,0)",
      font          = list(family = "'Inter', sans-serif", color = "#4b5563"),
      ...
    ) %>%
    config(displayModeBar = FALSE)
}

# ---------- Expand button for plot card headers ----------
make_exp_btn <- function(ns, pid) {
  actionButton(ns(paste0("exp_", pid)),
               label = NULL,
               icon  = icon("expand", lib = "font-awesome"),
               class = "btn-plot-expand",
               title = "Open larger")
}

# ---------- Full-screen modal with PNG download ----------
show_expand_modal <- function(plot_out_id, title_str, filename) {
  showModal(modalDialog(
    title = div(
      style = "display:flex; align-items:center; gap:16px; width:100%;",
      div(style = "font-weight:800; color:#1C2D5C; font-size:1.10rem; flex:1; min-width:0;",
          title_str),
      tags$button(
        type    = "button",
        class   = "btn btn-outline-primary btn-sm",
        style   = "flex-shrink:0; border-radius:18px; font-weight:600; display:inline-flex; align-items:center; gap:5px;",
        onclick = sprintf(
          "(function(){var el=document.getElementById('%s');if(el&&window.Plotly)Plotly.downloadImage(el,{format:'png',width:1400,height:800,scale:2,filename:'%s'});})();",
          plot_out_id, gsub("[^a-zA-Z0-9]", "-", filename)
        ),
        bs_icon("download"), "PNG"
      ),
      tags$button(type = "button", class = "btn-close",
                  `data-bs-dismiss` = "modal", `aria-label` = "Close",
                  style = "flex-shrink:0;")
    ),
    footer    = NULL,
    easyClose = FALSE,
    size      = "xl",
    plotlyOutput(plot_out_id, height = "72vh")
  ))
}
