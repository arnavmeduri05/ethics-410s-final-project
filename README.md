# Racial Justice Movement Dashboard

Interactive Shiny dashboard analyzing the racial justice movement and its counter-mobilization in the United States, 2021–2026, using Crowd Counting Consortium (CCC) protest event data.

## Setup

```bash
# 1. Install R packages
Rscript -e 'install.packages(c("shiny", "shinydashboard", "dplyr", "tidyr", "readr", "stringr", "lubridate", "plotly", "leaflet", "visNetwork", "DT", "purrr"))'

# 2. Place raw CSVs in data/
#    - data/ccc_compiled_20212024.csv  (Phase 2)
#    - data/ccc-phase3-public.csv      (Phase 3)

# 3. Run data prep (once)
Rscript prep_data.R

# 4. Launch the dashboard
Rscript -e 'shiny::runApp("app.R")'
```

## Tabs

1. **Overview** — Value boxes for pro/counter/dyad counts, monthly event timeline with annotated reference events
2. **Movement & counter-mobilization map** — Leaflet map of same-day same-city dyads, quarterly bar chart, clickable detail table, side-by-side dyad view
3. **Organizational infrastructure** — Top orgs by side, coalition co-mobilization network (visNetwork), org explorer
4. **Claims and frames** — Top verbatim claims by side, claim explorer

## Data

- 32,775 events tagged "racism" or "policing" from the Crowd Counting Consortium
- Phase 2: Jan 2021 – Dec 2024 (~140k total, ~25k racism/policing)
- Phase 3: Jan 2025 – Feb 2026 (~50k total, ~8k racism/policing)
