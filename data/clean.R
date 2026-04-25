suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
})

p2_raw <- read_csv("data/ccc_compiled_20212024.csv", show_col_types = FALSE, progress = FALSE)
p3_raw <- read_csv("data/ccc-phase3-public.csv",   show_col_types = FALSE, progress = FALSE)

p2_source_cols <- grep("^source_\\d+$", colnames(p2_raw), value = TRUE)
p3_source_cols <- grep("^source\\d+$",  colnames(p3_raw), value = TRUE)

p2_n_sources <- rowSums(!is.na(p2_raw[, p2_source_cols]) &
                          p2_raw[, p2_source_cols] != "")
p3_n_sources <- rowSums(!is.na(p3_raw[, p3_source_cols]) &
                          p3_raw[, p3_source_cols] != "")

p2 <- p2_raw |>
  transmute(
    date              = ymd(date),
    event_type        = type,
    title,
    organizations,
    claims_summary,
    issues            = issue_tags,
    valence           = as.integer(valence),
    size_mean         = suppressWarnings(as.numeric(size_mean)),
    arrests           = suppressWarnings(as.numeric(arrests)),
    lat               = suppressWarnings(as.numeric(lat)),
    lon               = suppressWarnings(as.numeric(lon)),
    resolved_locality,
    resolved_state,
    online,
    participant_measures,
    police_measures,
    macroevent,
    n_sources         = p2_n_sources,
    phase             = "P2"
  )

p3 <- p3_raw |>
  transmute(
    date              = mdy(date),
    event_type,
    title,
    organizations,
    claims_summary,
    issues,
    valence           = as.integer(valence),
    size_mean         = suppressWarnings(as.numeric(size_mean)),
    arrests           = suppressWarnings(as.numeric(arrests)),
    lat               = suppressWarnings(as.numeric(lat)),
    lon               = suppressWarnings(as.numeric(lon)),
    resolved_locality,
    resolved_state,
    online,
    participant_measures,
    police_measures,
    macroevent,
    n_sources         = p3_n_sources,
    phase             = "P3"
  )

events_all <- bind_rows(p2, p3)

# Filter: events whose tag list contains "racism" or "policing" as exact tags.
# CCC's "racism" tag is permissive: it gets applied to bundled right-leaning
# rallies (anti-CRT + anti-mask + Christian-values etc.) where the claims and
# title contain no actual race or policing content. To avoid flooding the
# dashboard with anti-mask rallies, we additionally require that an event
# tagged ONLY "racism" (without "policing") have race/policing language in
# its title or claims_summary. Events tagged "policing" pass through
# regardless.
race_keywords <- paste(c(
  "\\bblm\\b", "black lives", "floyd", "nichols", "massey", "chauvin",
  "police", "polic\\w*", "brutality",
  "racism", "racist", "racial", "anti-racism", "anti racism",
  "white supremacy", "white nationalis", "patriot front", "nsc-?131",
  "antisemit", "civil rights", "kkk", "klan", "hate crime",
  "aapi", "anti-asian", "stop asian hate", "asian american",
  "reparations", "critical race theory", "\\bcrt\\b",
  "\\bdei\\b", "diversity, equity", "anti-woke", "anti woke",
  "cop city", "atlanta forest", "weelaunee",
  "stop and frisk", "qualified immunity", "george floyd",
  "trayvon", "breonna", "ahmaud", "jacob blake",
  "racially", "race relations", "voting rights", "redlining",
  "ice\\b", "\\bice\\b", "deportation", "immigration raid", "migrant", "asylum",
  "border patrol", "abolish ice"
), collapse = "|")

core_tags <- c("racism", "policing")
events <- events_all |>
  mutate(tag_list   = str_split(issues, ";"),
         tag_list   = map(tag_list, \(x) str_trim(x)),
         has_polic  = map_lgl(tag_list, \(x) "policing" %in% x),
         has_racism = map_lgl(tag_list, \(x) "racism"   %in% x),
         in_core    = has_polic | has_racism,
         search_txt = tolower(paste(coalesce(title, ""),
                                    coalesce(claims_summary, ""))),
         race_match = str_detect(search_txt, race_keywords),
         in_scope   = in_core & (has_polic | (has_racism & race_match))) |>
  filter(in_scope) |>
  select(-tag_list, -has_polic, -has_racism, -in_core,
         -search_txt, -race_match, -in_scope)

# Side label: drop valence=0/NA from comparative views; keep raw column for filtering.
events <- events |>
  mutate(
    side = case_when(
      valence == 1 ~ "Pro-movement",
      valence == 2 ~ "Counter-movement",
      TRUE         ~ "Neither/Unknown"
    ),
    side = factor(side, levels = c("Pro-movement", "Counter-movement", "Neither/Unknown"))
  )

# Pre-explode organizations once (reused by Org tab).
orgs_long <- events |>
  mutate(org = str_split(organizations, ";")) |>
  unnest(org) |>
  mutate(org = str_trim(org)) |>
  filter(!is.na(org), org != "")

# Same-day same-city encounters: city/date pairs where both sides appear.
# Using fixed column names (pro_events / anti_events) avoids data-mask issues
# downstream when leaflet popups reference these counts.
encounters <- events |>
  filter(side %in% c("Pro-movement", "Counter-movement"),
         !is.na(resolved_locality), !is.na(resolved_state)) |>
  count(date, resolved_locality, resolved_state, side) |>
  pivot_wider(names_from = side, values_from = n, values_fill = 0) |>
  rename(pro_events = `Pro-movement`, anti_events = `Counter-movement`) |>
  filter(pro_events > 0 & anti_events > 0)

# Per-org summary (one row per organization).
org_summary <- orgs_long |>
  group_by(org) |>
  summarise(
    events       = n(),
    pro          = sum(side == "Pro-movement"),
    counter      = sum(side == "Counter-movement"),
    neither      = sum(side == "Neither/Unknown"),
    first_event  = min(date, na.rm = TRUE),
    last_event   = max(date, na.rm = TRUE),
    total_arrests = sum(arrests, na.rm = TRUE),
    .groups      = "drop"
  ) |>
  mutate(
    dominant_side = case_when(
      pro >= counter & pro >= neither ~ "Pro-movement",
      counter > pro & counter >= neither ~ "Counter-movement",
      TRUE                            ~ "Neither/Unknown"
    )
  ) |>
  arrange(desc(events))

# Co-occurrence edges: orgs co-listed at the same event. Threshold to keep readable.
event_id_orgs <- orgs_long |>
  mutate(eid = paste(date, resolved_locality, resolved_state, title, sep = "|")) |>
  select(eid, org)

co_edges <- event_id_orgs |>
  inner_join(event_id_orgs, by = "eid", relationship = "many-to-many") |>
  filter(org.x < org.y) |>
  count(from = org.x, to = org.y, name = "weight") |>
  filter(weight >= 2)

claim_phrases <- events |>
  filter(side %in% c("Pro-movement", "Counter-movement"),
         !is.na(claims_summary), claims_summary != "") |>
  mutate(phrase = str_split(claims_summary, ";")) |>
  unnest(phrase) |>
  mutate(phrase = str_trim(phrase) |> str_to_lower()) |>
  filter(phrase != "") |>
  count(side, phrase, name = "n")

# ----- Parse claim phrases into stance + object ------------------------------
# Most CCC claim phrases follow "for X" or "against X". Split on the leading
# stance verb so we can show, per object, how many "for" vs. "against" mentions.
claim_parsed <- claim_phrases |>
  mutate(
    stance = str_extract(phrase, "^(for|against)\\b"),
    object = str_remove(phrase,  "^(for|against)\\s+"),
    object = object |>
      str_replace_all(";", ",") |>
      str_replace_all("\\s+", " ") |>
      str_trim() |>
      str_remove("[[:punct:]]+$")
  ) |>
  filter(!is.na(stance), nchar(object) > 0)

claim_objects <- claim_parsed |>
  group_by(side, object) |>
  summarise(
    total       = sum(n),
    for_count   = sum(n[stance == "for"],     na.rm = TRUE),
    against_count = sum(n[stance == "against"], na.rm = TRUE),
    .groups     = "drop"
  ) |>
  group_by(side) |>
  slice_max(total, n = 15) |>
  ungroup()

# ----- Side-specific co-occurrence networks with strict thresholds -----------
# Goal: a small, readable graph per side (about 30 to 60 nodes), with a static
# Fruchterman-Reingold layout pre-computed so positions are stable.
suppressPackageStartupMessages(library(igraph))

build_side_network <- function(side_label, min_events, min_weight) {
  side_orgs <- orgs_long |>
    filter(side == side_label) |>
    count(org, name = "events") |>
    filter(events >= min_events) |>
    pull(org)
  edges <- co_edges |>
    filter(from %in% side_orgs, to %in% side_orgs, weight >= min_weight)
  nodes <- tibble(org = unique(c(edges$from, edges$to))) |>
    left_join(org_summary |> select(org, events, dominant_side),
              by = "org") |>
    filter(!is.na(events))
  if (nrow(nodes) == 0 || nrow(edges) == 0) {
    return(list(nodes = tibble(id = character(), label = character(),
                               events = integer(), x = numeric(), y = numeric()),
                edges = tibble(from = character(), to = character(),
                               weight = integer())))
  }
  g <- graph_from_data_frame(edges, vertices = nodes, directed = FALSE)
  set.seed(42)
  layout <- layout_with_fr(g, niter = 600)
  nodes <- nodes |>
    mutate(x = layout[, 1] * 200, y = layout[, 2] * 200)
  list(nodes = nodes, edges = edges)
}

# Pro side: large set, so high thresholds keep the network legible.
network_pro     <- build_side_network("Pro-movement",     min_events = 40, min_weight = 8)
# Counter side is much smaller, so thresholds are looser.
network_counter <- build_side_network("Counter-movement", min_events = 5,  min_weight = 2)

# --- ANES 2024 Time Series: variables specifically about racism and policing -
#   V241227x = SUMMARY PARTY ID (1=Strong Dem ... 7=Strong Rep)
#   V241501x = SUMMARY RACE/ETHNICITY (1=White, 2=Black, 3=Hispanic, 4=Asian/PI,
#              5=Native/other, 6=Multiple)
#   V242150  = POST FT Police (0-100)
#   V242152  = POST FT Black Lives Matter (0-100)
#   V242336  = POST: How often police use more force than necessary (1=Never .. 5=All the time)
#   V242525x = SUMMARY: Police treat Blacks or Whites better (1=Whites much better ..
#              4=Same .. 7=Blacks much better)
#   V242522x = SUMMARY: Federal government treats Blacks or Whites better (1..7 same scale)
#   V242549  = POST: How much discrimination in US against Blacks (1=A great deal .. 5=None at all)
#   V241397  = PRE: Best way to deal with urban unrest (1=Solve racism and police violence ..
#              7=Use all available force; 99=Haven't thought about it)
anes_raw <- read_csv("data/anes_timeseries_2024_csv_20250808.csv",
                     show_col_types = FALSE, progress = FALSE,
                     col_select = c(V241227x, V241501x,
                                    V242150, V242152,
                                    V242336, V242525x, V242522x,
                                    V242549, V241397))

# Helper: clean a thermometer (drop ANES negative codes, drop the lone 200 outlier).
clean_therm <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  ifelse(x >= 0 & x <= 100, x, NA_real_)
}

party_levels   <- c("Strong Democrat", "Weak Democrat",
                    "Independent leaning Democrat", "Independent",
                    "Independent leaning Republican",
                    "Weak Republican", "Strong Republican")
race_levels    <- c("White", "Black", "Hispanic", "Asian/PI",
                    "Native/other", "Multiple")
force_levels   <- c("Never", "Rarely", "About half the time",
                    "Most of the time", "All the time")
discrim_levels <- c("A great deal", "A lot", "A moderate amount",
                    "A little", "None at all")
treat_levels   <- c("Whites much better", "Whites moderately better",
                    "Whites a little better", "Both treated the same",
                    "Blacks a little better", "Blacks moderately better",
                    "Blacks much better")
unrest_levels  <- c("1: Solve racism / police violence",
                    "2", "3", "4", "5", "6",
                    "7: Use all available force")

safe_label <- function(x, levels) {
  i <- suppressWarnings(as.integer(x))
  i_safe <- ifelse(i >= 1 & i <= length(levels), i, NA_integer_)
  factor(levels[i_safe], levels = levels)
}

anes <- anes_raw |>
  transmute(
    party             = safe_label(V241227x, party_levels),
    race              = safe_label(V241501x, race_levels),
    ft_police         = clean_therm(V242150),
    ft_blm            = clean_therm(V242152),
    police_more_force = safe_label(V242336,  force_levels),
    police_treat      = safe_label(V242525x, treat_levels),
    fedgov_treat      = safe_label(V242522x, treat_levels),
    societal_disc     = safe_label(V242549,  discrim_levels),
    unrest            = safe_label(V241397,  unrest_levels)
  )

anes_by_party <- anes |>
  filter(!is.na(party)) |>
  group_by(party) |>
  summarise(
    n           = n(),
    mean_blm    = mean(ft_blm, na.rm = TRUE),
    mean_police = mean(ft_police, na.rm = TRUE),
    .groups     = "drop"
  )

anes_by_race <- anes |>
  filter(!is.na(race)) |>
  group_by(race) |>
  summarise(
    n           = n(),
    mean_blm    = mean(ft_blm, na.rm = TRUE),
    mean_police = mean(ft_police, na.rm = TRUE),
    .groups     = "drop"
  )

# Helper: percent distribution of a categorical answer by a grouping variable.
pct_by <- function(df, group_var, answer_var) {
  df |>
    filter(!is.na(.data[[group_var]]), !is.na(.data[[answer_var]])) |>
    count(.data[[group_var]], .data[[answer_var]]) |>
    rename(group = 1, answer = 2) |>
    group_by(group) |>
    mutate(pct = n / sum(n) * 100) |>
    ungroup()
}

therm_bin_levels <- c("Very cold (0-20)", "Cold (21-40)", "Neutral (41-60)",
                      "Warm (61-80)", "Very warm (81-100)")
bin_thermometer <- function(x) {
  cut(x, breaks = c(-Inf, 20, 40, 60, 80, Inf),
      labels = therm_bin_levels, right = TRUE)
}
anes <- anes |>
  mutate(ft_blm_bin    = bin_thermometer(ft_blm),
         ft_police_bin = bin_thermometer(ft_police))

anes_blm_bin_by_party    <- pct_by(anes, "party", "ft_blm_bin")
anes_blm_bin_by_race     <- pct_by(anes, "race",  "ft_blm_bin")
anes_police_bin_by_party <- pct_by(anes, "party", "ft_police_bin")
anes_police_bin_by_race  <- pct_by(anes, "race",  "ft_police_bin")

anes_force_by_party   <- pct_by(anes, "party", "police_more_force")
anes_force_by_race    <- pct_by(anes, "race",  "police_more_force")
anes_treat_by_party   <- pct_by(anes, "party", "police_treat")
anes_treat_by_race    <- pct_by(anes, "race",  "police_treat")
anes_fedgov_by_party  <- pct_by(anes, "party", "fedgov_treat")
anes_fedgov_by_race   <- pct_by(anes, "race",  "fedgov_treat")
anes_disc_by_party    <- pct_by(anes, "party", "societal_disc")
anes_disc_by_race     <- pct_by(anes, "race",  "societal_disc")
anes_unrest_by_party  <- pct_by(anes, "party", "unrest")
anes_unrest_by_race   <- pct_by(anes, "race",  "unrest")

dir.create("data/clean", showWarnings = FALSE)
saveRDS(events,      "data/clean/events.rds")
saveRDS(orgs_long,   "data/clean/orgs_long.rds")
saveRDS(encounters,  "data/clean/encounters.rds")
saveRDS(org_summary, "data/clean/org_summary.rds")
saveRDS(co_edges,    "data/clean/co_edges.rds")
saveRDS(claim_phrases, "data/clean/claim_phrases.rds")
saveRDS(anes,                "data/clean/anes.rds")
saveRDS(anes_by_party,       "data/clean/anes_by_party.rds")
saveRDS(anes_by_race,        "data/clean/anes_by_race.rds")
saveRDS(anes_force_by_party, "data/clean/anes_force_by_party.rds")
saveRDS(anes_force_by_race,  "data/clean/anes_force_by_race.rds")
saveRDS(anes_treat_by_party, "data/clean/anes_treat_by_party.rds")
saveRDS(anes_treat_by_race,  "data/clean/anes_treat_by_race.rds")
saveRDS(anes_fedgov_by_party,"data/clean/anes_fedgov_by_party.rds")
saveRDS(anes_fedgov_by_race, "data/clean/anes_fedgov_by_race.rds")
saveRDS(anes_disc_by_party,  "data/clean/anes_disc_by_party.rds")
saveRDS(anes_disc_by_race,   "data/clean/anes_disc_by_race.rds")
saveRDS(anes_unrest_by_party,"data/clean/anes_unrest_by_party.rds")
saveRDS(anes_unrest_by_race, "data/clean/anes_unrest_by_race.rds")
saveRDS(network_pro,             "data/clean/network_pro.rds")
saveRDS(network_counter,         "data/clean/network_counter.rds")
saveRDS(claim_objects,           "data/clean/claim_objects.rds")
saveRDS(anes_blm_bin_by_party,   "data/clean/anes_blm_bin_by_party.rds")
saveRDS(anes_blm_bin_by_race,    "data/clean/anes_blm_bin_by_race.rds")
saveRDS(anes_police_bin_by_party,"data/clean/anes_police_bin_by_party.rds")
saveRDS(anes_police_bin_by_race, "data/clean/anes_police_bin_by_race.rds")

cat("Wrote", nrow(events), "events,",
    nrow(orgs_long), "org-rows,",
    nrow(encounters), "encounter pairs,",
    nrow(org_summary), "orgs,",
    nrow(co_edges), "co-occurrence edges (weight >= 2).\n")
cat("Side breakdown:\n"); print(table(events$side, useNA = "ifany"))
cat("Date range:", as.character(range(events$date, na.rm = TRUE)), "\n")
