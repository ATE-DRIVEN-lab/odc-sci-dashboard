# app.R

library(shiny)
library(bslib)
library(plotly)
library(DT)
library(dplyr)
library(stringr)
library(bsicons)
library(writexl)
library(jsonlite)

# ---- Source all modules ----
source("R/assets.R")
source("R/column_meta.R")
source("R/data_loader.R")
source("R/data_cleaner.R")
source("R/utils.R")
source("R/plot_utils.R")
source("R/filters.R")
source("R/cards.R")
source("R/chart_builders.R")
source("R/mod_sidebar.R")
source("R/mod_loading.R")
source("R/mod_overview.R")
source("R/mod_charts.R")
source("R/mod_about.R")

# ---- Navbar brand ----
navbar_brand <- div(
  class = "navbar-brand",
  style = "display:flex; align-items:center; gap:0; width:360px; min-width:360px; padding:0;",

  tags$img(
    class = "odc-app-logo odc-app-logo--navbar",
    src   = LOGO_SRC,
    alt   = ""
  ),
  div(
    class = "brand-text-block",
    style = "margin-left:12px;",
    tags$span("ODC\u2013SCI", class = "brand-title"),
    tags$span("Public Data Sets", class = "brand-sub")
  )
)

# ---- UI ----
ui <- page_navbar(
  id       = "main_nav",
  fillable = FALSE,
  theme    = theme_odc_safe,
  sidebar  = sidebar_ui(),
  title    = navbar_brand,
  header   = tagList(
    tags$head(odc_local_assets),
    loading_overlay_ui()
  ),

  # KPI block
  nav_item(
    div(
      class = "navbar-kpi-block navbar-kpi-nav-item",
      span("DATASETS", class = "navbar-kpi-label"),
      uiOutput("kpi_datasets_val", inline = TRUE),
      span("SUBJECTS",  class = "navbar-kpi-label"),
      uiOutput("kpi_subjects_val",  inline = TRUE)
    )
  ),

  nav_panel("Search",         value = "Dashboard",      icon = icon("table-cells", lib = "font-awesome"),  mod_overview_ui("overview")),
  nav_panel("Visualizations", value = "Visualizations", icon = icon("chart-bar", lib = "font-awesome"),    mod_charts_ui("charts")),
  nav_panel("About",          value = "About",          icon = icon("circle-info", lib = "font-awesome"),  mod_about_ui("about"))
)

# ---- SERVER ----
server <- function(input, output, session) {

  # ── Load on startup: try GitHub first, fall back to local cache ──
  .init <- load_initial_data()
  raw_public_rv <- reactiveVal(.init$public)
  raw_dict_rv   <- reactiveVal(.init$dict)
  rm(.init)

  # ── Hourly auto-refresh from GitHub ──
  github_timer <- reactiveTimer(3600000)   # 1 hour in ms

  observeEvent(github_timer(), {
    fetched <- refresh_from_github()
    if (!is.null(fetched$public)) raw_public_rv(fetched$public)
    if (!is.null(fetched$dict))   raw_dict_rv(fetched$dict)
  }, ignoreInit = TRUE)

  # ── Cleaned dataset ──
  pd_clean <- reactive({
    req(raw_public_rv())
    clean_public_data(raw_public_rv())
  })

  # ── Sidebar: dynamic UIs + filters reactive ──
  filters_debounced <- sidebar_server(pd_clean, input, output, session)

  # ── Navbar KPIs ──
  observeEvent(list(raw_public_rv(), pd_clean()), {
    output$kpi_datasets_val <- renderUI({
      raw <- raw_public_rv()
      n_raw <- if (is.null(raw)) 0L else nrow(raw)
      d     <- pd_clean()
      if (is.null(d) || nrow(d) == 0)
        return(div(class = "navbar-kpi-row",
                   span(format(n_raw, big.mark = ","), class = "navbar-kpi-value")))

      yr_vals <- d$Year[!is.na(d$Year)]
      curr_yr <- if (length(yr_vals)) max(yr_vals) else NA_integer_
      new_n   <- if (!is.na(curr_yr)) sum(d$Year == curr_yr, na.rm = TRUE) else 0L

      div(class = "navbar-kpi-row",
        span(format(n_raw, big.mark = ","), class = "navbar-kpi-value"),
        if (new_n > 0) span(paste0("+", new_n, " in ", curr_yr), class = "navbar-kpi-delta")
      )
    })

    output$kpi_subjects_val <- renderUI({
      d <- pd_clean()
      if (is.null(d) || nrow(d) == 0)
        return(div(class = "navbar-kpi-row", span("\u2014", class = "navbar-kpi-value")))
      yr_vals <- d$Year[!is.na(d$Year)]
      curr_yr <- if (length(yr_vals)) max(yr_vals) else NA_integer_
      new_s   <- if (!is.na(curr_yr)) sum(d$SubjectNbrs[!is.na(d$Year) & d$Year == curr_yr], na.rm = TRUE) else 0
      div(class = "navbar-kpi-row",
        span(format(sum(d$SubjectNbrs, na.rm = TRUE), big.mark = ","), class = "navbar-kpi-value"),
        if (new_s > 0) span(paste0("+", format(new_s, big.mark = ","), " in ", curr_yr), class = "navbar-kpi-delta")
      )
    })
  }, ignoreInit = FALSE)

  # ── Show/hide sidebar based on active tab ──
  observeEvent(input$main_nav, {
    session$sendCustomMessage("setSidebarVisibility",
                              list(hidden = input$main_nav %in% c("About")))
  }, ignoreInit = FALSE, ignoreNULL = TRUE)

  # ── Module servers ──
  mod_overview_server("overview",  pd_raw = pd_clean, filters = filters_debounced,
                      dict_raw = raw_dict_rv)
  mod_charts_server("charts",      pd_raw = pd_clean, filters = filters_debounced)
  mod_about_server("about")
}

shinyApp(ui, server)
