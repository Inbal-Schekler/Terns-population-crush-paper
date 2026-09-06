# ==============================================================================
# 03_breeding_mass.R
#
# Purpose: build a second, breeding-only version of the mass metric (issue
# #5, task 2), distinct from the spring/passage-migrant metric in
# 02_reverse_engineer_mass.R. Theory: birds still present in early summer
# (June-July, after the spring passage window has ended) are more likely to
# be actual Atlit breeders than passage migrants stopping over en route to
# Europe.
#
# Source: data_raw/ringing_data_raw.xlsx, sheet "Data" (local-only, not in
# git - see data_raw/README.md for the full column reference).
#
# IMPORTANT discovery (not obvious from task #5's wording): a naive
# "new individuals caught June-July" filter is dominated by THIS-YEAR
# CHICKS/JUVENILES, not adults - e.g. Common Tern July: 1,442 juveniles
# (EURING age 3) vs. 1,808 adults (age 6); Little Tern June: 154 juveniles
# vs. 242 adults (age 4). Chicks are ringed in the nest/shortly after
# fledging throughout the breeding season, so an unfiltered summer mean
# would mostly track fledgling weight, not adult breeding condition, and
# would NOT be comparable to the spring hirMASS/albMASS metric. Fixed by
# excluding EURING age 1 (pullus/nestling) and age 3 (this-year juvenile),
# keeping only adult age codes (4, 5, 6, and the two-digit known-exact-age
# adult codes). Confirmed with Inbal (2026-09-06) before implementing.
# ==============================================================================

library(readxl)
library(dplyr)
library(lubridate)

raw_dir <- "data_raw"
if (!dir.exists(raw_dir)) raw_dir <- "../data_raw"
stopifnot(dir.exists(raw_dir))

ringing_path <- file.path(raw_dir, "ringing_data_raw.xlsx")
stopifnot(file.exists(ringing_path))

# Same explicit column mapping as 02_reverse_engineer_mass.R - see that
# script's header comment for why (2-row merged header, duplicate leaf
# names, readxl's auto name-repair mangles them).
col_names_47 <- c(
  "CR1","RingReplace","Rec","RingPrefix","RingNum","Species","Sex","Age","Wing","Weight",
  "Date","Time","Place","Lat","Lon","Ringer","Country","Remarks","Net","CR2","Subsp","Tail","Head",
  "Breeding","CP1","CP2","CP3","CP4","Colour","D","M","OrigDate","OrigCountry","OrigLat","OrigLon","OrigAge",
  "OldCR1","OldCR2","OldCR3","OldMetal1","OldMetal2","OilHead","OilWings","OilUpperP","OilUnderP","OilLegs","OilSum"
)
raw <- read_excel(ringing_path, sheet = "Data", skip = 2, col_names = col_names_47)

# EURING age codes present in this sheet: 1 = pullus (nestling), 3 = this
# calendar year juvenile (i.e. this season's fledgling), 4 = full-grown,
# hatched before this year but exact year unknown, 5 = hatched last
# calendar year, 6 = hatched before last calendar year (exact year
# unknown), plus assorted two-digit exact-hatch-year adult codes (14, 22,
# 25, 28, 29, 35, 37...) confirmed with Inbal to extend the scale for
# known-age birds (terns can live ~20 years). Juvenile codes are 1 and 3;
# everything else observed in this sheet is an adult.
juvenile_ages <- c(1, 3)

# ---- Build the breeding (Jun-Jul) adult mean-mass metric ---------------
breeding_mass <- raw %>%
  filter(Species %in% c("STEALB", "STEHIR")) %>%
  filter(is.na(Rec) | trimws(Rec) == "") %>%   # new individuals only, no recaptures - same as spring metric
  filter(!is.na(Weight)) %>%
  filter(!(Age %in% juvenile_ages)) %>%         # adults only - see header comment
  mutate(year = year(Date), month = month(Date)) %>%
  filter(month %in% 6:7) %>%                    # summer breeding window = June-July
  group_by(year, Species) %>%
  summarise(mean_weight = mean(Weight), n = n(), .groups = "drop") %>%
  arrange(Species, year)

cat("Breeding (Jun-Jul) mean weight, new adult individuals only, by species/year:\n")
print(breeding_mass, n = 100)

# ---- Compare to the spring (passage) mass metric ------------------------
proc_dir <- sub("data_raw$", "data_processed", raw_dir)
spring_mass <- read.csv(file.path(proc_dir, "spring_mass_by_year_species.csv"))

comparison <- spring_mass %>%
  rename(spring_mean_weight = mean_weight, spring_n = n) %>%
  full_join(
    breeding_mass %>% rename(breeding_mean_weight = mean_weight, breeding_n = n),
    by = c("year", "Species")
  ) %>%
  mutate(diff = breeding_mean_weight - spring_mean_weight) %>%
  arrange(Species, year) %>%
  as_tibble()

cat("\n--- Comparison: spring (passage) vs. breeding (Jun-Jul, adults) mean weight ---\n")
print(comparison, n = 100)

for (sp in c("STEHIR", "STEALB")) {
  sub <- comparison %>% filter(Species == sp, !is.na(spring_mean_weight), !is.na(breeding_mean_weight))
  cat("\n", sp, "- correlation (spring vs. breeding):",
      round(cor(sub$spring_mean_weight, sub$breeding_mean_weight), 4),
      "| mean diff (breeding - spring):", round(mean(sub$diff), 2), "g\n")
}

# ---- Save output ---------------------------------------------------------
out_dir <- sub("data_raw$", "output", raw_dir)
dir.create(out_dir, showWarnings = FALSE)
sink(file.path(out_dir, "03_breeding_mass.txt"))
cat("Breeding (Jun-Jul) mean weight, new adult individuals only, by species/year:\n")
print(as.data.frame(breeding_mass), row.names = FALSE)
cat("\nComparison: spring (passage) vs. breeding (Jun-Jul, adults) mean weight:\n")
print(as.data.frame(comparison), row.names = FALSE)
for (sp in c("STEHIR", "STEALB")) {
  sub <- comparison %>% filter(Species == sp, !is.na(spring_mean_weight), !is.na(breeding_mean_weight))
  cat("\n", sp, "- correlation (spring vs. breeding):",
      round(cor(sub$spring_mean_weight, sub$breeding_mean_weight), 4),
      "| mean diff (breeding - spring):", round(mean(sub$diff), 2), "g\n")
}
sink()
cat("\nFull results written to", file.path(out_dir, "03_breeding_mass.txt"), "\n")

write.csv(breeding_mass, file.path(proc_dir, "breeding_mass_by_year_species.csv"), row.names = FALSE)
cat("Wrote", file.path(proc_dir, "breeding_mass_by_year_species.csv"), "\n")
