# Slide 13 ("תחרות בין-מינית 2012-2020"), extended with the years since -
# same interspecific-competition idea (other species' chick count 2 years
# ago vs. this species' chick count now), but:
#   - response = chicks_hir/chicks_alb (real ringing counts from
#     summary_2026.xlsx via master_dataset_2010_2026.csv), not slide 13's
#     "number of fledglings" - see issue #11, they don't match and the
#     ringing counts are the trusted source.
#   - years = 2012-2026 (n=15) instead of 2012-2020 (n=9); hirTWOyears/
#     albTWOyears in master_dataset_2010_2026.csv already extend that far.

library(ggplot2)

out_dir <- "output/figures"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

master <- read.csv("../data_processed/master_dataset_2010_2026.csv")

build_panel_data <- function(df, response, competitor_lag, response_label) {
  d <- data.frame(year = df$year, x = df[[competitor_lag]], y = df[[response]])
  d <- d[!is.na(d$x) & !is.na(d$y), ]
  d$period <- ifelse(d$year <= 2020, "2012-2020 (Yosef's original n=9)", "2021-2026 (new)")
  d$period <- factor(d$period, levels = c("2012-2020 (Yosef's original n=9)", "2021-2026 (new)"))
  d$species <- response_label
  d
}

hir_d <- build_panel_data(master, "chicks_hir", "albTWOyears", "Common Tern (hir)")
alb_d <- build_panel_data(master, "chicks_alb", "hirTWOyears", "Little Tern (alb)")
plot_data <- rbind(hir_d, alb_d)
plot_data$species <- factor(plot_data$species, levels = c("Common Tern (hir)", "Little Tern (alb)"))

xlabs <- c(
  "Common Tern (hir)" = "Little Tern chicks ringed, 2 years earlier",
  "Little Tern (alb)" = "Common Tern chicks ringed, 2 years earlier"
)
ylabs <- c(
  "Common Tern (hir)" = "Common Tern chicks ringed (this year)",
  "Little Tern (alb)" = "Little Tern chicks ringed (this year)"
)
label_df <- data.frame(species = factor(names(xlabs), levels = levels(plot_data$species)))

p <- ggplot(plot_data, aes(x = x, y = y)) +
  geom_smooth(data = subset(plot_data, year <= 2020), aes(x = x, y = y),
              method = "lm", se = FALSE, color = "grey55", linetype = "22",
              linewidth = 0.8, inherit.aes = FALSE) +
  geom_smooth(method = "lm", se = TRUE, color = "#2a78d6", fill = "#2a78d6",
              alpha = 0.12, linewidth = 1) +
  geom_point(aes(fill = period), shape = 21, size = 3.2, color = "white", stroke = 0.3) +
  ggrepel::geom_text_repel(aes(label = year), size = 2.6, color = "grey35",
                            max.overlaps = 20, seed = 1) +
  facet_wrap(~species, scales = "free", ncol = 2) +
  scale_fill_manual(values = c("2012-2020 (Yosef's original n=9)" = "#898781",
                                "2021-2026 (new)" = "#1baf7a")) +
  labs(title = "Interspecific competition (2-year lag), extended through 2026",
       subtitle = paste0("Response = chicks ringed (master_dataset_2010_2026.csv), not slide 13's \"number of fledglings\" - see issue #11.\n",
                          "Grey dashed = original 2012-2020 trend; blue = full 2012-2026 trend (shaded = 95% CI)."),
       x = NULL, y = NULL, fill = "Period") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top",
        strip.text = element_text(face = "bold"),
        plot.title = element_text(face = "bold", size = 13),
        plot.subtitle = element_text(color = "grey35", size = 9.5),
        panel.grid.minor = element_blank(),
        panel.spacing = unit(1.6, "lines"))

# per-facet axis labels via geom_text in the strip is awkward with free scales;
# add them as a caption instead, keeps the panels clean
p <- p + labs(caption = paste0(
  "x-axis: other species' chicks ringed 2 years earlier   |   ",
  "y-axis: this species' chicks ringed, current year"
)) + theme(plot.caption = element_text(color = "grey45", size = 8.5, hjust = 0))

ggsave(file.path(out_dir, "fig3_competition_extended_2012_2026.png"), p,
       width = 10, height = 5.5, dpi = 200, bg = "white")

cat("Wrote", file.path(out_dir, "fig3_competition_extended_2012_2026.png"), "\n")

# quick console readout: does the relationship hold up with 6 more years?
for (sp in list(list(name = "hir", d = hir_d), list(name = "alb", d = alb_d))) {
  d9  <- subset(sp$d, year <= 2020)
  d15 <- sp$d
  m9  <- lm(y ~ x, data = d9)
  m15 <- lm(y ~ x, data = d15)
  cat("\n---", sp$name, "---\n")
  cat("2012-2020 (n=", nrow(d9), "): slope=", round(coef(m9)[2], 3),
      " r2=", round(summary(m9)$r.squared, 3),
      " p=", round(summary(m9)$coefficients[2, 4], 4), "\n", sep = "")
  cat("2012-2026 (n=", nrow(d15), "): slope=", round(coef(m15)[2], 3),
      " r2=", round(summary(m15)$r.squared, 3),
      " p=", round(summary(m15)$coefficients[2, 4], 4), "\n", sep = "")
}
