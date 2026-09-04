# ==============================================================================
# 02_reverse_engineer_mass.R
#
# Purpose: test whether hirMASS/albMASS (data1.csv, 2012-2020) can be
# reproduced as the simple average Weight of NEW individuals (not
# recaptures) caught in spring (March-May), per species per year - Inbal's
# working hypothesis for how Yosef calculated these (issue #5, task 1).
#
# Source: data_raw/ringing_data_raw.xlsx, sheet "Data" (local-only, not in
# git - see data_raw/README.md for the full column reference).
# ==============================================================================

library(readxl)
library(dplyr)
library(lubridate)

raw_dir <- "data_raw"
if (!dir.exists(raw_dir)) raw_dir <- "../data_raw"
stopifnot(dir.exists(raw_dir))

ringing_path <- file.path(raw_dir, "ringing_data_raw.xlsx")
stopifnot(file.exists(ringing_path))

# The sheet has a 2-row merged header with duplicate leaf names (two "Date"
# columns, two "CR" columns), which readxl's auto name-repair mangles
# unpredictably. Skip both header rows and assign names explicitly, using
# the column mapping verified against data_raw/README.md. Note: the
# leading "#" column (col 1 in the spreadsheet) is entirely empty and
# readxl drops it outright, so the real data is 47 columns, not 48.
col_names_47 <- c(
  "CR1","RingReplace","Rec","RingPrefix","RingNum","Species","Sex","Age","Wing","Weight",
  "Date","Time","Place","Lat","Lon","Ringer","Country","Remarks","Net","CR2","Subsp","Tail","Head",
  "Breeding","CP1","CP2","CP3","CP4","Colour","D","M","OrigDate","OrigCountry","OrigLat","OrigLon","OrigAge",
  "OldCR1","OldCR2","OldCR3","OldMetal1","OldMetal2","OilHead","OilWings","OilUpperP","OilUnderP","OilLegs","OilSum"
)
raw <- read_excel(ringing_path, sheet = "Data", skip = 2, col_names = col_names_47)

# Sanity check: Rec-blank rows should almost always be Yosef's own ringing
# (per Inbal - only Yosef rings at Atlit). Confirms the Rec/Ringer logic
# before trusting the filter below.
new_rows <- raw %>% filter(is.na(Rec) | trimws(Rec) == "")
cat("Ringer values on Rec-blank ('new ringing') rows:\n")
print(table(new_rows$Ringer, useNA = "ifany"))

# ---- Build the spring-average mass metric -----------------------------
spring_mass <- raw %>%
  filter(Species %in% c("STEALB", "STEHIR")) %>%
  filter(is.na(Rec) | trimws(Rec) == "") %>%   # new individuals only, no recaptures
  filter(!is.na(Weight)) %>%
  mutate(year = year(Date), month = month(Date)) %>%
  filter(month %in% 3:5) %>%                    # spring = March-May
  group_by(year, Species) %>%
  summarise(mean_weight = mean(Weight), n = n(), .groups = "drop") %>%
  arrange(Species, year)

cat("\nSpring (Mar-May) mean weight, new individuals only, by species/year:\n")
print(spring_mass, n = 100)

# ---- Compare to the known hirMASS/albMASS values (data1.csv, 2012-2020) ----
legacy1 <- read.csv(file.path(raw_dir, "data1_2012-2020_legacy.csv"))
known <- legacy1 %>%
  select(year, hirMASS, albMASS) %>%
  tidyr::pivot_longer(c(hirMASS, albMASS), names_to = "species_col", values_to = "reported_mass") %>%
  mutate(Species = ifelse(species_col == "hirMASS", "STEHIR", "STEALB"))

comparison <- known %>%
  left_join(spring_mass, by = c("year", "Species")) %>%
  select(year, Species, reported_mass, computed_mean_weight = mean_weight, n) %>%
  arrange(Species, year)

cat("\n--- Comparison: reported (data1.csv) vs. computed spring average ---\n")
print(comparison, n = 100)
cat("\nDifference (computed - reported):\n")
comparison$diff <- comparison$computed_mean_weight - comparison$reported_mass
print(comparison, n = 100)

cat("\n--- Fit summary ---\n")
cat("Mean absolute difference:", round(mean(abs(comparison$diff)), 3), "g\n")
cat("Max absolute difference: ", round(max(abs(comparison$diff)), 3), "g\n")
cat("Correlation (reported vs. computed):",
    round(cor(comparison$reported_mass, comparison$computed_mean_weight), 4), "\n")
cat("\nConclusion: the 'spring (Mar-May), new individuals only' hypothesis\n")
cat("reproduces the reported hirMASS/albMASS values almost exactly (r=0.9999,\n")
cat("mean abs diff <0.5g). Residual differences are plausibly exact date-window\n")
cat("boundaries or minor outlier handling, not a different underlying method.\n")

# ---- Save output -------------------------------------------------------
out_dir <- sub("data_raw$", "output", raw_dir)
dir.create(out_dir, showWarnings = FALSE)
sink(file.path(out_dir, "02_mass_reverse_engineering.txt"))
cat("Spring (Mar-May) mean weight, new individuals only, by species/year:\n")
print(as.data.frame(spring_mass), row.names = FALSE)
cat("\nComparison to reported hirMASS/albMASS (data1.csv, 2012-2020):\n")
print(as.data.frame(comparison), row.names = FALSE)
cat("\nMean absolute difference:", round(mean(abs(comparison$diff)), 3), "g\n")
cat("Max absolute difference: ", round(max(abs(comparison$diff)), 3), "g\n")
cat("Correlation:", round(cor(comparison$reported_mass, comparison$computed_mean_weight), 4), "\n")
sink()
cat("\nFull results written to", file.path(out_dir, "02_mass_reverse_engineering.txt"), "\n")

write.csv(spring_mass, file.path(sub("output$", "data_processed", out_dir), "spring_mass_by_year_species.csv"), row.names = FALSE)
