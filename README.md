---
title: ODC-SCI
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 7860
pinned: false
---

# ODC-SCI Dashboard

A Shiny dashboard for browsing and filtering datasets from the [Open Data Commons for Spinal Cord Injury (ODC-SCI)](https://odc-sci.org). Built for researchers who want to quickly see what data is out there before deciding what to request or download.

---

## Features

The app has three tabs.

**Search** is the main view. Use the search bar to find datasets by title, lab name, purpose, or ODC accession ID — multiple words narrow results (AND logic). The sidebar has filters for year, species, sex, injury model, anatomical level, intervention, keywords, and funders. An interactive spine diagram lets you click cervical/thoracic/lumbar/sacral regions directly. Results show a summary card with breakdowns by injury type, species, sex, and intervention, followed by paginated dataset cards. Click a card to open the full record. Filtered or full results can be exported as CSV or Excel from the Save button.

**Visualizations** shows six Plotly charts that respond to the active sidebar filters: datasets over time, unique keywords over time, subjects by year, species and sex distribution, injury type by anatomical level, and dataset types over time.

**About** has project background and links.

---

## Running locally

Requires R 4.1 or newer.

```r
install.packages(c(
  "shiny", "bslib", "bsicons",
  "plotly", "DT", "dplyr",
  "stringr", "writexl", "jsonlite"
))
```

```bash
git clone https://github.com/ATE-DRIVEN-lab/odc-sci-dashboard.git
cd odc-sci-dashboard/yapp
```

```r
shiny::runApp()
```

On startup the app fetches the latest data from GitHub. If the fetch fails it falls back to the local `data/` cache. No API keys required.

---

## Data

| File | Description |
|---|---|
| `data/public_data.csv` | Publicly released ODC-SCI dataset records (local cache) |
| `data/dict_data.csv` | Data dictionary — field names, types, descriptions, units (local cache) |

Both files are fetched from [ATE-DRIVEN-lab/odc-sci-public-data](https://github.com/ATE-DRIVEN-lab/odc-sci-public-data) on GitHub at startup and refreshed every hour automatically. The local CSVs in `data/` serve as a fallback cache if GitHub is unreachable.

The pipeline in `R/data_cleaner.R` runs on every load and handles normalization: case, semicolon-delimited multi-value fields, NA variants, sex token normalization, numeric coercions, and exclusion of retracted records.

---

## Project layout

```
app.R                  — entry point: UI layout and server wiring
R/
  assets.R             — theme, palette, CSS/JS includes
  column_meta.R        — field groupings for the detail drawer
  data_loader.R        — fetches CSVs from GitHub, caches locally, hourly refresh
  data_cleaner.R       — normalization pipeline
  utils.R              — shared helpers (%||%, hl_text, pagination)
  plot_utils.R         — Plotly layout and expand-modal helpers
  filters.R            — filter pipeline, range sliders, pill builders
  cards.R              — dataset cards, summary card, detail drawer, DT table
  chart_builders.R     — chart functions
  mod_sidebar.R        — sidebar UI and filter server
  mod_overview.R       — Search tab module
  mod_charts.R         — Visualizations tab module
  mod_about.R          — About tab module
  mod_loading.R        — loading overlay
data/
  public_data.csv
  dict_data.csv
www/
  css/odc-main.css     — styles
  js/odc-main.js       — interactions (pill filters, sliders, card drawer)
  img/odc-logo.png     — ODC-SCI community mark
```

---

## Deployment

The live Space is at [HDD-Lab/odc-sci](https://huggingface.co/spaces/HDD-Lab/odc-sci) on Hugging Face. Updates are pushed via the `huggingface_hub` Python library rather than `git push hf`, since HF now requires Xet storage for binary files and rejects plain git pushes that include PNG assets.

To deploy manually from the project root:

```bash
python3 -c "
from huggingface_hub import HfApi
HfApi(token='YOUR_HF_TOKEN').upload_folder(
    folder_path='.',
    repo_id='HDD-Lab/odc-sci',
    repo_type='space',
    ignore_patterns=['.git/*', '.Rproj.user/*', 'renv/library/*', '.secrets/*'],
    commit_message='your message here'
)
"
```

