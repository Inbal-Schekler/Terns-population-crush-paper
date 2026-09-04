# data_raw — file by file

Source files exactly as received from Yosef (not edited). Each section below
documents one file: what it is, what each column means, and any caveats.
Built up incrementally as we review each file together.

---

## `data_2010-2020_legacy.csv`
*(original filename: `data.csv`)*

**What it is**: one row per breeding season, 2010–2020 (11 rows). This is
the dataset behind the first half of `GLM_2020_original.R` (the "11-year"
models, lines 1–256) — weather/predation/Newcastle as predictors of chick
counts, no competition or body-mass terms yet.

**Columns**:

| Column | Meaning | Notes |
|---|---|---|
| `year` | Breeding season year | 2010–2020 |
| `hir` | Common Tern (*Sterna hirundo*) chicks ringed that season | Response variable. "hir" = hirundo |
| `alb` | Little Tern (*Sternula albifrons*) chicks ringed that season | Response variable. "alb" = albifrons |
| `temp37` | Number of days (May–June) with max temp > 37°C | Heat-stress predictor |
| `temp12` | Number of days (May–June) with min temp < 12°C | Cold-stress predictor |
| `meanMAXtemp` | Mean daily maximum temperature, May–June | °C |
| `meanMINtemp` | Mean daily minimum temperature, May–June | °C |
| `rainMAY` | Rainfall in May | mm |
| `rainJUN` | Rainfall in June | mm |
| `predation` | Whether a predation event occurred that season | yes/no |
| `newcastle` | Whether a Newcastle disease outbreak occurred that season | yes/no |

**How I know this**: column names + `סיכום 2020.pptx` slide 8, which lists
these exact candidate factors (heat days, cold days, rain, predation,
Newcastle) as the predictors tested.

**Confirmed with Inbal**:
- `hir`/`alb` = counts of chicks **ringed** that season (not just observed).
- `predation` = yes if **at least one** predation event occurred that
  season (there can be more than one; the column doesn't distinguish
  frequency/severity, just presence/absence).

**Checked and correct**: I cross-checked this file numerically against
`data1_2012-2020_legacy.csv` (see that file's entry below) and confirmed
this one's `predation`/`newcastle`/temperature columns are internally
consistent — e.g. `predation=yes` in 2016 and 2017 lines up with the
Newcastle outbreak + predation events Yosef's slides describe around that
time. This is the file I used as the trusted source for these columns.

**Gap**: stops at 2020. No weather/predation/Newcastle data exists (in any
file sent) for 2021 onward — see main `NOTES.md`.

---

## `data1_2012-2020_legacy.csv`
*(original filename: `data1.csv`)*

**What it is**: a 2012–2020 (9 rows) extension of the same underlying study,
used for the second half of `GLM_2020_original.R` (the "9-year" models,
lines 265–481 — summarized on `סיכום 2020.pptx` slides 10 and 12). Adds
interspecific-competition and body-condition terms on top of a subset of
`data_2010-2020_legacy.csv`'s weather columns.

**Columns**: `year, hir, alb, temp37, temp12, meanMAXtemp, meanMINtemp, predation, hirTWOyears, albTWOyears, hirMASS, albMASS`

| Column | Status | Notes |
|---|---|---|
| `year`, `hir`, `alb` | **Correct** | Match `data_2010-2020_legacy.csv` exactly for the overlapping years |
| `temp37`, `temp12`, `meanMAXtemp`, `meanMINtemp` | **Corrupted** | See bug below |
| `predation` | **Corrupted / unusable** | See bug below |
| `rainMAY`, `rainJUN`, `newcastle` | **Not present** | Dropped entirely vs. `data_2010-2020_legacy.csv` — matches `GLM.R`, which doesn't test rain/Newcastle in this block |
| `hirTWOyears`, `albTWOyears` | **Correct, new** | The *other* species' chick count 2 years prior (interspecific-competition proxy). Checked against `data_2010-2020_legacy.csv`'s lagged values — matches. |
| `hirMASS`, `albMASS` | **Trusted, unverifiable** | Pre-breeding average body mass (g). Not derivable from any other file we have, so can't cross-check independently. Source/method unknown — ask Yosef (also needed to extend past 2020, see main `NOTES.md`). |

Also starts 2 years later than `data_2010-2020_legacy.csv` (2012 vs. 2010) —
consistent with needing a 2-year lag for `hirTWOyears`/`albTWOyears`.

### The bug: column values shifted, `predation` overwritten

Checked numerically against `data_2010-2020_legacy.csv` (trusted). Example,
year 2012:

| Column (as labeled here) | Value here | Value in `data_2010-2020_legacy.csv`'s same-named column | What this value actually matches in `data_2010-2020_legacy.csv` |
|---|---|---|---|
| `temp37` | 17.7 | 0 | `meanMINtemp` |
| `temp12` | 0 | 2 | `temp37` |
| `meanMAXtemp` | 2 | 28.5 | `temp12` |
| `meanMINtemp` | 28.5 | 17.7 | `meanMAXtemp` |
| `predation` | 17.7 | no | `meanMINtemp` again (duplicate, not yes/no) |

Same pattern holds on every row checked (e.g. 2013: all four shift the same
way with different numbers). This is a clean one-position rotation of the
4-column temperature block — consistent with a column having been
deleted/inserted in Excel without the headers re-aligning — and the real
`predation` yes/no values are gone, overwritten with a copy of the
(mis-shifted) `temp37` cell. **The real predation flags for 2012–2020 only
exist in `data_2010-2020_legacy.csv`**, which is what `00_build_dataset.R`
uses instead.

Ruled out: this is not Yosef intentionally testing two different heat/cold
metrics (day-count vs. daily-mean) across the two files — `data_2010-2020_legacy.csv`
already contains all four metrics correctly on its own (see that file's
entry above), and `data1.csv` reuses the *identical* column names rather
than naming a genuinely new metric, which is what you'd expect if this were
deliberate.

### Consequence for Yosef's original 2020 results

Of the 23 candidate models per species in this block (`m1`–`m23`), only 3
per species are untouched by the bug — the ones using solely
`albTWOyears`/`hirTWOyears` and/or `hirMASS`/`albMASS` (`m2`, `m3`, `m8`).
The other 20 per species include `predation` and/or one of the 4 corrupted
temperature columns.

Two concrete, verified consequences:

1. **Perfect collinearity, silently mis-fit.** Models combining `predation` +
   `temp37` (Common Tern models `m7`, `m12`, `m13`, `m15`) are regressing on
   two identical columns. Verified directly:
   ```r
   > m7 <- glm(hir ~ predation + temp37, family=gaussian, data=data1)
   > summary(m7)
   Coefficients: (1 not defined because of singularities)
               Estimate Std. Error t value Pr(>|t|)
   (Intercept)   334.07     969.51   0.345    0.741
   predation     -11.02      55.18  -0.200    0.847
   temp37            NA         NA      NA       NA
   ```
   R silently drops `temp37` and fits a single-predictor model. Easy to miss
   if you only read the coefficient table and not the header line.

2. **Mislabeled weather variable in the results actually reported.** On
   `סיכום 2020.pptx` slide 10 (Common Tern), 2 of the top 4 models use
   `temp12`, presented as "cold temperature (12°)" — but `temp12` here
   actually holds `data_2010-2020_legacy.csv`'s real `temp37` (hot-day
   count). So that reported cold-temperature effect was statistically driven
   by the hot-day count instead. On slide 12 (Little Tern), the top model
   (competition alone, weight 0.46) is unaffected — but the second-place
   model (weight 0.28, "competition + cold average temp") used
   `meanMINtemp`, which here actually holds the real `meanMAXtemp` — a heat
   metric presented as a cold one.

**Bottom line**: the headline 2020 conclusion (interspecific competition is
the top single predictor of Little Tern breeding success) is not affected —
it comes from `m2`, one of the 3 clean models. But most of the secondary
weather-driven conclusions on slides 10 and 12, for both species, are either
statistically broken (collinear/NA) or describe the wrong variable (heat
reported as cold, or vice versa). Worth raising with Yosef before this
propagates into the new paper.
