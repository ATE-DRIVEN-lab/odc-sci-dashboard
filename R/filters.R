# R/filters.R — filter logic, filter UI builders, range slider, mini histogram

library(shiny)
library(bslib)
library(stringr)
library(dplyr)

# ---------- Debounce delay constants ----------
DEBOUNCE_FILTERS_MS <- 180L   # sidebar filters
DEBOUNCE_SEARCH_MS  <- 280L   # text search 

# ---------- Combine pill + selectize filter sources ----------
combine_filters <- function(...) {
  vals     <- unique(unlist(list(...)))
  if (is.null(vals) || length(vals) == 0) return("All")
  specific <- vals[vals != "All"]
  if (length(specific) > 0) specific else "All"
}

# ---------- Central filter pipeline ----------
.re_esc <- function(x) gsub("([.+*?^${}()|\\[\\]\\\\])", "\\\\\\1", x)

.tok_filter <- function(col_vec, vals) {
  pat  <- paste0("(?i)(?:^|;\\s*)(", paste(.re_esc(tolower(vals)), collapse="|"), ")(?:\\s*;|$)")
  !is.na(col_vec) & grepl(pat, col_vec, perl=TRUE)
}

apply_filters <- function(d, f) {
  if (is.null(d) || nrow(d) == 0) return(d)

  # Year range
  if (!is.null(f$year_range) && length(f$year_range) == 2)
    d <- d[!is.na(d$Year) & d$Year >= f$year_range[1] & d$Year <= f$year_range[2], , drop=FALSE]

  # Subject count range
  if (!is.null(f$subject_range) && length(f$subject_range) == 2)
    d <- d[is.na(d$SubjectNbrs) |
           (d$SubjectNbrs >= f$subject_range[1] & d$SubjectNbrs <= f$subject_range[2]), , drop=FALSE]

  # Dataset type
  if (!is.null(f$dataset_type) && !"All" %in% f$dataset_type)
    d <- d[!is.na(d$DatasetTyp) & d$DatasetTyp %in% f$dataset_type, , drop=FALSE]

  # Species — vectorized regex token match
  if (!is.null(f$species) && !"All" %in% f$species)
    d <- d[.tok_filter(d$SpeciesTyp, f$species), , drop=FALSE]

  if (!is.null(f$sex) && !"All" %in% f$sex) {
    sx  <- tolower(as.character(d$SexTyp))
    sx[is.na(d$SexTyp)] <- ""
    mat <- vapply(f$sex, function(sel) switch(sel,
      female  = sx %in% c("female", "female; male"),
      male    = sx %in% c("male",   "female; male"),
      mixed   = sx == "female; male",
      unknown = sx == "",
      rep(FALSE, length(sx))
    ), logical(length(sx)))
    d <- d[rowSums(mat) > 0L, , drop=FALSE]
  }

  # Injury level — vectorized ifelse
  level_selected <- !is.null(f$injury_level) && !"All" %in% f$injury_level
  if (!isTRUE(f$na_injury_level) || level_selected) {
    lv      <- tolower(as.character(d$InjuryLevelAnatomical))
    na_mask <- is.na(d$InjuryLevelAnatomical) | lv %in% NA_STRINGS
    keep    <- ifelse(na_mask,
                 isTRUE(f$na_injury_level),
                 if (level_selected) lv %in% tolower(f$injury_level) else TRUE)
    d <- d[keep, , drop=FALSE]
  }

  # Multi-value column helper
  multi_filter <- function(d, col, vals) {
    if (is.null(vals) || "All" %in% vals) return(d)
    d[.tok_filter(d[[col]], vals), , drop=FALSE]
  }

  d <- multi_filter(d, "InjuryTyp",       f$injury_type)
  d <- multi_filter(d, "InjuryDevice",    f$injury_device)
  d <- multi_filter(d, "InterventionTyp", f$intervention)
  d <- multi_filter(d, "AuthorKeywords",  f$keyword)

  # NA keywords toggle — vectorized
  if (!isTRUE(f$ignore_na_keywords)) {
    v    <- str_trim(as.character(d$AuthorKeywords))
    keep <- !is.na(d$AuthorKeywords) & nzchar(v) & !tolower(v) %in% NA_STRINGS
    d    <- d[keep, , drop=FALSE]
  }

  # Funders — vectorized regex token match
  if (!is.null(f$funder) && !"All" %in% f$funder)
    d <- d[.tok_filter(d$Funders, f$funder), , drop=FALSE]

  d
}

# ---------- Text search across key columns ----------
apply_smart_search <- function(d, terms) {
  terms <- terms[nzchar(terms)]
  if (!length(terms) || is.null(d) || nrow(d) == 0) return(d)
  cols <- intersect(c("DatasetTitle", "Purpose", "Laboratory", "ODCAccessionNbr"), names(d))
  if (!length(cols)) return(d)
  haystack <- tolower(do.call(paste, c(d[, cols, drop=FALSE], list(sep=" "))))
  keep     <- Reduce("&", lapply(tolower(terms), function(t) grepl(t, haystack, fixed=TRUE)))
  d[keep, , drop=FALSE]
}

# ---------- Mini histogram SVG ----------
.make_bar_svg <- function(vals, discrete = TRUE, n_bins = 20,
                           height = 34, color = "#427c98", alpha = 0.45) {
  vals <- vals[!is.na(vals)]
  if (!length(vals)) return(NULL)

  if (discrete) {
    tbl    <- table(vals)
    tbl    <- tbl[order(as.numeric(names(tbl)))]
    counts <- as.integer(tbl)
  } else {
    br     <- hist(vals, breaks = n_bins, plot = FALSE)
    counts <- br$counts
  }

  n <- length(counts)
  if (n == 0 || max(counts) == 0) return(NULL)
  mx <- max(counts)

  bars <- vapply(seq_along(counts), function(i) {
    bh <- max(2, counts[i] / mx * height * 0.92)
    x  <- (i - 1) / n * 100 + 100 / n * 0.10
    w  <- 100 / n * 0.80
    sprintf('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="1.5" fill="%s" opacity="%.2f"/>',
            x, height - bh, w, bh, color, alpha)
  }, character(1))

  HTML(sprintf(
    '<svg viewBox="0 0 100 %d" preserveAspectRatio="none" style="width:100%%;height:%dpx;display:block;pointer-events:none;margin-bottom:-7px;">%s</svg>',
    height, height, paste(bars, collapse = "")))
}

# ---------- Native dual-range slider ----------
range_slider <- function(id, min, max, value, step = 1) {
  tags$div(
    class          = "dual-range-wrap",
    `data-rs-id`   = id,
    `data-rs-min`  = min,
    `data-rs-max`  = max,
    `data-rs-lo`   = value[1],
    `data-rs-hi`   = value[2],
    `data-rs-step` = step,
    tags$div(class = "dual-range-display",
      tags$span(class = "dual-range-badge dual-range-badge-lo", id = paste0(id, "-badge-lo")),
      tags$span(class = "dual-range-badge dual-range-badge-hi", id = paste0(id, "-badge-hi")),
      tags$div(class = "dual-range-track",
        tags$div(class = "dual-range-fill", id = paste0(id, "-fill"))
      ),
      tags$input(type = "range", class = "dual-range-input dual-range-lo",
                 id = paste0(id, "-lo"), min = min, max = max, value = value[1], step = step),
      tags$input(type = "range", class = "dual-range-input dual-range-hi",
                 id = paste0(id, "-hi"), min = min, max = max, value = value[2], step = step)
    )
  )
}

# ---------- Top-N pills + selectize dropdown filter ----------
render_smart_filter <- function(id, label, choices, top_n = 10) {
  freq     <- sort(table(choices), decreasing = TRUE)
  top_vals <- names(freq)[seq_len(min(top_n, length(freq)))]
  all_vals <- sort(unique(choices))

  tagList(
    tags$label(label,
               style = "font-weight:700; font-size:0.94rem; margin-top:12px; color:#374151;"),
    tags$div(
      class              = "custom-selector",
      id                 = paste0(id, "-pills"),
      `data-shiny-input` = paste0(id, "_custom"),
      lapply(top_vals, function(v)
        tags$div(class = "custom-pill", `data-val` = v, v))
    ),
    selectizeInput(
      inputId  = paste0(id, "_search"),
      label    = NULL,
      choices  = c("Search or select..." = "", all_vals),
      multiple = TRUE,
      options  = list(placeholder = "Search or select others...")
    )
  )
}

# ---------- Pill-only filter with inline search for extras ----------
render_pill_filter <- function(id, label, choices, top_n = 10) {
  if (length(choices) == 0) return(NULL)

  freq        <- sort(table(choices), decreasing = TRUE)
  all_vals    <- names(freq)
  top_vals    <- head(all_vals, top_n)
  extra_vals  <- tail(all_vals, max(0L, length(all_vals) - top_n))

  top_pills   <- lapply(top_vals, function(v)
    tags$div(class = "custom-pill", `data-val` = v, v))
  extra_pills <- lapply(extra_vals, function(v)
    tags$div(class = "custom-pill pill-extra", `data-val` = v,
             style = "display:none;", v))

  search_ui <- if (length(extra_vals) > 0)
    div(class = "pill-search-wrapper",
        tags$span(class = "pill-search-icon", bs_icon("search")),
        tags$input(type = "text", class = "pill-search-input",
                   `data-pills-id` = paste0(id, "-pills"),
                   placeholder = "Search more\u2026"))
  else NULL

  tagList(
    tags$label(label,
               style = "font-weight:700; font-size:0.94rem; margin-top:12px; color:#374151; display:block;"),
    tags$div(
      class              = "custom-selector",
      id                 = paste0(id, "-pills"),
      `data-shiny-input` = paste0(id, "_custom"),
      tagList(top_pills, extra_pills)
    ),
    search_ui
  )
}
