# Figures for YOSEF_2020_ANALYSIS.md: how much the AICc ranking moved once the
# data1.csv column-rotation bug was fixed, and why AICc's small-sample
# correction term makes that instability expected at n=9-11.
# Source numbers: output/01_replication_results.txt (after) and
# YOSEF_2020_ANALYSIS.md section 2, quoting סיכום 2020.pptx slides 10/12 (before).

library(ggplot2)

out_dir <- "output/figures"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

## ---- Figure 1: before/after AICc weight, same formulas ----

fig1_data <- data.frame(
  species = factor(c(rep("Common Tern (hir), Block B n=9", 4),
                      rep("Little Tern (alb), Block B n=9", 3)),
                    levels = c("Common Tern (hir), Block B n=9",
                               "Little Tern (alb), Block B n=9")),
  formula = c("temp12 alone", "competition alone", "mass alone", "competition + temp12",
              "competition alone", 'competition + "cold" (mislabeled)',
              "competition + hot temp\n(correct top model)"),
  before = c(0.14, 0.21, 0.21, 0.12,  0.46, 0.28, NA),
  after  = c(0.208, 0.183, 0.076, 0.032,  0.297, 0.010, 0.488)
)
fig1_data$formula <- factor(fig1_data$formula, levels = rev(unique(fig1_data$formula)))

fig1_long <- do.call(rbind, list(
  data.frame(species = fig1_data$species, formula = fig1_data$formula,
             period = "2020 slides (buggy data1.csv)", weight = fig1_data$before),
  data.frame(species = fig1_data$species, formula = fig1_data$formula,
             period = "Corrected data (rerun today)", weight = fig1_data$after)
))
fig1_long$period <- factor(fig1_long$period,
                            levels = c("2020 slides (buggy data1.csv)", "Corrected data (rerun today)"))

p1 <- ggplot(fig1_long, aes(x = formula, y = weight, fill = period)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6, na.rm = TRUE) +
  geom_text(aes(label = ifelse(is.na(weight), "", sprintf("%.3f", weight))),
            position = position_dodge(width = 0.7), hjust = -0.15, size = 3.2, na.rm = TRUE) +
  coord_flip(clip = "off") +
  facet_wrap(~species, scales = "free_y", ncol = 1) +
  scale_fill_manual(values = c("2020 slides (buggy data1.csv)" = "#2a78d6",
                                "Corrected data (rerun today)" = "#1baf7a")) +
  scale_y_continuous(limits = c(0, 0.58), expand = expansion(mult = c(0, 0.12))) +
  labs(title = "Same formulas, same 9 seasons—only the mislabeled column fixed",
       subtitle = "AICc weight before vs. after correcting the data1.csv column-rotation bug",
       x = NULL, y = "AICc weight", fill = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top",
        panel.grid.major.y = element_blank(),
        panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold", size = 12.5),
        plot.subtitle = element_text(color = "grey35", size = 10),
        plot.margin = margin(10, 30, 10, 10))

ggsave(file.path(out_dir, "fig1_before_after_weights.png"), p1,
       width = 9, height = 6, dpi = 200, bg = "white")

## ---- Figure 2: AICc small-sample correction term vs k ----

correction <- function(n, k) (2 * k * (k + 1)) / (n - k - 1)

make_series <- function(n) {
  ks <- 1:(n - 2)
  data.frame(n = factor(n), k = ks, val = correction(n, ks))
}
fig2_data <- do.call(rbind, lapply(c(9, 11, 50), make_series))
fig2_data <- fig2_data[fig2_data$k <= 9, ]

ref_points <- data.frame(
  n = factor(c(11, 9)), k = c(5, 6),
  label = c("Block A largest model\n(k=5, n=11)", "Block B largest model\n(k=6, n=9)")
)
ref_points$val <- correction(as.numeric(as.character(ref_points$n)), ref_points$k)

p2 <- ggplot(fig2_data, aes(x = k, y = pmin(val, 45), color = n, linetype = n)) +
  geom_hline(yintercept = 2, linetype = "dotted", color = "grey60") +
  annotate("text", x = 8.7, y = 4, label = "ΔAICc support\nthreshold (~2)",
           size = 2.9, color = "grey45", hjust = 1) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_point(data = ref_points, aes(x = k, y = pmin(val, 45)),
             inherit.aes = FALSE, shape = 21, size = 5.5, stroke = 1.3, color = "#d03b3b", fill = NA) +
  geom_text(data = ref_points, aes(x = k, y = pmin(val, 45), label = label),
            inherit.aes = FALSE, vjust = -0.9, size = 2.9, color = "#d03b3b", lineheight = 0.9) +
  scale_color_manual(values = c("9" = "#2a78d6", "11" = "#1baf7a", "50" = "grey55"),
                      labels = c("9" = "n = 9 (Block B)", "11" = "n = 11 (Block A)",
                                 "50" = "n = 50 (reference, not their data)")) +
  scale_linetype_manual(values = c("9" = "solid", "11" = "solid", "50" = "22"),
                         labels = c("9" = "n = 9 (Block B)", "11" = "n = 11 (Block A)",
                                    "50" = "n = 50 (reference, not their data)")) +
  scale_x_continuous(breaks = 1:9) +
  scale_y_continuous(limits = c(0, 46), expand = expansion(mult = c(0.02, 0.08))) +
  labs(title = "AICc's small-sample correction term explodes as parameters approach n",
       subtitle = expression(paste("Correction added to AIC: ", frac(2*k*(k+1), n-k-1))),
       x = "k — estimated parameters (predictors + intercept + residual variance)",
       y = "AICc correction term (capped at 45)",
       color = NULL, linetype = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top",
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(color = "grey35", size = 10))

ggsave(file.path(out_dir, "fig2_aicc_correction.png"), p2,
       width = 7.5, height = 5.2, dpi = 200, bg = "white")

cat("Wrote:\n",
    file.path(out_dir, "fig1_before_after_weights.png"), "\n",
    file.path(out_dir, "fig2_aicc_correction.png"), "\n")
