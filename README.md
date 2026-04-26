# U.S. Race and Policing Protest Explorer

This documentation memo details how to navigate and use the dashboard I created for my final project for Ethics 410S. To run the dashboard, please follow the steps below in Setup. Alternatively, you can access the deployed website at <https://arnavmeduri-ethics-410s-final-project.share.connect.posit.cloud/>.

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
* Located in `data/`: `ccc_compiled_20212024.csv` (phase 2) and `ccc-phase3-public.csv` (phase 3).

**ANES 2024 Time Series Study**: This was the source I used for every public opinion measure on the Public Opinion tab. The dataset includes nationally representative survey responses from the 2024 wave on race, policing, party identification, race or ethnicity, and related demographic and attitudinal variables.

* Public access link: <https://electionstudies.org/data-center/2024-time-series-study/>
* I used ANES for the dumbbell chart and the Likert charts on the Public Opinion tab.
* Located in `data/`: `anes_timeseries_2024_csv_20250808.csv` (data) and `anes_timeseries_2024_userguidecodebook_20250808.pdf` (variable codebook).

## Tabs

### About this Dashboard

This tab provides a very brief introduction to the project and an introduction to the data I used, and also walks through how I filtered the dataset (e.g., what I considered when deciding which events to include). I would recommend reading this tab first to get an understanding of the dashboard before proceeding to the other tabs.

### Overview

The Overview tab provides a general overview of race and policing protest activity in the United States from 2021–2026. At the top of the tab are four value boxes that show the total number of left-leaning events, the total number of right-leaning events, the total number of arrests across all events, and the total number of same-day same-city encounters between the two sides. Below the value boxes is a chart showing weekly event counts for left-leaning and right-leaning protest. Below the weekly chart is an animated map that shows where events occurred over time; to interact with the map, choose a view (i.e., all events by side, left-leaning sub-movements, or right-leaning sub-movements) and press play or drag the slider. At the bottom of the tab is a bar chart that lists the fifteen events with the largest number of distinct news sources cited.

### Mobilization Geography

The Mobilization Geography tab provides a look into the geographic patterns of protest activity. For example, you can look at where each side of the protest activity is concentrated geographically and at the days when both sides held events in the same city. At the top of the tab is a clustered map of every event in the dataset, colored by side. To filter the map by side, use the radio button above the map (Both, Left-leaning only, Right-leaning only). Below the map are two bar charts that rank the top fifteen cities by left-leaning event count and by right-leaning event count, one chart per side. Below the bar charts is a sortable encounter explorer table that lists every same-day same-city encounter, sorted by total events on that day. To explore a specific encounter, click any row in the table. The map at the top will zoom to that city and show only the events recorded on that day, and a description card will appear below the table with a summary of the day's tactical mix, top organizations, and most common claims.

### Tactics and Framing

The Tactics and Framing tab provides a comparative look at what each side of the protest activity does on the ground and what each side advocates for or against, and is divided into two sections: Tactical Repertoire and Framing. The Tactical Repertoire section at the top of the tab shows two bar charts that rank the top ten event types per side (rallies, marches, vigils, demonstrations, and so on), one chart per side. The Framing section below it shows two diverging plotly bar charts of the most-mentioned issues per side, with bars to the right of zero showing mentions framed as "for" and bars to the left showing mentions framed as "against." To see the full text of any issue label, hover over the corresponding bar in the claims chart.

### Organizational Infrastructure

The Organizational Infrastructure tab provides a profile view for any single organization in the dataset. At the top of the tab is a side filter and a searchable dropdown; to pick an organization, narrow the dropdown by side first if you want, then start typing the organization's name. Below the dropdown are four value boxes that show summary statistics for the selected organization (total events, states active in, total arrests, and activity timeline). Below the value boxes is a sortable table that lists every recorded event for the organization. Below the events table is a Leaflet map showing the cities where the organization has been active, alongside a panel that summarizes the organization's most-used event types and a crowd-size distribution with the organization's median marked against the dataset overall. At the bottom of the tab is a coalition network that shows the other organizations the selected one has co-appeared with on at least two of the same events.

### Public Opinion

The Public Opinion tab provides a snapshot of how Americans answered survey questions about race, policing, and related topics in the ANES 2024 study. At the top of the tab is a dumbbell chart that plots the mean Black Lives Matter feeling thermometer rating and the mean police feeling thermometer rating (on a 0 to 100 scale) for each group, with a horizontal line connecting the two dots on each row; to switch the breakdown between party identification and race or ethnicity, use the dropdown inside that card. Below the dumbbell is a question selector card; to view a different survey question, pick a new entry from the dropdown, and the stacked Likert chart below it will update to show the response distribution.
