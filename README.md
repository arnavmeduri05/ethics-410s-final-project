# U.S. Protest on Race and Policing (2021–2026)

This documentation memo details the structure of the Shiny dashboard, the data sources behind it, what each tab contains, and how to launch it. To run the dashboard, please install the R packages listed below, place the source files in `data/`, run the data prep script once, and then call `shiny::runApp("app.R")`.

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

I used two datasets.

**Crowd Counting Consortium (CCC)** — the source for every protest event in the dashboard. Each event record includes a date, location, claims summary, organizing groups, an estimated crowd size, an arrest count, the news sources cited, and a left- or right-leaning valence assigned by the source coders. I used CCC for every chart on every tab except Public Opinion.
Public access: <https://dataverse.harvard.edu/dataverse/crowdcountingconsortium>.
Located in `data/`: `ccc_compiled_20212024.csv` (phase 2) and `ccc-phase3-public.csv` (phase 3).

**ANES 2024 Time Series Study** — the source for every public opinion measure in the dashboard. I used ANES for the dumbbell chart and the Likert charts on the Public Opinion tab.
Public access: <https://electionstudies.org/data-center/2024-time-series-study/>.
Located in `data/`: `anes_timeseries_2024_csv_20250808.csv` (data) and `anes_timeseries_2024_userguidecodebook_20250808.pdf` (variable codebook).

## Tabs

### About this Dashboard

What it contains:
- A short prose section describing what the dashboard documents and the two filtering rules I used to keep an event in scope.
- A card titled "Data Source #1: Crowd Counting Consortium" with a description, a public-access link, and two codebook tables (variables drawn directly from CCC, and variables I computed from CCC inside `data/clean.R`).
- A card titled "Data Source #2: ANES 2024 Time Series Study" with a description, a public-access link, and a codebook table for the ANES variables used in the dashboard.

Justification: a reader needs to know what is in scope and how each variable is defined before reading any chart.

### Overview

What it contains:
- Four value boxes: left-leaning event count, right-leaning event count, total arrests across events, total same-day same-city encounters.
- "Events per week": a mirrored area chart of weekly event counts, with left-leaning events above the axis and right-leaning events below, and key reference dates (Chauvin verdict, Tyre Nichols killed, 2024 election, etc.) labeled on the timeline.
- "Animated Map of Events Over Time": a `plotly` scattergeo of events plotted by month, with a play button and slider to scrub through time and a radio toggle for three views (all events by side, left-leaning sub-movements, right-leaning sub-movements).
- "Most-Covered Individual Events": a horizontal bar chart of the 15 events with the largest number of distinct news sources cited, with a callout explaining why some headline-grabbing protests are not primarily about race or policing.

Justification: gives a one-screen summary of how the two sides compare in scale, timing, and press coverage.

### Mobilization Geography

What it contains:
- "Mobilization map": a clustered Leaflet map of every qualifying event, colored by side, with a side filter (Both, Left-leaning only, Right-leaning only) above the map.
- "Top cities for left-leaning mobilization" and "Top cities for right-leaning mobilization": two horizontal bar charts, one per side, ranking the top 15 cities by event count for that side.
- "Encounter explorer": a sortable DataTable of every same-day same-city encounter (a calendar day on which both sides held at least one event in the same city). Clicking a row zooms the map to that city, replaces the all-time cluster overlay with markers for only that day's events, and surfaces a description card with the day's tactical mix, top organizations, and most common claims.

Justification: shows where each side concentrates at city level and surfaces the days both sides were physically present in the same place.

### Tactics and Framing

What it contains:
- "Tactics used at left-leaning events" and "Tactics used at right-leaning events": two horizontal bar charts of the top 10 event types per side (rallies, marches, vigils, demonstrations, etc.), ranked by frequency.
- "Claims raised at left-leaning events" and "Claims raised at right-leaning events": two stacked plotly bar charts. I split each event's claims summary on its leading verb ("for" or "against") to get a stance and an issue, then plotted the most-mentioned issues per side. Bars to the right of zero are mentions framed as "for", bars to the left are mentions framed as "against". Hover any bar for the full issue text.

Justification: documents what forms of action each side actually takes and what each side is for and against.

### Organizational Infrastructure

What it contains:
- A side filter (All, Left-leaning, Right-leaning) and a searchable dropdown of organization names. Picking an organization populates the rest of the tab.
- Four value boxes: total events, number of states the organization was active in, total arrests across its events, and the year range of its activity.
- "All recorded events for this organization": a sortable DataTable of every event for the selected organization.
- "Geographic footprint": a Leaflet map of the localities where the organization has been recorded.
- "Tactical signature and crowd size": a horizontal bar of the organization's top tactics, plus a density plot of crowd sizes across the entire dataset with a vertical line at this organization's median crowd size for context.
- "Coalition network for this organization": an interactive visNetwork ego-graph of the top 15 organizations this one has co-appeared with on at least two shared events. If the organization has no qualifying ties, the panel shows a "No coalition partners on file" message instead.

Justification: lets a reader profile any organization in the dataset along its geographic, tactical, and coalition dimensions.

### Public Opinion

What it contains:
- "Comparing the two thermometers: Black Lives Matter vs. Police": a dumbbell chart of mean Black Lives Matter and police thermometer ratings (0–100) per group, with a dropdown that switches the breakdown between party identification and race or ethnicity.
- "Pick a question to see how Americans answered it": a dropdown with 13 question/breakdown combinations covering BLM warmth, police warmth, frequency of police using more force than necessary, perceived differential treatment by police and federal government, perceived discrimination against Black Americans, and views on urban unrest. Picking an entry renders a stacked Likert chart of the response distribution.

Justification: grounds the protest record against a population-level snapshot of public attitudes from late 2024.
