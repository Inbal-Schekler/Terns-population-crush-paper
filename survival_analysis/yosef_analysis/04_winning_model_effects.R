# ==============================================================================
# 04_winning_model_effects.R
#
# Purpose: for the top-ranked (AICc-winning) model in each of 03's four
# TIER 2 tables (Block A/B x hir/alb, now with SST candidates included),
# plot the effect of each predictor on the response - holding every other
# predictor in that model at its mean (continuous) or mode (categorical),
# with the real data points shown for context. One PNG per winning model
# (one panel per predictor), via cowplot (no new package deps - patchwork/
# gridExtra aren't installed, cowplot is).
#
# Winning models, verified programmatically against the fitted model objects
# (formula()/coef()), not read off 03's printed fixed-width table - a first
# pass misread the Block B alb row and plotted an 11th-ranked model instead
# of the true winner, caught 2026-10-25 when Inbal asked for the full
# candidate tables to be regenerated the same way:
#   Block A hir (weather-only, n=17):  hir ~ newcastle                (w=0.099)
#   Block A alb (weather-only, n=17):  alb ~ meanMINsst_inb           (w=0.202)
#   Block B hir (full, n=15):          hir ~ albTWOyears + temp37_inb (w=0.358)
#   Block B alb (full, n=15):          alb ~ meanMINsst_inb           (w=0.161)
#
# Does not modify 00/01/02/03/05's outputs; only reads the master dataset.
# ==============================================================================

library(dplyr)
library(ggplot2)
library(cowplot)

proc_candidates <- c("../../data_processed", "../data_processed", "data_processed")
out_candidates  <- c("output", "yosef_analysis/output", "survival_analysis/yosef_analysis/output")
proc_idx <- which(dir.exists(proc_candidates))[1]
proc_dir <- proc_candidates[proc_idx]
out_dir  <- out_candidates[proc_idx]
master <- read.csv(file.path(proc_dir, "master_dataset_2010_2026.csv"))

dataA_inb <- master %>% filter(year >= 2010, year <= 2026) %>%
  select(year, hir = chicks_hir, alb = chicks_alb, predation, newcastle,
         temp37_inb, temp12_inb, meanMAXtemp_inb, meanMINtemp_inb, rainMAY_inb, rainJUN_inb,
         meanSST_inb, meanMAXsst_inb, meanMINsst_inb)

dataB_inb <- master %>% filter(year >= 2012, year <= 2026) %>%
  select(year, hir = chicks_hir, alb = chicks_alb, predation,
         hirTWOyears, albTWOyears, hirMASS, albMASS,
         temp37_inb, temp12_inb, meanMAXtemp_inb, meanMINtemp_inb,
         meanSST_inb, meanMAXsst_inb, meanMINsst_inb)

# human-readable labels for the predictors that show up below
var_labels <- c(
  newcastle      = "Newcastle disease (yes/no)",
  meanMINsst_inb = "Mean daily minimum SST (°C)",
  albTWOyears    = "Little Tern 2yr competition index",
  hirTWOyears    = "Common Tern 2yr competition index",
  temp37_inb     = "Days ≥ 37°C (self-computed IMS)",
  albMASS        = "Little Tern spring mass (g)"
)
response_labels <- c(hir = "Common Tern chicks ringed", alb = "Little Tern chicks ringed")

# Effect of `focal` on the model's response, other predictors in the model
# held at their mean (numeric) or mode (categorical). Real data shown as
# grey points for context (not partial residuals - these are raw y vs x).
effect_plot <- function(model, data, focal) {
  response_var <- all.vars(formula(model))[1]
  other_vars <- setdiff(all.vars(formula(model))[-1], focal)
  is_factor <- !is.numeric(data[[focal]])

  if (is_factor) {
    newdata <- data.frame(setNames(list(sort(unique(data[[focal]]))), focal))
  } else {
    rng <- range(data[[focal]])
    newdata <- data.frame(setNames(list(seq(rng[1], rng[2], length.out = 50)), focal))
  }
  for (v in other_vars) {
    if (is.numeric(data[[v]])) {
      newdata[[v]] <- mean(data[[v]])
    } else {
      tab <- table(data[[v]])
      newdata[[v]] <- names(tab)[which.max(tab)]
    }
  }

  pred <- predict(model, newdata = newdata, se.fit = TRUE)
  newdata$fit <- pred$fit
  newdata$lwr <- pred$fit - 1.96 * pred$se.fit
  newdata$upr <- pred$fit + 1.96 * pred$se.fit

  held_note <- if (length(other_vars) == 0) "no other predictors in this model" else
    paste("others held at mean/mode:", paste(other_vars, collapse = ", "))

  p <- ggplot(data, aes(x = .data[[focal]], y = .data[[response_var]])) +
    geom_point(color = "grey45", size = 2.2)

  if (is_factor) {
    p <- p + geom_pointrange(data = newdata,
                              aes(x = .data[[focal]], y = fit, ymin = lwr, ymax = upr),
                              inherit.aes = FALSE, color = "steelblue", linewidth = 1, size = 0.9)
  } else {
    p <- p +
      geom_ribbon(data = newdata, aes(x = .data[[focal]], ymin = lwr, ymax = upr),
                  inherit.aes = FALSE, alpha = 0.18, fill = "steelblue") +
      geom_line(data = newdata, aes(x = .data[[focal]], y = fit),
                inherit.aes = FALSE, color = "steelblue", linewidth = 1)
  }

  p +
    labs(x = var_labels[[focal]], y = response_labels[[response_var]], subtitle = held_note) +
    theme_minimal(base_size = 11)
}

make_model_figure <- function(model, data, focal_vars, title, filename) {
  panels <- lapply(focal_vars, function(v) effect_plot(model, data, v))
  width <- 4.5 * length(focal_vars)
  wrap_width <- max(30, round(width * 8))  # ~8 chars/inch at title font size
  title_lines <- strwrap(title, width = wrap_width)
  title_wrapped <- paste(title_lines, collapse = "\n")
  title_row <- ggdraw() +
    draw_label(title_wrapped, fontface = "bold", size = 12, x = 0.02, hjust = 0, lineheight = 1.1)
  fig <- plot_grid(plotlist = panels, nrow = 1, labels = NULL) %>%
    plot_grid(title_row, ., ncol = 1,
              rel_heights = c(0.09 * length(title_lines) + 0.03, 1))
  height <- 4.3 + 0.3 * length(title_lines)
  ggsave(file.path(out_dir, filename), fig, width = width, height = height, limitsize = FALSE)
  cat("Saved", filename, "\n")
}

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

m_A_hir <- glm(hir ~ newcastle, family = gaussian, data = dataA_inb)
make_model_figure(m_A_hir, dataA_inb, "newcastle",
                   "Block A winner - Common Tern (hir ~ newcastle, weight 0.099, n=17)",
                   "04_effect_blockA_hir.png")

m_A_alb <- glm(alb ~ meanMINsst_inb, family = gaussian, data = dataA_inb)
make_model_figure(m_A_alb, dataA_inb, "meanMINsst_inb",
                   "Block A winner - Little Tern (alb ~ meanMINsst_inb, weight 0.202, n=17)",
                   "04_effect_blockA_alb.png")

m_B_hir <- glm(hir ~ albTWOyears + temp37_inb, family = gaussian, data = dataB_inb)
make_model_figure(m_B_hir, dataB_inb, c("albTWOyears", "temp37_inb"),
                   "Block B winner - Common Tern (hir ~ albTWOyears + temp37_inb, weight 0.358, n=15)",
                   "04_effect_blockB_hir.png")

m_B_alb <- glm(alb ~ meanMINsst_inb, family = gaussian, data = dataB_inb)
make_model_figure(m_B_alb, dataB_inb, "meanMINsst_inb",
                   "Block B winner - Little Tern (alb ~ meanMINsst_inb, weight 0.161, n=15)",
                   "04_effect_blockB_alb.png")

cat("\nAll 4 winning-model effect figures written to", out_dir, "\n")
