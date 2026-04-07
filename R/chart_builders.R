# R/chart_builders.R — pure chart builder functions

library(plotly)
library(dplyr)
library(stringr)

# ---------- Published Datasets Overview ----------
mk_ds_both <- function(df) {
  t <- df %>% count(Year, name = "new") %>% arrange(Year) %>%
    mutate(cumulative = cumsum(new))
  odc_layout(
    plot_ly() %>%
      add_bars(data = t, x = ~Year, y = ~new, name = "New",
               marker = list(color = "#427c98", line = list(color = "transparent", width = 0))) %>%
      add_lines(data = t, x = ~Year, y = ~cumulative, name = "Cumulative",
                yaxis = "y2", mode = "lines+markers",
                line   = list(color = "#72c02c", width = 3, shape = "spline"),
                marker = list(color = "#72c02c", size = 8)),
    hovermode = "x unified", hoverlabel = ODC_HL,
    xaxis  = list(title = "", showgrid = FALSE, dtick = 1,
                  tickfont = list(color = "#9ca3af", size = 11)),
    yaxis  = list(title = "New Datasets", showgrid = TRUE,
                  gridcolor = "rgba(66,124,152,0.07)", tickfont = list(color = "#6b7280", size = 11)),
    yaxis2 = list(title = "Cumulative", overlaying = "y", side = "right",
                  showgrid = FALSE, tickfont = list(color = "#72c02c", size = 11)),
    legend = list(orientation = "h", x = 0.5, y = 1.1, xanchor = "center", font = list(size = 11)),
    margin = list(l = 50, r = 55, t = 30, b = 35)
  )
}

# ---------- Unique Keywords Overview ----------
mk_kw_both <- function(df, ignore_na_keywords = TRUE) {
  d <- df
  if (isTRUE(ignore_na_keywords))
    d <- d %>% filter(!is.na(AuthorKeywords), !tolower(AuthorKeywords) %in% NA_STRINGS)
  if (nrow(d) == 0) {
    t <- tibble(Year = integer(), new = integer(), cumulative = integer())
  } else {
    t <- d %>%
      group_by(Year) %>%
      summarise(new = n_distinct(unlist(strsplit(AuthorKeywords, ";\\s*"))), .groups = "drop") %>%
      arrange(Year) %>% mutate(cumulative = cumsum(new))
  }
  odc_layout(
    plot_ly() %>%
      add_bars(data = t, x = ~Year, y = ~new, name = "New Keywords",
               marker = list(color = "#427c98", line = list(color = "transparent", width = 0))) %>%
      add_lines(data = t, x = ~Year, y = ~cumulative, name = "Cumulative",
                yaxis = "y2", mode = "lines+markers",
                line   = list(color = "#72c02c", width = 3, shape = "spline"),
                marker = list(color = "#72c02c", size = 8)),
    hovermode = "x unified", hoverlabel = ODC_HL,
    xaxis  = list(title = "", showgrid = FALSE, dtick = 1,
                  tickfont = list(color = "#9ca3af", size = 11)),
    yaxis  = list(title = "New Keywords", showgrid = TRUE,
                  gridcolor = "rgba(66,124,152,0.07)", tickfont = list(color = "#6b7280", size = 11)),
    yaxis2 = list(title = "Cumulative", overlaying = "y", side = "right",
                  showgrid = FALSE, tickfont = list(color = "#72c02c", size = 11)),
    legend = list(orientation = "h", x = 0.5, y = 1.1, xanchor = "center", font = list(size = 11)),
    margin = list(l = 50, r = 55, t = 30, b = 35)
  )
}

# ---------- Dataset Types over Time ----------
mk_type_cum <- function(df) {
  t <- df %>%
    filter(!is.na(DatasetTyp), !tolower(DatasetTyp) %in% NA_STRINGS) %>%
    count(DatasetTyp, Year, name = "new") %>%
    group_by(DatasetTyp) %>% arrange(Year) %>%
    mutate(cumulative = cumsum(new)) %>% ungroup()
  suppressWarnings(odc_layout(
    plot_ly(t, x = ~Year, y = ~cumulative, type = "scatter", mode = "lines+markers",
            color = ~DatasetTyp,
            colors = c("#1C2D5C", "#427c98", "#93c5dc", "#72c02c", "#619bb8"),
            line = list(shape = "spline", width = 3),
            marker = list(size = 8)),
    hovermode = "x unified", hoverlabel = ODC_HL,
    xaxis  = list(title = "", showgrid = FALSE, dtick = 1,
                  tickfont = list(color = "#9ca3af", size = 11)),
    yaxis  = list(title = "Cumulative Datasets", showgrid = TRUE,
                  gridcolor = "rgba(66,124,152,0.07)", tickfont = list(color = "#6b7280", size = 11)),
    legend = list(orientation = "v", x = 1.02, y = 0.5, font = list(size = 11)),
    margin = list(r = 110, l = 50, t = 20, b = 35)
  ))
}

# ---------- Total Subjects by Year (bar chart) ----------
mk_subjects_year <- function(df) {
  t <- df %>%
    group_by(Year) %>%
    summarise(TotalSubjects = sum(SubjectNbrs, na.rm = TRUE), .groups = "drop")
  odc_layout(
    plot_ly(t, x = ~Year, y = ~TotalSubjects, type = "bar",
            marker = list(color = "#427c98", line = list(color = "transparent")),
            text = ~TotalSubjects, textposition = "outside",
            textfont = list(color = "#6b7280", size = 11)),
    xaxis  = list(title = "", showgrid = FALSE, dtick = 1,
                  tickfont = list(color = "#9ca3af", size = 11)),
    yaxis  = list(title = "Total Subjects", showgrid = TRUE,
                  gridcolor = "rgba(66,124,152,0.07)", tickfont = list(color = "#6b7280", size = 11)),
    margin = list(l = 50, r = 20, t = 20, b = 35)
  )
}

# ---------- Species & Sex Distribution ----------
mk_species_sex <- function(df) {
  t <- df %>%
    filter(!is.na(SpeciesTyp), !is.na(SexTyp),
           !tolower(SpeciesTyp) %in% NA_STRINGS) %>%
    mutate(SexLabel = dplyr::case_when(
      SexTyp == "female; male" ~ "Mixed",
      TRUE ~ str_to_title(SexTyp)
    )) %>%
    count(SpeciesTyp, SexLabel, name = "Count")
  odc_layout(
    plot_ly(t, x = ~Count, y = ~SpeciesTyp, color = ~SexLabel, type = "bar",
            orientation = "h",
            colors = c("#427c98", "#93c5dc", "#1C2D5C", "#619bb8", "#72c02c", "#c5dfe9"),
            marker = list(line = list(width = 0))),
    barmode = "stack", hoverlabel = ODC_HL,
    xaxis  = list(title = "Total Datasets", showgrid = TRUE,
                  gridcolor = "rgba(66,124,152,0.07)", tickfont = list(color = "#6b7280", size = 11)),
    yaxis  = list(categoryorder = "total ascending", automargin = TRUE,
                  tickfont = list(color = "#4b5563", size = 11)),
    legend = list(orientation = "h", x = 0, y = 1.08, font = list(size = 10)),
    margin = list(l = 10, r = 20, t = 40, b = 35)
  )
}

# ---------- Injury Type & Anatomical Level ----------
mk_injury_grouped <- function(df) {
  t <- df %>%
    filter(!is.na(InjuryTyp), !is.na(InjuryLevelAnatomical),
           !tolower(InjuryTyp) %in% NA_STRINGS,
           !tolower(InjuryLevelAnatomical) %in% NA_STRINGS) %>%
    count(InjuryTyp, InjuryLevelAnatomical, name = "Count")
  odc_layout(
    plot_ly(t, x = ~Count, y = ~InjuryTyp, color = ~InjuryLevelAnatomical, type = "bar",
            orientation = "h",
            colors = c("#1C2D5C","#2a4382","#427c98","#619bb8","#93c5dc","#72c02c","#6b7280","#c5dfe9"),
            marker = list(line = list(width = 0))),
    barmode = "stack", hoverlabel = ODC_HL,
    xaxis  = list(title = "Total Datasets", showgrid = TRUE,
                  gridcolor = "rgba(66,124,152,0.07)", tickfont = list(color = "#6b7280", size = 11)),
    yaxis  = list(categoryorder = "total ascending", automargin = TRUE,
                  tickfont = list(color = "#4b5563", size = 11)),
    legend = list(orientation = "h", x = 0, y = -0.18, font = list(size = 10)),
    margin = list(l = 10, r = 20, t = 10, b = 80)
  )
}
