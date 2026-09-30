# Slide 13 ("תחרות בין-מינית 2012-2020") revisited: is the interspecific-
# competition pattern (other species' chick output 2 years ago vs. this
# species' chick output now) still there once BOTH sides are on the
# effort-normalized scale (chicks per ringing night, from
# 05_ringing_effort_days.R / ringing_effort_by_year.csv), instead of raw
# ringing counts (as in 01_extended_competition_plot.R, issue #11's
# follow-up)?
#
# Same two-step structure as the chick-count trend check in issue #12:
#   1. Yosef's original years only, 2012-2020 (n=9)
#   2. Extended through the most recent year available, 2012-2026 (n=15)
# Both with Pearson + Spearman correlation and a Shapiro-Wilk normality
# check on the regression residuals (don't assume Pearson is valid, check).

library(dplyr)
library(ggplot2)

proc_dir <- "../data_processed"
if (!dir.exists(proc_dir)) proc_dir <- "data_processed"

effort <- read.csv(file.path(proc_dir, "ringing_effort_by_year.csv")) %>% arrange(year)

# ---- lag-2 normalized competition predictor --------------------------------
effort <- effort %>%
  mutate(
    hirTWOyears_norm = lag(hir_per_night, 2),   # Common Tern rate, 2 yrs earlier
    albTWOyears_norm = lag(alb_per_night, 2)    # Little Tern rate, 2 yrs earlier
  )

build_panel <- function(df, response_col, predictor_col, species_label) {
  d <- data.frame(year = df$year, x = df[[predictor_col]], y = df[[response_col]])
  d <- d[!is.na(d$x) & !is.na(d$y) & is.finite(d$x) & is.finite(d$y), ]
  d$species <- species_label
  d
}

hir_d <- build_panel(effort, "hir_per_night", "albTWOyears_norm", "Common Tern (hir)")
alb_d <- build_panel(effort, "alb_per_night", "hirTWOyears_norm", "Little Tern (alb)")

# ---- significance + normality, per window ----------------------------------
report_window <- function(d, window_label, year_max) {
  dw <- subset(d, year <= year_max)
  cat("---", unique(d$species), "-", window_label, "(n =", nrow(dw), ") ---\n")
  ct  <- cor.test(dw$x, dw$y, method = "pearson")
  cts <- cor.test(dw$x, dw$y, method = "spearman", exact = FALSE)
  m   <- lm(y ~ x, data = dw)
  s   <- summary(m)
  sw  <- shapiro.test(resid(m))
  cat(sprintf("Pearson r=%.3f (r2=%.3f, p=%.4f) | Spearman rho=%.3f (p=%.4f) | slope=%.3f (p=%.4f)\n",
              ct$estimate, ct$estimate^2, ct$p.value, cts$estimate, cts$p.value,
              coef(m)[2], s$coefficients[2, 4]))
  cat(sprintf("Residual normality: Shapiro-Wilk W=%.3f, p=%.4f -> %s\n\n",
              sw$statistic, sw$p.value,
              ifelse(sw$p.value < 0.05, "NOT normal, prefer Spearman", "~normal, Pearson OK")))
}

for (sp in list(hir_d, alb_d)) {
  report_window(sp, "Yosef's years (2012-2020)", 2020)
  report_window(sp, "Extended (2012-2026)", 2026)
}

# ---- plots ------------------------------------------------------------------
out_dir <- "output/figures"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
species_colors <- c("Little Tern (alb)" = "#F6C90A", "Common Tern (hir)" = "#FF0000")

plot_data <- bind_rows(hir_d, alb_d) %>%
  mutate(species = factor(species, levels = c("Common Tern (hir)", "Little Tern (alb)")))

xlabs <- c("Common Tern (hir)" = "Little Tern rate, 2 yrs earlier (chicks/night)",
           "Little Tern (alb)" = "Common Tern rate, 2 yrs earlier (chicks/night)")

# --- Figure A: Yosef's years only, 2012-2020 --------------------------------
pa_data <- subset(plot_data, year >= 2012 & year <= 2020)
pA <- ggplot(pa_data, aes(x = x, y = y)) +
  geom_smooth(method = "lm", se = FALSE, color = "black", linetype = "dotted", linewidth = 0.9) +
  geom_point(aes(fill = species), shape = 21, size = 3, color = "grey20", stroke = 0.3) +
  facet_wrap(~species, scales = "free") +
  scale_fill_manual(values = species_colors, guide = "none") +
  labs(title = "Interspecific competition, effort-normalized: Yosef's years, 2012-2020",
       subtitle = "x = other species' chicks/ringing-night, 2 yrs earlier | y = this species' chicks/ringing-night, this year",
       x = NULL, y = "Chicks ringed per ringing night (this year)") +
  theme_minimal(base_size = 12) +
  theme(strip.text = element_text(face = "bold"),
        plot.title = element_text(face = "bold", size = 13),
        plot.subtitle = element_text(color = "grey35", size = 8.5),
        panel.grid.minor = element_blank(),
        panel.spacing = unit(1.6, "lines"))
ggsave(file.path(out_dir, "fig6a_competition_normalized_2012_2020.png"), pA,
       width = 9, height = 4.5, dpi = 200, bg = "white")
cat("Wrote", file.path(out_dir, "fig6a_competition_normalized_2012_2020.png"), "\n")

# --- Figure B: extended through 2026, grey dashed = original-window trend --
pb_data <- subset(plot_data, year >= 2012 & year <= 2026)
pb_data$period <- ifelse(pb_data$year <= 2020, "2012-2020 (Yosef's years)", "2021-2026 (new)")
pb_data$period <- factor(pb_data$period, levels = c("2012-2020 (Yosef's years)", "2021-2026 (new)"))

pB <- ggplot(pb_data, aes(x = x, y = y)) +
  geom_smooth(data = subset(pb_data, year <= 2020), aes(x = x, y = y),
              method = "lm", se = FALSE, color = "grey55", linetype = "22",
              linewidth = 0.8, inherit.aes = FALSE) +
  geom_smooth(method = "lm", se = FALSE, color = "black", linetype = "dotted", linewidth = 0.9) +
  geom_point(aes(fill = species, alpha = period), shape = 21, size = 3, color = "grey20", stroke = 0.3) +
  scale_alpha_manual(values = c("2012-2020 (Yosef's years)" = 0.55, "2021-2026 (new)" = 1)) +
  facet_wrap(~species, scales = "free") +
  scale_fill_manual(values = species_colors, guide = "none") +
  labs(title = "Interspecific competition, effort-normalized: extended through 2026",
       subtitle = "x = other species' chicks/ringing-night, 2 yrs earlier | y = this species' chicks/ringing-night, this year\nGrey dashed = 2012-2020 trend only; black dotted = full 2012-2026 trend. Faint points = original years.",
       x = NULL, y = "Chicks ringed per ringing night (this year)", alpha = "Period") +
  theme_minimal(base_size = 12) +
  theme(strip.text = element_text(face = "bold"),
        plot.title = element_text(face = "bold", size = 13),
        plot.subtitle = element_text(color = "grey35", size = 8.5),
        panel.grid.minor = element_blank(),
        panel.spacing = unit(1.6, "lines"),
        legend.position = "top")
ggsave(file.path(out_dir, "fig6b_competition_normalized_2012_2026.png"), pB,
       width = 9, height = 4.8, dpi = 200, bg = "white")
cat("Wrote", file.path(out_dir, "fig6b_competition_normalized_2012_2026.png"), "\n")

write.csv(effort, file.path(proc_dir, "ringing_effort_by_year.csv"), row.names = FALSE, na = "NA")
