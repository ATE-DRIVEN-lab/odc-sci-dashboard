# R/mod_sidebar.R — sidebar filter panel UI + server logic

library(shiny)
library(bslib)
library(bsicons)
library(stringr)
library(dplyr)

# ---------- UI ----------
sidebar_ui <- function() {
  sidebar(
    width = 360,
    open  = "desktop",

    div(
      style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:14px;",
      span(
        bs_icon("sliders"), " Filters",
        style = "font-weight:800; color:#1C2D5C; font-size:1.05rem;"
      ),
      actionButton("reset_filters", "Reset",
                   icon  = icon("rotate-right"),
                   class = "btn-sm",
                   style = "border-radius:16px; color:#ef4444; background:rgba(254,226,226,0.85); border:none; font-weight:700; font-size:0.83rem; padding:4px 10px;")
    ),

    accordion(
      open     = c("Study Metrics", "Subject Details", "Injury & Intervention", "Keywords & Funding"),
      multiple = TRUE,

      # ---- Study Metrics ----
      accordion_panel(
        "Study Metrics", icon = icon("chart-simple", lib = "font-awesome"),

        uiOutput("year_range_ui"),
        uiOutput("subject_range_ui"),

        div(class = "fi-card",
            div(class = "fi-label", bs_icon("collection"), "Dataset Type"),
            uiOutput("dataset_type_ui"))
      ),

      # ---- Subject Details + Anatomical Level ----
      accordion_panel(
        "Subject Details", icon = icon("paw", style = "color:#427c98;"),
        div(style = "display:flex; gap:12px; align-items:flex-start;",
          # LEFT: Species + Sex stacked
          div(style = "flex:1; min-width:0;",
            div(class = "fi-label", bs_icon("cursor"), "Species"),
            uiOutput("species_ui"),
            div(class = "fi-label", style = "margin-top:10px;", bs_icon("gender-ambiguous"), "Sex"),
            uiOutput("sex_ui")
          ),
          # RIGHT: Anatomical Level SVG
          div(style = "flex:1; min-width:0;",
            div(style = "display:flex; align-items:center; justify-content:space-between; margin-bottom:4px;",
              div(class = "fi-label", style = "margin-bottom:0;", bs_icon("geo-alt"), "Anatomical Level"),
              tags$button(id = "spine-all-btn", type = "button", class = "custom-pill active",
                          style = "font-size:0.75rem; padding:2px 9px; border-radius:12px;", "All")
            ),
            HTML('
            <div id="spine-wrapper" style="margin-bottom:6px;">
              <div id="spine-tooltip" class="spine-tooltip"></div>
              <svg viewBox="0 0 400 1100" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
                <defs>
                  <path id="cv" d="M -22 -10 C -18 -15, 18 -15, 22 -10 L 25 5 C 20 10, 10 15, 0 15 L -10 15 C -20 10, -25 5, -22 -10 Z"/>
                  <path id="th" d="M -28 -14 C -22 -20, 22 -20, 28 -14 L 32 8 C 28 15, 15 20, 0 20 L -15 20 C -28 15, -32 8, -28 -14 Z"/>
                  <path id="lb" d="M -34 -18 C -26 -25, 26 -25, 34 -18 L 40 12 C 35 20, 20 28, 0 28 L -20 28 C -35 20, -40 12, -34 -18 Z"/>
                </defs>
                <text x="338" y="90"  font-size="22" fill="#9ca3af" font-weight="800" font-family="Inter">C</text>
                <text x="308" y="320" font-size="22" fill="#9ca3af" font-weight="800" font-family="Inter">T</text>
                <text x="338" y="730" font-size="22" fill="#9ca3af" font-weight="800" font-family="Inter">L</text>
                <text x="338" y="930" font-size="22" fill="#9ca3af" font-weight="800" font-family="Inter">S</text>
                <g transform="translate(200,50)">
                  <g class="spine-region" data-level="cervical">
                    <use xlink:href="#cv" class="spine-vert turquoise" transform="translate(0,0) rotate(0) scale(1.0)"/>
                    <use xlink:href="#cv" class="spine-vert turquoise" transform="translate(5,26) rotate(5) scale(1.02)"/>
                    <use xlink:href="#cv" class="spine-vert turquoise" transform="translate(12,53) rotate(10) scale(1.04)"/>
                    <use xlink:href="#cv" class="spine-vert turquoise" transform="translate(18,81) rotate(12) scale(1.06)"/>
                    <use xlink:href="#cv" class="spine-vert turquoise" transform="translate(22,110) rotate(10) scale(1.08)"/>
                    <use xlink:href="#cv" class="spine-vert turquoise" transform="translate(20,140) rotate(5) scale(1.1)"/>
                    <use xlink:href="#cv" class="spine-vert turquoise" transform="translate(12,171) rotate(0) scale(1.12)"/>
                  </g>
                  <g class="spine-region" data-level="thoracic" transform="translate(12,210)">
                    <use xlink:href="#th" class="spine-vert turquoise" transform="translate(0,0) rotate(-5) scale(1.0)"/>
                    <use xlink:href="#th" class="spine-vert turquoise" transform="translate(-10,35) rotate(-10) scale(1.01)"/>
                    <use xlink:href="#th" class="spine-vert turquoise" transform="translate(-24,71) rotate(-15) scale(1.02)"/>
                    <use xlink:href="#th" class="spine-vert turquoise" transform="translate(-38,108) rotate(-18) scale(1.03)"/>
                    <use xlink:href="#th" class="spine-vert turquoise" transform="translate(-50,146) rotate(-20) scale(1.04)"/>
                    <use xlink:href="#th" class="spine-vert turquoise" transform="translate(-58,185) rotate(-18) scale(1.05)"/>
                    <use xlink:href="#th" class="spine-vert turquoise" transform="translate(-62,224) rotate(-15) scale(1.06)"/>
                    <use xlink:href="#th" class="spine-vert turquoise" transform="translate(-60,263) rotate(-10) scale(1.07)"/>
                    <use xlink:href="#th" class="spine-vert turquoise" transform="translate(-52,302) rotate(-5) scale(1.08)"/>
                    <use xlink:href="#th" class="spine-vert turquoise" transform="translate(-38,340) rotate(0) scale(1.09)"/>
                    <use xlink:href="#th" class="spine-vert turquoise" transform="translate(-20,378) rotate(5) scale(1.1)"/>
                    <use xlink:href="#th" class="spine-vert turquoise" transform="translate(2,415) rotate(10) scale(1.11)"/>
                  </g>
                  <g class="spine-region" data-level="lumbar" transform="translate(14,665)">
                    <use xlink:href="#lb" class="spine-vert turquoise" transform="translate(0,0) rotate(15) scale(1.0)"/>
                    <use xlink:href="#lb" class="spine-vert turquoise" transform="translate(18,42) rotate(18) scale(1.01)"/>
                    <use xlink:href="#lb" class="spine-vert turquoise" transform="translate(38,85) rotate(15) scale(1.02)"/>
                    <use xlink:href="#lb" class="spine-vert turquoise" transform="translate(50,130) rotate(5) scale(1.03)"/>
                    <use xlink:href="#lb" class="spine-vert turquoise" transform="translate(55,175) rotate(-5) scale(1.04)"/>
                  </g>
                  <g class="spine-region" data-level="sacral" transform="translate(69,885)">
                    <path class="spine-vert turquoise" d="M -44 -20 C -36 -28, 36 -28, 44 -20 L 25 35 L 5 80 L -5 80 L -25 35 Z" transform="scale(1.05) rotate(-20)"/>
                  </g>
                </g>
              </svg>
            </div>
            '),
            div(class = "checkbox-compact",
                style = "padding:4px 8px; background:#f8fafc; border-radius:8px; border:1px solid #e2e8f0; display:block; width:100%; box-sizing:border-box;",
                checkboxInput("na_injury_level",
                              tags$span(style = "font-size:0.79rem; font-weight:600; color:#475569;",
                                        "Include unknown"),
                              value = TRUE))
          )
        )
      ),

      # ---- Injury & Intervention ----
      accordion_panel(
        "Injury & Intervention", icon = icon("bolt", lib = "font-awesome"),

        uiOutput("injury_type_ui"),
        uiOutput("injury_device_ui"),
        uiOutput("intervention_ui")
      ),

      # ---- Keywords & Funding ----
      accordion_panel(
        "Keywords & Funding", icon = icon("tags", lib = "font-awesome"),
        uiOutput("keyword_ui"),
        div(class = "checkbox-compact",
            style = "margin-bottom:7px; padding:5px 10px; background:#f8fafc; border-radius:8px; border:1px solid #e2e8f0; display:inline-block; width:fit-content;",
            checkboxInput("ignore_na_keywords",
                          tags$span(style = "font-size:0.86rem; font-weight:600; color:#475569;",
                                    "Ignore NA Keywords"),
                          value = TRUE)),
        hr(style = "margin:10px 0; border-color:#1C2D5C; opacity:0.08;"),
        uiOutput("funder_ui")
      )
    )
  )
}

# ---------- Server ----------
sidebar_server <- function(pd_clean, input, output, session) {

  # Build dynamic UIs once data is ready
  observeEvent(pd_clean(), {
    d <- pd_clean()

    curr_yr <- as.integer(format(Sys.Date(), "%Y"))
    yr      <- d$Year[!is.na(d$Year)]
    min_yr  <- if (length(yr)) min(yr) else curr_yr - 5L
    max_yr  <- if (length(yr)) max(yr) else curr_yr
    output$year_range_ui <- renderUI({
      div(class = "fi-card",
        div(class = "fi-label", bs_icon("calendar3"), "Publication Year"),
        .make_bar_svg(yr, discrete = TRUE),
        range_slider("year_range", min = min_yr, max = max_yr,
                     value = c(min_yr, max_yr), step = 1))
    })

    sn     <- d$SubjectNbrs[!is.na(d$SubjectNbrs) & d$SubjectNbrs >= 1]
    max_sn <- if (length(sn)) ceiling(max(sn)) else 500L
    output$subject_range_ui <- renderUI({
      div(class = "fi-card",
        div(class = "fi-label", bs_icon("people"), "Subject Count (N)"),
        .make_bar_svg(sn, discrete = FALSE, n_bins = 25),
        range_slider("subject_range", min = 1L, max = max_sn,
                     value = c(1L, max_sn), step = 1))
    })

    output$dataset_type_ui <- renderUI({
      types <- sort(unique(na.omit(d$DatasetTyp)))
      all_p <- tags$div(class = "custom-pill active", `data-val` = "All",
                        tags$i(class = "fa fa-list"), "All")
      pills <- lapply(types, function(t) {
        ico <- if (t == "animal") tags$i(class = "fa fa-paw")
               else if (t == "clinical") tags$i(class = "fa fa-hospital-user")
               else tags$i(class = "fa fa-database")
        tags$div(class = "custom-pill", `data-val` = t, ico, str_to_title(t))
      })
      tags$div(id = "dataset-type-ui", class = "custom-selector",
               `data-shiny-input` = "dataset_type_custom",
               c(list(all_p), pills))
    })

    output$species_ui <- renderUI({
      sp <- sort(unique(str_trim(unlist(strsplit(as.character(na.omit(d$SpeciesTyp)), "\\s*;\\s*")))))
      sp <- sp[nzchar(sp) & !tolower(sp) %in% NA_STRINGS]
      all_p <- tags$div(class = "custom-pill species-tile active", `data-val` = "All",
                        tags$span(class = "tile-icon", tags$i(class = "fa fa-list")),
                        tags$span(class = "tile-caption", "All"))
      pills <- lapply(sp, function(s)
        tags$div(class = "custom-pill species-tile", `data-val` = s,
                 tags$span(class = "tile-icon", .get_species_icon(s)),
                 tags$span(class = "tile-caption", str_to_title(s))))
      tags$div(id = "species-ui", class = "custom-selector",
               `data-shiny-input` = "species_custom",
               c(list(all_p), pills))
    })

    output$sex_ui <- renderUI({
      sex_cats <- list(
        list(val = "female",  icon = "fa-venus",      label = "Female"),
        list(val = "male",    icon = "fa-mars",       label = "Male"),
        list(val = "mixed",   icon = "fa-venus-mars", label = "Mixed"),
        list(val = "unknown", icon = "fa-question",   label = "Unknown")
      )
      all_p <- tags$div(class = "custom-pill sex-tile active", `data-val` = "All",
                        tags$span(class = "tile-icon", tags$i(class = "fa fa-list")),
                        tags$span(class = "tile-caption", "All"))
      pills <- lapply(sex_cats, function(s)
        tags$div(class = "custom-pill sex-tile", `data-val` = s$val,
                 tags$span(class = "tile-icon", tags$i(class = paste("fa", s$icon))),
                 tags$span(class = "tile-caption", s$label))
      )
      tags$div(id = "sex-ui", class = "custom-selector",
               `data-shiny-input` = "sex_custom",
               c(list(all_p), pills))
    })

    output$injury_type_ui   <- renderUI({ render_smart_filter("injury_type",   "Injury Model / Type", sort(unique(split_multi(d$InjuryTyp)))) })
    output$injury_device_ui <- renderUI({ render_smart_filter("injury_device", "Injury Device",       sort(unique(split_multi(d$InjuryDevice)))) })
    output$intervention_ui  <- renderUI({ render_smart_filter("intervention",  "Intervention",        sort(unique(split_multi(d$InterventionTyp)))) })
    output$keyword_ui       <- renderUI({ render_smart_filter("keyword",       "Author Keywords",     sort(unique(split_multi(d$AuthorKeywords)))) })
    output$funder_ui        <- renderUI({ render_smart_filter("funder",        "Funders",             sort(unique(split_multi(d$Funders)))) })

  }, ignoreInit = FALSE)

  # Filters reactive
  filters <- reactive({
    list(
      year_range         = input$year_range,
      subject_range      = input$subject_range,
      dataset_type       = combine_filters(input$dataset_type_custom),
      species            = combine_filters(input$species_custom),
      sex                = combine_filters(input$sex_custom),
      injury_level       = combine_filters(input$injury_level_custom),
      injury_type        = combine_filters(input$injury_type_custom,   input$injury_type_search),
      injury_device      = combine_filters(input$injury_device_custom, input$injury_device_search),
      intervention       = combine_filters(input$intervention_custom,  input$intervention_search),
      keyword            = combine_filters(input$keyword_custom,       input$keyword_search),
      funder             = combine_filters(input$funder_custom,        input$funder_search),
      ignore_na_keywords = isTRUE(input$ignore_na_keywords),
      na_injury_level    = isTRUE(input$na_injury_level)
    )
  })

  # Reset handler
  observeEvent(input$reset_filters, {
    session$sendCustomMessage("resetAllPills", list())
    session$sendCustomMessage("clearTextSearch", list())
    updateSelectizeInput(session, "injury_type_search",   selected = character(0))
    updateSelectizeInput(session, "injury_device_search", selected = character(0))
    updateSelectizeInput(session, "intervention_search",  selected = character(0))
    updateSelectizeInput(session, "keyword_search",       selected = character(0))
    updateSelectizeInput(session, "funder_search",        selected = character(0))
    updateCheckboxInput(session, "ignore_na_keywords", value = TRUE)
    updateCheckboxInput(session, "na_injury_level",    value = TRUE)
    d <- pd_clean()
    if (!is.null(d)) {
      yr <- d$Year[!is.na(d$Year)]
      sn <- d$SubjectNbrs[!is.na(d$SubjectNbrs) & d$SubjectNbrs >= 1]
      if (length(yr)) session$sendCustomMessage("rangeReset", list(id = "year_range",    lo = min(yr),  hi = max(yr)))
      if (length(sn)) session$sendCustomMessage("rangeReset", list(id = "subject_range", lo = 1,        hi = ceiling(max(sn))))
    }
  })

  debounce(filters, DEBOUNCE_FILTERS_MS)
}
