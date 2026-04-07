# R/mod_charts.R

mod_charts_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(style = "margin-bottom:20px;",
        h4("Data Visualizations",
           style = "font-weight:800; color:#1C2D5C; margin-bottom:8px; font-size:1.10rem; text-transform:uppercase; letter-spacing:0.5px;")),

    # Row 1
    layout_columns(
      col_widths = c(6, 6),
      div(class = "bento-card bento-light", style = "height:460px;",
          div(class = "bento-header",
              div(class = "bento-header-left",
                bs_icon("graph-up", style = "color:#427c98; font-size:1.21rem;"),
                span(class = "bento-title", "Published Datasets Overview", style = "color:#1C2D5C;")),
              make_exp_btn(ns, "p_ds_both")),
          plotlyOutput(ns("p_ds_both"), height = "calc(100% - 44px)")
      ),
      div(class = "bento-card bento-light", style = "height:460px;",
          div(class = "bento-header",
              div(class = "bento-header-left",
                bs_icon("tags", style = "color:#619bb8; font-size:1.21rem;"),
                span(class = "bento-title", "Unique Keywords Overview", style = "color:#1C2D5C;")),
              make_exp_btn(ns, "p_kw_both")),
          plotlyOutput(ns("p_kw_both"), height = "calc(100% - 44px)")
      )
    ),

    # Row 2
    div(style = "margin-top:20px;",
        layout_columns(
          col_widths = c(6, 6),
          div(class = "bento-card bento-light", style = "height:440px;",
              div(class = "bento-header",
                  div(class = "bento-header-left",
                    bs_icon("people", style = "color:#427c98; font-size:1.21rem;"),
                    span(class = "bento-title", "Total Subjects by Year", style = "color:#1C2D5C;")),
                  make_exp_btn(ns, "p_subjects_year")),
              plotlyOutput(ns("p_subjects_year"), height = "calc(100% - 44px)")
          ),
          div(class = "bento-card bento-light", style = "height:440px;",
              div(class = "bento-header",
                  div(class = "bento-header-left",
                    bs_icon("grid", style = "color:#427c98; font-size:1.21rem;"),
                    span(class = "bento-title", "Species & Sex Distribution", style = "color:#1C2D5C;")),
                  make_exp_btn(ns, "p_species_sex")),
              plotlyOutput(ns("p_species_sex"), height = "calc(100% - 44px)")
          )
        )
    ),

    # Row 3
    div(style = "margin-top:20px;",
        layout_columns(
          col_widths = c(6, 6),
          div(class = "bento-card bento-light", style = "height:480px;",
              div(class = "bento-header",
                  div(class = "bento-header-left",
                    bs_icon("activity", style = "color:#427c98; font-size:1.21rem;"),
                    span(class = "bento-title", "Injury Type & Anatomical Level", style = "color:#1C2D5C;")),
                  make_exp_btn(ns, "p_injury_grouped")),
              plotlyOutput(ns("p_injury_grouped"), height = "calc(100% - 44px)")
          ),
          div(class = "bento-card bento-light", style = "height:480px;",
              div(class = "bento-header",
                  div(class = "bento-header-left",
                    bs_icon("collection", style = "color:#427c98; font-size:1.21rem;"),
                    span(class = "bento-title", "Dataset Types over Time", style = "color:#1C2D5C;")),
                  make_exp_btn(ns, "p_type_cum")),
              plotlyOutput(ns("p_type_cum"), height = "calc(100% - 44px)")
          )
        )
    )
  )
}

.plot_titles <- c(
  p_ds_both        = "Published Datasets Overview",
  p_kw_both        = "Unique Keywords Overview",
  p_subjects_year  = "Total Subjects by Year",
  p_species_sex    = "Species & Sex Distribution",
  p_injury_grouped = "Injury Type & Anatomical Level",
  p_type_cum       = "Dataset Types over Time"
)

mod_charts_server <- function(id, pd_raw, filters) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    pd <- reactive({
      req(pd_raw())
      apply_filters(pd_raw(), filters())
    })

    # ── Main outputs ─────────────────────────────────────────────
    output$p_ds_both        <- renderPlotly(mk_ds_both(pd()))
    output$p_kw_both        <- renderPlotly(mk_kw_both(pd(), isTRUE(filters()$ignore_na_keywords)))
    output$p_type_cum       <- renderPlotly(mk_type_cum(pd()))
    output$p_subjects_year  <- renderPlotly(mk_subjects_year(pd()))
    output$p_species_sex    <- renderPlotly(mk_species_sex(pd()))
    output$p_injury_grouped <- renderPlotly(mk_injury_grouped(pd()))

    # ── Expand modal ─────────────────────────────────────────────
    rv <- reactiveValues(pid = NULL)

    lapply(names(.plot_titles), function(pid) {
      observeEvent(input[[paste0("exp_", pid)]], {
        rv$pid <- pid
        show_expand_modal(
          plot_out_id = ns("modal_plot"),
          title_str   = .plot_titles[pid],
          filename    = .plot_titles[pid]
        )
      }, ignoreInit = TRUE)
    })

    output$modal_plot <- renderPlotly({
      req(rv$pid)
      switch(rv$pid,
        p_ds_both        = mk_ds_both(pd()),
        p_kw_both        = mk_kw_both(pd(), isTRUE(filters()$ignore_na_keywords)),
        p_subjects_year  = mk_subjects_year(pd()),
        p_species_sex    = mk_species_sex(pd()),
        p_injury_grouped = mk_injury_grouped(pd()),
        p_type_cum       = mk_type_cum(pd())
      )
    })
  })
}
