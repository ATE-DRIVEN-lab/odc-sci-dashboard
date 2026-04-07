# R/mod_about.R

mod_about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(
      style = "max-width: 1100px; padding-bottom: 40px; margin: 0 auto;",
      div(
        # Hero card
        div(
          class = "bento-card bento-primary",
          style = "margin-bottom:20px; padding:36px 40px;",
          div(style = "display:flex; align-items:center; gap:18px; margin-bottom:22px;",
              tags$img(
                class = "odc-app-logo odc-app-logo--about",
                src   = LOGO_SRC,
                alt   = ""
              ),
              div(
                div(style = "font-size:1.98rem; font-weight:900; color:#fff; letter-spacing:-0.5px; line-height:1;",
                    "ODC\u2013SCI Dashboard"),
                div(style = "font-size:1.10rem; color:rgba(255,255,255,0.68); margin-top:5px;",
                    "Open Data Commons - Spinal Cord Injury")
              )
          ),
          div(
            style = "font-size:1.16rem; color:rgba(255,255,255,0.82); line-height:1.7; max-width:760px;",
            "This dashboard provides overview to publicly available datasets
             submitted to ODC-SCI."
          ),
          div(class = "bento-icon-bg", bs_icon("database"))
        ),

        # Two-column features row
        layout_columns(
          col_widths = c(6, 6),
          style = "margin-bottom:20px;",

          div(class = "bento-card bento-light",
              div(class = "bento-header",
                  span(class = "bento-title", "Search & Filter",
                       style = "color:#1C2D5C;"),
                  bs_icon("funnel-fill", style = "color:#427c98; font-size:1.54rem;")),
              div(style = "font-size:0.99rem; color:#4b5563; line-height:1.65;",
                  "Filter datasets by publication year, species, sex, injury model, anatomical
                   level, intervention, keywords, and funders. The sidebar updates all tabs
                   simultaneously."),
              div(class = "bento-icon-bg", bs_icon("funnel-fill"))
          ),

          div(class = "bento-card bento-light",
              div(class = "bento-header",
                  span(class = "bento-title", "Visualizations",
                       style = "color:#1C2D5C;"),
                  bs_icon("bar-chart-line-fill", style = "color:#72c02c; font-size:1.54rem;")),
              div(style = "font-size:0.99rem; color:#4b5563; line-height:1.65;",
                  "Interactive charts track datasets published over time, subject counts,
                   species and sex distributions."),
              div(class = "bento-icon-bg", bs_icon("bar-chart-line-fill"))
          )
        ),

        # Data info card
        div(class = "bento-card bento-light", style = "margin-bottom:20px;",
            div(class = "bento-header",
                span(class = "bento-title", "About the Data", style = "color:#1C2D5C;"),
                bs_icon("database-fill", style = "color:#427c98; font-size:1.54rem;")),
            layout_columns(
              div(style = "font-size:0.99rem; color:#4b5563; line-height:1.7;",
                  tags$p(tags$strong("Source: "), "Maintained by the ODC\u2013SCI curation team."),
                  tags$p(tags$strong("Coverage: "), "All publicly released datasets submitted to ODC\u2013SCI,
                         spanning clinical and pre-clinical spinal cord injury research.")
              ),
            ),
            div(class = "bento-icon-bg", bs_icon("database-fill"))
        ),

        # Links & contact
        div(class = "bento-card bento-light",
            div(class = "bento-header",
                span(class = "bento-title", "Learn More", style = "color:#1C2D5C;"),
                bs_icon("link-45deg", style = "color:#427c98; font-size:1.54rem;")),
            div(style = "display:flex; flex-wrap:wrap; gap:10px;",
                tags$a(href = "https://odc-sci.org", target = "_blank",
                       class = "btn btn-outline-primary btn-sm",
                       style = "border-radius:18px; font-weight:600;",
                       bs_icon("house-fill"), " ODC\u2013SCI Website"),
                tags$a(href = "https://odc-sci.org/about/about-us", target = "_blank",
                       class = "btn btn-outline-secondary btn-sm",
                       style = "border-radius:18px; font-weight:600;",
                       bs_icon("info-circle-fill"), " About ODC\u2013SCI"),
                tags$a(href = "https://atespin.github.io/", target = "_blank",
                       class = "btn btn-outline-secondary btn-sm",
                       style = "border-radius:18px; font-weight:600;",
                       bs_icon("journal-code"), " health.data DRIVEN Lab"),
                tags$a(href = "https://github.com/ATE-DRIVEN-lab/odc-sci-public-data", target = "_blank",
                       class = "btn btn-outline-primary btn-sm",
                       style = "border-radius:18px; font-weight:600;",
                       bs_icon("database-fill"), " Public Data"),
                tags$a(href = "https://github.com/ATE-DRIVEN-lab/odc-sci-dashboard", target = "_blank",
                       class = "btn btn-outline-success btn-sm",
                       style = "border-radius:18px; font-weight:600;",
                       bs_icon("github"), " Source Code"),
                tags$a(href = "https://github.com/ATE-DRIVEN-lab/odc-sci-dashboard/issues", target = "_blank",
                       class = "btn btn-outline-danger btn-sm",
                       style = "border-radius:18px; font-weight:600;",
                       bs_icon("bug"), " Report an Issue")
            ),
            div(class = "bento-icon-bg", bs_icon("link-45deg"))
        ),

      )
    )
  )
}

mod_about_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # No server logic needed
  })
}
