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

I used two datasets for this dashboard: the Crowd Counting Consortium dataset for the protest event record, and the ANES 2024 Time Series Study for U.S. public opinion data on race and policing.

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

This tab provides a very brief introduction to the project and an introduction to the data I used, walks through my thought process behind how I filtered the dataset, and includes the codebook as well. I would recommend reading this tab first to get context before reading any of the charts on the other tabs.

### Overview

The Overview tab provides a general overview of race and policing protest activity in the United States from January 2021 through February 2026. At the top of the tab, four value boxes show the total number of left-leaning events, the total number of right-leaning events, the total number of arrests across all events, and the total number of same-day same-city encounters between the two sides. Below the value boxes is a weekly events chart, with left-leaning events plotted above the horizontal axis and right-leaning events plotted below it, and key reference dates labeled along the timeline. Below the weekly chart is an animated map that plots each event as a single point on a U.S. base map. To use the animated map, choose one of the three views (all events by side, left-leaning sub-movements, right-leaning sub-movements) using the radio buttons above the map, then press play or drag the slider below the map to step through months. At the bottom of the tab is a bar chart that lists the fifteen events with the largest number of distinct news sources cited, along with a callout that explains why some of those events are not primarily about race or policing.

### Mobilization Geography

The Mobilization Geography tab provides a look into the geographic patterns of protest activity. For example, you can look at where each side of the protest activity is concentrated geographically and at the days when both sides held events in the same city. At the top of the tab is a clustered map of every event in the dataset, colored by side. To filter the map by side, use the radio button above the map (Both, Left-leaning only, Right-leaning only). Below the map are two bar charts that rank the top fifteen cities by left-leaning event count and by right-leaning event count, one chart per side. Below the bar charts is a sortable encounter explorer table that lists every same-day same-city encounter, sorted by total events on that day. To explore a specific encounter, click any row in the table. The map at the top will zoom to that city and show only the events recorded on that day, and a description card will appear below the table with a summary of the day's tactical mix, top organizations, and most common claims.

### Tactics and Framing

The Tactics and Framing tab provides a comparative look at what each side of the protest activity does on the ground and what each side advocates for or against, and is divided into two sections: Tactical Repertoire and Framing. The Tactical Repertoire section at the top of the tab shows two bar charts that rank the top ten event types per side (rallies, marches, vigils, demonstrations, and so on), one chart per side. The Framing section below it shows two diverging plotly bar charts of the most-mentioned issues per side, with bars to the right of zero showing mentions framed as "for" and bars to the left showing mentions framed as "against." To see the full text of any issue label, hover over the corresponding bar in the claims chart.

### Organizational Infrastructure

In the Organizational Infrastructure tab, you can look up any single organization in the dataset and see its profile. At the top of the tab is a side filter and a searchable dropdown. To pick an organization, narrow the dropdown by side first if you want, then start typing the organization's name. Once an organization is selected, the rest of the tab fills in: four value boxes show summary statistics (total events, states active in, total arrests, active span), a sortable table lists every recorded event for the organization, a Leaflet map shows the cities where the organization has been active, a panel summarizes the organization's most-used event types alongside a crowd-size distribution with the organization's median marked against the dataset overall, and a coalition network shows the other organizations it has co-appeared with on at least two of the same events. If the selected organization has no qualifying coalition partners, the network panel will show a "No coalition partners on file" message instead of an ego graph.

### Public Opinion

In the Public Opinion tab, you can look at how Americans answered survey questions about race, policing, and related topics in the ANES 2024 study. At the top of the tab is a dumbbell chart that plots the mean Black Lives Matter feeling thermometer rating and the mean police feeling thermometer rating (on a 0 to 100 scale) for each group, with a horizontal line connecting the two dots on each row. To switch the breakdown between party identification and race or ethnicity, use the dropdown inside that card. Below the dumbbell is a question selector card. To view a different survey question, pick a new entry from the dropdown; the stacked Likert chart below it will update to show the response distribution for that question.
