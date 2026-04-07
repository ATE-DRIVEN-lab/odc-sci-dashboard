# R/data_loader.R

DATA_DIR    <- "data"
DATA_PUBLIC <- file.path(DATA_DIR, "public_data.csv")
DATA_DICT   <- file.path(DATA_DIR, "dict_data.csv")

GITHUB_DATA_URL <- "https://raw.githubusercontent.com/ATE-DRIVEN-lab/odc-sci-public-data/main/public_data.csv"
GITHUB_DICT_URL <- "https://raw.githubusercontent.com/ATE-DRIVEN-lab/odc-sci-public-data/main/dict_data.csv"

load_public_data <- function() {
  if (!file.exists(DATA_PUBLIC))
    stop("Dataset file not found: ", DATA_PUBLIC,
         "\nPlace 'public_data.csv' in the '", DATA_DIR, "/' folder and restart.")
  read.csv(DATA_PUBLIC, stringsAsFactors = FALSE, na.strings = "")
}

load_dict_data <- function() {
  if (!file.exists(DATA_DICT))
    stop("Dictionary file not found: ", DATA_DICT,
         "\nPlace 'dict_data.csv' in the '", DATA_DIR, "/' folder and restart.")
  read.csv(DATA_DICT, stringsAsFactors = FALSE, na.strings = "")
}

# Fetch both CSVs from GitHub, save locally. Returns list(public=df, dict=df),
# or NULL on error (caller falls back to local cache).
refresh_from_github <- function() {
  .fetch <- function(url, local_path, label) {
    tryCatch({
      tmp <- tempfile(fileext = ".csv")
      download.file(url, tmp, mode = "wb", quiet = TRUE)
      d <- read.csv(tmp, stringsAsFactors = FALSE, na.strings = "")
      write.csv(d, local_path, row.names = FALSE)
      message(sprintf("[data_loader] %s refreshed from GitHub: %d rows at %s",
                      label, nrow(d), format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
      d
    }, error = function(e) {
      warning(sprintf("[data_loader] GitHub fetch failed (%s): %s – using local cache.",
                      label, conditionMessage(e)))
      NULL
    })
  }
  pub  <- .fetch(GITHUB_DATA_URL, DATA_PUBLIC, "public_data.csv")
  dict <- .fetch(GITHUB_DICT_URL, DATA_DICT,   "dict_data.csv")
  list(public = pub, dict = dict)
}

# Load data on startup: try GitHub first, fall back to local cache.
load_initial_data <- function() {
  fetched <- refresh_from_github()

  public <- if (!is.null(fetched$public)) {
    fetched$public
  } else {
    tryCatch(load_public_data(), error = function(e) {
      warning("Local public_data cache load failed: ", conditionMessage(e))
      data.frame()
    })
  }

  dict <- if (!is.null(fetched$dict)) {
    fetched$dict
  } else {
    tryCatch(load_dict_data(), error = function(e) {
      warning("Local dict_data cache load failed: ", conditionMessage(e))
      data.frame()
    })
  }

  list(public = public, dict = dict)
}
