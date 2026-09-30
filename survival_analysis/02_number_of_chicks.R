# Ground-truth "chicks ringed per year" count, computed directly from the raw
# ringing database (data_raw/ringing_data_raw.xlsx, sheet "Data" - one row per
# ringing record, ~66k rows, all species/years), instead of trusting
# summary_2026.xlsx's pre-tallied "מספר צעירים" sheet (currently the source of
# chicks_hir/chicks_alb in master_dataset_2010_2026.csv) or slide 13/14's
# plotted "number of fledglings" (issue #11 - source undocumented, doesn't
# match either).
#
# Filter, per Inbal: a record counts as "a chick ringed this year" if
#   - Age == 3 (EURING: hatched this calendar year - i.e. this year's young)
#   - the retrap/status column ("Rec") is blank - i.e. a NEW capture, not a
#     recapture/control of a bird ringed earlier
# grouped by the record's Date -> year, and by Species (STEALB = Little Tern
# "alb", STEHIR = Common Tern "hir").
#
# Verification: compare the resulting 2010-2020 counts against
# data_2010-2020_legacy.csv's hir/alb columns (NOTES.md: "Verified correct",
# the trusted source Yosef's original 2020 analysis was built on). Inbal
# spot-checked one year by hand and it matched; this checks all 11.
#
# 2026 is included - unlike summary_2026.xlsx (NOTES.md open item #1: 2026
# chick count there is an unconfirmed copy-paste of 2025), the raw ringing
# database has real 2026 ringing records, so this method's 2026 figure is not
# a placeholder.

library(readxl)
library(dplyr)

raw_dir <- "data_raw"
if (!dir.exists(raw_dir)) raw_dir <- "../data_raw"
stopifnot(dir.exists(raw_dir))
proc_dir <- sub("data_raw$", "data_processed", raw_dir)

# ---- 1. read raw ringing records -------------------------------------------
# Header spans 2 rows (merged super-headers + actual field names) - read
# positionally instead, same approach as scripts/00_build_dataset.R uses for
# summary_2026.xlsx's messy sheets.
ring_path <- file.path(raw_dir, "ringing_data_raw.xlsx")
raw <- read_excel(ring_path, sheet = "Data", col_names = FALSE, skip = 2)

# NB: readxl silently drops the fully-blank leading column that openpyxl
# keeps, so these positions are one less than the raw file's visual column
# order (verified against openpyxl's positional read of the same sheet).
rec     <- raw[[3]]   # retrap/status column ("Rec"): blank = new capture
species <- raw[[6]]   # "Species": STEALB / STEHIR / STESAN / STEREP
age     <- suppressWarnings(as.numeric(raw[[8]]))   # "Age" (EURING code)
date    <- raw[[11]]  # "Date"

is_blank <- function(x) is.na(x) | trimws(as.character(x)) == ""

# ---- 2. filter to new-capture chicks (age 3, blank retrap column) ---------
chick_records <- data.frame(
  year    = as.integer(format(as.Date(date), "%Y")),
  species = species,
  stringsAsFactors = FALSE
) %>%
  filter(age == 3, is_blank(rec), species %in% c("STEALB", "STEHIR"), !is.na(year))

# ---- 3. tally per year / species -------------------------------------------
chicks_from_raw <- chick_records %>%
  count(year, species) %>%
  mutate(species = recode(species, STEALB = "alb", STEHIR = "hir")) %>%
  tidyr::pivot_wider(names_from = species, values_from = n, values_fill = 0,
                      names_prefix = "chicks_") %>%
  arrange(year)

cat("Chicks ringed per year, computed from ringing_data_raw.xlsx (Age==3, new capture):\n")
print(chicks_from_raw)

# ---- 4. verify against the trusted 2010-2020 legacy file -------------------
legacy <- read.csv(file.path(raw_dir, "data_2010-2020_legacy.csv"), stringsAsFactors = FALSE) %>%
  select(year, chicks_hir_legacy = hir, chicks_alb_legacy = alb)

check <- chicks_from_raw %>%
  inner_join(legacy, by = "year") %>%
  mutate(
    delta_hir = chicks_hir - chicks_hir_legacy,
    delta_alb = chicks_alb - chicks_alb_legacy
  ) %>%
  select(year, chicks_hir, chicks_hir_legacy, delta_hir,
         chicks_alb, chicks_alb_legacy, delta_alb)

cat("\nVerification vs data_2010-2020_legacy.csv (delta = raw-derived minus legacy):\n")
print(check)

n_mismatch <- sum(check$delta_hir != 0) + sum(check$delta_alb != 0)
cat("\n", n_mismatch, "of", 2 * nrow(check),
    "species-year values differ from the legacy file (see deltas above).\n")

# ---- 5. write out for reuse -------------------------------------------------
dir.create(proc_dir, showWarnings = FALSE)
out_path <- file.path(proc_dir, "chicks_ringed_from_raw_2010_2026.csv")
write.csv(chicks_from_raw, out_path, row.names = FALSE, na = "NA")
cat("\nWrote", normalizePath(out_path), "\n")
