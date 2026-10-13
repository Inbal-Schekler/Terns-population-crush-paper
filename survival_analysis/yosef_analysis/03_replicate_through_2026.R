# ==============================================================================
# 03_replicate_through_2026.R
#
# Purpose: extend 01_replicate_2020_baseline.R's model sets through 2026,
# "as-is" - same predictors, same model structures as Yosef's original 2020
# work. Per NOTES.md's "Next session" pointer: Inbal wants to see his
# original approach rerun on the recent years first, issues and all, before
# any redesign.
#
# Weather past 2020: Yosef's own legacy columns (temp37/temp12/meanMAXtemp/
# meanMINtemp/rainMAY/rainJUN) are NA 2021-2026 - no Yosef-equivalent source
# exists for those years. But the separately-built `_inb` columns (self-
# computed from raw IMS station data, validated against Yosef's real
# 2010-2020 values - see NOTES.md) now cover the FULL 2010-2026 range with
# one consistent method. TIER 2 below uses those to rerun Yosef's full
# original model structure (all 27/23 candidates, weather included) over
# the full range (Block A: 2010-2026, n=17; Block B: 2012-2026, n=15) -
# this is the main "as-is through 2026" comparison. TIER 1 (kept from the
# first pass, before the _inb data covered the full range) is a narrower,
# legacy-only comparison of just the non-weather predictors (predation/
# newcastle; predation/competition/mass) - kept alongside Tier 2 rather
# than replaced, per [[feedback-additive-analysis-iteration]], since it's
# still a valid same-model-set-different-years comparison in its own right.
#
# This script does NOT modify 01's original tables.
# ==============================================================================

library(dplyr)
library(MuMIn)

options(na.action = "na.fail")

proc_candidates <- c("../../data_processed", "../data_processed", "data_processed")
out_candidates  <- c("output", "yosef_analysis/output", "survival_analysis/yosef_analysis/output")
proc_idx <- which(dir.exists(proc_candidates))[1]
proc_dir <- proc_candidates[proc_idx]
master <- read.csv(file.path(proc_dir, "master_dataset_2010_2026.csv"))

fit_models <- function(response, rhs_list, data) {
  f <- function(rhs) as.formula(paste(response, "~", rhs))
  models <- lapply(rhs_list, function(rhs) glm(f(rhs), family = gaussian, data = data))
  names(models) <- paste0("m", seq_along(models))
  models
}

# ------------------------------------------------------------------------
# Block A, extended: 2010-2026 (17 years), predation/newcastle only
# (the only Block A predictors with no NA past 2020)
# ------------------------------------------------------------------------
dataA_ext <- master %>% filter(year >= 2010, year <= 2026) %>%
  select(year, hir = chicks_hir, alb = chicks_alb, predation, newcastle)
stopifnot(nrow(dataA_ext) == 17, !anyNA(dataA_ext))
dataA_orig_reduced <- dataA_ext %>% filter(year <= 2020)
stopifnot(nrow(dataA_orig_reduced) == 11)

rhs_no_weather <- c("predation", "newcastle", "predation + newcastle")  # null dropped, matches 01's convention

models_hir_A_ext <- fit_models("hir", rhs_no_weather, dataA_ext)
models_alb_A_ext <- fit_models("alb", rhs_no_weather, dataA_ext)
models_hir_A_orig_reduced <- fit_models("hir", rhs_no_weather, dataA_orig_reduced)
models_alb_A_orig_reduced <- fit_models("alb", rhs_no_weather, dataA_orig_reduced)

cat("\n================ TIER 1: Block A extended (2010-2026, n=17) - predation/newcastle only ================\n")
cat("(Weather-containing models from 01's Block A are NOT extended here - temp/rain legacy\n")
cat(" columns are NA for 2021-2026, see header comment. This is a reduced comparison: just\n")
cat(" the 3 non-null predation/newcastle models. Shown twice, same model set both times, so the\n")
cat(" only thing that differs is how many years are in the data: 2010-2020 (n=11, matches 01's\n")
cat(" original window) vs 2010-2026 (n=17, extended) - isolates the effect of the extra years.)\n")
cat("\n--- Common Tern (hir), 2010-2020 (n=11) ---\n")
print(model.sel(models_hir_A_orig_reduced))
cat("\n--- Common Tern (hir), 2010-2026 (n=17) ---\n")
sel_hir_A_ext <- model.sel(models_hir_A_ext)
print(sel_hir_A_ext)
cat("\n--- Little Tern (alb), 2010-2020 (n=11) ---\n")
print(model.sel(models_alb_A_orig_reduced))
cat("\n--- Little Tern (alb), 2010-2026 (n=17) ---\n")
sel_alb_A_ext <- model.sel(models_alb_A_ext)
print(sel_alb_A_ext)

# ------------------------------------------------------------------------
# Block B, extended: 2012-2026 (15 years), predation + competition + mass only
# (the only Block B predictors with no NA past 2020 - temp37/temp12/
# meanMAXtemp/meanMINtemp are legacy-only)
# ------------------------------------------------------------------------
dataB_ext <- master %>% filter(year >= 2012, year <= 2026) %>%
  select(year, hir = chicks_hir, alb = chicks_alb, predation,
         hirTWOyears, albTWOyears, hirMASS, albMASS)
stopifnot(nrow(dataB_ext) == 15, !anyNA(dataB_ext))
dataB_orig_reduced <- dataB_ext %>% filter(year <= 2020)
stopifnot(nrow(dataB_orig_reduced) == 9)

rhs_no_temp_hir <- c(
  "predation", "albTWOyears", "hirMASS",
  "predation + albTWOyears", "predation + hirMASS", "albTWOyears + hirMASS",
  "predation + albTWOyears + hirMASS"
)
rhs_no_temp_alb <- c(
  "predation", "hirTWOyears", "albMASS",
  "predation + hirTWOyears", "predation + albMASS", "hirTWOyears + albMASS",
  "predation + hirTWOyears + albMASS"
)

models_hir_B_ext <- fit_models("hir", rhs_no_temp_hir, dataB_ext)
models_alb_B_ext <- fit_models("alb", rhs_no_temp_alb, dataB_ext)
models_hir_B_orig_reduced <- fit_models("hir", rhs_no_temp_hir, dataB_orig_reduced)
models_alb_B_orig_reduced <- fit_models("alb", rhs_no_temp_alb, dataB_orig_reduced)

cat("\n================ TIER 1: Block B extended (2012-2026, n=15) - predation/competition/mass only ================\n")
cat("(Weather-containing models from 01's Block B are NOT extended here, same reason as Block A.\n")
cat(" Reduced comparison: the 7 non-temperature models per species, shown at 2012-2020 (n=9,\n")
cat(" matches 01's original window) and 2012-2026 (n=15, extended) to isolate the year effect.)\n")
cat("\n--- Common Tern (hir), 2012-2020 (n=9) ---\n")
print(model.sel(models_hir_B_orig_reduced))
cat("\n--- Common Tern (hir), 2012-2026 (n=15) ---\n")
sel_hir_B_ext <- model.sel(models_hir_B_ext)
print(sel_hir_B_ext)
cat("\n--- Little Tern (alb), 2012-2020 (n=9) ---\n")
print(model.sel(models_alb_B_orig_reduced))
cat("\n--- Little Tern (alb), 2012-2026 (n=15) ---\n")
sel_alb_B_ext <- model.sel(models_alb_B_ext)
print(sel_alb_B_ext)

# ------------------------------------------------------------------------
# TIER 2: full original model structure, weather included, via the `_inb`
# columns - now 2010-2026 (n=17), the full range, since the 2010-2013 raw
# IMS downloads closed the gap that used to cap this at 2014. Variable-for-
# variable swap of the legacy weather names in 01's rhs_list for their
# `_inb` equivalents; every other predictor/model-structure choice is
# identical to 01.
# ------------------------------------------------------------------------
ims_swap <- function(rhs_list) {
  pairs <- list(c("temp37", "temp37_inb"), c("temp12", "temp12_inb"),
                c("meanMAXtemp", "meanMAXtemp_inb"), c("meanMINtemp", "meanMINtemp_inb"),
                c("rainMAY", "rainMAY_inb"), c("rainJUN", "rainJUN_inb"))
  for (p in pairs) rhs_list <- gsub(p[1], p[2], rhs_list, fixed = TRUE)
  rhs_list
}

dataA_inb <- master %>% filter(year >= 2010, year <= 2026) %>%
  select(year, hir = chicks_hir, alb = chicks_alb, predation, newcastle,
         temp37_inb, temp12_inb, meanMAXtemp_inb, meanMINtemp_inb, rainMAY_inb, rainJUN_inb)
stopifnot(nrow(dataA_inb) == 17, !anyNA(dataA_inb))

rhs_block_a <- c(
  "1", "predation", "newcastle", "predation + newcastle",
  "temp37", "predation + temp37", "newcastle + temp37", "predation + newcastle + temp37",
  "temp12", "predation + temp12", "newcastle + temp12", "predation + newcastle + temp12",
  "meanMAXtemp", "predation + meanMAXtemp", "newcastle + meanMAXtemp", "predation + newcastle + meanMAXtemp",
  "meanMINtemp", "predation + meanMINtemp", "newcastle + meanMINtemp", "predation + newcastle + meanMINtemp",
  "rainMAY", "predation + rainMAY", "newcastle + rainMAY", "predation + newcastle + rainMAY",
  "rainJUN", "predation + rainJUN", "newcastle + rainJUN", "predation + newcastle + rainJUN"
)
rhs_block_a_inb <- ims_swap(rhs_block_a)

models_hir_A_inb <- fit_models("hir", rhs_block_a_inb, dataA_inb)
models_alb_A_inb <- fit_models("alb", rhs_block_a_inb, dataA_inb)

cat("\n================ TIER 2: Block A, full structure via _inb weather (2010-2026, n=17) ================\n")
cat("(Same 27-model structure as 01's Block A, weather included - just the `_inb` columns instead\n")
cat(" of the legacy ones, so it can reach 2021-2026. Full 2010-2026 range now that the raw IMS\n")
cat(" downloads cover every year. Compare to 01's Block A, 2010-2020/n=11, for the years effect.)\n")
cat("\n--- Common Tern (hir) ---\n")
sel_hir_A_inb <- model.sel(models_hir_A_inb[-1])  # drop null, matches 01's convention
print(sel_hir_A_inb)
cat("\n--- Little Tern (alb) ---\n")
sel_alb_A_inb <- model.sel(models_alb_A_inb[-1])
print(sel_alb_A_inb)

dataB_inb <- master %>% filter(year >= 2012, year <= 2026) %>%
  select(year, hir = chicks_hir, alb = chicks_alb, predation,
         hirTWOyears, albTWOyears, hirMASS, albMASS,
         temp37_inb, temp12_inb, meanMAXtemp_inb, meanMINtemp_inb)
stopifnot(nrow(dataB_inb) == 15, !anyNA(dataB_inb))

rhs_block_b_hir <- c(
  "predation", "albTWOyears", "hirMASS", "temp37",
  "predation + albTWOyears", "predation + hirMASS", "predation + temp37",
  "albTWOyears + hirMASS", "albTWOyears + temp37", "hirMASS + temp37",
  "predation + albTWOyears + hirMASS", "predation + albTWOyears + temp37",
  "predation + hirMASS + temp37", "albTWOyears + hirMASS + temp37",
  "predation + albTWOyears + hirMASS + temp37",
  "temp12", "predation + temp12", "albTWOyears + temp12", "hirMASS + temp12",
  "predation + albTWOyears + temp12", "predation + hirMASS + temp12",
  "albTWOyears + hirMASS + temp12", "predation + albTWOyears + hirMASS + temp12"
)
rhs_block_b_alb <- c(
  "predation", "hirTWOyears", "albMASS", "meanMINtemp",
  "predation + hirTWOyears", "predation + albMASS", "predation + meanMINtemp",
  "hirTWOyears + albMASS", "hirTWOyears + meanMINtemp", "albMASS + meanMINtemp",
  "predation + hirTWOyears + albMASS", "predation + hirTWOyears + meanMINtemp",
  "predation + albMASS + meanMINtemp", "hirTWOyears + albMASS + meanMINtemp",
  "predation + hirTWOyears + albMASS + meanMINtemp",
  "meanMAXtemp", "predation + meanMAXtemp", "hirTWOyears + meanMAXtemp", "albMASS + meanMAXtemp",
  "predation + hirTWOyears + meanMAXtemp", "predation + albMASS + meanMAXtemp",
  "hirTWOyears + albMASS + meanMAXtemp", "predation + hirTWOyears + albMASS + meanMAXtemp"
)
rhs_block_b_hir_inb <- ims_swap(rhs_block_b_hir)
rhs_block_b_alb_inb <- ims_swap(rhs_block_b_alb)

models_hir_B_inb <- fit_models("hir", rhs_block_b_hir_inb, dataB_inb)
models_alb_B_inb <- fit_models("alb", rhs_block_b_alb_inb, dataB_inb)

cat("\n================ TIER 2: Block B, full structure via _inb weather (2012-2026, n=15) ================\n")
cat("(Same 23-model structure as 01's Block B, weather included via `_inb`. Compare to 01's\n")
cat(" Block B, 2012-2020/n=9, for the years effect.)\n")
cat("\n--- Common Tern (hir) ---\n")
sel_hir_B_inb <- model.sel(models_hir_B_inb)
print(sel_hir_B_inb)
cat("\n--- Little Tern (alb) ---\n")
sel_alb_B_inb <- model.sel(models_alb_B_inb)
print(sel_alb_B_inb)

out_dir <- out_candidates[proc_idx]
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
sink(file.path(out_dir, "03_replication_through_2026_results.txt"))
cat("Block A, reduced predation/newcastle-only model set (same models both rows):\n")
cat("\nBlock A reduced, 2010-2020 (n=11) - hir\n"); print(model.sel(models_hir_A_orig_reduced))
cat("\nBlock A reduced, 2010-2026 (n=17) - hir\n"); print(sel_hir_A_ext)
cat("\nBlock A reduced, 2010-2020 (n=11) - alb\n"); print(model.sel(models_alb_A_orig_reduced))
cat("\nBlock A reduced, 2010-2026 (n=17) - alb\n"); print(sel_alb_A_ext)
cat("\n\nBlock B, reduced predation/competition/mass-only model set (same models both rows):\n")
cat("\nBlock B reduced, 2012-2020 (n=9) - hir\n"); print(model.sel(models_hir_B_orig_reduced))
cat("\nBlock B reduced, 2012-2026 (n=15) - hir\n"); print(sel_hir_B_ext)
cat("\nBlock B reduced, 2012-2020 (n=9) - alb\n"); print(model.sel(models_alb_B_orig_reduced))
cat("\nBlock B reduced, 2012-2026 (n=15) - alb\n"); print(sel_alb_B_ext)
cat("\n\nTIER 2: full original structure via _inb weather (full range now that 2010-2013 is filled):\n")
cat("\nBlock A full, 2010-2026 (_inb) - hir\n"); print(sel_hir_A_inb)
cat("\nBlock A full, 2010-2026 (_inb) - alb\n"); print(sel_alb_A_inb)
cat("\nBlock B full, 2012-2026 (_inb) - hir\n"); print(sel_hir_B_inb)
cat("\nBlock B full, 2012-2026 (_inb) - alb\n"); print(sel_alb_B_inb)
sink()
cat("\nFull results also written to", file.path(out_dir, "03_replication_through_2026_results.txt"), "\n")
