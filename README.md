# U.S. Protest on Race and Policing (2021–2026)

An interactive R Shiny dashboard documenting protest activity on race and policing in the United States from January 2021 through February 2026, alongside a snapshot of U.S. public opinion from the 2024 American National Election Studies survey. The dashboard places left-leaning protest in deep blue and right-leaning protest in deep maroon on every chart and map, so each side's pattern can be read against the other.

## Setup

```bash
# 1. Install required R packages
Rscript -e 'install.packages(c("shiny", "shinydashboard", "tidyverse", "lubridate", "ggplot2", "ggrepel", "plotly", "leaflet", "visNetwork", "DT", "RColorBrewer", "igraph"))'

# 2. Place raw source files in data/
#    - data/ccc_compiled_20212024.csv               (CCC phase 2)
#    - data/ccc-phase3-public.csv                   (CCC phase 3)
#    - data/anes_timeseries_2024_csv_20250808.csv   (ANES 2024)

# 3. Run the data prep script once to generate the cleaned RDS files
Rscript data/clean.R

# 4. Launch the dashboard
Rscript -e 'shiny::runApp("app.R")'
```

## Documentation memo

### Overview

The dashboard is built around Meyer and Staggenborg's argument that movements and the countermovements that contest them must be studied as a single interactive system. Every comparative view places left-leaning and right-leaning protest side by side, on the same axes, the same maps, and the same tables, so the asymmetry of mobilization is visible at a glance. Six tabs walk a reader from methodology through scale, geography, tactics, organizations, and ending with public opinion as both context and outcome. The protest record is drawn from the Crowd Counting Consortium dataset; public opinion is drawn from the ANES 2024 Time Series Study.

### About this Dashboard

This tab documents how the dataset was filtered, the two source datasets, and a full codebook for every variable used in the dashboard. The codebook is split into three tables: the variables drawn directly from the Crowd Counting Consortium files, the variables I computed from those source files inside `data/clean.R`, and the variables from the ANES 2024 study. Both data sources include a description, sample notes, and a public-access link.

*Justification.* Putting the filtering rules and the codebook at the top of the dashboard makes the methodology auditable. A reader can verify exactly what is and is not in scope before interpreting any chart, and the inclusion rules are framed plainly: an event is kept if its source coders tagged it with `policing`, or if it was tagged with `racism` and the title or claims summary explicitly mentioned race or policing language.

### Overview

This tab shows the headline scale of mobilization. Four value boxes summarize left-leaning event count, right-leaning event count, total arrests across events, and total same-day same-city encounters. A mirrored weekly events chart plots left-leaning events above the axis and right-leaning events below, with key reference dates labeled. A three-view animated map lets the user scrub through months and switch between all events by side, left-leaning sub-movements, and right-leaning sub-movements. A most-covered events bar chart surfaces the fifteen events with the largest number of distinct news sources cited.

*Justification.* The mirrored chart and the animated map make the relative scale of each side legible over time and across geography. The most-covered events list illustrates frame extension directly by surfacing multi-issue marches that incidentally include race or policing claims, with an inline note explaining why those events qualify under the filter.

### Mobilization Geography

This tab answers two questions in sequence: where on the map does each side concentrate, and where and when do the two sides actually collide? A clustered map of every qualifying event includes a side filter (Both, Left-leaning only, Right-leaning only). Two top-cities bar charts rank cities separately by left- and right-leaning event count, surfacing right-leaning strongholds that would otherwise be drowned out by larger left-leaning totals. An encounter explorer table lists every same-day same-city encounter. Clicking a row zooms the map to that city, replaces the all-time cluster overlay with markers for only that day's events, and surfaces a description card with the tactical mix, top organizations, and most common claims.

*Justification.* Meyer and Staggenborg argue that movements and countermovements compete across multiple arenas. This tab focuses on the streets specifically, surfacing same-day same-city encounters as the moments where the two sides directly meet.

### Tactics and Framing

This tab visualizes Tilly's repertoire and Snow et al.'s frame extension. The Tactical Repertoire section ranks the most common forms of action used at left-leaning events and at right-leaning events. The Framing section parses each event's claims summary into stance (for or against) and issue, then plots the most-mentioned issues for each side as a diverging bar chart with hover tooltips for full issue text.

*Justification.* The bars read as a coalition map: each side's core frame visibly stretches to encompass adjacent groups' interests, which is frame extension in action.

### Organizational Infrastructure

This tab profiles individual social movement organizations. After narrowing by side, picking an organization populates four value boxes (total events, states active in, total arrests, active span), a sortable events table, a leaflet geographic footprint map, a tactical signature panel showing top tactics and a crowd-size distribution with this organization's median compared to the overall median, and a coalition network of the top organizations it has co-mobilized with on at least two shared events.

*Justification.* Lune and Chen describe SMOs as the durable infrastructure of a movement; Almeida adds that organizations carry frames across events. Each profile treats one organization as a node and shows its geographic, tactical, and coalition footprint.

### Public Opinion

This tab grounds the protest record in a snapshot of public attitudes from ANES 2024. A dumbbell chart compares mean BLM and police thermometer ratings with a dropdown to switch between party identification and race breakdowns. A single-card question selector pairs each survey question with a breakdown dimension and renders the resulting Likert chart.

*Justification.* Following Snow and Soule, protest movements are best evaluated against the cultural and attitudinal shifts they produce. The questions span feelings toward BLM and police, perceived differential treatment, perceived discrimination, and the best response to urban unrest.

## Data sources

- **Crowd Counting Consortium**: <https://dataverse.harvard.edu/dataverse/crowdcountingconsortium>
- **ANES 2024 Time Series Study**: <https://electionstudies.org/data-center/2024-time-series-study/>
