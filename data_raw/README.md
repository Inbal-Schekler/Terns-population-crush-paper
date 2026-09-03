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
