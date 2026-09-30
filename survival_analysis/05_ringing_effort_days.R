# Yosef's reply on issue #12: "from memory, I may have limited the analysis
# to the minimal number of ringings in the year" - i.e. his slide 13/14
# "number of fledglings" values may be effort-capped somehow, not a distinct
# fledging-success metric. Consistent with the finding there: his numbers are
# always <= the raw/legacy ringing counts, never higher.
#
# Per Inbal: check ringing EFFORT - how many summer days was the team out
# ringing at all, regardless of whether a chick was caught that day - and
# normalize the chick counts by it.
#
# Effort measure, from ringing_data_raw.xlsx ("Data" sheet):
#   summer ringing days = distinct dates, June-August, with >=1 tern ringing
#   record of EITHER species - ANY age/status (adults + chicks, new captures
#   + retraps). Per Inbal: Little Tern and Common Tern are ringed at the same
#   site on the same site visits, so effort is a single shared number, not
#   two separate species-specific day counts - when he's out ringing, both
#   species get the same effort that day.
#   Deliberately NOT "days a chick was ringed" - that measure is circular,
#   since by construction such a day always has >=1 chick in it, so it can
#   only ever track the chick count, not measure independent field effort.
#   June-August window chosen because 99.8% of all age==3 (chick) records
#   fall in those 3 months (260 June + 1941 July + 1178 August + 3 September,
#   checked across the full file) - i.e. it's the real breeding-season
#   ringing window, not an arbitrary date cut.

library(readxl)
library(dplyr)

raw_dir <- "../data_raw"
if (!dir.exists(raw_dir)) raw_dir <- "data_raw"
stopifnot(dir.exists(raw_dir))
proc_dir <- sub("data_raw$", "data_processed", raw_dir)

ring_path <- file.path(raw_dir, "ringing_data_raw.xlsx")
raw <- read_excel(ring_path, sheet = "Data", col_names = FALSE, skip = 2)

# Same column positions as 02_number_of_chicks.R (readxl drops the fully
# blank leading column openpyxl keeps, so these are one less than the file's
# visual column order).
species <- raw[[6]]
date    <- raw[[11]]

records <- data.frame(
  date    = as.Date(date),
  year    = as.integer(format(as.Date(date), "%Y")),
  month   = as.integer(format(as.Date(date), "%m")),
  species = species,
  stringsAsFactors = FALSE
) %>%
  filter(species %in% c("STEALB", "STEHIR"), !is.na(year))

# ---- total summer (Jun-Aug) ringing days per year, BOTH species pooled ----
# One shared effort number: a day counts if either species was ringed that
# day (same site visit covers both).
ringing_days <- records %>%
  filter(month %in% 6:8) %>%
  distinct(year, date) %>%
  count(year, name = "ringing_days")

cat("Total summer (Jun-Aug) ringing days per year, both species pooled:\n")
print(ringing_days)

# ---- bring in the chick counts, compute chicks-per-ringing-day ------------
chicks <- read.csv(file.path(proc_dir, "chicks_ringed_from_raw_2010_2026.csv"))

effort <- ringing_days %>%
  full_join(chicks, by = "year") %>%
  arrange(year) %>%
  mutate(
    alb_per_day = round(chicks_alb / ringing_days, 2),
    hir_per_day = round(chicks_hir / ringing_days, 2)
  )

cat("\nChicks per (shared) ringing day, 2010-2026:\n")
print(effort %>% select(year, ringing_days, chicks_alb, alb_per_day,
                         chicks_hir, hir_per_day))

out_path <- file.path(proc_dir, "ringing_effort_by_year.csv")
write.csv(effort, out_path, row.names = FALSE, na = "NA")
cat("\nWrote", normalizePath(out_path), "\n")

cat("\n=== Is total summer ringing effort roughly steady across years? ===\n")
cat(sprintf("Ringing days/year: mean=%.1f, sd=%.1f, CV=%.1f%%, range=%d-%d\n",
            mean(effort$ringing_days), sd(effort$ringing_days),
            100 * sd(effort$ringing_days) / mean(effort$ringing_days),
            min(effort$ringing_days), max(effort$ringing_days)))

# ---- does the year-trend hold on the per-day rate, not just raw count? ----
cat("\n=== Year trend: raw count vs. chicks-per-ringing-day ===\n")
for (sp in c("alb", "hir")) {
  raw_col <- paste0("chicks_", sp)
  rate_col <- paste0(sp, "_per_day")
  d <- effort[!is.na(effort[[rate_col]]) & is.finite(effort[[rate_col]]), ]
  ct_raw  <- cor.test(d$year, d[[raw_col]])
  ct_rate <- cor.test(d$year, d[[rate_col]])
  cts_rate <- cor.test(d$year, d[[rate_col]], method = "spearman", exact = FALSE)
  cat(sprintf("%s: raw count r=%.3f p=%.4f  |  per-day rate r=%.3f p=%.4f (Spearman rho=%.3f p=%.4f)\n",
              sp, ct_raw$estimate, ct_raw$p.value, ct_rate$estimate, ct_rate$p.value,
              cts_rate$estimate, cts_rate$p.value))
}

cat("\n=== Normality check on the per-day rates (residuals of rate ~ year) ===\n")
for (sp in c("alb", "hir")) {
  rate_col <- paste0(sp, "_per_day")
  d <- effort[is.finite(effort[[rate_col]]), ]
  m <- lm(d[[rate_col]] ~ d$year)
  sw <- shapiro.test(resid(m))
  cat(sprintf("%s_per_day residuals: W=%.3f, p=%.4f -> %s\n", sp, sw$statistic, sw$p.value,
              ifelse(sw$p.value < 0.05, "NOT normal, prefer Spearman", "~normal, Pearson OK")))
}

# ---- final plot: chicks-per-ringing-day, same slide-14 design -------------
library(ggplot2)
out_dir <- "output/figures"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

species_colors <- c("Little Tern (alb)" = "#F6C90A", "Common Tern (hir)" = "#FF0000")
plot_data <- bind_rows(
  data.frame(year = effort$year, count = effort$hir_per_day, species = "Common Tern (hir)"),
  data.frame(year = effort$year, count = effort$alb_per_day, species = "Little Tern (alb)")
) %>%
  filter(is.finite(count)) %>%
  mutate(species = factor(species, levels = c("Common Tern (hir)", "Little Tern (alb)")))

p <- ggplot(plot_data, aes(x = year, y = count)) +
  geom_smooth(method = "lm", se = FALSE, color = "black", linetype = "dotted", linewidth = 0.9) +
  geom_point(aes(fill = species), shape = 21, size = 3, color = "grey20", stroke = 0.3) +
  facet_wrap(~species, scales = "free_y") +
  scale_fill_manual(values = species_colors, guide = "none") +
  labs(title = "Chicks ringed per (shared) summer ringing day, 2010-2026",
       subtitle = "Normalized for field effort: chicks_alb/hir ÷ total distinct Jun-Aug ringing days that season (both species pooled - same site visits)",
       x = "Year", y = "Chicks ringed per ringing day") +
  theme_minimal(base_size = 12) +
  theme(strip.text = element_text(face = "bold"),
        plot.title = element_text(face = "bold", size = 13),
        plot.subtitle = element_text(color = "grey35", size = 9.5),
        panel.grid.minor = element_blank(),
        panel.spacing = unit(1.4, "lines"))

ggsave(file.path(out_dir, "fig5_chicks_per_ringing_day_2010_2026.png"), p,
       width = 9, height = 4.5, dpi = 200, bg = "white")
cat("Wrote", file.path(out_dir, "fig5_chicks_per_ringing_day_2010_2026.png"), "\n")
