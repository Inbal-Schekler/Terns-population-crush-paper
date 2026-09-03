# ==============================================================================
# 00_build_dataset.R
#
# Purpose: build one clean, tidy, year-by-year master dataset for both species
# (Little Tern = "alb" = Sternula albifrons; Common Tern = "hir" = Sterna
# hirundo) from the raw sources Yosef sent, instead of trusting the legacy
# data1.csv, which contains a confirmed data bug (see NOTES.md).
#
# Sources combined:
#   - data_raw/summary_2026.xlsx  -> chick (fledgling) counts and pair counts,
#     2010-2025 (sheets "מספר צעירים" and "מספר זוגות בעתלית - רב שנתי")
#   - data_raw/data_2010-2020_legacy.csv -> weather, predation, newcastle,
#     2010-2020 (verified correct; NOT the buggy file)
#   - data_raw/data1_2012-2020_legacy.csv -> pre-breeding body mass only
#     (hirMASS/albMASS columns are NOT affected by the bug; everything else
#     in that file is re-derived instead of trusted, see NOTES.md)
#
# Known gap (intentional): weather / predation / newcastle / body-mass data
# for 2021-2025 do not exist anywhere in the folder Yosef sent. Those cells
# are left NA on purpose - they need to be filled in from field records
# before the model can be extended past 2020. See NOTES.md "Open items".
# ==============================================================================

library(readxl)
library(dplyr)

# Works whether you run this with the working directory set to analysis/
# or analysis/scripts/ (e.g. Rscript scripts/00_build_dataset.R from analysis/).
raw_dir <- "data_raw"
if (!dir.exists(raw_dir)) raw_dir <- "../data_raw"
stopifnot(dir.exists(raw_dir))

xlsx_path <- file.path(raw_dir, "summary_2026.xlsx")

# ---- 1. chick (fledgling) counts, 2010-2025, both species ------------------
chicks_raw <- read_excel(xlsx_path, sheet = "מספר צעירים", col_names = FALSE)
years <- as.numeric(chicks_raw[2, -1])
chicks_alb <- as.numeric(chicks_raw[3, -1])
chicks_hir <- as.numeric(chicks_raw[4, -1])
chicks <- data.frame(year = years, chicks_alb = chicks_alb, chicks_hir = chicks_hir)

# ---- 2. pair counts + counting method, 2011-2025, both species -------------
pairs_raw <- read_excel(xlsx_path, sheet = "מספר זוגות בעתלית - רב שנתי", col_names = TRUE)
names(pairs_raw) <- c("year", "pairs_hir", "pairs_alb", "pairs_method")
pairs_raw$year <- as.numeric(pairs_raw$year)

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
    # species' fledgling count two years prior. Recomputed here directly
    # from the chick counts above (do not trust legacy hirTWOyears/albTWOyears).
    hirTWOyears = lag(chicks_hir, 2),
    albTWOyears = lag(chicks_alb, 2)
  )

proc_dir <- sub("data_raw$", "data_processed", raw_dir)
dir.create(proc_dir, showWarnings = FALSE)
out_path <- file.path(proc_dir, "master_dataset.csv")
write.csv(master, out_path, row.names = FALSE, na = "NA")

cat("Master dataset written to:", normalizePath(out_path), "\n")
cat("Rows:", nrow(master), " | Years:", min(master$year), "-", max(master$year), "\n")
cat("\nMissing data by column (years 2021-2025 gaps are EXPECTED - see NOTES.md):\n")
print(sapply(master, function(x) sum(is.na(x))))
print(master)
