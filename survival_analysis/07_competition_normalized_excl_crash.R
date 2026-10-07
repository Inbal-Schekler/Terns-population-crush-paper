# Follow-up to 06_competition_normalized.R (issue #11): does the
# interspecific-competition pattern hold if we drop 2025-2026, the two years
# where Little Tern chick output collapsed to near-zero (5, then 4 chicks -
# vs. 21 in 2024 and a historical range mostly in the tens-to-hundreds)?
# Hypothesis being tested: those two years may reflect a floor/collapse
# dynamic rather than a continuation of the competition relationship, and
# could be dominating or masking the correlation as outliers.
#
# Adds a THIRD window alongside 06's existing two (2012-2020, 2012-2026):
#   3. 2012-2024 (n=13) - same start, extended end, crash years excluded.
# Does not modify 06 - kept side by side per Inbal's standing preference,
# see [[feedback-additive-analysis-iteration]].

library(dplyr)
library(ggplot2)

proc_dir <- "../data_processed"
if (!dir.exists(proc_dir)) proc_dir <- "data_processed"

effort <- read.csv(file.path(proc_dir, "ringing_effort_by_year.csv")) %>% arrange(year)

# hirTWOyears_norm / albTWOyears_norm already written to this file by 06 -
# recompute defensively in case this is ever run standalone before 06.
effort <- effort %>%
  mutate(
    hirTWOyears_norm = lag(hir_per_night, 2),
    albTWOyears_norm = lag(alb_per_night, 2)
  )

build_panel <- function(df, response_col, predictor_col, species_label) {
  d <- data.frame(year = df$year, x = df[[predictor_col]], y = df[[response_col]])
  d <- d[!is.na(d$x) & !is.na(d$y) & is.finite(d$x) & is.finite(d$y), ]
  d$species <- species_label
  d
}

hir_d <- build_panel(effort, "hir_per_night", "albTWOyears_norm", "Common Tern (hir)")
alb_d <- build_panel(effort, "alb_per_night", "hirTWOyears_norm", "Little Tern (alb)")

report_window <- function(d, window_label, year_min, year_max) {
  dw <- subset(d, year >= year_min & year <= year_max)
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

cat("=== Reference: full windows from 06_competition_normalized.R ===\n")
for (sp in list(hir_d, alb_d)) {
  report_window(sp, "Yosef's years (2012-2020)", 2012, 2020)
  report_window(sp, "Extended (2012-2026)", 2012, 2026)
}

cat("=== New: 2012-2024, excluding the 2025-2026 Little Tern collapse ===\n")
for (sp in list(hir_d, alb_d)) {
  report_window(sp, "Excl. crash years (2012-2024)", 2012, 2024)
}

# ---- plot: 2012-2024 window, same visual design as fig6a/6c ----------------
out_dir <- "output/figures"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
species_colors <- c("Little Tern (alb)" = "#F6C90A", "Common Tern (hir)" = "#FF0000")

plot_data <- bind_rows(hir_d, alb_d) %>%
  mutate(species = factor(species, levels = c("Common Tern (hir)", "Little Tern (alb)")))

pD_data <- subset(plot_data, year >= 2012 & year <= 2024)
pD <- ggplot(pD_data, aes(x = x, y = y)) +
  geom_smooth(method = "lm", se = TRUE, color = "#2a78d6", fill = "#2a78d6",
              alpha = 0.12, linewidth = 1) +
  geom_point(aes(fill = species), shape = 21, size = 3.2, color = "white", stroke = 0.3) +
  ggrepel::geom_text_repel(aes(label = year), size = 2.6, color = "grey35",
                            max.overlaps = 20, seed = 1) +
  facet_wrap(~species, scales = "free", ncol = 2) +
  scale_fill_manual(values = species_colors, guide = "none") +
  labs(title = "Interspecific competition, effort-normalized: 2012-2024 (excl. 2025-2026 Little Tern collapse)",
       subtitle = "x = other species' chicks/ringing-night, 2 yrs earlier | y = this species' chicks/ringing-night, this year\n2025-2026 dropped: Little Tern chick output fell to 5 then 4, vs. 21 in 2024 - possible floor effect, not tested here as cause.",
       x = NULL, y = "Chicks ringed per ringing night (this year)") +
  theme_minimal(base_size = 12) +
  theme(strip.text = element_text(face = "bold"),
        plot.title = element_text(face = "bold", size = 12.5),
        plot.subtitle = element_text(color = "grey35", size = 8.5),
        panel.grid.minor = element_blank(),
        panel.spacing = unit(1.6, "lines"))
ggsave(file.path(out_dir, "fig7_competition_normalized_2012_2024_excl_crash.png"), pD,
       width = 10, height = 5.2, dpi = 200, bg = "white")
cat("Wrote", file.path(out_dir, "fig7_competition_normalized_2012_2024_excl_crash.png"), "\n")
