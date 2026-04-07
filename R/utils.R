# R/utils.R — small generic helpers used across the whole app

library(shiny)
library(stringr)

# ---------- Null-coalescing ----------
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

# ---------- HTML-escape for untrusted text ----------
esc_html <- function(x) {
  x <- as.character(x %||% "")
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;",  x, fixed = TRUE)
  x <- gsub(">", "&gt;",  x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x <- gsub("'", "&#39;",  x, fixed = TRUE)
  x
}

# ---------- Safe text extraction ----------
safe_text <- function(x, fallback = "N/A") {
  if (is.na(x) || tolower(str_trim(as.character(x))) %in% NA_STRINGS) fallback
  else as.character(x)
}

# ---------- Split semicolon-separated multi-value column ----------
split_multi <- function(col) {
  vals <- unlist(strsplit(as.character(col[!is.na(col)]), "\\s*;\\s*"))
  vals <- str_trim(vals)
  vals[vals != "" & !tolower(vals) %in% NA_STRINGS]
}

# ---------- Text highlighting (search terms → <mark>) ----------
hl_text <- function(text, terms) {
  s <- as.character(text %||% "")
  if (is.na(s)) s <- ""
  s <- gsub("&", "&amp;", s, fixed = TRUE)
  s <- gsub("<", "&lt;",  s, fixed = TRUE)
  s <- gsub(">", "&gt;",  s, fixed = TRUE)
  if (!length(terms) || !nzchar(s)) return(HTML(s))

  hl_terms <- terms[nchar(terms) >= 3L]
  if (!length(hl_terms)) return(HTML(s))

  for (term in hl_terms) {
    esc <- gsub("([.+*?^${}()|\\[\\]\\\\])", "\\\\\\1", term, perl = TRUE)
    if (!nzchar(esc)) next
    pat <- if (grepl(" ", term, fixed = TRUE))
             paste0("(", esc, ")")          # phrase — exact match
           else
             paste0("\\b(", esc, ")\\b")    # word — boundary match
    s <- tryCatch(
      gsub(pat, '<mark class="hl">\\1</mark>',
           s, ignore.case = TRUE, perl = TRUE),
      error = function(e) s
    )
  }
  HTML(s)
}

# ---------- Pagination: page numbers with ellipsis gaps ----------
get_page_range <- function(cur, total) {
  if (total <= 7) return(seq_len(total))
  pages <- unique(sort(c(1L, as.integer(total),
                         max(1L, cur - 1L), as.integer(cur),
                         min(as.integer(total), cur + 1L))))
  result <- c()
  prev_p <- 0L
  for (p in pages) {
    if (p - prev_p > 1L) result <- c(result, NA_integer_)
    result <- c(result, p)
    prev_p <- p
  }
  result
}

# ---------- Species emoji icons ----------
.SPECIES_ICONS <- list(
  rat    = tags$span("\U0001F400", style = "font-size:1.16rem; line-height:1;"),
  mouse  = tags$span("\U0001F401", style = "font-size:1.16rem; line-height:1;"),
  human  = tags$span("\U0001F9D1", style = "font-size:1.16rem; line-height:1;"),
  monkey = tags$span("\U0001F412", style = "font-size:1.16rem; line-height:1;"),
  pig    = tags$span("\U0001F437", style = "font-size:1.16rem; line-height:1;"),
  cat    = tags$span("\U0001F431", style = "font-size:1.16rem; line-height:1;")
)

.get_species_icon <- function(s) {
  key <- tolower(s)
  for (p in names(.SPECIES_ICONS))
    if (grepl(p, key, fixed = TRUE))
      return(.SPECIES_ICONS[[p]])
  tags$span("\U0001F43E", style = "font-size:1.16rem; line-height:1;")
}
