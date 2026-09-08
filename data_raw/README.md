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
| `hirMASS`, `albMASS` | **Trusted, unverifiable** | Pre-breeding average body mass (g), presumably spring adults. Searched every file in the folder (docx, pptx, R scripts, all CSVs, and the 8,490-record raw ringing sheet `גיליון1`) for "mass"/"weight"/משקל/גרם — the word `MASS` only occurs as these two column headers. No documentation of the method (date window, sample size, ages included), and no individual-level records to recompute or verify these 9 numbers from. Ask Yosef for the underlying raw mass measurements, not just the 2021-2026 summary numbers — see issue #1. |

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

---

## `data2_method_check_legacy.csv`
*(original filename: `data2.csv`)*

**What it is**: pair-count estimates (not chick counts) for both species,
2010–2020, labeled by which counting method produced them: `car` (רכב) vs.
`h` (**"high"** - tower/camera method). Feeds `plot_2020_original.R`, which
produces the boxplot figure `איור השפעת שיטה על מספר זוגות.tiff` and runs a
t-test + Wilcoxon test comparing methods for Little Tern (`alb`) pairs:
car mean = 140.8, tower/camera mean = 209.5, t-test p = 0.0038, Wilcoxon
p = 0.0080 - a statistically significant ~49% difference depending purely on
which method was used that year. (Same comparison wasn't run for `hir`
in the original script.)

**Structure**: rows 1-11 hold both species side by side (`x_alb`/`type_alb`,
`x_hir`/`type_hir`); rows 12-22 repeat the `hir` values into the plain
`x`/`type` columns so `boxplot(x ~ type, ...)` has one column spanning all
4 groups.

**Not used in this paper**: per Inbal, this method-comparison result was
already analyzed and published in a separate paper. Kept here for reference
only, not part of the current analysis pipeline.

---

## `summary_2026.xlsx`
*(original filename: `סיכום 2026.xlsx`)*

Yosef's annual-summary workbook, per his email mostly a copy of the 2025
version with a 2026 column added. 8 sheets - documented one at a time below.

### Sheet: `סיכום טיבוע` (ringing summary)

Total individuals of each species **ringed** each year, 2010-2025 (all ages
combined - spring migration + breeding season). Used by
`scripts/00_build_dataset.R`? No - not currently used; the master dataset
uses the `מספר צעירים` sheet (chicks only) instead. This sheet is broader
(includes adults).

**Confirmed with Inbal**: this sheet's numbers (e.g. 2020: 80 Little Tern,
1,071 Common Tern) are noticeably lower than `סיכום 2020.pptx` slide 2's
stated 2020 catch totals (101 / 1,190) because the pptx figure includes
**recaptures** (birds already ringed in a previous year, caught again),
while this sheet counts only newly ringed individuals.

Note: the other 5 sheets in this workbook (`כללי`, `גיליון1`, `חו"ל`,
`חו"ל (2)`, `מספר זוגות ע"י אלגוריתם`) are not needed for this paper -
skipped per Inbal, not documented here.

### Sheet: `מספר צעירים` (number of chicks)

**The headline data for this paper.** Chicks ringed per species per year,
2010-2026 - this is what `00_build_dataset.R` uses for `chicks_alb`/
`chicks_hir`, and matches `data_2010-2020_legacy.csv`'s `alb`/`hir` columns
exactly for the overlapping years. Same definition, confirmed with Inbal:
chicks ringed that season.

```
                2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026
שחפית גמדית       22   34   96   65   95  104   44    9   67   56   11   63   72   16   21    5    4
שחפית ים          28   96  101   74   54  227   22   39  198  309  242  271  315  209   82  179  165
```

This is the crash: Little Tern chicks drop from double/triple digits (up
to 2019) to single digits every year since 2023.

**Open item**: the 2026 Little Tern value (4) needs Inbal's confirmation -
per Yosef's email this file may still hold last year's placeholder. See
issue #4.

### Sheet: `מספר זוגות בעתלית - רב שנתי` (breeding pairs at Atlit, multi-year)

Breeding pair counts per species per year, 2011-2025, each year labeled with
the counting method used that year. This is the density data behind Yosef's
suggestion to model rising Common Tern density as a predictor of Little
Tern breeding success.

```
Year   Common Tern   Little Tern   Method
2011      430          170         רכב (car)
2012      490          105         רכב
2013      550          135         רכב
2014      525          176         מצלמה אחת / מגדל (one camera/tower)
2015      530          214         מצלמה אחת / מגדל
2016      735          222         מצלמה אחת / מגדל
2017      734          241         מצלמה אחת / מגדל
2018      898          233         מצלמה אחת / מגדל
2019      754          171         מצלמה אחת / מגדל
2020      550          124         רכב
2021      550          185         רכב
2022        -            -         (blank - gap, see issue #4)
2023     1149          185         שתי מצלמות (two cameras)
2024     1155          156         שתי מצלמות
2025     1297          138         שתי מצלמות
```

**Pattern**: Common Tern pairs show a large apparent rise (430 -> ~1,300)
while Little Tern stays roughly flat (105-241) throughout, regardless of
method - the empirical basis for Yosef's density/competition idea.

**Caveat - three different counting methods across the series**: car (2011-
2013, 2020-2021), one camera/tower (2014-2019), two cameras (2023-2025).
Confirmed with Inbal: "two cameras" is better coverage of the same colony,
not a different estimation procedure. That still means detection improves
over time (more of the true population gets counted), which is the same
direction of bias as the car-vs-tower difference already demonstrated
statistically in `data2_method_check_legacy.csv` (car undercounts relative
to tower, p<0.01 for Little Tern). So at least part of the Common Tern rise
across this table is plausibly a *detection* improvement, not purely a real
population increase - relevant to how the density index gets built (see
NOTES.md "Density index" open item). Not corrected for here.

**Gaps**: no 2010 row (table starts 2011), 2022 blank (still open, see
issue #4). 2026 row added by Inbal (2026-09-04): 1063 Common Tern / 67
Little Tern pairs, two-cameras method.

**Method labels translated to English at build time**: `00_build_dataset.R`
recodes `רכב`->`Car`, `מצלמה אחת / מגדל`->`One camera/tower`,
`שתי מצלמות`->`2 cameras` when building `master_dataset_2010_2026.csv`. The
sheet itself stays in Hebrew (source of truth); translation happens in the
script so it isn't a manual, easily-overwritten edit on the output file.

---

## `GLM_2020_original.R`

Yosef's original 2020 modeling script. For both species, fits GLMs (gaussian
family) on every candidate combination of predictors, then uses AIC
(AICc, via `MuMIn::model.sel()`) to select the best-supported model(s).
Uses `data.csv` for 2010-2020, then `data1.csv` for 2012-2020 (see that
file's entry above for the bug this introduced).

## `plot_2020_original.R`

Produces the counting-method boxplot figure and runs the car-vs-tower
significance test - see `data2_method_check_legacy.csv` above (not used in
this paper).

---

## `ringing_data_raw.xlsx` (local-only, not in git)
*(original filename: `Terns Data.xlsx`)*

Full raw ringing database from Yosef, obtained by Inbal specifically to
calculate `hirMASS`/`albMASS` for 2021-2026 (issue #3). 12 sheets; the
`Data` sheet is the individual-record master table (66,414 rows x 48 cols)
with a `Weight` column per capture.

**Kept out of git per Inbal** (`.gitignore`'d) - 11MB, well under GitHub's
limits, so this is a repo-hygiene preference, not a technical constraint.
Present locally in `data_raw/` for scripts to read, just never committed.

### `Data` sheet - column reference

66,414 rows x 48 columns, 2-row header. Standard European ringing-scheme
record format. One row = one encounter (ringing, retrap, or field
observation) of one bird.

**How to tell ringing/retrap apart from a field observation** (confirmed
with Inbal): only Yosef does the actual ringing/handling at Atlit. If the
`Ringer` column names anyone else, that row is a field observation (ring
read at a distance), not a capture. Also: `Wing`/`Weight` are only ever
populated when the bird was physically in hand - so a non-blank `Weight`
implies a real capture regardless of who's listed as ringer.

**`Rec` column (col 3) - confirmed with Inbal**:
- `R` = **recapture** (bird originally ringed at Atlit, caught again)
- blank = new ringing at Atlit
- `IL`, and other short codes (`A`, `F`, etc.) = the bird was ringed under a
  **different/foreign ringing scheme** - identifiable because the ring
  number format differs from Atlit's own numbering. `IL` likely marks a
  different Israeli scheme/ringer than Yosef's Atlit series, `A`/`F`-style
  codes are presumably other countries' scheme codes. These rows should
  line up with the (so far unseen populated) "Origin Ringing Data - only
  for foreign birds" column group (cols 32-36).
- Not yet confirmed: whether foreign-origin rows ever have `Wing`/`Weight`
  filled in (i.e. represent an actual in-hand control at Atlit) vs. always
  being blank (i.e. just a distant resighting report) - matters for
  filtering, since either way these aren't new Atlit ringing events.

**Confirmed columns**:

| # | Column | Meaning |
|---|---|---|
| 3 | `Rec` | Record type - see above: blank=new ringing, `R`=recapture, other codes=foreign-origin bird |
| 4-5 | `Ring` / `Number` | Metal ring prefix + serial number |
| 6 | `Species` | 6-letter code (genus3+species3). Found: `STEALB` (Little Tern), `STEHIR` (Common Tern), `STESAN` (Sandwich Tern), `STEREP` (White-cheeked Tern) |
| 7 | `Sex` | M/F/unknown |
| 8 | `Age` | Standard EURING age code. Confirmed with Inbal: values run up to 49 (not the typical 1-9) because terns can live ~20 years and EURING's known-hatch-year coding extends the scale accordingly for older known-age birds |
| 9 | `Wing` | Wing chord length (mm) - capture only |
| **10** | **`Weight`** | **Body mass (g) - capture only. The column this whole investigation (issue #5) is about** |
| 11-12 | `Date`/`Time` | Capture/observation date and time |
| 13-16 | `Place`/`Lat`/`Lon`/`Ringer` | Location, coordinates, person who handled/observed the bird |
| 17 | `Country` | Presumably blank = Israel |
| 18-19 | `Remarks`/`Net` | Free text / mist net number |
| 21-23 | `Subsp`/`Tail`/`Head` | Subspecies, tail length, head+bill length (mm) |

**Still uncertain, not yet confirmed with Inbal**:
- Col 1 (`Index`/`CR`, e.g. `WE83`) vs. col 20 (`CR`, e.g. `E83`) - two related "CR" (colour ring?) columns, guess: full code vs. code without a colour-prefix letter.
- Col 2 `Ring replace` (e.g. `+`) - flag for a replaced ring?
- Cols 24-29 (`Breeding`, `Character position` 1-4, `Colour`) - possibly encoding the colour-ring's design/lettering, unclear.
- Cols 32-36 (`Origin Ringing Data - only for foreign birds`) - self-explanatory label, blank in the rows checked so far.
- Cols 37-41 (`Old colour rings`, `Old metal rings`) - previous ring code, for birds that had a ring replaced?
- Cols 42-47 (`Oil (0-3)`: Head/Wings/UpperP/UnderP/Legs/Sum) - oil-contamination scoring by body region, fairly confident on this one.

### Mass analysis (issue #5) - see `scripts/02_mass_analysis.Rmd`

All mass-metric work (tasks 1-2 plus a follow-up refinement) is
consolidated in one knittable report, `scripts/02_mass_analysis.Rmd`
(rendered: `output/02_mass_analysis.html`) - superseding the former
`02_reverse_engineer_mass.R` / `03_breeding_mass.R` scripts (deleted).
Summary of what it contains and found:

- **Spring mass** (task 1, confirmed): `hirMASS`/`albMASS` = mean `Weight`
  of new (non-recapture) individuals caught in spring (March-May), per
  species per year. Reproduces the known 2012-2020 values almost exactly
  (r=0.9999, mean abs diff 0.45g). Single source for `hirMASS`/`albMASS`
  in `master_dataset_2010_2026.csv`, 2011-2026. Caveat - some years rest on
  very few individuals: `n` ranges from 1 (Little Tern, 2024) to 196
  (Common Tern, 2022).
- **Breeding-season mass** (task 2): restricted to June-July, as a proxy
  for actual breeders rather than passage migrants. Naively reusing the
  spring filter (new/non-recapture individuals) on the summer window does
  NOT work: summer catches are dominated by **this-year chicks/juveniles**
  (EURING age 1 = pullus, age 3 = this-calendar-year juvenile). E.g.
  Common Tern, July: 1,442 juveniles (age 3) vs. 1,808 adults (age 6).
  Fixed by excluding age 1 and 3, keeping only adult codes (4, 5, 6, and
  the two-digit known-exact-hatch-year codes, e.g. 14/22/25/28/29/35/37).
  Result: breeding-season adults weigh consistently less than spring
  arrivals (Common Tern ~7.8g lower, decoupled from spring value
  year-to-year, r=-0.03; Little Tern ~2.3g lower, more correlated with
  spring, r=0.57) - consistent with incubation/chick-rearing costs.
- **Confirmed-breeder spring mass** (follow-up, Inbal's request): any
  adult weighed in spring (new ringing OR in-hand recapture - not just
  first-time ringings, since Yosef's own spring parameter isn't restricted
  that way either) further flagged as a confirmed breeder if that ring was
  also recorded (recapture or resighting) in June/July of the same year -
  stronger evidence it stayed to breed. Matched by `RingPrefix`+`RingNum`.
  Caveat: 1,383 records sheet-wide are flagged `RingReplace` (physical ring
  changed), which breaks this matching for those individuals; also, since
  recaptures are included, the same individual can appear in more than one
  year's cohort (mild non-independence in the pooled tests). Result:
  **Common Tern** confirmed breeders (n=180) significantly lighter than
  Yosef's spring parameter / the general spring cohort (~4.5g, p<0.001,
  holds after controlling for year) - stable finding. **Little Tern**
  (n=86) shows NO significant difference in any test (p=0.32-0.62) - an
  earlier run that only counted first-time-ringed spring adults (n=40)
  had found a significant year-controlled effect (+1.57g, p=0.02), but
  that turned out to be a small-sample artifact once recaptures were
  correctly included - superseded, don't cite the old number.
- **Any-year variant** (task 2c, kept alongside task 2b, not yet decided
  which to use): confirms breeder status from a June/July sighting in
  *any* year (tern site fidelity - breeders return to the same colony
  repeatedly), not just the same year as the spring weighing. Roughly
  triples the confirmed sample. **Common Tern** n=490, effect unchanged
  (~4.4g lighter, year-controlled p=6.4e-17 - gets more significant with
  more data). **Little Tern** n=184, still no effect (year-controlled
  +0.11g, p=0.77) - consistent with relatively low Little Tern passage
  volume through Atlit, i.e. a genuine null rather than a power issue.
