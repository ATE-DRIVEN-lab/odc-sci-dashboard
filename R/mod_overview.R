# R/mod_overview.R

mod_overview_ui <- function(id) {
  ns <- NS(id)

  div(class = "ov-layout",
    # ── Cards column ─────────────────────────────────────────────
    div(class = "ov-cards-col",
      div(
        id = "results-container",
        # Search bar
        div(
          class = "search-bar-wrapper",
          div(style = "display:flex; align-items:center; gap:6px;",
            div(class = "search-bar", style = "flex:1;",
              tags$span(bs_icon("search"), class = "search-bar-icon"),
              textInput(ns("text_search"), label = NULL, width = "100%",
                        placeholder = "Search by title, purpose, lab name, ODC ID\u2026"),
              tags$button(type = "button", class = "search-bar-clear btn btn-link",
                          bs_icon("x-circle-fill"))
            ),
            tags$span(class = "search-info-icon",
              `data-hint` = "Search: title \u00b7 purpose \u00b7 lab \u00b7 ODC ID \u2014 multiple words = AND logic \u2014 quotes for exact phrase: \u201clocomotor recovery\u201d",
              bs_icon("info-circle-fill"))
          ),
          div(class = "search-hint")
        ),
        # Summary KPI card — always visible
        uiOutput(ns("summary_card")),
        # Matched Records header
        div(
          style = "display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:6px; margin-bottom:14px;",
          div(style = "display:flex; align-items:center; gap:10px;",
            h4("Matched Records",
               style = "font-weight:800; color:#1C2D5C; margin:0; font-size:1.21rem; text-transform:uppercase; letter-spacing:0.5px; padding-left:4px;"),
            uiOutput(ns("matched_counts"), inline = TRUE)
          ),
          div(style = "display:flex; align-items:center; gap:6px;",
            local({
              lbl_id <- ns("sort_lbl")
              inp_id <- ns("sort_by")
              opts   <- list(
                list(val="year_desc",  txt="Year \u2193 newest"),
                list(val="year_asc",   txt="Year \u2191 oldest"),
                list(val="title_asc",  txt="Title A\u2013Z"),
                list(val="title_desc", txt="Title Z\u2013A"),
                list(val="subj_desc",  txt="Subjects \u2193"),
                list(val="odc_asc",    txt="ODC# \u2191")
              )
              div(class = "dropdown",
                tags$button(
                  type = "button",
                  class = "btn btn-outline-secondary btn-sm dropdown-toggle ov-ctrl",
                  `data-bs-toggle` = "dropdown",
                  bs_icon("sort-down-alt"),
                  tags$span(id = lbl_id, "Year \u2193 newest")
                ),
                div(class = "dropdown-menu dropdown-menu-end p-1",
                    style = "min-width:155px; font-size:0.90rem;",
                    lapply(opts, function(o)
                      tags$button(
                        class   = "dropdown-item rounded",
                        type    = "button",
                        style   = "padding:5px 10px;",
                        onclick = paste0(
                          "Shiny.setInputValue('", inp_id, "','", o$val,
                          "',{priority:'event'});",
                          "document.getElementById('", lbl_id,
                          "').textContent='", o$txt, "';"
                        ),
                        o$txt
                      )
                    )
                )
              )
            }),
            # Save dropdown
            div(class = "dropdown",
              tags$button(type = "button",
                class = "btn btn-outline-secondary btn-sm dropdown-toggle ov-ctrl",
                `data-bs-toggle` = "dropdown",
                bs_icon("download"), " Save"),
              div(class = "dropdown-menu dropdown-menu-end p-2",
                style = "min-width:185px; font-size:0.90rem;",
                tags$span(style = "display:block; font-size:0.74rem; font-weight:700; color:#94a3b8; text-transform:uppercase; padding:4px 8px 4px;",
                          "Filtered results"),
                downloadButton(ns("dl_filtered_csv"),
                  tagList(bs_icon("filetype-csv"), " CSV"),
                  class = "dropdown-item btn-sm"),
                downloadButton(ns("dl_filtered_excel"),
                  tagList(bs_icon("file-earmark-excel"), " Excel"),
                  class = "dropdown-item btn-sm"),
                tags$hr(class = "dropdown-divider my-1"),
                tags$span(style = "display:block; font-size:0.74rem; font-weight:700; color:#94a3b8; text-transform:uppercase; padding:4px 8px 4px;",
                          "Full list"),
                downloadButton(ns("dl_full_csv"),
                  tagList(bs_icon("filetype-csv"), " CSV"),
                  class = "dropdown-item btn-sm"),
                downloadButton(ns("dl_full_excel"),
                  tagList(bs_icon("file-earmark-excel"), " Excel"),
                  class = "dropdown-item btn-sm"),
                tags$hr(class = "dropdown-divider my-1"),
                actionButton(ns("open_dict_ov"), tagList(bs_icon("book-half"), " Dictionary"),
                  title = "Open Data Dictionary",
                  class = "dropdown-item btn-sm",
                  style = "font-weight:600;")
              )
            ),
            tags$button(
              type = "button",
              id = ns("expand_all_btn"),
              class = "btn btn-outline-secondary btn-sm ov-ctrl",
              onclick = "window._toggleAllCards(this)",
              bs_icon("arrows-expand"),
              tags$span(class = "ov-expand-lbl", " Expand all")
            )
          )
        ),
        # Dataset result cards + pagination
        uiOutput(ns("cards_pane"))
      )
    )
  )
}

mod_overview_server <- function(id, pd_raw, filters, dict_raw = NULL) {
  moduleServer(id, function(input, output, session) {

    PAGE_SIZE <- reactive({ 20L })

    page_num         <- reactiveVal(1)
    show_all         <- reactiveVal(FALSE)

    # Reset pagination on filter change
    observeEvent(filters(), {
      page_num(1)
      show_all(FALSE)
    }, ignoreInit = TRUE)

    # Unified page-jump handler 
    observeEvent(input$goto_page_js, {
      d <- pd()
      req(nrow(d) > 0)
      total_pages <- ceiling(nrow(d) / PAGE_SIZE())
      p <- as.integer(input$goto_page_js)
      if (!is.na(p) && p >= 1L && p <= total_pages) {
        page_num(p)
        session$sendCustomMessage("scrollToResults", list())
      }
    })

    observeEvent(input$show_all_btn,   { show_all(TRUE) })
    observeEvent(input$show_paged_btn, { show_all(FALSE); page_num(1) })

    # ---- Search: parse query into terms ----
    search_raw <- reactive({
      q <- trimws(input$text_search %||% "")
      if (!nzchar(q)) return(character(0))
      phrases   <- gsub('"', '', regmatches(q, gregexpr('"[^"]+"', q, perl = TRUE))[[1]])
      remaining <- trimws(gsub('"[^"]+"', ' ', q, perl = TRUE))
      words     <- Filter(nzchar, strsplit(remaining, "\\s+")[[1]])
      unique(c(phrases, words))
    })
    search_parsed <- debounce(search_raw, DEBOUNCE_SEARCH_MS)

    # Send term list to JS for search-bar chip display
    observeEvent(search_parsed(), {
      terms <- search_parsed()
      session$sendCustomMessage("applySearchHighlight",
        if (length(terms)) list(terms = as.list(terms), clear = FALSE)
        else                list(clear = TRUE))
    }, ignoreInit = TRUE)

    # Reset pagination when search changes
    observeEvent(search_parsed(), {
      page_num(1)
      show_all(FALSE)
    }, ignoreInit = TRUE)

    # ---- Filtered data ----
    pd <- reactive({
      req(pd_raw())
      d     <- apply_filters(pd_raw(), filters())
      terms <- search_parsed()
      if (length(terms)) d <- apply_smart_search(d, terms)

      switch(input$sort_by %||% "year_desc",
        year_desc  = { d <- d[order(-d$Year, na.last = TRUE), ] },
        year_asc   = { d <- d[order( d$Year, na.last = TRUE), ] },
        title_asc  = { d <- d[order( d$DatasetTitle,              na.last = TRUE), ] },
        title_desc = { d <- d[order( d$DatasetTitle, decreasing = TRUE, na.last = TRUE), ] },
        subj_desc  = { d <- d[order(-as.numeric(d$SubjectNbrs),   na.last = TRUE), ] },
        odc_asc    = { d <- d[order( suppressWarnings(as.numeric(d$ODCAccessionNbr)), na.last = TRUE), ] }
      )
      d
    }) |> bindCache(filters(), search_parsed(), input$sort_by %||% "year_desc", nrow(pd_raw()))

    # ---- Record detail drawer ----
    observeEvent(input$ov_card_clicked, {
      req(pd())
      idx <- suppressWarnings(as.integer(input$ov_card_clicked))
      req(length(idx) == 1L, !is.na(idx), idx >= 1L, idx <= nrow(pd()))
      row  <- pd()[idx, , drop = FALSE]
      html <- tryCatch(
        as.character(tagList(.build_drawer_content(
          row,
          if (is.function(dict_raw)) dict_raw() else NULL,
          show_head = FALSE,
          hl_terms  = search_parsed()
        ))),
        error = function(e) paste0(
          '<p style="color:#ef4444;padding:16px;">Error: ',
          htmltools::htmlEscape(conditionMessage(e)), '</p>'
        )
      )
      session$sendCustomMessage("injectCardDetail",
                                list(div_id = paste0("card_exp_", idx), html = html))
    })

    # ---- Matched Records counts ----
    output$matched_counts <- renderUI({
      d <- pd()
      if (is.null(d) || nrow(d) == 0) return(NULL)
      n_ds  <- format(nrow(d), big.mark = ",")
      n_sub <- format(sum(d$SubjectNbrs, na.rm = TRUE), big.mark = ",")
      tags$div(
        class = "btn btn-outline-secondary btn-sm ov-ctrl mr-counts-pill",
        tags$span(n_ds,  class = "mr-val"), " datasets",
        tags$span("|",   class = "mr-sep"),
        tags$span(n_sub, class = "mr-val"), " subjects"
      )
    })

    # ---- Summary KPI card ----
    output$summary_card <- renderUI({
      build_summary_card(pd())
    })

    # ---- Result cards + pagination ----
    output$cards_pane <- renderUI({
      d       <- pd()
      terms   <- search_parsed()
      n_total <- if (is.null(d)) 0L else nrow(d)

      # ── No results ──
      if (n_total == 0)
        return(div(style = "min-height:220px;",
                   div(class = "alert alert-warning mt-3",
                       bs_icon("exclamation-triangle"), " No datasets match the selected filters.")))

      # ── Build page slice ──
      if (show_all()) {
        pd_indices <- seq_len(n_total)
        d_sub      <- d
        disp_start <- 1L; disp_end <- n_total
      } else {
        disp_start <- (page_num() - 1L) * PAGE_SIZE() + 1L
        disp_end   <- min(page_num() * PAGE_SIZE(), n_total)
        pd_indices <- seq(disp_start, disp_end)
        d_sub      <- d[pd_indices, ]
      }

      cards <- lapply(seq_along(pd_indices), function(i)
        build_card(d_sub[i, ], pd_row_idx = pd_indices[i], hl_terms = terms, ns = session$ns))

      # ── Pagination bar ──
      S_bar <- "margin:16px 0 12px; display:flex !important; flex-direction:column; align-items:center; gap:10px;"
      S_row <- "display:flex !important; align-items:center; flex-wrap:wrap; gap:5px; justify-content:center;"

      pager <- if (show_all()) {
        div(style = S_bar,
          div(style = "font-size:0.90rem; color:#6b7280; font-weight:500;",
              sprintf("Showing all %d datasets", n_total)),
          actionButton(session$ns("show_paged_btn"), "Back to Pages",
                       icon  = icon("th-list"),
                       class = "btn btn-outline-secondary btn-sm",
                       style = "border-radius:18px; font-weight:600;"))
      } else {
        total_pages <- ceiling(n_total / PAGE_SIZE())
        cur         <- page_num()

        S_btn        <- "border-radius:8px !important; min-width:32px; height:32px; padding:0 8px !important; font-size:0.88rem !important; font-weight:600 !important; line-height:32px !important;"
        S_btn_active <- paste0(S_btn, " cursor:default;")
        JS_SCROLL    <- "try{window.scrollTo({top:0,behavior:'smooth'})}catch(e){};"

        page_btns <- if (total_pages > 1)
          lapply(get_page_range(cur, total_pages), function(p) {
            if (is.na(p))
              tags$span("\u2026", style = "color:#9ca3af; font-size:0.99rem; padding:0 3px; align-self:center;")
            else if (p == cur)
              tags$button(type = "button", class = "btn btn-primary btn-sm", style = S_btn_active, as.character(p))
            else
              tags$button(type = "button", class = "btn btn-outline-secondary btn-sm", style = S_btn,
                onclick = sprintf("%sShiny.setInputValue('%s',%d,{priority:'event'});",
                                  JS_SCROLL, session$ns("goto_page_js"), p),
                as.character(p))
          })
        else list()

        prev_btn <- tags$button(type = "button",
          class   = paste0("btn btn-sm ", if (cur <= 1) "btn-outline-secondary disabled" else "btn-outline-primary"),
          style   = S_btn,
          onclick = if (cur > 1) sprintf("%sShiny.setInputValue('%s',%d,{priority:'event'});", JS_SCROLL, session$ns("goto_page_js"), cur - 1L) else NULL,
          tags$i(class = "fa fa-chevron-left"))
        next_btn <- tags$button(type = "button",
          class   = paste0("btn btn-sm ", if (cur >= total_pages) "btn-outline-secondary disabled" else "btn-outline-primary"),
          style   = S_btn,
          onclick = if (cur < total_pages) sprintf("%sShiny.setInputValue('%s',%d,{priority:'event'});", JS_SCROLL, session$ns("goto_page_js"), cur + 1L) else NULL,
          tags$i(class = "fa fa-chevron-right"))

        sep <- tags$span(style = "display:inline-block; width:1px; height:22px; background:#e5e7eb; margin:0 8px; align-self:center;")

        goto_id <- session$ns("goto_input")
        goto_group <- div(style = "display:flex !important; align-items:center; gap:5px;",
          tags$span("Go to:", style = "font-size:0.87rem; color:#6b7280; white-space:nowrap;"),
          tags$input(type = "number", id = goto_id, value = cur, min = 1L, max = total_pages,
            style = "display:inline-block !important; width:52px !important; border:1px solid #d1d5db; border-radius:8px; padding:3px 6px; font-size:0.88rem; text-align:center; outline:none;"),
          tags$span(sprintf("of %d", total_pages), style = "font-size:0.87rem; color:#6b7280; white-space:nowrap;"),
          tags$button(type = "button", class = "btn btn-outline-primary btn-sm",
            style = "border-radius:8px; font-weight:600;",
            onclick = sprintf(
              "%svar v=parseInt(document.getElementById('%s').value);if(v>=1&&v<=%d)Shiny.setInputValue('%s',v,{priority:'event'});",
              JS_SCROLL, goto_id, total_pages, session$ns("goto_page_js")), "Go"))

        show_all_btn <- if (n_total > PAGE_SIZE())
          actionButton(session$ns("show_all_btn"), sprintf("Show All %d", n_total),
                       class = "btn btn-outline-success btn-sm",
                       style = "border-radius:18px; font-weight:600;")
        else NULL

        controls_children <- c(list(prev_btn), page_btns, list(next_btn, sep, goto_group),
                                if (!is.null(show_all_btn)) list(show_all_btn) else list())

        div(style = S_bar,
          div(style = "font-size:0.90rem; color:#6b7280; font-weight:500;",
              sprintf("Showing %d\u2013%d of %d datasets", disp_start, disp_end, n_total)),
          do.call(div, c(list(style = S_row), controls_children)))
      }

      # ── Combine: cards first, then pager ──
      div(style = "min-height:400px;", tagList(cards), pager)
    })

    # ---- Data Dictionary modal ----
    observeEvent(input$open_dict_ov, {
      req(is.function(dict_raw), dict_raw())
      showModal(modalDialog(
        title = div(
          style = "display:flex; align-items:center; gap:10px; color:#1C2D5C; font-weight:800;",
          bs_icon("book-half", style = "color:#427c98; font-size:1.54rem;"),
          "Data Dictionary"),
        size = "xl", footer = modalButton("Close"), easyClose = TRUE,
        DTOutput(session$ns("tbl_dict_modal_ov"))))
    })

    output$tbl_dict_modal_ov <- renderDT({
      req(is.function(dict_raw), dict_raw())
      render_dict_datatable(dict_raw())
    })

    # ---- Download handlers ----
    output$dl_filtered_csv <- downloadHandler(
      filename = function() paste0("odc_sci_filtered_", Sys.Date(), ".csv"),
      content  = function(file) write.csv(pd(), file, row.names = FALSE)
    )
    output$dl_filtered_excel <- downloadHandler(
      filename = function() paste0("odc_sci_filtered_", Sys.Date(), ".xlsx"),
      content  = function(file) writexl::write_xlsx(pd(), file)
    )
    output$dl_full_csv <- downloadHandler(
      filename = function() paste0("odc_sci_full_", Sys.Date(), ".csv"),
      content  = function(file) write.csv(pd_raw(), file, row.names = FALSE)
    )
    output$dl_full_excel <- downloadHandler(
      filename = function() paste0("odc_sci_full_", Sys.Date(), ".xlsx"),
      content  = function(file) writexl::write_xlsx(pd_raw(), file)
    )

    invisible(NULL)
  })
}
