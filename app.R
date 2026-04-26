suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(tidyverse)
  library(lubridate)
  library(ggplot2)
  library(ggrepel)
  library(plotly)
  library(leaflet)
  library(visNetwork)
  library(DT)
})

PRO_COLOR <- "#2c5282"
ANTI_COLOR <- "#9c2a2a"
PRO_LABEL <- "Left-leaning"
ANTI_LABEL <- "Right-leaning"
side_colors <- setNames(c(PRO_COLOR, ANTI_COLOR), c(PRO_LABEL, ANTI_LABEL))

LIKERT_5 <- RColorBrewer::brewer.pal(5, "Blues")
LIKERT_7 <- RColorBrewer::brewer.pal(7, "Blues")

events <- readRDS("data/clean/events.rds")
orgs_long <- readRDS("data/clean/orgs_long.rds")
encounters <- readRDS("data/clean/encounters.rds")
org_summary <- readRDS("data/clean/org_summary.rds")
co_edges <- readRDS("data/clean/co_edges.rds")
claim_objects <- readRDS("data/clean/claim_objects.rds")
anes_blm_bin_by_party <- readRDS("data/clean/anes_blm_bin_by_party.rds")
anes_blm_bin_by_race <- readRDS("data/clean/anes_blm_bin_by_race.rds")
anes_police_bin_by_party <- readRDS("data/clean/anes_police_bin_by_party.rds")
anes_police_bin_by_race <- readRDS("data/clean/anes_police_bin_by_race.rds")
anes_force_by_party <- readRDS("data/clean/anes_force_by_party.rds")
anes_force_by_race <- readRDS("data/clean/anes_force_by_race.rds")
anes_treat_by_party <- readRDS("data/clean/anes_treat_by_party.rds")
anes_treat_by_race <- readRDS("data/clean/anes_treat_by_race.rds")
anes_fedgov_by_party <- readRDS("data/clean/anes_fedgov_by_party.rds")
anes_fedgov_by_race <- readRDS("data/clean/anes_fedgov_by_race.rds")
anes_disc_by_party <- readRDS("data/clean/anes_disc_by_party.rds")
anes_disc_by_race <- readRDS("data/clean/anes_disc_by_race.rds")
anes_unrest_by_party <- readRDS("data/clean/anes_unrest_by_party.rds")
anes_by_party <- readRDS("data/clean/anes_by_party.rds")
anes_by_race <- readRDS("data/clean/anes_by_race.rds")

recode_side <- function(x) {
  fct_recode(as.factor(x),
             !!PRO_LABEL := "Pro-movement",
             !!ANTI_LABEL := "Counter-movement")
}
events$side <- recode_side(events$side)
orgs_long$side <- recode_side(orgs_long$side)
org_summary$dominant_side <- recode_side(org_summary$dominant_side)
claim_objects$side <- recode_side(claim_objects$side)

recode_ba <- function(df) {
  df |> mutate(answer = recode(as.character(answer),
    "Whites much better" = "White Americans much better",
    "Whites moderately better" = "White Americans moderately better",
    "Whites a little better" = "White Americans a little better",
    "Blacks a little better" = "Black Americans a little better",
    "Blacks moderately better" = "Black Americans moderately better",
    "Blacks much better" = "Black Americans much better"))
}
anes_treat_by_party <- recode_ba(anes_treat_by_party)
anes_treat_by_race <- recode_ba(anes_treat_by_race)
anes_fedgov_by_party <- recode_ba(anes_fedgov_by_party)
anes_fedgov_by_race <- recode_ba(anes_fedgov_by_race)

events_pc <- events |> filter(side %in% c(PRO_LABEL, ANTI_LABEL))

ref_dates <- tibble(
  label = c("Chauvin verdict", "Buffalo Tops shooting",
            "Tyre Nichols killed", "Affirmative action overturned",
            "Sonya Massey killed", "2024 election",
            "Trump's 2nd inauguration",
            "Labor Day: Workers Over Billionaires",
            "ICE Out national day"),
  date = as.Date(c("2021-04-20", "2022-05-14",
                   "2023-01-07", "2023-06-29",
                   "2024-07-06", "2024-11-05",
                   "2025-01-20",
                   "2025-09-01",
                   "2026-01-26"))
)

classify_left_sub <- function(title, claims) {
  text <- tolower(paste(coalesce(title, ""), coalesce(claims, "")))
  case_when(
    str_detect(text, "aapi|stop asian hate|anti-asian|asian american") ~ "Anti-AAPI hate",
    str_detect(text, "hands off|no kings|tesla takedown|workers over billionaires") ~ "Hands Off! / No Kings coalition",
    str_detect(text, "\\bice\\b|deportation|immigration raid|migrant|asylum") ~ "Anti-ICE / immigration",
    str_detect(text, "blm|black lives|floyd|nichols|massey|police brutality|police violence|police accountability|police terrorism|cop city|atlanta forest|weelaunee") ~ "Anti-police-violence",
    TRUE ~ "Other left-leaning"
  )
}

classify_right_sub <- function(title, claims) {
  text <- tolower(paste(coalesce(title, ""), coalesce(claims, "")))
  case_when(
    str_detect(text, "white supremacy|white nationalism|white nationalist|patriot front|nsc-?131|antisemitism") ~ "White-nationalist / supremacist",
    str_detect(text, "critical race theory|\\bcrt\\b|\\bdei\\b|diversity, equity|anti-woke|anti woke") ~ "Anti-CRT / anti-DEI",
    str_detect(text, "covid|vaccine mandate|medical freedom|j6|january 6|election fraud|election integrity|stop the steal") ~ "COVID mandates / January 6 / election integrity",
    str_detect(text, "patriotism|\\bfreedom\\b|christian values|second amendment|back the blue|blue lives") ~ "Patriot / freedom / Christian values",
    TRUE ~ "Other right-leaning"
  )
}

left_sub_levels <- c(
  "Anti-police-violence",
  "Anti-ICE / immigration",
  "Hands Off! / No Kings coalition",
  "Anti-AAPI hate",
  "Other left-leaning"
)
left_sub_palette <- setNames(RColorBrewer::brewer.pal(5, "Dark2"), left_sub_levels)

right_sub_levels <- c(
  "White-nationalist / supremacist",
  "Patriot / freedom / Christian values",
  "Anti-CRT / anti-DEI",
  "COVID mandates / January 6 / election integrity",
  "Other right-leaning"
)
right_sub_palette <- setNames(RColorBrewer::brewer.pal(5, "Set1"), right_sub_levels)

events_geo <- events_pc |>
  filter(!is.na(lat), !is.na(lon)) |>
  mutate(month = floor_date(date, "month"),
         month_label = format(month, "%Y-%m"))

events_geo_left <- events_geo |>
  filter(side == PRO_LABEL) |>
  mutate(sub = classify_left_sub(title, claims_summary),
         sub = factor(sub, levels = left_sub_levels))
events_geo_right <- events_geo |>
  filter(side == ANTI_LABEL) |>
  mutate(sub = classify_right_sub(title, claims_summary),
         sub = factor(sub, levels = right_sub_levels))

city_side_counts <- events_pc |>
  filter(!is.na(resolved_locality), resolved_locality != "",
         !is.na(resolved_state),    resolved_state != "") |>
  mutate(city = paste0(resolved_locality, ", ", resolved_state)) |>
  count(city, side, name = "events")

top_cities_left <- city_side_counts |>
  filter(side == PRO_LABEL) |>
  slice_max(events, n = 15) |>
  arrange(events) |>
  mutate(city = factor(city, levels = city))

top_cities_right <- city_side_counts |>
  filter(side == ANTI_LABEL) |>
  slice_max(events, n = 15) |>
  arrange(events) |>
  mutate(city = factor(city, levels = city))

org_choices <- org_summary |>
  arrange(desc(events)) |>
  pull(org)

derive_title <- function(title, event_type, locality, state) {
  has_title <- !is.na(title) & title != ""
  fallback <- paste0(
    ifelse(is.na(event_type) | event_type == "", "Event",
           tools::toTitleCase(as.character(event_type))),
    ifelse(is.na(locality) | locality == "", "",
           paste0(" in ", locality, ", ", state))
  )
  ifelse(has_title, title, fallback)
}

events_for_map <- events_pc |>
  filter(!is.na(lat), !is.na(lon)) |>
  mutate(
    title_disp = derive_title(title, event_type, resolved_locality, resolved_state),
    side_chr = as.character(side),
    color = ifelse(side_chr == PRO_LABEL, PRO_COLOR, ANTI_COLOR),
    popup_html = paste0(
      "<b>", title_disp, "</b><br>",
      format(date, "%b %d, %Y"), " &middot; ",
      resolved_locality, ", ", resolved_state, "<br>",
      "<i>", side_chr, "</i><br>",
      "<b>Event type:</b> ",
      ifelse(is.na(event_type), "(unknown)", event_type),
      ifelse(is.na(organizations) | organizations == "", "",
             paste0("<br><b>Organizations:</b> ",
                    gsub(";", "; ", organizations, fixed = TRUE))),
      ifelse(is.na(claims_summary) | claims_summary == "", "",
             paste0("<br><i>",
                    gsub(";", "; ", claims_summary, fixed = TRUE), "</i>"))
    )
  )

encounters_for_map <- encounters |>
  left_join(events_pc |> filter(!is.na(lat), !is.na(lon)) |>
              group_by(date, resolved_locality, resolved_state) |>
              summarise(lat = mean(lat), lon = mean(lon), .groups = "drop"),
            by = c("date", "resolved_locality", "resolved_state")) |>
  filter(!is.na(lat), !is.na(lon)) |>
  mutate(total = pro_events + anti_events,
         popup_html = paste0(
           "<b>", resolved_locality, ", ", resolved_state, "</b><br>",
           format(date, "%b %d, %Y"), "<br>",
           PRO_LABEL,  ": ", pro_events,  "<br>",
           ANTI_LABEL, ": ", anti_events
         ))

top_event_types <- events_pc |>
  filter(!is.na(event_type), event_type != "") |>
  mutate(event_type = tools::toTitleCase(event_type)) |>
  count(side, event_type, name = "events") |>
  group_by(side) |>
  slice_max(events, n = 10) |>
  ungroup()

media_top_events <- events_pc |>
  filter(!is.na(n_sources), n_sources > 0,
         !is.na(title), title != "") |>
  arrange(desc(n_sources)) |>
  slice_head(n = 15) |>
  mutate(label = paste0(title, " (",
                        coalesce(resolved_locality, "?"), ", ",
                        coalesce(resolved_state, "?"), ", ",
                        format(date, "%b %Y"), ")"),
         label_short = str_trunc(label, 70))

total_arrests_dataset <- sum(events_pc$arrests, na.rm = TRUE)
encounters_n <- nrow(encounters)

codebook_ccc <- tibble::tribble(
  ~Variable,            ~`Type / values`,                                       ~Description,
  "date",               "Date (YYYY-MM-DD)",                                    "The day the event was held.",
  "event_type",         "Categorical (rally, march, vigil, demonstration, sit-in, etc.)", "Form of action used at the event.",
  "title",              "Free text",                                            "Event title as recorded by the source coders, when available.",
  "organizations",      "Semicolon-separated free text",                        "Names of the organizations recorded as participating or organizing.",
  "claims_summary",     "Semicolon-separated free text, each phrase prefixed with for or against", "Short claim phrases describing what the event was for or against.",
  "issues",             "Semicolon-separated tags",                             "CCC topical tags applied to the event (e.g., racism, policing, immigration, healthcare).",
  "valence",            "Integer: 1 = left-leaning, 2 = right-leaning, 0 = neither", "Source coders' classification of the event's political valence.",
  "size_mean",          "Numeric (integer count)",                              "Estimated crowd size, the mean of the low and high estimates published by CCC.",
  "arrests",            "Numeric (integer count)",                              "Number of arrests recorded at the event.",
  "lat / lon",          "Numeric (decimal degrees)",                            "Geocoded latitude and longitude of the event.",
  "resolved_locality",  "Free text",                                            "Geocoded city or municipality name.",
  "resolved_state",     "Two-letter postal code",                               "Geocoded U.S. state.",
  "online",             "Binary: 1 = online, 0 = in person",                    "Whether the event was held online rather than in person.",
  "participant_measures","Free text",                                           "Notes on participants (e.g., armed, masked) when CCC source coders recorded them.",
  "police_measures",    "Free text",                                            "Notes on police presence or response (e.g., tear gas, arrests).",
  "macroevent",         "Free text",                                            "Identifier linking the event to a wider macroevent (e.g., a national day of action), when applicable.",
  "n_sources",          "Numeric (integer count)",                              "Count of distinct news sources cited by CCC for this event; used as a proxy for press coverage.",
  "phase",              "Categorical: P2 or P3",                                "Which CCC source file the row came from (phase 2 file 2021 to 2024, phase 3 file 2024 onward)."
)

codebook_derived <- tibble::tribble(
  ~Variable,         ~`Type / values`,                                         ~`Computed from`,                                                ~Description,
  "side",            "Factor: Left-leaning, Right-leaning, Neither/Unknown",   "valence",                                                        "Human-readable side label used throughout the dashboard. Comparative charts drop Neither/Unknown.",
  "in_scope",        "Logical (filter applied during data prep)",              "issues, title, claims_summary",                                  "Inclusion filter: an event is kept if it has the policing tag, or it has the racism tag plus race or policing language in its title or claims summary.",
  "encounter",       "One row per (date, locality, state) where both sides have at least one event", "events with side in {Left-leaning, Right-leaning}", "Same-day same-city pairing of left- and right-leaning events. Drives the Mobilization Geography tab encounter explorer.",
  "co_edges",        "Edge list (organization-organization, weight)",          "exploded organizations on each event",                           "Pairs of organizations that co-occurred on at least two of the same events. Drives the coalition network on each organization profile.",
  "claim_objects",   "Long-format counts per (side, object, stance)",          "claims_summary parsed into stance + object",                     "Each claim phrase is split on the leading 'for' or 'against' verb to yield a stance and an issue object. Drives the claims bars on Tactics and Framing.",
  "n_sources",       "Integer count per event",                                "raw CCC source_1 ... source_30 columns (P2) and source1 ... source30 (P3)", "Number of non-empty source URLs cited for the event; used as a proxy for press coverage."
)

codebook_ccc_combined <- dplyr::bind_rows(
  codebook_ccc |>
    dplyr::mutate(Source = "Drawn directly from CCC files",
                  `Computed from` = NA_character_),
  codebook_derived |>
    dplyr::mutate(Source = "Computed from CCC inside data/clean.R")
) |>
  dplyr::select(Variable, Source, `Type / values`, `Computed from`, Description)

codebook_anes <- tibble::tribble(
  ~Variable,             ~`ANES code`, ~`Values / scale`,                                                                                                   ~Description,
  "party",               "V241227x",   "Strong Democrat, Weak Democrat, Independent leaning Democrat, Independent, Independent leaning Republican, Weak Republican, Strong Republican", "Summary 7-point party identification.",
  "race",                "V241501x",   "White, Black, Hispanic, Asian or Pacific Islander, Native or other, Multiple",                                       "Summary race or ethnicity.",
  "ft_blm",              "V242152",    "Feeling thermometer, 0 to 100",                                                                                      "Warmth toward the Black Lives Matter movement (0 = very cold, 100 = very warm).",
  "ft_police",           "V242150",    "Feeling thermometer, 0 to 100",                                                                                      "Warmth toward the police.",
  "police_more_force",   "V242336",    "Never, Rarely, About half the time, Most of the time, All the time",                                                 "How often the respondent thinks police use more force than necessary.",
  "police_treat",        "V242525x",   "7 levels from White Americans much better to Black Americans much better",                                            "Whether the respondent thinks police treat White or Black Americans better.",
  "fedgov_treat",        "V242522x",   "7 levels from White Americans much better to Black Americans much better",                                            "Whether the respondent thinks the federal government treats White or Black Americans better.",
  "societal_disc",       "V242549",    "A great deal, A lot, A moderate amount, A little, None at all",                                                      "How much discrimination the respondent thinks there is against Black Americans in the United States today.",
  "unrest",              "V241397",    "7 levels from 1: Solve racism / police violence to 7: Use all available force",                                       "What the respondent thinks is the best way to deal with urban unrest."
)

codebook_dt <- function(d) {
  DT::datatable(d, rownames = FALSE,
                escape = FALSE,
                options = list(pageLength = 25, dom = "t",
                               ordering = FALSE,
                               columnDefs = list(list(className = "dt-top",
                                                      targets = "_all"))),
                class = "compact stripe hover")
}

all_sizes <- events_pc$size_mean
all_sizes <- all_sizes[!is.na(all_sizes) & all_sizes > 0]
size_dist_overall <- tibble(size = all_sizes,
                            log_size = log10(all_sizes))

capitalize_clauses <- function(x) {
  vapply(x, function(s) {
    if (is.na(s) || s == "") return(coalesce(s, ""))
    parts <- strsplit(s, ";")[[1]] |> stringr::str_trim()
    parts <- ifelse(parts == "", parts,
                    paste0(toupper(substr(parts, 1, 1)),
                           substr(parts, 2, nchar(parts))))
    paste(parts, collapse = "; ")
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)
}

empty_msg_plot <- function(msg) {
  ggplot() +
    annotate("text", x = 0, y = 0, label = msg, color = "#888", size = 4) +
    theme_void()
}

callout_box <- function(..., variant = "info") {
  styles <- switch(
    variant,
    info = list(border = "#2c5282", bg = "#eef4fb",
                badge_bg = "#2c5282", badge = "Note"),
    theory = list(border = "#b7791f", bg = "#fdf6e3",
                  badge_bg = "#b7791f", badge = "The Big Picture"),
    list(border = "#2c5282", bg = "#eef4fb",
         badge_bg = "#2c5282", badge = "Note")
  )
  tags$div(
    style = paste0(
      "border-left: 4px solid ", styles$border, ";",
      "background: ", styles$bg, ";",
      "padding: 12px 16px;",
      "margin: 12px 0;",
      "border-radius: 0 6px 6px 0;",
      "color: #2d3748;",
      "line-height: 1.55;"),
    tags$span(
      style = paste0(
        "display: inline-block;",
        "background: ", styles$badge_bg, ";",
        "color: #fff;",
        "padding: 2px 8px;",
        "border-radius: 3px;",
        "font-size: 11px;",
        "font-weight: 600;",
        "letter-spacing: 0.04em;",
        "text-transform: uppercase;",
        "margin-bottom: 8px;"),
      styles$badge
    ),
    tags$div(...)
  )
}

ui <- dashboardPage(
  title = "U.S. Race and Policing Protest Explorer",
  dashboardHeader(title = tags$span(icon("people-group"), " ",
                                    "U.S. Race and Policing Protest Explorer"),
                  titleWidth = 460),
  dashboardSidebar(
    width = 260,
    sidebarMenu(
      menuItem("About this Dashboard",           tabName = "about"),
      menuItem("Overview",                       tabName = "overview"),
      menuItem("Mobilization Geography",         tabName = "mobilization"),
      menuItem("Tactics and Framing",            tabName = "tactics"),
      menuItem("Organizational Infrastructure",  tabName = "orgs"),
      menuItem("Public Opinion",                 tabName = "opinion")
    )
  ),
  dashboardBody(
    tabItems(

      tabItem(
        tabName = "about",
        fluidRow(
          column(width = 12,
                 tags$h2("About this Dashboard",
                         style = "margin: 4px 0 12px 0;"),
                 tags$p(style = "color:#444; font-size: 15px; margin: 0 0 8px 0;",
                        "This dashboard is meant to be a resource for anyone looking to learn about race and policing protest in the United States. It documents protest activity between January 2021 and February 2026, alongside a snapshot of U.S. public opinion from late 2024 (the American National Election Studies survey)."),
                 tags$p(style = "color:#444; font-size: 15px; margin: 0 0 6px 0;",
                        HTML("I filtered the Crowd Counting Consortium dataset based on two rules: (1) I kept events the source coders had tagged with <em>policing</em>; and (2) I kept events the source coders had tagged with <em>racism</em> only if the event's title or claims summary also explicitly mentioned race or policing language (e.g., Black Lives Matter, police brutality, white supremacy, civil rights, immigration enforcement). I also dropped events whose left-versus-right valence (the source coders' indicator of whether an event leans politically left or right) was missing or neutral, so left-leaning and right-leaning mobilization could be compared directly."))
          )
        ),
        fluidRow(
          box(title = "Data Source #1: Crowd Counting Consortium",
              width = 12, status = "primary", solidHeader = TRUE,
              tags$div(
                style = "padding: 4px 0 0 0;",
                tags$h5("Description",
                        style = "color:#2c5282; font-weight: 600;
                                 border-bottom: 1px solid #e2e8f0;
                                 padding-bottom: 4px; margin: 0 0 8px 0;"),
                tags$p(style = "margin: 0 0 8px 0;",
                       "Source for every protest event in the dashboard. A public crowdsourced project, co-founded by Erica Chenoweth and Jeremy Pressman, that compiles political crowds in the United States from media reports, organizer statements, and on-the-ground observation. Each event record carries a date, a location, a claims summary, the organizing groups, an estimated crowd size, an arrest count, the news sources cited, and a left-leaning or right-leaning valence assigned by the source coders. Coverage used here: January 2021 through February 2026, from the compiled phase-2 file (2021 to 2024) and the phase-3 public file (2024 onward)."),
                tags$p(style = "margin: 0 0 18px 0;",
                       tags$b("Public access: "),
                       tags$a(href = "https://dataverse.harvard.edu/dataverse/crowdcountingconsortium",
                              target = "_blank",
                              "https://dataverse.harvard.edu/dataverse/crowdcountingconsortium")),
                tags$h5("Codebook: variables drawn directly from the source files",
                        style = "color:#2c5282; font-weight: 600;
                                 border-bottom: 1px solid #e2e8f0;
                                 padding-bottom: 4px; margin: 0 0 8px 0;"),
                DTOutput("codebook_ccc"),
                tags$h5("Codebook: variables I computed from the source files",
                        style = "color:#2c5282; font-weight: 600;
                                 border-bottom: 1px solid #e2e8f0;
                                 padding-bottom: 4px; margin: 22px 0 8px 0;"),
                DTOutput("codebook_derived")
              ))
        ),
        fluidRow(
          box(title = "Data Source #2: ANES 2024 Time Series Study",
              width = 12, status = "primary", solidHeader = TRUE,
              tags$div(
                style = "padding: 4px 0 0 0;",
                tags$h5("Description",
                        style = "color:#2c5282; font-weight: 600;
                                 border-bottom: 1px solid #e2e8f0;
                                 padding-bottom: 4px; margin: 0 0 8px 0;"),
                tags$p(style = "margin: 0 0 8px 0;",
                       "Source for every public opinion measure in the dashboard. The American National Election Studies Time Series Study is a long-running probability-sample survey of the United States adult population, fielded around each presidential election. The 2024 wave was administered before and after the November 2024 election. Sample used here: post-election interviews; n = 5,521. Within-group percentages on the Public Opinion tab are unweighted for legibility."),
                tags$p(style = "margin: 0 0 18px 0;",
                       tags$b("Public access: "),
                       tags$a(href = "https://electionstudies.org/data-center/2024-time-series-study/",
                              target = "_blank",
                              "https://electionstudies.org/data-center/2024-time-series-study/")),
                tags$h5("Codebook",
                        style = "color:#2c5282; font-weight: 600;
                                 border-bottom: 1px solid #e2e8f0;
                                 padding-bottom: 4px; margin: 0 0 8px 0;"),
                DTOutput("codebook_anes")
              ))
        )
      ),

      tabItem(
        tabName = "overview",
        fluidRow(
          column(width = 12,
                 callout_box(
                   variant = "theory",
                   tags$p(style = "margin: 0;",
                          HTML("<b>Movement and countermovement mobilization.</b> David S. Meyer and Suzanne Staggenborg argue that a movement and the countermovement that opposes it must be studied as a single interactive system, since each side's tactics, framings, and victories influence the other's response."))
                 )
          )
        ),
        fluidRow(
          valueBoxOutput("vb_pro",        width = 3),
          valueBoxOutput("vb_anti",       width = 3),
          valueBoxOutput("vb_arrests",    width = 3),
          valueBoxOutput("vb_encounters", width = 3)
        ),
        fluidRow(
          box(title = "Events per week",
              width = 12, status = "primary", solidHeader = TRUE,
              p("Weekly events for the movement (above the axis) and the countermovement (mirrored below), with key reference dates labeled."),
              plotOutput("overview_wow", height = "520px"))
        ),
        fluidRow(
          box(title = "Animated Map of Events Over Time",
              width = 12, status = "primary", solidHeader = TRUE,
              p("Each point is one protest event. Use the radio buttons below to switch between three views. Press play or drag the slider to scrub through months."),
              radioButtons("overview_geo_view", label = NULL, inline = TRUE,
                           choices = c("All events by side" = "all",
                                       "Left-leaning by sub-movement" = "left",
                                       "Right-leaning by sub-movement" = "right"),
                           selected = "all"),
              plotlyOutput("overview_geo_anim", height = "520px"))
        ),
        fluidRow(
          box(title = "Most-Covered Individual Events",
              width = 12, status = "primary", solidHeader = TRUE,
              tags$p("The fifteen events with the largest number of distinct news sources cited in the dataset. Bar length is the count of distinct sources; color marks the side."),
              tags$div(
                style = "border-left: 4px solid #b7791f;
                         background: #fdf6e3;
                         padding: 10px 14px 10px 14px;
                         margin: 8px 0 12px 0;
                         border-radius: 0 6px 6px 0;
                         color: #2d3748;",
                tags$div(style = "display: flex; align-items: flex-start; gap: 10px;",
                  tags$div(style = "flex: 0 0 auto; color: #b7791f; font-size: 18px; line-height: 1; padding-top: 1px;",
                           icon("circle-info")),
                  tags$div(
                    tags$p(style = "margin: 0 0 6px 0;",
                           tags$b("Why some events here are not primarily about race or policing.")),
                    tags$p(style = "margin: 0;",
                           HTML("Many of the most-covered protests are large multi-issue mass marches (e.g., marches on the Democratic or Republican National Convention, Bigger Than Roe, or Gaza solidarity rallies, whose dominant frame is something other than race or policing), but appear here because the Crowd Counting Consortium source coders tagged them with <em>policing</em> or <em>racism</em>. This is <em>frame extension</em> in action (see the Tactics and Framing tab)."))
                  )
                )
              ),
              plotOutput("overview_media_top", height = "440px"))
        )
      ),

      tabItem(
        tabName = "mobilization",
        fluidRow(
          column(width = 12,
                 tags$h2("How do the two sides mobilize on the ground?",
                         style = "margin: 4px 0 6px 0;"),
                 tags$p(style = "color:#555; margin: 0 0 14px 0;",
                        "This page answers two questions in sequence. First, where on the map does each side concentrate its activity? Second, where and when do the two sides actually collide on the same day in the same city? Use the side filter on the map to isolate one side, then scroll down to the encounter explorer to find specific contested days and drill into the underlying events."),
                 callout_box(
                   variant = "theory",
                   tags$p(style = "margin: 0;",
                          HTML("<b>Movements and countermovements.</b> David S. Meyer and Suzanne Staggenborg argue that a countermovement emerges in response to a movement's apparent gains, that movement and countermovement then compete for influence across multiple arenas (the streets, the legislative arena, the courts, and the media), and that each side's tactics, framings, and victories shape the other's response. This page focuses on one of those arenas (the streets), looking first at where each side mobilizes geographically, then at the specific days and cities where both sides showed up at the same time."))
                 )
          )
        ),
        fluidRow(
          column(width = 12,
                 tags$h3("Where does each side mobilize?",
                         style = "margin: 6px 0 4px 0;")
          )
        ),
        fluidRow(
          box(title = "Mobilization map",
              width = 12, status = "primary", solidHeader = TRUE,
              tags$p(style = "margin-bottom: 6px;",
                     "Every qualifying event from January 2021 through February 2026, clustered at low zoom and colored by side. Use the radio button below to isolate one side. Because the view stacks five years of activity, a single dot may represent many years of events in that location."),
              radioButtons("event_map_side_filter", label = NULL, inline = TRUE,
                           choices = c("Both sides" = "all",
                                       "Left-leaning only" = "left",
                                       "Right-leaning only" = "right"),
                           selected = "all"),
              uiOutput("event_map_ui"))
        ),
        fluidRow(
          column(width = 12,
                 tags$p(style = "color:#555; margin: 12px 0 10px 0;",
                        HTML("The bars below take the same data and rank it at the city level, <em>separately</em> for each side. This surfaces the right-leaning strongholds, which would otherwise be drowned out by the larger left-leaning totals, and makes it easy to spot cities that appear on both lists."))
          )
        ),
        fluidRow(
          box(title = paste0("Top cities for ", tolower(PRO_LABEL), " mobilization"),
              width = 6, status = "primary", solidHeader = TRUE,
              plotOutput("top_cities_left", height = "440px")),
          box(title = paste0("Top cities for ", tolower(ANTI_LABEL), " mobilization"),
              width = 6, status = "primary", solidHeader = TRUE,
              plotOutput("top_cities_right", height = "440px"))
        ),
        fluidRow(
          column(width = 12,
                 tags$h3("Days when both sides mobilized in the same city",
                         style = "margin: 22px 0 4px 0;"),
                 tags$p(style = "color:#555; margin: 0 0 12px 0;",
                        HTML("An <em>encounter</em> is a single calendar day on which at least one left-leaning event and at least one right-leaning event were recorded in the same city. The table below lists every encounter in the dataset, sorted by total events that day. Click any row to drill in: the map above zooms to the city and replaces the all-time cluster overlay with markers for <em>only</em> the events recorded on that single day, and the detail panel below the table summarizes who showed up and what they were claiming."))
          )
        ),
        fluidRow(
          box(title = "Encounter explorer",
              width = 12, status = "primary", solidHeader = TRUE,
              DTOutput("encounter_table"))
        ),
        fluidRow(uiOutput("encounter_detail_ui"))
      ),

      tabItem(
        tabName = "tactics",
        fluidRow(
          column(width = 12,
                 tags$h4("Tactical Repertoire"),
                 tags$p("Different social movements use different forms of collective action — rallies, marches, vigils, sit-ins, civil disobedience, and so on — and each form carries a different signal about urgency, discipline, and willingness to escalate. The two charts below rank the most common forms used by each side, by event count."),
                 callout_box(
                   variant = "theory",
                   tags$p(style = "margin: 0;",
                          HTML("<b>Repertoires of contention.</b> Charles Tilly describes a movement's <em>repertoire</em> as the limited menu of action forms that activists in a given era and place know how to perform. Tactical choice has real consequences for how movements are received; the two charts below show which tactics each side actually performs, ranked by frequency.")))
          )
        ),
        fluidRow(
          box(title = paste0("Tactics used at ", tolower(PRO_LABEL), " events"),
              width = 6, status = "primary", solidHeader = TRUE,
              plotOutput("tactics_pro_types", height = "320px")),
          box(title = paste0("Tactics used at ", tolower(ANTI_LABEL), " events"),
              width = 6, status = "primary", solidHeader = TRUE,
              plotOutput("tactics_anti_types", height = "320px"))
        ),
        fluidRow(
          column(width = 12,
                 tags$h4("Framing", style = "margin-top: 18px;"),
                 tags$p(HTML("Every event in the Crowd Counting Consortium dataset comes with a claims summary: a list of short phrases like \"for racial justice\" or \"against critical race theory\". For the charts below, I split each phrase on its leading verb (<em>for</em> or <em>against</em>) to separate the stance from the issue, then counted how many times each issue showed up under each stance, separately for left-leaning and right-leaning events. A bar extending left means the issue was raised in the <em>against</em> direction; a bar extending right means it was raised in the <em>for</em> direction. Hover over any bar for the full issue text and the exact count.")),
                 callout_box(
                   variant = "theory",
                   tags$p(style = "margin: 0;",
                          HTML("<b>Frame extension.</b> David A. Snow, E. Burke Rochford Jr., Steven K. Worden, and Robert D. Benford describe <em>frame extension</em> as a movement's effort to recruit participants by extending the boundaries of its core frame to include the views, interests, or sentiments of adjacent targeted groups, and the patterns below illustrate this directly: on the left-leaning side the core frame of opposing racism and police brutality is visibly extended to issues such as LGBTQ+ rights, Medicaid, healthcare, housing, environmental conservation, and immigration enforcement, while on the right-leaning side the core frame of patriotism and white supremacy is extended to issues such as Christian values, freedom, election integrity, and opposition to critical race theory."))
                 )
          )
        ),
        fluidRow(
          box(title = paste0("Claims raised at ", tolower(PRO_LABEL), " events"),
              width = 12, status = "primary", solidHeader = TRUE,
              plotlyOutput("claims_bar_pro", height = "520px"))
        ),
        fluidRow(
          box(title = paste0("Claims raised at ", tolower(ANTI_LABEL), " events"),
              width = 12, status = "primary", solidHeader = TRUE,
              plotlyOutput("claims_bar_anti", height = "520px"))
        )
      ),

      tabItem(
        tabName = "orgs",
        fluidRow(
          column(width = 12,
                 callout_box(
                   variant = "theory",
                   tags$p(style = "margin: 0;",
                          HTML("<b>Social movement organizations.</b> Howard Lune describes social movement organizations, or SMOs, as the durable infrastructure that converts diffuse public sentiment into sustained collective action (i.e., by recruiting, training, funding, framing, and coordinating). Paul Almeida adds that movements emerge most readily where preexisting organizations are already in place, providing the leaders, networks, and resources needed to launch collective action. This tab documents each organization's profile (e.g., its geographic footprint, its tactical repertoire, the claims it has raised, and the other organizations it has co-mobilized with)."))
                 )
          )
        ),
        fluidRow(
          box(title = "Search for an organization",
              width = 12, status = "primary", solidHeader = TRUE,
              p("Narrow the dropdown by side first, then pick an organization to see its profile."),
              radioButtons("org_side_filter", label = NULL, inline = TRUE,
                           choices = c("All organizations" = "all",
                                       "Left-leaning" = "left",
                                       "Right-leaning" = "right"),
                           selected = "all"),
              selectizeInput("org_pick", label = NULL,
                             choices = NULL, selected = NULL,
                             width = "100%",
                             options = list(
                               placeholder = "Type an organization name",
                               maxOptions = 200)))
        ),
        uiOutput("org_profile_ui")
      ),

      tabItem(
        tabName = "opinion",
        fluidRow(
          column(width = 12,
                 tags$h2("How does the public see race and policing?",
                         style = "margin: 4px 0 6px 0;"),
                 tags$p(style = "color:#555; margin: 0 0 12px 0;",
                        "All percentages on this page are computed directly from the ANES 2024 Time Series Study (post-election survey, n = 5,521). ANES asks respondents both multiple-choice opinion questions and feeling thermometers, where respondents rate a person or group on a 0-100 scale (0 means very cold or very unfavorable, 100 means very warm or very favorable). Each respondent's answer is grouped by their party identification or by their race / ethnicity, and the bars show the share of respondents in each group who chose each answer."),
                 callout_box(
                   variant = "theory",
                   tags$p(style = "margin: 0;",
                          HTML("<b>Movement consequences.</b> David A. Snow and Sarah A. Soule argue that protest movements have effects that go well beyond passing legislation, including shifts in cultural norms and public attitudes. Public opinion data is one way to look at those broader effects."))
                 )
          )
        ),
        fluidRow(
          box(title = "Comparing the two thermometers: Black Lives Matter vs. Police",
              width = 12, status = "primary", solidHeader = TRUE,
              tags$p(style = "margin-bottom: 8px;",
                     "Mean feeling-thermometer rating each group of respondents gave to the Black Lives Matter movement and to the police, on a 0-100 scale. The further the two dots sit apart on a row, the more polarized that group is between the movement and the institution it confronts."),
              selectInput("anes_dumbbell_breakdown", label = "Break down by",
                          width = "260px",
                          choices = c("Party identification" = "party",
                                      "Race or ethnicity" = "race"),
                          selected = "party"),
              plotlyOutput("anes_dumbbell", height = "440px"))
        ),
        fluidRow(
          box(title = "Pick a question to see how Americans answered it",
              width = 12, status = "primary", solidHeader = TRUE,
              tags$p(style = "margin-bottom: 8px;",
                     "Each option below pairs a survey question with a breakdown dimension; pick one to see the resulting Likert chart."),
              selectInput("anes_question_breakdown", label = "Survey question",
                          width = "100%",
                          choices = c(
                            "How would you rate the Black Lives Matter movement? (by party identification)" = "blm__party",
                            "How would you rate the Black Lives Matter movement? (by race or ethnicity)" = "blm__race",
                            "How would you rate the Police? (by party identification)" = "police__party",
                            "How would you rate the Police? (by race or ethnicity)" = "police__race",
                            "How often do police use more force than necessary? (by party identification)" = "force__party",
                            "How often do police use more force than necessary? (by race or ethnicity)" = "force__race",
                            "Do the police treat Black or White Americans better? (by party identification)" = "treat__party",
                            "Do the police treat Black or White Americans better? (by race or ethnicity)" = "treat__race",
                            "Does the federal government treat Black or White Americans better? (by party identification)" = "fedgov__party",
                            "Does the federal government treat Black or White Americans better? (by race or ethnicity)" = "fedgov__race",
                            "How much discrimination against Black Americans today? (by party identification)" = "disc__party",
                            "How much discrimination against Black Americans today? (by race or ethnicity)" = "disc__race",
                            "Best way to deal with urban unrest (by party identification)" = "unrest__party"
                          ),
                          selected = "blm__party"),
              plotlyOutput("anes_question_chart", height = "480px"))
        )
      )
    )
  )
)

server <- function(input, output, session) {

  output$codebook_ccc <- renderDT(codebook_dt(codebook_ccc))
  output$codebook_derived <- renderDT(codebook_dt(codebook_derived))
  output$codebook_anes <- renderDT(codebook_dt(codebook_anes))

  org_choices_left <- org_summary |>
    filter(as.character(dominant_side) == PRO_LABEL) |>
    arrange(desc(events)) |> pull(org)
  org_choices_right <- org_summary |>
    filter(as.character(dominant_side) == ANTI_LABEL) |>
    arrange(desc(events)) |> pull(org)

  observe({
    side <- input$org_side_filter %||% "all"
    choices <- switch(side,
                      left  = org_choices_left,
                      right = org_choices_right,
                      org_choices)
    updateSelectizeInput(session, "org_pick",
                         choices = choices,
                         selected = character(0),
                         server = TRUE)
  })

  output$vb_pro <- renderValueBox({
    valueBox(format(sum(events$side == PRO_LABEL), big.mark = ","),
             paste0(PRO_LABEL, " events"),
             icon = icon("fist-raised"), color = "blue")
  })
  output$vb_anti <- renderValueBox({
    valueBox(format(sum(events$side == ANTI_LABEL), big.mark = ","),
             paste0(ANTI_LABEL, " events"),
             icon = icon("shield-alt"), color = "red")
  })
  output$vb_arrests <- renderValueBox({
    valueBox(format(total_arrests_dataset, big.mark = ","),
             "Total arrests across events",
             icon = icon("gavel"), color = "yellow")
  })
  output$vb_encounters <- renderValueBox({
    valueBox(format(encounters_n, big.mark = ","),
             "Days both sides protested in same city",
             icon = icon("people-arrows"), color = "purple")
  })

  output$overview_wow <- renderPlot({
    weekly <- events_pc |>
      mutate(week = floor_date(date, "week", week_start = 1)) |>
      count(week, side, name = "events") |>
      complete(week = seq(min(week), max(week), by = "week"),
               side = c(PRO_LABEL, ANTI_LABEL),
               fill = list(events = 0))
    weekly_mirrored <- weekly |>
      mutate(events_signed = ifelse(side == PRO_LABEL, events, -events))
    y_max <- max(abs(weekly_mirrored$events_signed), na.rm = TRUE)
    n_ref <- nrow(ref_dates)
    ref_pos <- ref_dates |>
      mutate(y_pos = y_max * rep(c(1.10, 1.22, 1.34), length.out = n_ref))

    ggplot(weekly_mirrored, aes(x = week, y = events_signed, fill = side)) +
      geom_area(alpha = 0.85, position = "identity") +
      geom_hline(yintercept = 0, color = "#333", size = 0.4) +
      geom_vline(data = ref_pos, aes(xintercept = date),
                 inherit.aes = FALSE,
                 linetype = "dashed", color = "#666", size = 0.4) +
      ggrepel::geom_label_repel(
        data = ref_pos,
        aes(x = date, y = y_pos, label = label),
        inherit.aes = FALSE,
        size = 3.1, color = "#222", fill = "white",
        label.size = 0.2, label.padding = unit(0.18, "lines"),
        segment.color = "#999", segment.size = 0.3,
        direction = "x", min.segment.length = 0,
        max.overlaps = Inf,
        nudge_y = y_max * 0.04
      ) +
      scale_fill_manual(values = side_colors) +
      scale_y_continuous(labels = function(x) format(abs(x), big.mark = ","),
                         expand = expansion(mult = c(0.05, 0.30))) +
      scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
      labs(x = NULL, y = "Events per week", fill = NULL) +
      theme_minimal() +
      theme(legend.position = "bottom",
            panel.grid.minor = element_blank())
  })

  output$overview_geo_anim <- renderPlotly({
    view <- input$overview_geo_view %||% "all"
    base_layout <- function(p) {
      p |>
        layout(geo = list(scope = "usa",
                          projection = list(type = "albers usa"),
                          showland = TRUE, landcolor = "#f4efe6",
                          showlakes = TRUE, lakecolor = "#dbe9f6",
                          showrivers = TRUE, rivercolor = "#dbe9f6",
                          showcountries = TRUE, countrycolor = "#a8a8a8",
                          showcoastlines = TRUE, coastlinecolor = "#a8a8a8",
                          showsubunits = TRUE, subunitcolor = "#cdc9bf",
                          subunitwidth = 0.6,
                          bgcolor = "#fbfaf6"),
               paper_bgcolor = "#fbfaf6",
               dragmode = FALSE,
               legend = list(orientation = "h", x = 0, y = -0.05),
               margin = list(t = 20, b = 80, l = 0, r = 0)) |>
        animation_opts(frame = 350, transition = 200, easing = "cubic-in-out") |>
        animation_slider(currentvalue = list(prefix = "Month: ")) |>
        config(scrollZoom = FALSE, displaylogo = FALSE,
               modeBarButtonsToRemove = c("zoomIn2d", "zoomOut2d", "pan2d",
                                          "autoScale2d", "zoom2d",
                                          "toggleSpikelines", "select2d",
                                          "lasso2d", "resetScale2d"))
    }
    if (view == "all") {
      d <- events_geo |> arrange(month_label)
      p <- plot_ly(d, type = "scattergeo", mode = "markers",
                   lat = ~lat, lon = ~lon, color = ~side,
                   colors = side_colors,
                   frame = ~month_label,
                   marker = list(size = 6, opacity = 0.7,
                                 line = list(width = 0)),
                   text = ~paste0(coalesce(title, "(untitled)"),
                                  "<br>", resolved_locality, ", ", resolved_state),
                   hovertemplate = "%{text}<extra></extra>")
      base_layout(p)
    } else if (view == "left") {
      d <- events_geo_left |> arrange(month_label)
      p <- plot_ly(d, type = "scattergeo", mode = "markers",
                   lat = ~lat, lon = ~lon, color = ~sub,
                   colors = left_sub_palette[left_sub_levels],
                   frame = ~month_label,
                   marker = list(size = 6, opacity = 0.75,
                                 line = list(width = 0)),
                   text = ~paste0(coalesce(title, "(untitled)"),
                                  "<br>", resolved_locality, ", ", resolved_state),
                   hovertemplate = "%{text}<extra></extra>")
      base_layout(p)
    } else {
      d <- events_geo_right |> arrange(month_label)
      p <- plot_ly(d, type = "scattergeo", mode = "markers",
                   lat = ~lat, lon = ~lon, color = ~sub,
                   colors = right_sub_palette[right_sub_levels],
                   frame = ~month_label,
                   marker = list(size = 6, opacity = 0.75,
                                 line = list(width = 0)),
                   text = ~paste0(coalesce(title, "(untitled)"),
                                  "<br>", resolved_locality, ", ", resolved_state),
                   hovertemplate = "%{text}<extra></extra>")
      base_layout(p)
    }
  })

  output$overview_media_top <- renderPlot({
    d <- media_top_events |>
      arrange(n_sources) |>
      mutate(label_short = factor(label_short, levels = label_short),
             side_chr    = as.character(side))
    ggplot(d, aes(x = n_sources, y = label_short, fill = side_chr)) +
      geom_col(width = 0.7) +
      geom_text(aes(label = n_sources), hjust = -0.2,
                size = 3.3, color = "#333") +
      scale_fill_manual(values = side_colors, name = NULL) +
      scale_x_continuous(expand = expansion(mult = c(0, 0.18))) +
      labs(x = "Distinct news sources cited", y = NULL) +
      theme_minimal() +
      theme(legend.position = "bottom",
            panel.grid.major.y = element_blank())
  })

  output$event_map_ui <- renderUI({
    if (nrow(events_for_map) == 0) {
      tags$div(style = "display:flex; align-items:center; justify-content:center;
                        height:520px; color:#888; font-style:italic;",
               "Geographic information not available.")
    } else {
      leafletOutput("event_map", height = "520px")
    }
  })

  events_for_map_filtered <- reactive({
    side <- input$event_map_side_filter %||% "all"
    if (side == "left")  return(events_for_map |> filter(side_chr == PRO_LABEL))
    if (side == "right") return(events_for_map |> filter(side_chr == ANTI_LABEL))
    events_for_map
  })

  output$event_map <- renderLeaflet({
    leaflet() |>
      addProviderTiles(providers$CartoDB.Positron) |>
      setView(lng = -96, lat = 38, zoom = 4) |>
      setMaxBounds(lng1 = -130, lat1 = 22, lng2 = -64, lat2 = 51)
  })

  city_bar_render <- function(df, fill_color) {
    if (nrow(df) == 0) return(empty_msg_plot("No mobilization data available."))
    ggplot(df, aes(x = events, y = city)) +
      geom_col(fill = fill_color, width = 0.7) +
      geom_text(aes(label = format(events, big.mark = ",")),
                hjust = -0.2, size = 3.3, color = "#333") +
      scale_x_continuous(expand = expansion(mult = c(0, 0.18))) +
      labs(x = "Events", y = NULL) +
      theme_minimal() +
      theme(panel.grid.major.y = element_blank())
  }
  output$top_cities_left  <- renderPlot(city_bar_render(top_cities_left,  PRO_COLOR))
  output$top_cities_right <- renderPlot(city_bar_render(top_cities_right, ANTI_COLOR))

  encounter_table_full <- reactive({
    encounters_for_map |>
      arrange(desc(total)) |>
      mutate(row_id = row_number())
  })

  encounter_table_data <- reactive({
    encounter_table_full() |>
      transmute(Date = date,
                Locality = resolved_locality,
                State    = resolved_state,
                !!paste0(PRO_LABEL,  " events") := pro_events,
                !!paste0(ANTI_LABEL, " events") := anti_events,
                `Total events` = total)
  })
  output$encounter_table <- renderDT({
    datatable(encounter_table_data(), rownames = FALSE, selection = "single",
              options = list(pageLength = 10, scrollX = TRUE))
  })

  selected_encounter <- reactive({
    sel <- input$encounter_table_rows_selected
    if (is.null(sel) || length(sel) == 0) return(NULL)
    encounter_table_full()[sel, ]
  })

  observe({
    d   <- events_for_map_filtered()
    enc <- selected_encounter()
    proxy <- leafletProxy("event_map") |>
      clearGroup("all_events") |>
      clearGroup("day_highlight")
    if (is.null(enc)) {
      proxy |>
        setView(lng = -96, lat = 38, zoom = 4) |>
        addCircleMarkers(data = d,
                         group = "all_events",
                         lng = ~lon, lat = ~lat, color = ~color,
                         radius = 4, weight = 0.5, fillOpacity = 0.7,
                         clusterOptions = markerClusterOptions(),
                         popup = ~popup_html)
    } else {
      day_events <- events_for_map |>
        filter(date == enc$date,
               resolved_locality == enc$resolved_locality,
               resolved_state    == enc$resolved_state)
      proxy <- proxy |> setView(lng = enc$lon, lat = enc$lat, zoom = 12)
      if (nrow(day_events) > 0) {
        proxy |>
          addCircleMarkers(data = day_events,
                           group = "day_highlight",
                           lng = ~lon, lat = ~lat, color = ~color,
                           radius = 11, weight = 2, fillOpacity = 0.85,
                           popup = ~popup_html)
      }
    }
  })

  output$encounter_detail_ui <- renderUI({
    enc <- selected_encounter()
    if (is.null(enc)) {
      return(box(width = 12, status = "primary", solidHeader = FALSE,
                 tags$p(tags$em("Click any row in the encounter table above to drill into a single same-day same-city encounter."))))
    }
    box(width = 12, status = "primary", solidHeader = TRUE,
        title = paste0("Encounter on ",
                       format(enc$date, "%B %d, %Y"),
                       " in ", enc$resolved_locality, ", ", enc$resolved_state),
        uiOutput("encounter_detail_summary"),
        tags$hr(style = "margin: 12px 0;"),
        tags$div(style = "color:#444; font-weight: 600; margin-bottom: 6px;",
                 "Every event recorded that day in this city"),
        DTOutput("encounter_detail_table"))
  })

  output$encounter_detail_summary <- renderUI({
    enc <- selected_encounter(); req(enc)
    day_events <- events_pc |>
      filter(date == enc$date,
             resolved_locality == enc$resolved_locality,
             resolved_state    == enc$resolved_state)
    types_summary <- day_events |>
      filter(!is.na(event_type), event_type != "") |>
      mutate(event_type = tools::toTitleCase(event_type)) |>
      count(event_type, sort = TRUE) |>
      mutate(s = paste0(n, " ", event_type)) |>
      pull(s) |> paste(collapse = ", ")
    orgs_summary <- day_events |>
      filter(!is.na(organizations), organizations != "") |>
      mutate(o = str_split(organizations, ";")) |> unnest(o) |>
      mutate(o = str_trim(o)) |> filter(o != "") |>
      count(o, sort = TRUE) |> slice_head(n = 5) |> pull(o) |>
      paste(collapse = "; ")
    claims_summary_top <- day_events |>
      filter(!is.na(claims_summary), claims_summary != "") |>
      mutate(c = str_split(claims_summary, ";")) |> unnest(c) |>
      mutate(c = str_trim(c)) |> filter(c != "") |>
      count(c, sort = TRUE) |> slice_head(n = 3) |> pull(c) |>
      paste(collapse = "; ")
    tags$div(
      style = "padding: 4px 4px 0 4px;",
      tags$p(
        tags$b(enc$pro_events), " ", PRO_LABEL,
        " event(s) and ", tags$b(enc$anti_events), " ", ANTI_LABEL,
        " event(s) in this city on this day."
      ),
      if (nzchar(types_summary))
        tags$p(tags$b("Tactical mix:"), " ", types_summary),
      if (nzchar(orgs_summary))
        tags$p(tags$b("Top organizations involved:"), " ", orgs_summary),
      if (nzchar(claims_summary_top))
        tags$p(tags$b("Most common claims:"), " ", claims_summary_top)
    )
  })

  output$encounter_detail_table <- renderDT({
    enc <- selected_encounter(); req(enc)
    events_pc |>
      filter(date == enc$date,
             resolved_locality == enc$resolved_locality,
             resolved_state    == enc$resolved_state) |>
      mutate(Title = derive_title(title, event_type, resolved_locality, resolved_state),
             Claims = ifelse(is.na(claims_summary), "",
                             capitalize_clauses(claims_summary))) |>
      transmute(Side = side,
                Title,
                `Event type` = event_type,
                `Crowd size` = size_mean,
                Arrests = arrests,
                Organizations = organizations,
                Claims) |>
      datatable(rownames = FALSE,
                options = list(pageLength = 10, scrollX = TRUE))
  })

  tactics_render <- function(side_label, fill_color) {
    d <- top_event_types |>
      filter(side == side_label) |>
      arrange(events) |>
      mutate(event_type = factor(event_type, levels = event_type))
    ggplot(d, aes(x = events, y = event_type)) +
      geom_col(fill = fill_color, width = 0.7) +
      geom_text(aes(label = format(events, big.mark = ",")),
                hjust = -0.2, size = 3.4, color = "#333") +
      scale_x_continuous(expand = expansion(mult = c(0, 0.18))) +
      labs(x = "Events", y = NULL) +
      theme_minimal() +
      theme(panel.grid.major.y = element_blank())
  }
  output$tactics_pro_types  <- renderPlot(tactics_render(PRO_LABEL,  PRO_COLOR))
  output$tactics_anti_types <- renderPlot(tactics_render(ANTI_LABEL, ANTI_COLOR))

  claims_bar_render <- function(side_label) {
    d <- claim_objects |>
      filter(side == side_label) |>
      slice_max(total, n = 12) |>
      arrange(total) |>
      mutate(object_full = tools::toTitleCase(object),
             object = str_trunc(object_full, 50, ellipsis = "…"),
             object = factor(object, levels = unique(object)))
    if (nrow(d) == 0) {
      return(plotly_empty(type = "scatter", mode = "markers") |>
               layout(annotations = list(list(
                 text = "No claim data.",
                 xref = "paper", yref = "paper",
                 x = 0.5, y = 0.5, showarrow = FALSE,
                 font = list(color = "#888")))))
    }
    max_abs <- max(abs(c(d$for_count, -d$against_count)))
    plot_ly(d) |>
      add_bars(y = ~object, x = ~-against_count,
               name = "Against",
               marker = list(color = ANTI_COLOR),
               customdata = ~object_full,
               hovertemplate = paste0("<b>%{customdata}</b><br>",
                                      "Against: %{x:,}<extra></extra>")) |>
      add_bars(y = ~object, x = ~for_count,
               name = "For",
               marker = list(color = PRO_COLOR),
               customdata = ~object_full,
               hovertemplate = paste0("<b>%{customdata}</b><br>",
                                      "For: %{x:,}<extra></extra>")) |>
      layout(barmode = "relative",
             bargap  = 0.3,
             xaxis = list(title = "Mentions  (against on left, for on right)",
                          range = c(-max_abs * 1.05, max_abs * 1.05),
                          tickformat = ",d",
                          tickvals = pretty(c(-max_abs, max_abs)),
                          ticktext = format(abs(pretty(c(-max_abs, max_abs))),
                                            big.mark = ","),
                          zerolinecolor = "#333", zerolinewidth = 1,
                          gridcolor = "#eee"),
             yaxis = list(title = "", automargin = TRUE,
                          tickfont = list(size = 12)),
             legend = list(orientation = "h", x = 0.5, y = -0.18,
                           xanchor = "center"),
             margin = list(t = 10, b = 80, l = 10, r = 10),
             paper_bgcolor = "#ffffff",
             plot_bgcolor  = "#ffffff") |>
      config(displaylogo = FALSE,
             modeBarButtonsToRemove = c("lasso2d", "select2d",
                                        "autoScale2d", "toggleSpikelines"))
  }
  output$claims_bar_pro  <- renderPlotly(claims_bar_render(PRO_LABEL))
  output$claims_bar_anti <- renderPlotly(claims_bar_render(ANTI_LABEL))

  selected_org <- reactive({
    o <- input$org_pick
    if (is.null(o) || !nzchar(o)) return(NULL)
    o
  })
  org_data <- reactive({
    o <- selected_org(); if (is.null(o)) return(NULL)
    rows <- orgs_long |> filter(org == o)
    list(
      name      = o,
      summary   = org_summary |> filter(org == o) |> slice(1),
      events    = rows,
      n_states  = n_distinct(rows$resolved_state[!is.na(rows$resolved_state)]),
      locality_map = rows |>
        filter(!is.na(lat), !is.na(lon)) |>
        group_by(resolved_locality, resolved_state) |>
        summarise(lat = mean(lat, na.rm = TRUE), lon = mean(lon, na.rm = TRUE),
                  n = n(), .groups = "drop"),
      top_co    = co_edges |>
        filter(from == o | to == o) |>
        mutate(other = if_else(from == o, to, from)) |>
        arrange(desc(weight)) |> head(15)
    )
  })
  output$org_profile_ui <- renderUI({
    od <- org_data()
    if (is.null(od)) {
      return(fluidRow(
        box(width = 12, status = "primary",
            tags$p(tags$em("Pick an organization above to see its profile.")))
      ))
    }
    tagList(
      fluidRow(
        valueBoxOutput("org_vb_total",   width = 3),
        valueBoxOutput("org_vb_states",  width = 3),
        valueBoxOutput("org_vb_arrests", width = 3),
        valueBoxOutput("org_vb_span",    width = 3)
      ),
      fluidRow(
        box(title = "All recorded events for this organization",
            width = 12, status = "primary", solidHeader = TRUE,
            DTOutput("org_events_table"))
      ),
      fluidRow(
        box(title = "Geographic footprint",
            width = 6, status = "primary", solidHeader = TRUE,
            height = "660px",
            uiOutput("org_map_ui")),
        box(title = "Tactical signature and crowd size",
            width = 6, status = "primary", solidHeader = TRUE,
            height = "660px",
            uiOutput("org_signature_ui"))
      ),
      fluidRow(
        box(title = "Coalition network for this organization",
            width = 12, status = "primary", solidHeader = TRUE,
            uiOutput("org_network_ui"))
      )
    )
  })
  output$org_vb_total <- renderValueBox({
    od <- org_data(); req(od)
    valueBox(format(nrow(od$events), big.mark = ","),
             "Total events", icon = icon("flag"), color = "blue")
  })
  output$org_vb_states <- renderValueBox({
    od <- org_data(); req(od)
    valueBox(od$n_states, "States active in",
             icon = icon("map"), color = "purple")
  })
  output$org_vb_arrests <- renderValueBox({
    od <- org_data(); req(od)
    valueBox(format(od$summary$total_arrests, big.mark = ","),
             "Total arrests across events",
             icon = icon("gavel"), color = "red")
  })
  output$org_vb_span <- renderValueBox({
    od <- org_data(); req(od)
    valueBox(paste0(format(od$summary$first_event, "%Y"), " to ",
                    format(od$summary$last_event,  "%Y")),
             "Activity timeline", icon = icon("calendar"), color = "yellow")
  })
  output$org_events_table <- renderDT({
    od <- org_data(); req(od)
    od$events |>
      arrange(desc(date)) |>
      transmute(Date = date,
                Locality = resolved_locality,
                State = resolved_state,
                Side = side,
                `Event type` = event_type,
                `Crowd size` = size_mean,
                Arrests = arrests,
                Title = title,
                Claims = claims_summary) |>
      datatable(rownames = FALSE,
                options = list(pageLength = 5, scrollX = TRUE))
  })
  output$org_map_ui <- renderUI({
    od <- org_data(); req(od)
    if (nrow(od$locality_map) == 0) {
      tags$div(style = "display:flex; align-items:center; justify-content:center;
                        height:560px; color:#888; font-style:italic;",
               "Geographic information not available for this organization.")
    } else {
      leafletOutput("org_map", height = "560px")
    }
  })
  output$org_map <- renderLeaflet({
    od <- org_data(); req(od)
    d <- od$locality_map
    req(nrow(d) > 0)
    m <- leaflet(d) |>
      addProviderTiles(providers$CartoDB.Positron) |>
      setMaxBounds(lng1 = -130, lat1 = 22, lng2 = -64, lat2 = 51)
    lng_span <- diff(range(d$lon))
    lat_span <- diff(range(d$lat))
    if (nrow(d) == 1 || (lng_span < 0.05 && lat_span < 0.05)) {
      m <- m |> setView(lng = d$lon[1], lat = d$lat[1], zoom = 9)
    } else {
      m <- m |> fitBounds(lng1 = min(d$lon), lat1 = min(d$lat),
                          lng2 = max(d$lon), lat2 = max(d$lat))
    }
    m |> addCircleMarkers(lng = ~lon, lat = ~lat,
                          radius = ~pmin(4 + sqrt(n) * 2, 22),
                          weight = 1, fillOpacity = 0.7, color = "#888",
                          popup = ~paste0("<b>", resolved_locality, ", ", resolved_state, "</b><br>",
                                          n, " events"))
  })
  output$org_signature_ui <- renderUI({
    od <- org_data(); req(od)
    has_types <- any(!is.na(od$events$event_type) & od$events$event_type != "")
    if (!has_types) {
      return(tags$div(
        style = "display:flex; align-items:center; justify-content:center;
                 height:600px; color:#888; font-style:italic;",
        "Tactical information not available for this organization."))
    }
    tagList(
      tags$div(style = "font-size: 13px; color:#555; margin-bottom: 4px;",
               "Top tactics used by this organization."),
      plotOutput("org_signature", height = "230px"),
      tags$hr(style = "margin: 10px 0;"),
      tags$div(style = "font-size: 13px; color:#555; margin-bottom: 4px;",
               "Crowd size at this organization's events compared with the rest of the dataset (log-scale). The vertical line marks the organization's median."),
      plotOutput("org_size_dist", height = "230px")
    )
  })

  output$org_signature <- renderPlot({
    od <- org_data(); req(od)
    d <- od$events |>
      filter(!is.na(event_type), event_type != "") |>
      mutate(event_type = tools::toTitleCase(event_type)) |>
      count(event_type, name = "events") |>
      slice_max(events, n = 8) |>
      arrange(events) |>
      mutate(event_type = factor(event_type, levels = event_type))
    side_color <- if (as.character(od$summary$dominant_side) == PRO_LABEL) PRO_COLOR else ANTI_COLOR
    ggplot(d, aes(x = events, y = event_type)) +
      geom_col(fill = side_color, width = 0.7) +
      geom_text(aes(label = events), hjust = -0.2, size = 3.4, color = "#333") +
      scale_x_continuous(expand = expansion(mult = c(0, 0.18))) +
      labs(x = "Events", y = NULL) +
      theme_minimal() +
      theme(panel.grid.major.y = element_blank(),
            plot.margin = margin(4, 8, 4, 4))
  })

  output$org_size_dist <- renderPlot({
    od <- org_data(); req(od)
    sz <- od$events$size_mean
    sz <- sz[!is.na(sz) & sz > 0]
    if (length(sz) == 0 || nrow(size_dist_overall) == 0) {
      return(empty_msg_plot("Crowd size not reported for this organization."))
    }
    side_color <- if (as.character(od$summary$dominant_side) == PRO_LABEL) PRO_COLOR else ANTI_COLOR
    org_med <- median(sz)
    overall_med <- median(size_dist_overall$size)
    breaks_log <- c(1, 10, 100, 1000, 10000, 100000)
    ggplot(size_dist_overall, aes(x = size)) +
      geom_density(fill = "#dadada", color = "#999", alpha = 0.7) +
      geom_vline(xintercept = overall_med, linetype = "dotted",
                 color = "#666", linewidth = 0.5) +
      geom_vline(xintercept = org_med, color = side_color, linewidth = 1.1) +
      annotate("label", x = org_med, y = Inf, vjust = 1.6,
               label = paste0("This organization: ", format(round(org_med), big.mark = ",")),
               color = side_color, fill = "white",
               label.size = 0.2, size = 3.3) +
      annotate("text", x = overall_med, y = 0, vjust = -0.5,
               label = paste0("Overall median: ", format(round(overall_med), big.mark = ",")),
               color = "#666", size = 3.0) +
      scale_x_log10(breaks = breaks_log,
                    labels = function(x) format(x, big.mark = ",", scientific = FALSE)) +
      labs(x = "Crowd size (log scale)", y = NULL) +
      theme_minimal() +
      theme(axis.text.y = element_blank(),
            panel.grid.minor = element_blank(),
            plot.margin = margin(4, 8, 4, 4))
  })
  org_partners <- reactive({
    od <- org_data(); req(od)
    co_edges |>
      filter(from == od$name | to == od$name) |>
      mutate(other = if_else(from == od$name, to, from)) |>
      arrange(desc(weight)) |>
      head(15)
  })

  output$org_network_ui <- renderUI({
    od <- org_data(); req(od)
    partners <- org_partners()
    if (nrow(partners) == 0) {
      return(tags$div(
        style = "display:flex; align-items:center; justify-content:center;
                 height:440px; color:#888; font-style:italic;",
        "No coalition partners on file."
      ))
    }
    visNetworkOutput("org_network", height = "440px")
  })

  output$org_network <- renderVisNetwork({
    od <- org_data(); req(od)
    partners <- org_partners()
    req(nrow(partners) > 0)
    side_color <- if (as.character(od$summary$dominant_side) == PRO_LABEL) PRO_COLOR else ANTI_COLOR
    nodes <- tibble(
      id    = c(od$name, partners$other),
      label = c(od$name, partners$other),
      value = c(max(partners$weight) * 1.5, partners$weight),
      color = c(side_color, rep("#9aa0a6", nrow(partners))),
      title = c(paste0("<b>", od$name, "</b><br>", nrow(od$events), " events"),
                paste0("<b>", partners$other, "</b><br>",
                       partners$weight, " shared events"))
    )
    edges <- tibble(
      from  = od$name,
      to    = partners$other,
      value = partners$weight,
      title = paste0(partners$weight, " shared events")
    )
    visNetwork(nodes, edges, width = "100%") |>
      visNodes(shape = "dot",
               scaling = list(min = 12, max = 36),
               font = list(size = 15, strokeWidth = 4, strokeColor = "#ffffff")) |>
      visEdges(smooth = list(enabled = TRUE, type = "continuous"),
               color = list(opacity = 0.45, color = "#aaa"),
               scaling = list(min = 1, max = 6)) |>
      visPhysics(stabilization = list(iterations = 400),
                 barnesHut = list(gravitationalConstant = -9000,
                                  springLength = 260,
                                  springConstant = 0.02,
                                  avoidOverlap = 1)) |>
      visInteraction(zoomView = TRUE, dragView = TRUE,
                     dragNodes = TRUE, hover = TRUE)
  })

  blm_palette    <- setNames(LIKERT_5, c("Very cold (0-20)", "Cold (21-40)",
                                         "Neutral (41-60)", "Warm (61-80)",
                                         "Very warm (81-100)"))
  police_palette <- blm_palette
  force_palette  <- setNames(LIKERT_5, c("Never", "Rarely", "About half the time",
                                         "Most of the time", "All the time"))
  disc_palette   <- setNames(rev(LIKERT_5), c("A great deal", "A lot",
                                              "A moderate amount", "A little",
                                              "None at all"))
  treat_palette  <- setNames(LIKERT_7,
                             c("White Americans much better",
                               "White Americans moderately better",
                               "White Americans a little better",
                               "Both treated the same",
                               "Black Americans a little better",
                               "Black Americans moderately better",
                               "Black Americans much better"))
  unrest_palette <- setNames(LIKERT_7,
                             c("1: Solve racism / police violence", "2", "3", "4",
                               "5", "6", "7: Use all available force"))

  likert_stack <- function(df, palette) {
    if (nrow(df) == 0) return(plotly_empty(type = "scatter", mode = "markers"))
    df <- df |>
      mutate(group = factor(as.character(group), levels = rev(levels(factor(group)))))
    plot_ly(df, y = ~group, x = ~pct, color = ~answer, type = "bar",
            orientation = "h", colors = palette,
            hovertemplate = "%{y}<br>%{fullData.name}: %{x:.1f}%<extra></extra>") |>
      layout(barmode = "stack",
             bargap = 0.25,
             xaxis = list(title = "Percentage of respondents",
                          ticksuffix = "%",
                          range = c(0, 100), showgrid = TRUE,
                          gridcolor = "#eee"),
             yaxis = list(title = "", automargin = TRUE,
                          ticks = "outside",
                          ticklen = 14,
                          tickcolor = "rgba(0,0,0,0)",
                          tickfont = list(size = 13)),
             legend = list(orientation = "h", x = 0.5, y = -0.18,
                           xanchor = "center", yanchor = "top",
                           tracegroupgap = 8,
                           font = list(size = 12)),
             margin = list(t = 20, b = 110, l = 10, r = 20),
             paper_bgcolor = "#ffffff",
             plot_bgcolor  = "#ffffff")
  }

  question_lookup <- list(
    blm    = list(party = anes_blm_bin_by_party,    race = anes_blm_bin_by_race,
                  palette = blm_palette,    group_label = "Feeling toward BLM"),
    police = list(party = anes_police_bin_by_party, race = anes_police_bin_by_race,
                  palette = police_palette, group_label = "Feeling toward police"),
    force  = list(party = anes_force_by_party,      race = anes_force_by_race,
                  palette = force_palette,
                  group_label = "How often police use more force than necessary"),
    treat  = list(party = anes_treat_by_party,      race = anes_treat_by_race,
                  palette = treat_palette,
                  group_label = "Police treat Black or White Americans better"),
    fedgov = list(party = anes_fedgov_by_party,     race = anes_fedgov_by_race,
                  palette = treat_palette,
                  group_label = "Federal government treats Black or White Americans better"),
    disc   = list(party = anes_disc_by_party,       race = anes_disc_by_race,
                  palette = disc_palette,
                  group_label = "How much discrimination against Black Americans"),
    unrest = list(party = anes_unrest_by_party,     race = NULL,
                  palette = unrest_palette,
                  group_label = "Best way to deal with urban unrest")
  )

  output$anes_question_chart <- renderPlotly({
    sel <- input$anes_question_breakdown %||% "blm__party"
    parts <- strsplit(sel, "__", fixed = TRUE)[[1]]
    q <- parts[1]; breakdown <- parts[2]
    spec <- question_lookup[[q]]
    target <- if (breakdown == "race") spec$race else spec$party
    if (is.null(target)) {
      return(plotly_empty(type = "scatter", mode = "markers") |>
               layout(annotations = list(list(
                 text = "This question is only available by party identification.",
                 xref = "paper", yref = "paper",
                 x = 0.5, y = 0.5, showarrow = FALSE,
                 font = list(color = "#888")))))
    }
    likert_stack(target, spec$palette)
  })

  dumbbell_render <- function(df, group_var) {
    if (nrow(df) == 0) return(plotly_empty(type = "scatter", mode = "markers"))
    d <- df |>
      filter(!is.na(.data[[group_var]])) |>
      mutate(group = .data[[group_var]],
             gap   = mean_blm - mean_police) |>
      arrange(gap) |>
      mutate(group = factor(as.character(group), levels = as.character(group)))
    plot_ly(d) |>
      add_segments(x = ~mean_police, xend = ~mean_blm,
                   y = ~group, yend = ~group,
                   line = list(color = "#bbb", width = 4),
                   showlegend = FALSE,
                   hoverinfo = "skip") |>
      add_trace(x = ~mean_police, y = ~group, type = "scatter", mode = "markers",
                marker = list(color = ANTI_COLOR, size = 14,
                              line = list(color = "#fff", width = 1.5)),
                name = "Police thermometer",
                hovertemplate = paste0("<b>%{y}</b><br>",
                                       "Mean police thermometer: %{x:.1f}",
                                       "<extra></extra>")) |>
      add_trace(x = ~mean_blm, y = ~group, type = "scatter", mode = "markers",
                marker = list(color = PRO_COLOR, size = 14,
                              line = list(color = "#fff", width = 1.5)),
                name = "BLM thermometer",
                hovertemplate = paste0("<b>%{y}</b><br>",
                                       "Mean BLM thermometer: %{x:.1f}",
                                       "<extra></extra>")) |>
      layout(xaxis = list(title = "Mean thermometer rating (0 = very cold, 100 = very warm)",
                          range = c(0, 100), zeroline = FALSE),
             yaxis = list(title = ""),
             legend = list(orientation = "h", x = 0, y = -0.18,
                           xanchor = "left", yanchor = "top"),
             margin = list(t = 20, b = 90, l = 10, r = 10))
  }

  output$anes_dumbbell <- renderPlotly({
    breakdown <- input$anes_dumbbell_breakdown %||% "party"
    if (breakdown == "race") {
      dumbbell_render(anes_by_race, "race")
    } else {
      dumbbell_render(anes_by_party, "party")
    }
  })
}

shinyApp(ui, server)
