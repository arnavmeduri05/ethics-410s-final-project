# U.S. Protest on Race and Policing (2021–2026)

This documentation memo details how to navigate and use the dashboard I created for my final project as part of Ethics 410s. To run the dashboard, please follow the steps below in Setup. Alternatively, you can access the deployed website at [placeholder URL].

## Setup

1. Install the required R packages:

   ```bash
   Rscript -e 'install.packages(c("shiny", "shinydashboard", "tidyverse", "lubridate", "ggplot2", "ggrepel", "plotly", "leaflet", "visNetwork", "DT", "RColorBrewer", "igraph"))'
   ```

2. Confirm the source files are in `data/` (already in this repo via Git LFS):
   - `data/ccc_compiled_20212024.csv` (CCC phase 2, 2021–2024)
   - `data/ccc-phase3-public.csv` (CCC phase 3, 2024 onward)
   - `data/anes_timeseries_2024_csv_20250808.csv` (ANES 2024)

3. Run the data prep script once to generate the cleaned RDS files in `data/clean/`:

   ```bash
   Rscript data/clean.R
   ```

4. Launch the dashboard:

   ```bash
   Rscript -e 'shiny::runApp("app.R")'
   ```

## Data sources

I used two datasets for this dashboard: the Crowd Counting Consortium dataset for the protest event record, and the ANES 2024 Time Series Study for the public opinion environment surrounding it.

**Crowd Counting Consortium (CCC)**: This was the source I used for every protest event in the dashboard. The dataset includes information at the event level (e.g., date, location, claims summary, organizing groups, estimated crowd size, arrest count, news sources cited, and a left-leaning or right-leaning valence assigned by the source coders).

* Public access link: <https://dataverse.harvard.edu/dataverse/crowdcountingconsortium>
* I used CCC for every chart on every tab except Public Opinion.
* Located in `data/`: `ccc_compiled_20212024.csv` (phase 2) and `ccc-phase3-public.csv` (phase 3).

**ANES 2024 Time Series Study**: This was the source I used for every public opinion measure on the Public Opinion tab. The dataset includes nationally representative survey responses from the 2024 wave on race, policing, party identification, race or ethnicity, and related demographic and attitudinal variables.

* Public access link: <https://electionstudies.org/data-center/2024-time-series-study/>
* I used ANES for the dumbbell chart and the Likert charts on the Public Opinion tab.
* Located in `data/`: `anes_timeseries_2024_csv_20250808.csv` (data) and `anes_timeseries_2024_userguidecodebook_20250808.pdf` (variable codebook).

## Tabs

### About this Dashboard

This tab is a brief introduction to the dashboard. It explains the project at a high level, walks through the data I pulled from the Crowd Counting Consortium and the ANES 2024 study and how I used each in this dashboard, and includes a codebook for every variable that appears in the visualizations. Please use it as a reference before reading any chart on the other tabs.

### Overview

The Overview tab provides a general overview of race and policing protest activity in the United States from January 2021 through February 2026. At the top of the tab, four value boxes show the headline counts for the dataset: total left-leaning events, total right-leaning events, total arrests across events, and total same-day same-city encounters between the two sides. Below the value boxes, a weekly events chart plots left-leaning events above the axis and right-leaning events mirrored below, with key reference dates labeled on the timeline so the spikes around specific moments are easy to read. Below the weekly chart, an animated map plots each event as a point on a U.S. base map. To use the animated map, switch between the three views (all events by side, left-leaning sub-movements, right-leaning sub-movements) using the radio buttons above the map, then press play or drag the slider to scrub through months. At the bottom of the tab, a most-covered events bar chart lists the fifteen events with the largest number of distinct news sources cited, with a callout explaining why some of the most-covered protests are not primarily about race or policing.

### Mobilization Geography

This tab provides a geographic view of where each side mobilizes and an explorer for the days both sides showed up in the same city. At the top of the tab, a clustered map plots every qualifying event in the dataset, colored by side. To filter the map by side, use the radio button above the map (Both, Left-leaning only, Right-leaning only). Below the map, two bar charts rank the top fifteen cities by left-leaning event count and by right-leaning event count, side by side, so the cities that anchor each side's mobilization are visible at a glance. Below the bar charts, an encounter explorer table lists every same-day same-city encounter, sorted by total events that day. To drill into a specific contested day, click any row in the encounter table. The map at the top will zoom to that city, switch to show only that day's events, and a description card will appear below the table summarizing the day's tactical mix, top organizations, and most common claims.

### Tactics and Framing

This tab provides a comparative view of what each side does and what each side advocates for or against. The Tactical Repertoire section at the top shows two bar charts ranking the top ten event types per side (rallies, marches, vigils, demonstrations, and so on), so the difference in repertoire between left-leaning and right-leaning protest is visible at a glance. Below that, the Framing section shows two diverging plotly bar charts of the most-mentioned issues per side, with bars to the right of zero showing mentions framed as "for" and bars to the left showing mentions framed as "against." To see the full text of any issue label, hover over the corresponding bar in the claims chart.

### Organizational Infrastructure

This tab provides a profile view for any single organization in the dataset. At the top of the tab, a side filter and a searchable dropdown let you pick an organization. Once an organization is selected, the rest of the tab populates automatically: four value boxes show summary statistics (total events, states active in, total arrests, active span), a sortable table lists every recorded event for the organization, a Leaflet map shows the cities where the organization has been active, a panel summarizes the organization's tactical mix and a crowd-size distribution with this organization's median marked against the dataset overall, and a coalition network shows the other organizations it has co-appeared with on at least two of the same events. To profile an organization, narrow the dropdown by side first if you want, then start typing the organization's name. If the selected organization has no qualifying coalition partners, the network panel will show a "No coalition partners on file" message instead of an ego graph.

### Public Opinion

This tab provides a snapshot of U.S. public opinion on race and policing from the ANES 2024 survey. At the top of the tab, a dumbbell chart compares the mean Black Lives Matter and police feeling thermometer ratings (on a 0 to 100 scale) across groups, with the gap between the two dots on each row showing the polarization within that group. To switch the dumbbell breakdown between party identification and race or ethnicity, use the dropdown inside that card. Below the dumbbell, a question selector lets you pick from thirteen survey question and breakdown combinations and renders a stacked Likert chart of the response distribution. To view a different survey question, pick a new entry from the question selector dropdown.
