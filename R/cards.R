# R/cards.R — dataset cards, summary card, detail drawer, data dictionary table

library(shiny)
library(bslib)
library(stringr)
library(dplyr)
library(DT)
library(jsonlite)

# ---------- Data Dictionary DT renderer ----------
render_dict_datatable <- function(data) {
  datatable(
    data, escape = FALSE, rownames = FALSE,
    class      = "display nowrap stripe hover",
    extensions = c("Buttons", "FixedColumns"),
    options = list(
      dom = '<"d-flex justify-content-between align-items-center mb-3"<"dt-buttons-container"B><"dt-search-container"f>>rt<"d-flex justify-content-between align-items-center mt-3"ip>',
      buttons = list(
        list(extend = "copy",  className = "btn btn-sm btn-outline-secondary rounded-pill fw-bold px-3"),
        list(extend = "csv",   className = "btn btn-sm btn-outline-secondary rounded-pill fw-bold px-3"),
        list(extend = "excel", className = "btn btn-sm btn-outline-success  rounded-pill fw-bold px-3")),
      searchHighlight = TRUE, scrollX = TRUE, scrollY = "60vh",
      scrollCollapse  = TRUE, pageLength = 50,
      fixedColumns    = list(leftColumns = 1),
      columnDefs = list(list(
        targets = 0, width = "180px", className = "dt-left",
        render  = JS("function(d,t,r,m){ if(t==='display'&&d!=null) return '<span style=\"font-weight:800;color:#1C2D5C;\">'+d+'</span>'; return d; }"))),
      initComplete = JS("function(s,j){$(this.api().table().container()).css({'font-family':'Inter'});}"))
  )
}

# ---------- Format a single field value for the detail drawer ----------
.fmt_field_drawer <- function(val, col_name, hl_terms = character(0)) {
  v <- as.character(val %||% "")
  if (is.null(val) || is.na(val) || !nzchar(v) || tolower(v) %in% NA_STRINGS)
    return(tags$span(class = "df-empty", "\u2014"))

  if (col_name == "DOI") {
    doi_url <- if (grepl("^https?://", v)) v
               else paste0("https://doi.org/", gsub("^doi:\\s*", "", v))
    return(tags$a(href = doi_url, target = "_blank",
                  class = "df-doi-link", paste0(v, " \u2197")))
  }

  if (grepl(";", v, fixed = TRUE)) {
    parts <- str_trim(unlist(strsplit(v, ";\\s*")))
    parts <- parts[nzchar(parts) & !tolower(parts) %in% NA_STRINGS]
    if (length(parts))
      return(div(class = "df-pills",
                 lapply(parts, function(p) tags$span(class = "df-pill", hl_text(p, hl_terms)))))
    return(tags$span(class = "df-empty", "\u2014"))
  }

  tags$span(class = "df-value", hl_text(v, hl_terms))
}

# ---------- Build drawer content for one data row ----------
.build_drawer_content <- function(row, dict, show_head = TRUE, hl_terms = character(0),
                                  exclude_cols = .CARD_SHOWN_COLS) {
  all_cols    <- names(row)
  grouped_all <- unique(unlist(.DRAWER_GROUPS))
  other_cols  <- setdiff(all_cols, c(grouped_all, exclude_cols))
  groups      <- c(.DRAWER_GROUPS,
                   if (length(other_cols)) list("Other Details" = other_cols) else list())

  get_dict <- function(col) {
    if (is.null(dict) || !"VariableName" %in% names(dict)) return(NULL)
    r <- dict[dict$VariableName == col, , drop = FALSE]
    if (!nrow(r)) return(NULL)
    list(
      desc = as.character(r$Description[1] %||% ""),
      unit = if ("Unit" %in% names(r) && !is.na(r$Unit[1]) && r$Unit[1] != "NA")
               as.character(r$Unit[1]) else NULL
    )
  }

  .is_empty <- function(val) {
    v <- as.character(val %||% "")
    if (is.null(val) || is.na(val) || !nzchar(v) || tolower(v) %in% NA_STRINGS) return(TRUE)
    if (grepl(";", v, fixed = TRUE)) {
      parts <- str_trim(unlist(strsplit(v, ";\\s*")))
      return(!length(parts[nzchar(parts) & !tolower(parts) %in% NA_STRINGS]))
    }
    FALSE
  }

  col_label <- function(col) {
    if (col %in% names(.COL_LABELS)) .COL_LABELS[[col]] else col
  }

  make_group <- function(group_label, cols) {
    present <- setdiff(intersect(cols, all_cols), exclude_cols)
    if (!length(present)) return(NULL)
    fields <- Filter(Negate(is.null), lapply(present, function(col) {
      if (.is_empty(row[[col]])) return(NULL)
      di <- get_dict(col)
      div(class = "df-field",
          div(class = "df-field-lhs",
              span(class = "df-label", col_label(col)),
              if (!is.null(di$unit)) span(class = "df-unit-badge", di$unit)),
          div(class = "df-field-rhs",
              .fmt_field_drawer(row[[col]], col, hl_terms),
              if (!is.null(di) && !is.na(di$desc) && nzchar(di$desc))
                div(class = "df-desc", di$desc)))
    }))
    if (!length(fields)) return(NULL)
    div(class = "df-group",
        `data-g` = .GROUP_KEYS[[group_label]] %||% "other",
        div(class = "df-group-label", group_label),
        do.call(div, c(list(class = "df-group-fields"), fields)))
  }

  title <- as.character(row[["DatasetTitle"]] %||% "")
  acc   <- as.character(row[["ODCAccessionNbr"]] %||% "")
  year  <- as.character(row[["Year"]] %||% "")
  lab   <- as.character(row[["Laboratory"]] %||% "")

  tagList(
    if (show_head)
      div(class = "df-drawer-head",
          div(class = "df-drawer-badges",
              if (nzchar(acc))  tags$span(class = "df-badge-acc",  acc),
              if (nzchar(year)) tags$span(class = "df-badge-year", year),
              if (nzchar(lab))  tags$span(class = "df-badge-lab",  lab)),
          div(class = "df-drawer-title", if (nzchar(title)) title else "\u2014")),
    local({
      rendered <- Filter(Negate(is.null),
                         mapply(make_group, names(groups), groups, SIMPLIFY = FALSE))
      if (!length(rendered))
        return(div(class = "df-drawer-body",
                   div(class = "df-no-extra",
                       tags$i(class = "bi bi-check-circle-fill", style = "color:#72c02c;"),
                       " All key details are shown in the card above")))
      half  <- ceiling(length(rendered) / 2)
      left  <- rendered[seq_len(half)]
      right <- rendered[seq(half + 1L, length(rendered))]
      div(class = "df-drawer-body",
          div(class = "df-drawer-col", left),
          div(class = "df-drawer-col", right))
    })
  )
}

# ---------- KPI mini-bento breakdown list ----------
generate_mini_bento_list <- function(df, col_name, label, top_n = 4, split = TRUE) {
  cap <- function(x) {
    x <- as.character(x)
    if (tolower(x) == "dlq")          return("DLQ")
    if (tolower(x) == "female; male") return("Mixed")
    paste0(toupper(substr(x, 1, 1)), substr(x, 2, nchar(x)))
  }

  empty_section <- div(class = "kpi-section",
    div(class = "kpi-section-header",
        span(class = "kpi-section-label", label),
        span(class = "kpi-section-count", "0")))

  if (is.null(df) || nrow(df) == 0 || !col_name %in% names(df)) return(empty_section)

  if (split) {
    vals <- df[[col_name]] %>% as.character() %>% strsplit(";\\s*") %>% unlist() %>% str_trim()
    vals <- vals[!is.na(vals) & vals != "" & !tolower(vals) %in% NA_STRINGS]
  } else {
    raw   <- str_trim(as.character(df[[col_name]]))
    na_mk <- is.na(df[[col_name]]) | raw == "" | tolower(raw) %in% NA_STRINGS
    vals  <- ifelse(na_mk, "Unknown", raw)
  }

  if (!length(vals)) return(empty_section)

  n_unique <- n_distinct(tolower(vals))
  dist_all <- as.data.frame(table(tolower(vals))) %>%
    setNames(c("item", "n")) %>% arrange(desc(n))

  top     <- head(dist_all, top_n)
  rest_df <- tail(dist_all, max(0L, nrow(dist_all) - top_n))
  rest    <- sum(rest_df$n)

  rows <- lapply(seq_len(nrow(top)), function(i)
    div(class = "kpi-row",
        span(class = "kpi-row-label", cap(top$item[i])),
        span(class = "kpi-row-count", top$n[i])))

  if (rest > 0) {
    rest_items <- data.frame(
      item = vapply(as.character(rest_df$item), cap, character(1)),
      n    = as.integer(rest_df$n),
      stringsAsFactors = FALSE
    )
    rest_json <- jsonlite::toJSON(
      list(label = label, items = rest_items),
      auto_unbox = TRUE, dataframe = "rows"
    )
    rows <- c(rows, list(
      div(class = "kpi-row kpi-row-other",
          `data-other-items` = rest_json,
          span(class = "kpi-row-label", paste0("Other (", nrow(rest_df), ")")),
          span(class = "kpi-row-count", rest))))
  }

  div(class = "kpi-section",
      div(class = "kpi-section-header",
          span(class = "kpi-section-label", label),
          span(class = "kpi-section-count", n_unique)),
      do.call(div, c(list(class = "kpi-section-list"), rows)))
}

# ---------- Summary KPI card ----------
build_summary_card <- function(d) {
  n_datasets   <- nrow(d)
  n_subj       <- format(sum(d$SubjectNbrs, na.rm = TRUE), big.mark = ",")
  last_updated <- tryCatch(
    format(file.mtime(DATA_PUBLIC), "%d %b %Y, %H:%M"),
    error = function(e) NULL
  )

  div(
    class = "dataset-card summary-card-results",
    div(
      style = "display:flex; align-items:center; justify-content:space-between; margin-bottom:6px;",
      tags$span(
        bs_icon("clipboard2-data", class = "me-2", style = "color:#427c98;"),
        style = "font-size:0.97rem; font-weight:800; color:#1C2D5C; text-transform:uppercase; letter-spacing:0.4px;",
        "Filtered Records Context"
      ),
      if (!is.null(last_updated))
        div(style = "font-size:0.78rem; color:#94a3b8; display:flex; align-items:center; gap:4px;",
            bs_icon("clock-history"), " Data last updated: ", last_updated)
    ),
    div(
      class = "kpi-grid",
      generate_mini_bento_list(d, "DatasetTyp",            "By Dataset Type",     top_n = 5),
      generate_mini_bento_list(d, "InjuryLevelAnatomical", "By Anatomical Level", top_n = 4),
      generate_mini_bento_list(d, "InjuryTyp",             "By Injury Model",     top_n = 4),
      generate_mini_bento_list(d, "SpeciesTyp",            "By Species",          top_n = 4),
      generate_mini_bento_list(d, "SexTyp",                "By Sex",              top_n = 4, split = FALSE),
      generate_mini_bento_list(d, "InterventionTyp",       "By Intervention",     top_n = 4)
    )
  )
}

# ---------- Single dataset result card ----------
build_card <- function(row, pd_row_idx, hl_terms = character(0), ns) {
  doi_raw <- tryCatch(safe_text(row$DOI, ""), error = function(e) "")
  doi_url <- if (doi_raw == "") ""
             else if (grepl("^http", doi_raw)) doi_raw
             else paste0("https://doi.org/", gsub("^doi:\\s*", "", doi_raw))

  ov_input <- ns("ov_card_clicked")
  exp_id   <- paste0("card_exp_", pd_row_idx)
  title_el <- div(
    class   = "ov-card-title",
    onclick = paste0("Shiny.setInputValue('", ov_input, "',", pd_row_idx,
                     ",{priority:'event'});",
                     "window._toggleCardDetail('", exp_id, "');"),
    hl_text(row$DatasetTitle, hl_terms)
  )

  col_val <- function(col) { v <- row[[col]]; if (is.null(v)) NA_character_ else v }

  lab_text     <- safe_text(row$Laboratory, "Lab Not Reported")
  leader_val   <- col_val("StudyLeader")
  leader_text  <- if (!is.na(leader_val) && !tolower(leader_val) %in% NA_STRINGS)
                    paste0(" (", leader_val, ")") else ""
  species_text <- stringr::str_to_title(safe_text(row$SpeciesTyp, "Unknown"))
  strain_val   <- col_val("SpeciesStrainTyp")
  strain_text  <- if (!is.na(strain_val) && !tolower(strain_val) %in% NA_STRINGS)
                    paste0("-", strain_val) else ""
  sex_text     <- safe_text(row$SexTyp, "Unknown Sex")
  age_val      <- col_val("AgeVal")
  age_text     <- if (!is.na(age_val) && !tolower(age_val) %in% NA_STRINGS)
                    paste0(", Age: ", age_val) else ""
  injury_text  <- stringr::str_to_title(safe_text(row$InjuryTyp, "Unknown Injury"))
  level_val    <- col_val("InjuryLevelAnatomical")
  level_text   <- if (!is.na(level_val) && !tolower(level_val) %in% NA_STRINGS)
                    paste0(" (", level_val, ")") else ""
  device_val   <- col_val("InjuryDevice")
  device_text  <- if (!is.na(device_val) && !tolower(device_val) %in% NA_STRINGS)
                    paste0(" [", device_val, "]") else ""
  interv_type  <- safe_text(row$InterventionTyp, "None")
  agent_val    <- col_val("InterventionAgent")
  interv_agent <- if (!is.na(agent_val) && !tolower(agent_val) %in% NA_STRINGS)
                    paste0(": ", agent_val) else ""
  n_subj       <- if (!is.na(row$SubjectNbrs)) row$SubjectNbrs else "N/A"
  date_val     <- col_val("DatePublished")
  date_display <- if (!is.na(date_val) && nzchar(date_val)) date_val
                  else as.character(row$Year %||% "")
  purpose_text <- safe_text(row$Purpose, "No abstract/purpose provided.")

  div(
    class = "dataset-card",
    style = "position:relative;",
    if (nzchar(doi_url))
      tags$button(
        class   = "ov-share-btn",
        style   = "position:absolute; top:10px; right:12px; background:none; border:none; color:#cbd5e1; cursor:pointer; padding:4px 6px; border-radius:6px; font-size:0.94rem; line-height:1; z-index:1;",
        title   = "Share",
        onclick = paste0(
          "event.stopPropagation();",
          "var u=", jsonlite::toJSON(doi_url, auto_unbox = TRUE), ";",
          "if(navigator.share){navigator.share({url:u}).catch(function(){});}",
          "else{",
            "navigator.clipboard&&navigator.clipboard.writeText(u).catch(function(){});",
            "var b=this;b.title='\u2713 Copied!';",
            "setTimeout(function(){b.title='Share';},2000);",
          "}"
        ),
        bs_icon("share")
      ),
    div(style = "margin-bottom:6px; padding-right:42px;", title_el),
    div(style = "font-size:0.99rem; color:#427c98; margin-bottom:10px; font-weight:500;",
        bs_icon("building", class = "me-1"), hl_text(paste0(lab_text, leader_text), hl_terms),
        tags$span(" • ", style = "margin:0 6px; color:#cbd5e1;"),
        bs_icon("calendar3", class = "me-1"),
        tags$span(date_display,
                  style = "color:#0369a1; background:rgba(3,105,161,0.08); border-radius:6px; padding:1px 7px; font-size:0.99rem; font-weight:700;")),
    div(class = "ov-purpose-text",
        style = "font-size:0.99rem; color:#4b5563; margin-bottom:12px; line-height:1.5;",
        tags$strong("Purpose: ", style = "color:#1f2937;"), hl_text(purpose_text, hl_terms)),
    div(class = "card-badges",
        div(class = "dataset-card-badge badge-odc",
            "ODC: ", hl_text(as.character(row$ODCAccessionNbr), hl_terms)),
        if (nzchar(doi_url))
          tags$a(class = "dataset-card-badge ov-doi-badge",
                 href = doi_url, target = "_blank",
                 onclick = "event.stopPropagation();",
                 bs_icon("link-45deg", class = "me-1"), "DOI"),
        div(class = "dataset-card-badge badge-species",
            tags$i(class = "fa fa-paw me-1"),
            paste0(species_text, strain_text, " | ", sex_text, age_text)),
        div(class = "dataset-card-badge badge-injury",
            bs_icon("activity", class = "me-1"),
            paste0(injury_text, level_text, device_text)),
        div(class = "dataset-card-badge badge-interv",
            bs_icon("capsule", class = "me-1"), paste0(interv_type, interv_agent)),
        div(class = "dataset-card-badge badge-n",
            paste("N =", n_subj))
    ),
    div(id = exp_id, class = "ov-card-expand")
  )
}
