# R/data_cleaner.R

library(dplyr)
library(stringr)

# Constants — public (no leading dot) so helpers.R and modules can use them

NA_STRINGS <- c("na", "n/a", "not reported", "not applicable",
                "none", "unknown", "nan", "")

.is_na_like <- function(x) {
  is.na(x) | tolower(str_trim(as.character(x))) %in% NA_STRINGS
}

.clean_text <- function(x) {
  x <- str_trim(as.character(x))
  ifelse(.is_na_like(x), NA_character_, x)
}

# Normalize a single sex token.
.norm_sex_token <- function(tok) {
  t <- tolower(str_trim(tok))
  if (t %in% c("male", "m"))       return("male")
  if (t %in% c("female", "f"))     return("female")
  if (t %in% c("mixed", "both"))   return("mixed")
  NA_character_   # not reported / not disclosed / unknown / anything else → NA
}

.normalize_sex <- function(x) {
  if (.is_na_like(x)) return(NA_character_)
  parts <- str_trim(unlist(strsplit(as.character(x), "\\s*;\\s*")))
  normed <- unique(na.omit(sapply(parts, .norm_sex_token)))
  if (length(normed) == 0) return(NA_character_)
  if ("mixed" %in% normed)
    normed <- sort(unique(c(normed[normed != "mixed"], "female", "male")))
  paste(sort(normed), collapse = "; ")
}

# Parse a semicolon-separated multi-value field into a cleaned, sorted string
.parse_multi <- function(x, strip_suffix = FALSE) {
  if (.is_na_like(x)) return(NA_character_)
  parts <- str_trim(unlist(strsplit(as.character(x), "\\s*;\\s*")))
  if (strip_suffix) parts <- str_trim(sub("\\s*:.*$", "", parts))
  parts <- parts[!.is_na_like(parts)]
  parts <- unique(parts)
  if (length(parts) == 0) return(NA_character_)
  paste(sort(parts), collapse = "; ")
}

# Clean and preprocess the PublicData sheet.
clean_public_data <- function(df) {
  n_before <- nrow(df)

  # Exclude retracted records — any row where the "retracted" column
  ret_col <- names(df)[tolower(names(df)) == "retracted"]
  if (length(ret_col)) {
    rc <- ret_col[1]
    keep <- is.na(df[[rc]]) | trimws(as.character(df[[rc]])) == ""
    df <- df[keep, , drop = FALSE]
  }

  out <- df %>%
    mutate(
      # ---- Numeric coercions ----
      Year        = suppressWarnings(as.integer(Year)),
      SubjectNbrs = suppressWarnings(as.numeric(SubjectNbrs)),

      # ---- Categorical normalization ----
      DatasetTyp  = tolower(str_trim(as.character(DatasetTyp))),
      SpeciesTyp  = str_to_title(str_trim(as.character(SpeciesTyp))),
      SexTyp      = sapply(SexTyp, .normalize_sex, USE.NAMES = FALSE),

      # ---- Injury / intervention multi-value parsing ----
      InjuryTyp        = sapply(InjuryTyp,        .parse_multi, USE.NAMES = FALSE),
      InjuryDevice     = sapply(InjuryDevice,     .parse_multi, USE.NAMES = FALSE),
      InterventionTyp  = sapply(InterventionTyp,  .parse_multi, USE.NAMES = FALSE),
      AuthorKeywords   = sapply(AuthorKeywords,   .parse_multi, USE.NAMES = FALSE),

      # Funders: strip ": <grant-number>" suffix ONCE here — never again downstream
      Funders = sapply(Funders, function(x) .parse_multi(x, strip_suffix = TRUE),
                       USE.NAMES = FALSE),

      # ---- Anatomical level ----
      InjuryLevelAnatomical = {
        lv <- tolower(str_trim(as.character(InjuryLevelAnatomical)))
        ifelse(.is_na_like(lv), NA_character_, lv)
      },

      # ---- Free-text fields ----
      Laboratory   = .clean_text(Laboratory),
      StudyLeader  = .clean_text(StudyLeader),
      Purpose      = .clean_text(Purpose),
      DOI          = .clean_text(DOI)
    ) %>%
    filter(!is.na(Year))

  n_dropped <- n_before - nrow(out)
  if (n_dropped > 0)
    warning(sprintf(
      "[data_cleaner] %d row(s) removed because Year is NA or non-numeric.",
      n_dropped
    ))

  out
}
