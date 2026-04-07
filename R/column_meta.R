# R/column_meta.R

# All field groups for the detail drawer.
# Names + ordering mirror the sidebar filter accordion sections so the
.DRAWER_GROUPS <- list(
  "Study Metrics"         = c("ODCAccessionNbr", "DatasetTitle", "Laboratory",
                               "StudyLeader", "Year", "DatePublished", "DatasetTyp",
                               "DOI", "SubjectNbrs"),
  "Subject Details"       = c("SpeciesTyp", "SpeciesStrainTyp", "AnimalSourceNam",
                               "SexTyp", "AgeVal", "BodyWgtMeasrVal",
                               "InjuryLevelAnatomical"),
  "Injury & Intervention" = c("InjuryTyp", "InjuryDevice", "InjuryContusionDataAvail",
                               "Locomotion", "InterventionTyp", "InterventionAgent"),
  "Keywords & Funding"    = c("Purpose", "AuthorKeywords", "Funders",
                               "OtherBehaviour", "CoDES")
)

# CSS data-g key per group — drives accent colours in the drawer
.GROUP_KEYS <- c(
  "Study Metrics"         = "study",
  "Subject Details"       = "subject",
  "Injury & Intervention" = "injury",
  "Keywords & Funding"    = "keywords",
  "Other Details"         = "other"
)

# Columns already visible in the compact card — excluded from accordion detail
.CARD_SHOWN_COLS <- c(
  "ODCAccessionNbr", "DatasetTitle", "Laboratory", "StudyLeader",
  "Year", "DatePublished", "DOI",
  "SubjectNbrs", "SpeciesTyp", "SpeciesStrainTyp", "SexTyp", "AgeVal",
  "InjuryTyp", "InjuryLevelAnatomical", "InjuryDevice",
  "InterventionTyp", "InterventionAgent",
  "Purpose"
)

# Human-readable labels for column names shown in the accordion detail
.COL_LABELS <- c(
  DatasetTyp               = "Dataset Type",
  AnimalSourceNam          = "Animal Source",
  BodyWgtMeasrVal          = "Body Weight",
  InjuryContusionDataAvail = "Contusion Data",
  Locomotion               = "Locomotion Scale",
  OtherBehaviour           = "Other Behaviour",
  CoDES                    = "CoDES Score",
  AuthorKeywords           = "Keywords",
  Funders                  = "Funders"
)
