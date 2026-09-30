# Yosef's reply on issue #12: "from memory, I may have limited the analysis
# to the minimal number of ringings in the year" - i.e. his slide 13/14
# "number of fledglings" values may be effort-capped somehow, not a distinct
# fledging-success metric. Consistent with the finding there: his numbers are
# always <= the raw/legacy ringing counts, never higher.
#
# Per Inbal: check ringing EFFORT - how many nights was the team out ringing
# at all that season, regardless of whether a chick was caught - and
# normalize the chick counts by it. One shared number per year (not per
# species) since Little Tern and Common Tern are ringed on the same site
# visits.
#
# v1 of this script counted ANY tern record (any Rec status) as a day of
# effort and got absurd numbers (60-90+ days/season). Per Inbal, checking
# against an actual email of Yosef's 2025 ringing dates (7 nights:
# 24/06, 03/07, 13/07, 24/07, 04/08, 14/08, 21/08) showed why: the `Rec`
# column's dominant value `R` (40,568 of 66,412 rows - by far the largest
# category) is NOT a physical recapture/retrap - checking it shows records
# on 80 of ~92 possible summer days with up to 233/day, nothing like a
# ringing-session cadence. It's almost certainly passive resighting/
# colour-ring reads (telescope/camera), not hands-on ringing. Records with
# no Wing/Weight measurement at all support this - a bird that's only
# visually read was never in the hand.
#
# What actually isolates ringing-session dates: records with a BLANK `Rec`
# (genuinely new capture, in hand) - any age, not just chicks (adults get
# ringed/processed the same nights). For 2025 this gives 11 distinct dates
# in Jun-Aug - much closer to Yosef's 7, and critically, they cluster in
# adjacent-day PAIRS (e.g. 2025-07-03/07-04, 07-13/07-14...) at roughly
# 10-day intervals, matching Yosef's real cadence almost exactly once paired
# up. Per Inbal: ringing happens at night, so a single overnight session
# that straddles midnight gets split across two calendar dates in the data
# for birds processed before/after 00:00 - same session, not two.
#
# Fix: merge any run of consecutive calendar dates (gap == 1 day) into one
# "ringing night". For 2025 this gives 6 nights (Yosef's 7 minus one night
# with apparently zero NEW captures that year, so invisible to this method -
# see caveat in the issue writeup: a night where every bird processed was a
# resighting/control, not a new capture, leaves no trace here).

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
rec     <- raw[[3]]
species <- raw[[6]]
date    <- raw[[11]]

is_blank <- function(x) is.na(x) | trimws(as.character(x)) == ""

records <- data.frame(
  date    = as.Date(date),
  year    = as.integer(format(as.Date(date), "%Y")),
  month   = as.integer(format(as.Date(date), "%m")),
  species = species,
  rec     = rec,
  stringsAsFactors = FALSE
) %>%
  filter(species %in% c("STEALB", "STEHIR"), !is.na(year), is_blank(rec), month %in% 6:8)

# ---- merge consecutive-day dates into ringing "nights" ---------------------
merge_nights <- function(dates) {
  dates <- sort(unique(dates))
  if (length(dates) == 0) return(integer(0))
  breaks <- c(TRUE, diff(dates) > 1)   # start a new night whenever the gap > 1 day
  cumsum(breaks)
}

ringing_nights <- records %>%
  distinct(year, date) %>%
  group_by(year) %>%
  summarise(ringing_nights = length(unique(merge_nights(date))), .groups = "drop")

cat("Ringing nights per year (blank-Rec new captures, Jun-Aug, merging\n")
cat("same-session dates that cross midnight into one night):\n")
print(ringing_nights)

# ---- bring in the chick counts, compute chicks-per-ringing-night ----------
chicks <- read.csv(file.path(proc_dir, "chicks_ringed_from_raw_2010_2026.csv"))

effort <- ringing_nights %>%
  full_join(chicks, by = "year") %>%
  arrange(year) %>%
  mutate(
    alb_per_night = round(chicks_alb / ringing_nights, 2),
    hir_per_night = round(chicks_hir / ringing_nights, 2)
  )

cat("\nChicks per ringing night, 2010-2026:\n")
print(effort %>% select(year, ringing_nights, chicks_alb, alb_per_night,
                         chicks_hir, hir_per_night))

out_path <- file.path(proc_dir, "ringing_effort_by_year.csv")
write.csv(effort, out_path, row.names = FALSE, na = "NA")
cat("\nWrote", normalizePath(out_path), "\n")

cat("\n=== Is ringing effort (nights/season) roughly steady across years? ===\n")
cat(sprintf("Ringing nights/year: mean=%.1f, sd=%.1f, CV=%.1f%%, range=%d-%d\n",
            mean(effort$ringing_nights), sd(effort$ringing_nights),
            100 * sd(effort$ringing_nights) / mean(effort$ringing_nights),
            min(effort$ringing_nights), max(effort$ringing_nights)))

# ---- does the year-trend hold on the per-night rate, not just raw count? --
cat("\n=== Year trend: raw count vs. chicks-per-ringing-night ===\n")
for (sp in c("alb", "hir")) {
  raw_col <- paste0("chicks_", sp)
  rate_col <- paste0(sp, "_per_night")
  d <- effort[!is.na(effort[[rate_col]]) & is.finite(effort[[rate_col]]), ]
  ct_raw  <- cor.test(d$year, d[[raw_col]])
  ct_rate <- cor.test(d$year, d[[rate_col]])
  cts_rate <- cor.test(d$year, d[[rate_col]], method = "spearman", exact = FALSE)
  cat(sprintf("%s: raw count r=%.3f p=%.4f  |  per-night rate r=%.3f p=%.4f (Spearman rho=%.3f p=%.4f)\n",
              sp, ct_raw$estimate, ct_raw$p.value, ct_rate$estimate, ct_rate$p.value,
              cts_rate$estimate, cts_rate$p.value))
}

cat("\n=== Normality check on the per-night rates (residuals of rate ~ year) ===\n")
for (sp in c("alb", "hir")) {
  rate_col <- paste0(sp, "_per_night")
  d <- effort[is.finite(effort[[rate_col]]), ]
  m <- lm(d[[rate_col]] ~ d$year)
  sw <- shapiro.test(resid(m))
  cat(sprintf("%s_per_night residuals: W=%.3f, p=%.4f -> %s\n", sp, sw$statistic, sw$p.value,
              ifelse(sw$p.value < 0.05, "NOT normal, prefer Spearman", "~normal, Pearson OK")))
}

# ---- final plot: chicks-per-ringing-night, same slide-14 design -----------
library(ggplot2)
out_dir <- "output/figures"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

species_colors <- c("Little Tern (alb)" = "#F6C90A", "Common Tern (hir)" = "#FF0000")
plot_data <- bind_rows(
  data.frame(year = effort$year, count = effort$hir_per_night, species = "Common Tern (hir)"),
  data.frame(year = effort$year, count = effort$alb_per_night, species = "Little Tern (alb)")
) %>%
  filter(is.finite(count)) %>%
  mutate(species = factor(species, levels = c("Common Tern (hir)", "Little Tern (alb)")))

p <- ggplot(plot_data, aes(x = year, y = count)) +
  geom_smooth(method = "lm", se = FALSE, color = "black", linetype = "dotted", linewidth = 0.9) +
  geom_point(aes(fill = species), shape = 21, size = 3, color = "grey20", stroke = 0.3) +
  facet_wrap(~species, scales = "free_y") +
  scale_fill_manual(values = species_colors, guide = "none") +
  labs(title = "Chicks ringed per ringing night, 2010-2026",
       subtitle = "Normalized for field effort: chicks_alb/hir ÷ ringing nights that season (both species pooled; consecutive dates crossing midnight merged into one night)",
       x = "Year", y = "Chicks ringed per ringing night") +
  theme_minimal(base_size = 12) +
  theme(strip.text = element_text(face = "bold"),
        plot.title = element_text(face = "bold", size = 13),
        plot.subtitle = element_text(color = "grey35", size = 8.5),
        panel.grid.minor = element_blank(),
        panel.spacing = unit(1.4, "lines"))

ggsave(file.path(out_dir, "fig5_chicks_per_ringing_night_2010_2026.png"), p,
       width = 9, height = 4.5, dpi = 200, bg = "white")
cat("Wrote", file.path(out_dir, "fig5_chicks_per_ringing_night_2010_2026.png"), "\n")
