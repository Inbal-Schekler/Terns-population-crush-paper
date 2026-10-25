# ==============================================================================
# 06_sst_correlation.R
#
# Purpose: direct Pearson correlation between Little Tern chicks and each
# SST variable (meanSST_inb/meanMAXsst_inb/meanMINsst_inb), full 2010-2026
# range (n=17, same window as Block A). Complements the AICc model
# selection in 03/05 with a simple, single hypothesis test of the specific
# relationship those searches flagged - requested by Inbal as a sanity
# check ahead of the Yosef meeting.
#
# Shapiro-Wilk run first on both variables in each pair to confirm Pearson
# is appropriate (not assumed).
# ==============================================================================

proc_candidates <- c("../../data_processed", "../data_processed", "data_processed")
out_candidates  <- c("output", "yosef_analysis/output", "survival_analysis/yosef_analysis/output")
proc_idx <- which(dir.exists(proc_candidates))[1]
proc_dir <- proc_candidates[proc_idx]
out_dir  <- out_candidates[proc_idx]

master <- read.csv(file.path(proc_dir, "master_dataset_2010_2026.csv"))
m <- master[master$year >= 2010 & master$year <= 2026, ]
d <- data.frame(year = m$year, alb = as.numeric(m$chicks_alb),
                 meanSST_inb = as.numeric(m$meanSST_inb),
                 meanMAXsst_inb = as.numeric(m$meanMAXsst_inb),
                 meanMINsst_inb = as.numeric(m$meanMINsst_inb))
stopifnot(nrow(d) == 17, !anyNA(d))

sst_vars <- c("meanSST_inb", "meanMAXsst_inb", "meanMINsst_inb")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_file <- file.path(out_dir, "06_sst_correlation_results.txt")
sink(out_file)
cat("Little Tern chicks vs SST - Pearson correlation, full 2010-2026 (n=17)\n")
cat("Shapiro-Wilk run first on both variables to confirm normality before trusting Pearson.\n\n")

sw_alb <- shapiro.test(d$alb)
cat(sprintf("Shapiro-Wilk, Little Tern chicks: W = %.3f, p = %.3f\n\n", sw_alb$statistic, sw_alb$p.value))

for (v in sst_vars) {
  sw_v <- shapiro.test(d[[v]])
  pear <- cor.test(d$alb, d[[v]], method = "pearson")
  cat("=====", v, "=====\n")
  cat(sprintf("Shapiro-Wilk, %s: W = %.3f, p = %.3f\n", v, sw_v$statistic, sw_v$p.value))
  cat(sprintf("Pearson: r = %.3f, 95%% CI [%.3f, %.3f], t = %.3f, df = %d, p = %.4f\n\n",
              pear$estimate, pear$conf.int[1], pear$conf.int[2], pear$statistic, pear$parameter, pear$p.value))
}
sink()
cat("Written to", out_file, "\n")
