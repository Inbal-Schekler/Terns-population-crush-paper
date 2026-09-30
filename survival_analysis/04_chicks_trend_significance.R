# Is the year-on-year pattern in chicks_ringed_from_raw_2010_2026.csv (the
# raw-ringing-file ground truth from 02_number_of_chicks.R) actually
# significant, or could the apparent Little Tern decline / Common Tern rise
# be noise? Pearson + Spearman correlation and a simple linear trend, year vs.
# chicks ringed, per species, checked against:
#   - the full raw-derived series, 2010-2026
#   - the same, dropping 2026 (most recent year, in case it's provisional)
#   - Yosef's own original numbers, 2010-2020 only (data_2010-2020_legacy.csv)
#     - was the trend already visible in the data as Yosef originally had it,
#     before we extended/recomputed anything?
#   - Little Tern only, dropping 2010 - per Inbal, 2010 was Yosef's first
#     season and he may not have caught many juveniles yet; check whether
#     that one point is propping up the (already borderline) decline.

data_dir <- "../data_processed"
raw_dir  <- "../data_raw"
if (!dir.exists(data_dir)) { data_dir <- "data_processed"; raw_dir <- "data_raw" }

raw_derived <- read.csv(file.path(data_dir, "chicks_ringed_from_raw_2010_2026.csv"))
raw_derived <- raw_derived[order(raw_derived$year), ]

legacy <- read.csv(file.path(raw_dir, "data_2010-2020_legacy.csv"), stringsAsFactors = FALSE)
legacy <- data.frame(year = legacy$year, chicks_alb = legacy$alb, chicks_hir = legacy$hir)
legacy <- legacy[order(legacy$year), ]

# ---- normality check: does Pearson's assumption actually hold here? -------
check_normality <- function(d, label) {
  cat("--- Normality check:", label, "(n =", nrow(d), ") ---\n")
  for (sp in c("chicks_alb", "chicks_hir")) {
    sw_raw <- shapiro.test(d[[sp]])
    m <- lm(d[[sp]] ~ d$year)
    sw_res <- shapiro.test(resid(m))
    cat(sprintf("%s: raw W=%.3f p=%.4f | residuals W=%.3f p=%.4f -> %s\n",
                sp, sw_raw$statistic, sw_raw$p.value, sw_res$statistic, sw_res$p.value,
                ifelse(sw_res$p.value < 0.05,
                       "residuals NOT normal - prefer Spearman",
                       "residuals ~normal - Pearson OK")))
  }
  cat("\n")
}

# ---- correlation + trend ----------------------------------------------------
run_trend <- function(d, label) {
  cat("---", label, "(n =", nrow(d), ") ---\n")
  for (sp in c("chicks_alb", "chicks_hir")) {
    ct  <- cor.test(d$year, d[[sp]], method = "pearson")
    cts <- cor.test(d$year, d[[sp]], method = "spearman", exact = FALSE)
    m   <- lm(d[[sp]] ~ d$year)
    s   <- summary(m)
    cat(sprintf("%s: Pearson r=%.3f (r2=%.3f, p=%.4f) | Spearman rho=%.3f (p=%.4f) | slope=%.2f/yr (p=%.4f)\n",
                sp, ct$estimate, ct$estimate^2, ct$p.value,
                cts$estimate, cts$p.value,
                coef(m)[2], s$coefficients[2, 4]))
  }
  cat("\n")
}

check_normality(raw_derived, "2010-2026, full raw-derived series")
run_trend(raw_derived, "2010-2026, full raw-derived series")

run_trend(subset(raw_derived, year <= 2025), "2010-2025, excluding 2026 (sensitivity check)")

# ---- Yosef's original numbers, 2010-2020 only ------------------------------
# Same trend test, but on data_2010-2020_legacy.csv as Yosef originally had
# it - was the pattern already there in his own numbers/window, pre-dating
# our extension and re-derivation from the raw ringing file?
check_normality(legacy, "Yosef's original data, 2010-2020")
run_trend(legacy, "Yosef's original data, 2010-2020")

# ---- Little Tern, dropping 2010 --------------------------------------------
# 2010 was Yosef's first ringing season - per Inbal, he hadn't yet caught
# many juveniles that year. Does the (already borderline, p=0.061) alb decline
# depend on that one early point?
alb_no2010 <- subset(raw_derived, year > 2010, select = c(year, chicks_alb))
cat("--- Little Tern (alb) only, dropping 2010 (n =", nrow(alb_no2010), ") ---\n")
ct  <- cor.test(alb_no2010$year, alb_no2010$chicks_alb, method = "pearson")
cts <- cor.test(alb_no2010$year, alb_no2010$chicks_alb, method = "spearman", exact = FALSE)
m   <- lm(chicks_alb ~ year, data = alb_no2010)
s   <- summary(m)
cat(sprintf("chicks_alb: Pearson r=%.3f (r2=%.3f, p=%.4f) | Spearman rho=%.3f (p=%.4f) | slope=%.2f/yr (p=%.4f)\n",
            ct$estimate, ct$estimate^2, ct$p.value, cts$estimate, cts$p.value,
            coef(m)[2], s$coefficients[2, 4]))
cat("(for reference, WITH 2010: r=-0.464, p=0.0609 - see full series above)\n")
