# U.S. Protest on Race and Policing (2021–2026)

This documentation memo details how to navigate and use the dashboard I created for my final project as part of Ethics 410s. To run the dashboard, please install the R packages listed below, confirm the source files are in `data/`, run the data prep script once, and then call `shiny::runApp("app.R")`.

## Setup

```bash
# 1. Install required R packages
Rscript -e 'install.packages(c("shiny", "shinydashboard", "tidyverse", "lubridate", "ggplot2", "ggrepel", "plotly", "leaflet", "visNetwork", "DT", "RColorBrewer", "igraph"))'

# 2. Source files are in data/ (already in this repo via Git LFS):
#    - data/ccc_compiled_20212024.csv               (CCC phase 2, 2021–2024)
#    - data/ccc-phase3-public.csv                   (CCC phase 3, 2024 onward)
#    - data/anes_timeseries_2024_csv_20250808.csv   (ANES 2024)

# 3. Run the data prep script once to generate the cleaned RDS files in data/clean/
Rscript data/clean.R

# 4. Launch the dashboard
Rscript -e 'shiny::runApp("app.R")'
```

## Data sources

I used two datasets for this dashboard: the Crowd Counting Consortium dataset for the protest event record, and the ANES 2024 Time Series Study for the public opinion environment surrounding it.

**Crowd Counting Consortium (CCC)**: This was the source I used for every protest event in the dashboard. Each event record includes a date, location, claims summary, organizing groups, an estimated crowd size, an arrest count, the news sources cited, and a left- or right-leaning valence assigned by the source coders. I used CCC for every chart on every tab except Public Opinion.
Public access: <https://dataverse.harvard.edu/dataverse/crowdcountingconsortium>.
Located in `data/`: `ccc_compiled_20212024.csv` (phase 2) and `ccc-phase3-public.csv` (phase 3).

**ANES 2024 Time Series Study**: This was the source I used for every public opinion measure in the dashboard. I used ANES for the dumbbell chart and the Likert charts on the Public Opinion tab.
Public access: <https://electionstudies.org/data-center/2024-time-series-study/>.
Located in `data/`: `anes_timeseries_2024_csv_20250808.csv` (data) and `anes_timeseries_2024_userguidecodebook_20250808.pdf` (variable codebook).

## Tabs

### About this Dashboard

This tab provides an explanation of my reasoning, the dashboard's methodology, and the codebook. Please use it as a reference before reading any chart on the other tabs.

### Overview

This tab provides a one-screen summary of how mobilization on each side compares in scale, timing, and press coverage. It includes summary counts, a weekly events timeline, an animated geographic map of events over time, and a list of the most-covered events. To use the animated map, switch between the three views (all events, left-leaning sub-movements, right-leaning sub-movements) using the radio buttons above the map, then press play or drag the slider to scrub through months.

### Mobilization Geography

This tab provides a geographic view of where each side mobilizes and an explorer for the days both sides showed up in the same city. It includes a clustered map with a side filter, top-cities bar charts ranked separately for each side, and an encounter table. To filter the map by side, use the radio button above it. To drill into a specific contested day, click any row in the encounter table — the map will zoom to that city, switch to show only that day's events, and a description card will appear below the table summarizing the day.

### Tactics and Framing

This tab provides a comparative view of what each side does and what each side advocates for or against. It includes two bar charts of the tactical mix per side (rallies, marches, vigils, etc.) and two diverging plotly bar charts of the most-mentioned issues per side, with stance ("for" on the right, "against" on the left). To see the full text of any truncated issue label, hover over the corresponding bar in the claims chart.

### Organizational Infrastructure

This tab provides a profile view for any single organization in the dataset. It includes a side filter and a searchable dropdown to pick an organization, then summary statistics, an event table, a geographic footprint map, a tactical and crowd-size panel, and a coalition network of organizations that co-appeared on the same events. To profile an organization, narrow the dropdown by side first if you want, then start typing the organization's name; the rest of the tab will populate automatically once a name is selected.

### Public Opinion

This tab provides a snapshot of U.S. public opinion on race and policing from the ANES 2024 survey. It includes a dumbbell chart comparing mean Black Lives Matter and police thermometer ratings across groups, and a question selector that renders a stacked Likert chart for any of 13 question/breakdown combinations. To switch the dumbbell breakdown between party identification and race, use the dropdown inside that card. To view a different survey question, pick a new entry from the question selector dropdown below it.
