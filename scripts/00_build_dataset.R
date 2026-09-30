# ==============================================================================
# 00_build_dataset.R
#
# Purpose: build one clean, tidy, year-by-year master dataset for both species
# (Little Tern = "alb" = Sternula albifrons; Common Tern = "hir" = Sterna
# hirundo) from the raw sources Yosef sent, instead of trusting the legacy
# data1.csv, which contains a confirmed data bug (see NOTES.md).
#
# Sources combined:
#   - data_processed/chicks_ringed_from_raw_2010_2026.csv -> chick counts,
#     2010-2026, both species. Computed by survival_analysis/02_number_of_
#     chicks.R directly from data_raw/ringing_data_raw.xlsx (age==3, blank
#     retrap = new capture), NOT summary_2026.xlsx's pre-tallied sheet - see
#     issue #12. Verified against data_2010-2020_legacy.csv (16/22 exact
#     matches); real 2026 records, unlike summary_2026.xlsx's placeholder.
#   - data_processed/ringing_effort_by_year.csv -> effort-normalized chicks
#     per ringing night (survival_analysis/05_ringing_effort_days.R), added
#     alongside the raw counts per Inbal - both kept, not one replacing the
#     other (see feedback-additive-analysis-iteration).
#   - data_raw/summary_2026.xlsx -> pair counts only now (chick counts moved
#     to the raw-derived source above), 2011-2026 (sheet "מספר זוגות
#     בעתלית - רב שנתי")
#   - data_raw/data_2010-2020_legacy.csv -> weather, predation, newcastle,
#     2010-2020 (verified correct; NOT the buggy file)
#   - data_raw/data1_2012-2020_legacy.csv -> pre-breeding body mass only
#     (hirMASS/albMASS columns are NOT affected by the bug; everything else
#     in that file is re-derived instead of trusted, see NOTES.md). NOTE:
#     mass_analysis/scripts/02_mass_analysis.Rmd overwrites hirMASS/albMASS
#     and adds hirMASS_breed/albMASS_breed after this script runs - rerun it
#     too if you rebuild from scratch, or those columns revert to the
#     2012-2020-only legacy values / disappear entirely.
#
# Known gap (intentional): weather / predation / newcastle data for
# 2021-2026 do not exist anywhere in the folder Yosef sent. Those cells are
# left NA on purpose - they need to be filled in from field records before
# the model can be extended past 2020. See NOTES.md "Open items".
# ==============================================================================

library(readxl)
library(dplyr)

# Works whether you run this with the working directory set to analysis/
# or analysis/scripts/ (e.g. Rscript scripts/00_build_dataset.R from analysis/).
raw_dir <- "data_raw"
if (!dir.exists(raw_dir)) raw_dir <- "../data_raw"
stopifnot(dir.exists(raw_dir))

xlsx_path <- file.path(raw_dir, "summary_2026.xlsx")
proc_dir <- sub("data_raw$", "data_processed", raw_dir)

# ---- 1. chick counts, 2010-2026, both species -------------------------------
# Verified ground truth from the raw ringing database (issue #12), not
# summary_2026.xlsx's pre-tallied sheet. Ringing-effort-normalized rate
# (chicks per ringing night) kept alongside the raw count, not replacing it.
chicks <- read.csv(file.path(proc_dir, "chicks_ringed_from_raw_2010_2026.csv"))
effort <- read.csv(file.path(proc_dir, "ringing_effort_by_year.csv")) %>%
  select(year, ringing_nights, alb_per_night, hir_per_night)
chicks <- chicks %>% full_join(effort, by = "year")

# ---- 2. pair counts + counting method, 2011-2026, both species -------------
pairs_raw <- read_excel(xlsx_path, sheet = "מספר זוגות בעתלית - רב שנתי", col_names = TRUE)
names(pairs_raw) <- c("year", "pairs_hir", "pairs_alb", "pairs_method")
pairs_raw$year <- as.numeric(pairs_raw$year)
pairs_raw$pairs_method <- recode(pairs_raw$pairs_method,
  "רכב" = "Car",
  "מצלמה אחת / מגדל" = "One camera/tower",
  "שתי מצלמות" = "2 cameras"
)

# ---- 3. weather / predation / newcastle, 2010-2020 (verified source) -------
legacy <- read.csv(file.path(raw_dir, "data_2010-2020_legacy.csv"), stringsAsFactors = FALSE)
weather <- legacy %>%
  select(year, temp37, temp12, meanMAXtemp, meanMINtemp, rainMAY, rainJUN, predation, newcastle)

# ---- 4. pre-breeding body mass, 2012-2020 -----------------------------------
# Only hirMASS/albMASS are trusted from data1.csv - the temp/predation columns
# in that file are corrupted (see NOTES.md) and are deliberately NOT used here.
legacy1 <- read.csv(file.path(raw_dir, "data1_2012-2020_legacy.csv"), stringsAsFactors = FALSE)
mass <- legacy1 %>% select(year, hirMASS, albMASS)

# ---- 5. assemble master dataset --------------------------------------------
master <- chicks %>%
  full_join(pairs_raw, by = "year") %>%
  full_join(weather, by = "year") %>%
  full_join(mass, by = "year") %>%
  arrange(year) %>%
  mutate(
    # interspecific competition proxy used in the 2020 analysis: the OTHER
    # species' chick count two years prior. Recomputed here directly from
    # the chick counts above (do not trust legacy hirTWOyears/albTWOyears).
    # Normalized (per-ringing-night) version kept alongside, per issue #11's
    # effort-normalized competition follow-up.
    hirTWOyears = lag(chicks_hir, 2),
    albTWOyears = lag(chicks_alb, 2),
    hirTWOyears_norm = lag(hir_per_night, 2),
    albTWOyears_norm = lag(alb_per_night, 2)
  )

dir.create(proc_dir, showWarnings = FALSE)
out_path <- file.path(proc_dir, "master_dataset_2010_2026.csv")
write.csv(master, out_path, row.names = FALSE, na = "NA")

cat("Master dataset written to:", normalizePath(out_path), "\n")
cat("Rows:", nrow(master), " | Years:", min(master$year), "-", max(master$year), "\n")
cat("\nMissing data by column (years 2021-2025 gaps are EXPECTED - see NOTES.md):\n")
print(sapply(master, function(x) sum(is.na(x))))
print(master)
