# ==============================================================================
# 01_replicate_2020_baseline.R
#
# Purpose: reproduce Yosef's 2020 GLM / AICc model-selection analysis
# (originally data_raw/GLM_2020_original.R), but on the corrected dataset
# built by 00_build_dataset.R instead of the buggy data1.csv.
#
# This is a BASELINE CHECK, not the new analysis: same years (2010-2020 /
# 2012-2020), same predictors, same model structure as the original 2020
# work. The only change is that data1.csv's corrupted predation/temperature
# columns (see NOTES.md) have been replaced with the correct values. Compare
# the AICc weights below to the 2020 slides (סיכום 2020.pptx, slides 10 & 12)
# to see whether/how the conclusion changes once the bug is fixed.
# ==============================================================================

library(dplyr)
library(MuMIn)

options(na.action = "na.fail")  # required by MuMIn::dredge/model.sel on model sets

# data_processed/ is shared with mass_analysis/ (also holds master_dataset,
# which 02_mass_analysis.Rmd updates in place) - stays at the analysis root,
# not nested under survival_analysis/. out_dir below tracks the same
# candidate index so it resolves to a *local* output/ folder regardless of
# which of these three succeeds.
proc_candidates <- c("../../data_processed", "../data_processed", "data_processed")
out_candidates  <- c("output", "yosef_analysis/output", "survival_analysis/yosef_analysis/output")
proc_idx <- which(dir.exists(proc_candidates))[1]
proc_dir <- proc_candidates[proc_idx]
master <- read.csv(file.path(proc_dir, "master_dataset_2010_2026.csv"))

# ------------------------------------------------------------------------
# Block A: 2010-2020 (11 years), weather + predation + newcastle only
# Mirrors GLM_2020_original.R lines 1-256 (models m0-m27 for hir, then alb)
# ------------------------------------------------------------------------
dataA <- master %>% filter(year >= 2010, year <= 2020) %>%
  select(year, hir = chicks_hir, alb = chicks_alb, temp37, temp12,
         meanMAXtemp, meanMINtemp, rainMAY, rainJUN, predation, newcastle)
stopifnot(nrow(dataA) == 11, !anyNA(dataA))

fit_block_a <- function(response) {
  f <- function(rhs) as.formula(paste(response, "~", rhs))
  preds <- c("predation", "newcastle", "temp37", "temp12", "meanMAXtemp",
             "meanMINtemp", "rainMAY", "rainJUN")
  # same 28-model structure as the original: null + all combos actually used
  rhs_list <- list(
    "1", "predation", "newcastle", "predation + newcastle",
    "temp37", "predation + temp37", "newcastle + temp37", "predation + newcastle + temp37",
    "temp12", "predation + temp12", "newcastle + temp12", "predation + newcastle + temp12",
    "meanMAXtemp", "predation + meanMAXtemp", "newcastle + meanMAXtemp", "predation + newcastle + meanMAXtemp",
    "meanMINtemp", "predation + meanMINtemp", "newcastle + meanMINtemp", "predation + newcastle + meanMINtemp",
    "rainMAY", "predation + rainMAY", "newcastle + rainMAY", "predation + newcastle + rainMAY",
    "rainJUN", "predation + rainJUN", "newcastle + rainJUN", "predation + newcastle + rainJUN"
  )
  models <- lapply(rhs_list, function(rhs) glm(f(rhs), family = gaussian, data = dataA))
  names(models) <- paste0("m", seq_along(models) - 1)
  models
}

models_hir_A <- fit_block_a("hir")
models_alb_A <- fit_block_a("alb")

cat("\n================ Block A (2010-2020, weather/predation/newcastle) ================\n")
cat("\n--- Common Tern (hir) model selection ---\n")
print(model.sel(models_hir_A[-1]))  # drop null model m0 to match original model.sel() call
cat("\n--- Little Tern (alb) model selection ---\n")
print(model.sel(models_alb_A[-1]))

# ------------------------------------------------------------------------
# Block B: 2012-2020 (9 years), + interspecific competition + body mass
# Mirrors GLM_2020_original.R lines 265-481
# ------------------------------------------------------------------------
dataB <- master %>% filter(year >= 2012, year <= 2020) %>%
  select(year, hir = chicks_hir, alb = chicks_alb, temp37, temp12,
         meanMAXtemp, meanMINtemp, predation, hirTWOyears, albTWOyears,
         hirMASS, albMASS)
stopifnot(nrow(dataB) == 9)

cat("\nBlock B rows with any NA (should be none if 00_build_dataset.R ran cleanly):\n")
print(dataB[!complete.cases(dataB), ])
stopifnot(!anyNA(dataB))

# hir ~ predation, albTWOyears, hirMASS, temp37  (+ temp12 variants)
fit_block_b_hir <- function() {
  f <- function(rhs) as.formula(paste("hir ~", rhs))
  rhs_list <- list(
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
  models <- lapply(rhs_list, function(rhs) glm(f(rhs), family = gaussian, data = dataB))
  names(models) <- paste0("m", seq_along(models))
  models
}

# alb ~ predation, hirTWOyears, albMASS, meanMINtemp (+ meanMAXtemp variants)
fit_block_b_alb <- function() {
  f <- function(rhs) as.formula(paste("alb ~", rhs))
  rhs_list <- list(
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
  models <- lapply(rhs_list, function(rhs) glm(f(rhs), family = gaussian, data = dataB))
  names(models) <- paste0("m", seq_along(models))
  models
}

models_hir_B <- fit_block_b_hir()
models_alb_B <- fit_block_b_alb()

cat("\n================ Block B (2012-2020, + competition + body mass) ================\n")
cat("\n--- Common Tern (hir) model selection ---\n")
sel_hir_B <- model.sel(models_hir_B)
print(sel_hir_B)
cat("\n--- Little Tern (alb) model selection ---\n")
sel_alb_B <- model.sel(models_alb_B)
print(sel_alb_B)

cat("\n\nCompare the top rows (delta < 2) above to סיכום 2020.pptx slides 10 & 12:\n")
cat("2020 slide claimed for alb (Little Tern): interspecific competition alone, weight 0.46;\n")
cat("competition + cold temp, weight 0.28. Check whether that holds with the corrected data.\n")

out_dir <- out_candidates[proc_idx]
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
sink(file.path(out_dir, "01_replication_results.txt"))
cat("Block A - hir\n"); print(model.sel(models_hir_A[-1]))
cat("\nBlock A - alb\n"); print(model.sel(models_alb_A[-1]))
cat("\nBlock B - hir\n"); print(sel_hir_B)
cat("\nBlock B - alb\n"); print(sel_alb_B)
sink()
cat("\nFull results also written to", file.path(out_dir, "01_replication_results.txt"), "\n")
