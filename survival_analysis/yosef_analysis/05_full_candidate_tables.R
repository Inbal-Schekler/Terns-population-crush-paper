# ==============================================================================
# 05_full_candidate_tables.R
#
# Purpose: full candidate-model tables (predictors + delta AICc + Akaike
# weight) for all four of 03's TIER 2 blocks, generated directly from the
# fitted model objects (formula()/coef()) rather than read off 03's
# fixed-width printed/sink() output. Written after catching a real error
# 2026-10-25: a manual read of the printed table misidentified the Block B
# Little Tern winning model (attributed the win to an 11th-ranked model) -
# see 04_winning_model_effects.R's header comment and GitHub issue #2 for
# the correction. This script exists so that question never has to be
# answered by eyeballing text again.
#
# Mirrors 03_replicate_through_2026.R's data filters and rhs lists exactly -
# numbers here must match 03's output 1:1. Does not modify 00/01/02/03/04's
# outputs; only reads the master dataset.
# ==============================================================================

library(dplyr)
library(MuMIn)

options(na.action = "na.fail")

proc_candidates <- c("../../data_processed", "../data_processed", "data_processed")
out_candidates  <- c("output", "yosef_analysis/output", "survival_analysis/yosef_analysis/output")
proc_idx <- which(dir.exists(proc_candidates))[1]
proc_dir <- proc_candidates[proc_idx]
out_dir  <- out_candidates[proc_idx]
master <- read.csv(file.path(proc_dir, "master_dataset_2010_2026.csv"))

fit_models <- function(response, rhs_list, data) {
  f <- function(rhs) as.formula(paste(response, "~", rhs))
  models <- lapply(rhs_list, function(rhs) glm(f(rhs), family = gaussian, data = data))
  names(models) <- paste0("m", seq_along(models))
  models
}

ims_swap <- function(rhs_list) {
  pairs <- list(c("temp37", "temp37_inb"), c("temp12", "temp12_inb"),
                c("meanMAXtemp", "meanMAXtemp_inb"), c("meanMINtemp", "meanMINtemp_inb"),
                c("rainMAY", "rainMAY_inb"), c("rainJUN", "rainJUN_inb"))
  for (p in pairs) rhs_list <- gsub(p[1], p[2], rhs_list, fixed = TRUE)
  rhs_list
}

# Crosses `var` with every subset (incl. empty, i.e. `var` alone) of
# `base_vars` - same helper as 03_replicate_through_2026.R.
cross_with_base <- function(var, base_vars) {
  subsets <- unlist(lapply(seq_along(base_vars), function(k) {
    combn(base_vars, k, FUN = function(x) paste(x, collapse = " + "), simplify = TRUE)
  }))
  c(var, paste(subsets, "+", var))
}

# ------------------------------------------------------------------------
# Block A: predation/newcastle + weather (one-at-a-time), 2010-2026, n=17
# ------------------------------------------------------------------------
dataA_inb <- master %>% filter(year >= 2010, year <= 2026) %>%
  select(year, hir = chicks_hir, alb = chicks_alb, predation, newcastle,
         temp37_inb, temp12_inb, meanMAXtemp_inb, meanMINtemp_inb, rainMAY_inb, rainJUN_inb,
         meanSST_inb, meanMAXsst_inb, meanMINsst_inb)
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
rhs_block_a_sst <- unlist(lapply(c("meanSST_inb", "meanMAXsst_inb", "meanMINsst_inb"), function(v) c(
  v, paste("predation +", v), paste("newcastle +", v), paste("predation + newcastle +", v)
)))
rhs_block_a_inb <- c(ims_swap(rhs_block_a), rhs_block_a_sst)

models_hir_A_inb <- fit_models("hir", rhs_block_a_inb, dataA_inb)
models_alb_A_inb <- fit_models("alb", rhs_block_a_inb, dataA_inb)
sel_hir_A_inb <- model.sel(models_hir_A_inb[-1])  # drop null
sel_alb_A_inb <- model.sel(models_alb_A_inb[-1])

# ------------------------------------------------------------------------
# Block B: predation + competition + mass + weather (full crossing per
# species), 2012-2026, n=15
# ------------------------------------------------------------------------
dataB_inb <- master %>% filter(year >= 2012, year <= 2026) %>%
  select(year, hir = chicks_hir, alb = chicks_alb, predation,
         hirTWOyears, albTWOyears, hirMASS, albMASS,
         temp37_inb, temp12_inb, meanMAXtemp_inb, meanMINtemp_inb,
         meanSST_inb, meanMAXsst_inb, meanMINsst_inb)
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
rhs_block_b_hir_sst <- unlist(lapply(c("meanSST_inb", "meanMAXsst_inb", "meanMINsst_inb"),
                                      cross_with_base, base_vars = c("predation", "albTWOyears", "hirMASS")))
rhs_block_b_alb_sst <- unlist(lapply(c("meanSST_inb", "meanMAXsst_inb", "meanMINsst_inb"),
                                      cross_with_base, base_vars = c("predation", "hirTWOyears", "albMASS")))
rhs_block_b_hir_inb <- c(ims_swap(rhs_block_b_hir), rhs_block_b_hir_sst)
rhs_block_b_alb_inb <- c(ims_swap(rhs_block_b_alb), rhs_block_b_alb_sst)

models_hir_B_inb <- fit_models("hir", rhs_block_b_hir_inb, dataB_inb)
models_alb_B_inb <- fit_models("alb", rhs_block_b_alb_inb, dataB_inb)
sel_hir_B_inb <- model.sel(models_hir_B_inb)
sel_alb_B_inb <- model.sel(models_alb_B_inb)

# ------------------------------------------------------------------------
# Clean tables: model index -> predictors (straight from the rhs string
# that was actually fit, not a re-read of the printed +/coefficient grid),
# AICc, delta, weight. Verified once against formula()/coef() on the
# top-ranked object per table before trusting this approach (see commit
# 67566c1). Sorted by AICc ascending (model.sel()'s default row order) -
# lowest AICc = row 1 = the winning model; delta is every other row's
# AICc minus that winning model's AICc.
# ------------------------------------------------------------------------
make_clean_table <- function(sel_obj, rhs_list) {
  idx <- as.integer(sub("^m", "", rownames(sel_obj)))
  data.frame(
    predictors = rhs_list[idx],
    AICc = round(sel_obj$AICc, 2),
    delta = round(sel_obj$delta, 2),
    weight = round(sel_obj$weight, 3)
  )
}

tables <- list(
  "Block A, Common Tern (hir), full candidate table (n=39)" = make_clean_table(sel_hir_A_inb, rhs_block_a_inb),
  "Block A, Little Tern (alb), full candidate table (n=39)" = make_clean_table(sel_alb_A_inb, rhs_block_a_inb),
  "Block B, Common Tern (hir), full candidate table (n=47)" = make_clean_table(sel_hir_B_inb, rhs_block_b_hir_inb),
  "Block B, Little Tern (alb), full candidate table (n=47)" = make_clean_table(sel_alb_B_inb, rhs_block_b_alb_inb)
)

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_file <- file.path(out_dir, "05_full_candidate_tables.txt")
sink(out_file)
for (nm in names(tables)) {
  cat("\n================", nm, "================\n")
  print(tables[[nm]], row.names = FALSE)
}
sink()
cat("Full candidate tables written to", out_file, "\n")
