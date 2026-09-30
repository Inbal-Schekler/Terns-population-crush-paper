# Three-way comparison + plots for the GitHub issue "Number of chicks
# reported by Yosef" (follow-up to issue #11, which flagged the same
# unexplained gap for slide 13's scatter-by-competition version).
#
# Slide 14 of סיכום 2020.pptx ("תחרות בין-מינית 2012-2020") plots, per
# species, YEAR (x) vs. "הצלחת רבייה (מספר פרחונים)" / "breeding success
# (number of fledglings)" (y), 2012-2020, with a linear trendline - chart8
# (שחפית גמדית / Little Tern, yellow #F6C90A markers) and chart9 (שחפית ים /
# Common Tern, red #FF0000 markers). Design read directly from the pptx's
# embedded chart XML (ppt/charts/chart8.xml, chart9.xml): circle markers,
# black dotted linear trendline, no R²/equation displayed, per-species panel
# titled with the Hebrew species name.
#
# Three sources of "chicks ringed per year" now exist for 2012-2020, and they
# disagree:
#   1. legacy   - data_2010-2020_legacy.csv (hir/alb columns). NOTES.md calls
#                 this "verified correct"; it's what Yosef's original 2020
#                 GLM analysis was built on.
#   2. slide14  - the numbers Yosef actually plotted on slide 14 (extracted
#                 from chart8.xml/chart9.xml's cached values - same numbers
#                 already quoted in issue #11 for slide 13's y-axis, which
#                 plots the identical "מספר פרחונים" metric).
#   3. raw      - computed fresh from data_raw/ringing_data_raw.xlsx by
#                 02_number_of_chicks.R (Age==3, blank retrap column = new
#                 capture only). Extends to 2026 - real ringing records, not
#                 a placeholder - unlike legacy (stops 2020) or slide14
#                 (Yosef never had 2021+ to plot).
#
# This script does NOT resolve which is "right" - that's for Yosef. It lays
# the three side by side.

library(ggplot2)
library(dplyr)

data_dir <- "../data_processed"
if (!dir.exists(data_dir)) data_dir <- "data_processed"
out_dir <- "output/figures"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- 1. the three sources, 2012-2020 -----------------------------------
raw_derived <- read.csv(file.path(data_dir, "chicks_ringed_from_raw_2010_2026.csv"))

legacy <- read.csv(file.path(data_dir, "..", "data_raw", "data_2010-2020_legacy.csv"),
                    stringsAsFactors = FALSE) %>%
  transmute(year, chicks_hir_legacy = hir, chicks_alb_legacy = alb)

# Slide 14's plotted "number of fledglings", 2012-2020 - read straight off
# chart8.xml (alb, "שחפית גמדית") / chart9.xml (hir, "שחפית ים") cached
# c:yVal points, in year order 2012-2020. Same numbers as issue #11's slide
# 13 table (that slide plots the same y-metric against a different x).
slide14 <- data.frame(
  year             = 2012:2020,
  chicks_alb_slide = c(89, 65, 90, 87, 41,  9, 56,  49,   8),
  chicks_hir_slide = c(77, 74, 15, 91, 14, 39, 148, 258, 152)
)

# ---- 2. three-way comparison table, 2012-2020 ---------------------------
comparison <- raw_derived %>%
  filter(year >= 2012, year <= 2020) %>%
  rename(chicks_hir_raw = chicks_hir, chicks_alb_raw = chicks_alb) %>%
  left_join(legacy, by = "year") %>%
  left_join(slide14, by = "year") %>%
  mutate(
    hir_raw_vs_legacy   = chicks_hir_raw - chicks_hir_legacy,
    hir_slide_vs_legacy = chicks_hir_slide - chicks_hir_legacy,
    hir_raw_vs_slide     = chicks_hir_raw - chicks_hir_slide,
    alb_raw_vs_legacy   = chicks_alb_raw - chicks_alb_legacy,
    alb_slide_vs_legacy = chicks_alb_slide - chicks_alb_legacy,
    alb_raw_vs_slide     = chicks_alb_raw - chicks_alb_slide
  ) %>%
  select(year,
         chicks_hir_raw, chicks_hir_legacy, chicks_hir_slide,
         hir_raw_vs_legacy, hir_slide_vs_legacy, hir_raw_vs_slide,
         chicks_alb_raw, chicks_alb_legacy, chicks_alb_slide,
         alb_raw_vs_legacy, alb_slide_vs_legacy, alb_raw_vs_slide)

cat("Three-way comparison, 2012-2020 (raw = this script's ringing-file count,\n")
cat("legacy = data_2010-2020_legacy.csv, slide = Yosef's slide 14 plotted values):\n")
print(comparison)

comp_path <- file.path(data_dir, "chicks_three_way_comparison_2012_2020.csv")
write.csv(comparison, comp_path, row.names = FALSE, na = "NA")
cat("\nWrote", normalizePath(comp_path), "\n")

# ---- 3. shared plot design, matching Yosef's slide 14 ---------------------
species_colors <- c("Little Tern (alb)" = "#F6C90A", "Common Tern (hir)" = "#FF0000")

# Same y-axis ceiling per species across all three figures (0-100 for Little
# Tern, 0-300 for Common Tern), so the panels line up when comparing figures
# side by side. Implemented as invisible anchor points (not scale_*(limits=)
# + free_y) so a real value that exceeds the ceiling (e.g. hir=315 in 2022)
# still shows in full instead of being silently clipped off the panel.
y_anchors <- data.frame(
  species = factor(c("Common Tern (hir)", "Common Tern (hir)",
                      "Little Tern (alb)", "Little Tern (alb)"),
                    levels = c("Common Tern (hir)", "Little Tern (alb)")),
  year = 2015,
  count = c(0, 300, 0, 100)
)

make_slide14_style_plot <- function(df, title, subtitle, y_label, out_file,
                                     width = 8.5, height = 4.5) {
  p <- ggplot(df, aes(x = year, y = count)) +
    geom_blank(data = y_anchors, aes(x = year, y = count), inherit.aes = FALSE) +
    geom_smooth(method = "lm", se = FALSE, color = "black", linetype = "dotted",
                linewidth = 0.9) +
    geom_point(aes(fill = species), shape = 21, size = 3, color = "grey20", stroke = 0.3) +
    facet_wrap(~species, scales = "free_y") +
    scale_fill_manual(values = species_colors, guide = "none") +
    labs(title = title, subtitle = subtitle, x = "Year", y = y_label) +
    theme_minimal(base_size = 12) +
    theme(strip.text = element_text(face = "bold"),
          plot.title = element_text(face = "bold", size = 13),
          plot.subtitle = element_text(color = "grey35", size = 9.5),
          panel.grid.minor = element_blank(),
          panel.spacing = unit(1.4, "lines"))
  ggsave(file.path(out_dir, out_file), p, width = width, height = height, dpi = 200, bg = "white")
  cat("Wrote", file.path(out_dir, out_file), "\n")
  p
}

to_long <- function(df, alb_col, hir_col) {
  bind_rows(
    data.frame(year = df$year, count = df[[alb_col]], species = "Little Tern (alb)"),
    data.frame(year = df$year, count = df[[hir_col]], species = "Common Tern (hir)")
  ) %>%
    # Common Tern left, Little Tern right - matches chart8 (alb)/chart9 (hir)
    # left-right position on slide 14 itself, for easy side-by-side comparison.
    mutate(species = factor(species, levels = c("Common Tern (hir)", "Little Tern (alb)")))
}

# --- Plot A: Yosef's original slide 14, replica design + his own numbers ---
plot_a_data <- to_long(slide14, "chicks_alb_slide", "chicks_hir_slide")
make_slide14_style_plot(
  plot_a_data,
  title = "Slide 14 replica: Yosef's plotted values, 2012-2020",
  subtitle = 'y = "מספר פרחונים" / number of fledglings, as plotted on slide 14 (סיכום 2020.pptx)',
  y_label = "Number of fledglings (Yosef's slide 14)",
  out_file = "fig4a_slide14_yosef_numbers_2012_2020.png"
)

# --- Plot B: same design/years, but real ringing-file counts ---------------
plot_b_data <- to_long(comparison, "chicks_alb_raw", "chicks_hir_raw")
make_slide14_style_plot(
  plot_b_data,
  title = "Same design, real numbers: chicks ringed, 2012-2020",
  subtitle = "y = age==3, new-capture count from ringing_data_raw.xlsx (02_number_of_chicks.R)",
  y_label = "Chicks ringed (from raw ringing records)",
  out_file = "fig4b_real_numbers_2012_2020.png"
)

# --- Plot C: real numbers, full range through 2026 --------------------------
plot_c_data <- to_long(raw_derived, "chicks_alb", "chicks_hir")
make_slide14_style_plot(
  plot_c_data,
  title = "Chicks ringed per year, 2010-2026 (real ringing records)",
  subtitle = "Same age==3 / new-capture rule, extended through 2026 - see 02_number_of_chicks.R",
  y_label = "Chicks ringed (from raw ringing records)",
  out_file = "fig4c_real_numbers_2010_2026.png",
  width = 9, height = 4.5
)
