# Notes

## Source files (in `data_raw/`)

Copied from `Terns_Yosef_paper/re/` as received:

- `summary_2026.xlsx` (Yosef's `סיכום 2026.xlsx`) - chick counts, pair counts
  + method, ring-resighting effort, foreign recoveries, and a raw
  ring/species list (~8,460 records, sheet `גיליון1`), 2010-2025(/26).
- `data_2010-2020_legacy.csv` (`data.csv`) - the original 2010-2020 dataset
  used in the 2020 GLM analysis: weather, predation (yes/no), Newcastle
  disease (yes/no). Verified correct.
- `data1_2012-2020_legacy.csv` (`data1.csv`) - the original 2012-2020
  extended dataset (adds competition lag terms + body mass). **Contains a
  confirmed bug - see below.** Only the `hirMASS`/`albMASS` columns from this
  file are trusted and reused.
- `data2_method_check_legacy.csv` (`data2.csv`) - pair counts by counting
  method (car vs. camera/tower), underlies the boxplot figure
  (`איור השפעת שיטה על מספר זוגות.tiff`).
- `GLM_2020_original.R`, `plot_2020_original.R` - Yosef's original 2020
  scripts, kept for reference/comparison only. Not run directly - superseded
  by `scripts/01_replicate_2020_baseline.R`.

Not copied into this repo (left in the parent folder, reference only):
`סיכום 2020.pptx`/`.pdf` (the 2020 season-summary talk, source of the 2020
model-selection results quoted below), `ניטור שחפיות...2020.docx` (background
report), `הערות לניתוח מודלים.docx` (Yosef's candidate-predictor notes),
`סיכום 2020.xlsx` (superseded by `summary_2026.xlsx`).

## Known issue: `data1.csv` column bug

Checked numerically against `data.csv` (which is correct): the
`temp37/temp12/meanMAXtemp/meanMINtemp` block in `data1.csv` is shifted by
one column, **and the `predation` column in `data1.csv` does not contain
yes/no - it duplicates the (mislabeled) temperature value.** E.g. year 2012:
`data1.csv` has `predation = 17.7`; year 2013: `predation = 18.1`. These are
min-temperature values, not a predation flag.

Effect: every model in `GLM_2020_original.R` that includes `predation` in
the second half of the script (the 2012-2020 "9-year" models, both species)
was fit on a numeric temperature value mislabeled as `predation`, not the
real predation flag.

Fix applied in `scripts/00_build_dataset.R`: predation/Newcastle/weather for
2012-2020 are pulled from `data.csv` (verified correct) instead of
`data1.csv`. Only `hirMASS`/`albMASS`, which are not part of the shifted
block, are kept from `data1.csv`. The competition-lag terms
(`hirTWOyears`/`albTWOyears`) are recomputed directly from the chick counts
rather than trusted from either legacy file.

`scripts/01_replicate_2020_baseline.R` reruns the original model set on the
corrected data so we can see whether/how the reported top models change.
Compare its output to `סיכום 2020.pptx` slides 10 and 12, which reported (on
the buggy data):
- Little Tern (alb), 2012-2020: top model = interspecific competition alone
  (AICc weight 0.46); second = competition + cold temps (weight 0.28).
- Common Tern (hir), 2012-2020: competition + body condition + cold temps,
  more evenly split (~0.12-0.21 each).

## Known issue: counting-method confound

`data2.csv` / the boxplot figure show camera-tower pair counts running
noticeably higher than car-based counts for both species. The method
actually changed across the study period (see `pairs_method` column in
`master_dataset_2010_2026.csv`: car 2011-2013, camera/tower 2014-2020ish, car
again 2020-2021, two cameras 2023-2026). This means part of the apparent rise in
Common Tern pairs over time could be a detection-method artifact rather than
a true increase - relevant if Common Tern density/pair count is used as a
predictor of Little Tern breeding success, per Yosef's suggestion. Not yet
corrected for in any script.

## Open items (need input from Inbal / Yosef, not derivable from the files sent)

1. **2026 Little Tern chick count.** Per Yosef's email, `summary_2026.xlsx`
   is mostly a copy of the 2025 file - confirm/update the actual 2026 count
   (currently shows 4 in the sheet).
2. **Weather, predation, Newcastle-disease flags for 2021-2026.** Not present
   anywhere in the folder Yosef sent - `master_dataset_2010_2026.csv` has
   these as NA for those years. Needed to extend the GLM past 2020.
3. **Pre-breeding body mass (`hirMASS`/`albMASS`) for 2021-2026.** Also not
   present in `summary_2026.xlsx` - source unknown (data1.csv's values for
   2012-2020 presumably came from a separate ringing/biometrics database not
   included here).
4. **2022 pair counts** are missing in the source workbook itself
   (`מספר זוגות בעתלית - רב שנתי` sheet has a blank row for 2022). 2026 pair
   counts were added by Inbal directly to this sheet (2026-09-04): 1063
   Common Tern / 67 Little Tern pairs, two-cameras method.
5. **Density index for the paper's model.** Yosef suggested representing
   rising density (of Common Tern, and possibly of Little Tern on itself) as
   a predictor, e.g. a cumulative multi-year breeding-success index. Not yet
   designed - needs a deliberate decision, see README.

## Session log

### Session 1 (2026-09-03)
- Explored `Terns_Yosef_paper/re/` (Yosef's source folder), read every file
  (docx/pptx/pdf converted via LibreOffice, xlsx via `readxl`/`openpyxl`).
- Found and confirmed the `data1.csv` column-shift bug (see above).
- Set up this repo, `00_build_dataset.R` (builds `master_dataset.csv`,
  2010-2026, with 2021-2026 predictor gaps left as NA on purpose) and
  `01_replicate_2020_baseline.R` (reran Yosef's *original* 2012-2020 model
  set, unchanged, only with the bug fixed - NOT a new analysis, NOT extended
  to recent years, see "Known issue" above for why that's not possible yet).
- Result of that replication: fixing the bug changes Little Tern's top model
  from "competition alone" (2020 report, weight 0.46) to "predation +
  competition + heat" (weight 0.43, competition-alone now 2nd at 0.26).
  Caveat: n=9, weights are unstable at this sample size - a bug-check
  result, not a paper-ready finding. Worth flagging to Yosef.
- Started going through `data_raw/` file by file with Inbal (see
  `data_raw/README.md`, currently covers `data_2010-2020_legacy.csv` only).
  Confirmed with Inbal: `hir`/`alb` = chicks *ringed*; `predation` = at
  least one predation event that season (frequency not captured).
- Opened two GitHub issues:
  - [#1](https://github.com/Inbal-Schekler/Terns-population-crush-paper/issues/1)
    Extend master dataset to 2026 (chicks done; weather/predation/Newcastle/
    body-mass for 2021-2026 need to come from Yosef - no documentation of
    the original weather data source exists in any file sent, confirmed by
    search).
  - [#2](https://github.com/Inbal-Schekler/Terns-population-crush-paper/issues/2)
    Literature review on breeding-success predictors in terns/seabirds, to
    sanity-check the current predictor set and inform the density-index
    design.

### Session 2 (2026-09-04)
- Finished the file-by-file walkthrough of `data_raw/`: `data1.csv` bug
  (full mechanism + verified consequences on Yosef's 2020 results, incl. a
  demonstrated collinearity/NA case), `data2.csv` (not used in this paper,
  documented for reference only), the 3 relevant `summary_2026.xlsx` sheets,
  and both original R scripts. All in `data_raw/README.md`.
- Opened issue #3 (merge data.csv+data1.csv; reverse-engineer mass) and
  issue #4 (2026 numbers - Yosef's part and Inbal's part).
- Cleaned up file duplication: `re/`'s top-level copies of data.csv,
  data1.csv, data2.csv, GLM.R, plot.R, סיכום 2026.xlsx, Terns Data.xlsx
  deleted (verified byte-identical to `analysis/data_raw/` first) -
  `analysis/data_raw/` is now the single canonical copy.
- Inbal obtained the full raw ringing database from Yosef
  (`data_raw/ringing_data_raw.xlsx`, local-only/gitignored, 66k+ records
  with individual `Weight`). Documented its `Data` sheet's columns in
  `data_raw/README.md`, including the `Rec` column (blank=new ringing,
  `R`=recapture, other=foreign-origin bird) and the `Ringer` column trick
  (Yosef or Ohad Hatzofe = real capture; anyone else = field observation).
- Added Inbal's 2026 pairs count to the actual xlsx source (not just the
  output CSV) and moved the Hebrew->English `pairs_method` translation into
  `00_build_dataset.R` itself, so it's not a manual edit that silently gets
  overwritten on the next script run. Renamed output to
  `master_dataset_2010_2026.csv`.
- Opened issue #5 (mass investigation, 4 tasks). Completed task 1:
  `scripts/02_reverse_engineer_mass.R` confirmed Inbal's hypothesis (spring
  Mar-May mean weight, new/non-recapture individuals only) reproduces the
  known 2012-2020 hirMASS/albMASS almost exactly (r=0.9999). Used this to
  replace `master_dataset_2010_2026.csv`'s hirMASS/albMASS columns with a
  consistently-computed series covering 2011-2026 (previously NA outside
  2012-2020). Caveat: some years rest on very few individuals (Little Tern
  2011 n=2, 2024 n=1) - see `data_raw/README.md`.

### Session 3 (2026-09-06)
- Issue #5, task 2: breeding-only mass metric, `scripts/03_breeding_mass.R`.
  Discovered (before implementing, confirmed with Inbal) that a naive
  "new individuals caught in summer" filter is dominated by **this-year
  chicks/juveniles** (EURING age 1/3), not adults - e.g. Common Tern July:
  1,442 juveniles vs. 1,808 adults. Fixed by restricting to adult age codes
  only. Window: June-July (confirmed with Inbal), new/non-recapture
  individuals only, same convention as the spring metric.
  Result: breeding-season adults weigh consistently less than spring
  arrivals - Common Tern ~7.8g lower on average, weakly correlated with
  spring value (r=-0.03, i.e. the drop is a fairly constant offset,
  decoupled from year-to-year pre-breeding condition); Little Tern ~2.3g
  lower, more correlated with spring (r=0.57). Biologically consistent with
  incubation/chick-rearing costs. Output:
  `data_processed/breeding_mass_by_year_species.csv`,
  `output/03_breeding_mass.txt`. Not merged into
  `master_dataset_2010_2026.csv` - kept as a separate comparison metric per
  task 2's wording ("build a second version").

- Consolidated mass work into a single knittable report,
  `scripts/02_mass_analysis.Rmd` (renders to `output/02_mass_analysis.html`
  - requires pandoc; installed via `conda install -c conda-forge pandoc`
  into the miniconda3 env on this machine, no sudo needed). Deleted the
  now-superseded `02_reverse_engineer_mass.R` and `03_breeding_mass.R`
  (and their standalone `.txt` outputs) - same logic, now in the Rmd.
- Added a third mass metric (follow-up to task 2, Inbal's request):
  **confirmed-breeder spring mass** - spring-caught adults restricted to
  those also recorded (recapture or resighting) in June/July of the same
  year, as stronger evidence they stayed to breed at Atlit rather than
  passing through. Matched by ring number (`RingPrefix`+`RingNum`); caveat
  - 1,383 records sheet-wide are flagged `RingReplace`, which breaks this
  matching for those individuals (not corrected for).
  Compared against the full spring cohort three ways (Welch t-test,
  Wilcoxon, and a year-controlled linear model - added because the raw
  pooled comparison can be confounded by which years happen to have more
  confirmed-breeder records).

  **Revised (same session, per Inbal)**: the spring side of this metric
  originally reused task 1's `is_new`-only filter, so it only caught
  individuals ringed for the first time that spring. Changed to include
  **any** adult weighed in spring - new ringing or in-hand recapture -
  since Yosef's own parameter is about spring weight generally, not about
  first-time ringings specifically. Confirmed-breeder counts grew
  accordingly (Common Tern 113->180, Little Tern 40->86 - recaptured
  spring birds are more likely to also be seen again in summer, which
  makes sense for site-faithful local breeders). Findings with the
  corrected cohort:
  - **Common Tern**: confirmed breeders (n=180) still significantly
    lighter than Yosef's spring parameter / the general spring cohort
    (~4.5g lighter, p<0.001 in all three tests including year-controlled)
    - stable finding, unaffected by the recapture-inclusion fix.
  - **Little Tern**: confirmed breeders (n=86) show NO significant
    difference in any of the three tests (p=0.32-0.62, year-controlled
    effect shrank from +1.57g/p=0.02 to +0.48g/p=0.33). The earlier
    "significant year-controlled effect" reported before this fix was
    evidently an artifact of the smaller n=40 `is_new`-only sample, not a
    robust signal - superseded, do not cite the old +1.57g/p=0.02 number.

- **Task 2c added (same session, Inbal's request)**: a second version of
  the confirmed-breeder flag, based on tern site fidelity - a bird
  recorded in June/July of **any** year (not necessarily the same year as
  the spring weighing) counts as confirmed, since site-faithful breeders
  return to the same colony repeatedly. Kept side by side with task 2b
  (not replacing it) in `scripts/02_mass_analysis.Rmd` pending a decision
  on which definition to use. Results, same direction as 2b but with a
  much larger n (site fidelity relaxation roughly triples the confirmed
  sample):
  - **Common Tern**: n=490 (vs. 180 in 2b), still ~4.4g lighter,
    year-controlled p=6.4e-17 - effect gets *more* significant with more
    data, reinforcing it's real, not a small-sample artifact.
  - **Little Tern**: n=184 (vs. 86 in 2b), effect stays ~0 (year-controlled
    +0.11g, p=0.77) - more data did not surface a signal, consistent with
    Inbal's explanation that relatively few Little Terns pass through
    Atlit as migrants (i.e. there isn't much of a
    passing-through-vs-staying contrast to detect for this species in the
    first place, not a power problem).

- **Decided (2026-09-08, Inbal)**: use task 2c (any-year site-fidelity) as
  the confirmed-breeder definition for downstream analysis - "the broader
  thing... more right." Task 2b (same-year) kept in the Rmd for
  reference/transparency, not deleted, but not the one to build on.
- Added `hirMASS_breed`/`albMASS_breed` to `master_dataset_2010_2026.csv`
  (task 2c/any-year confirmed-breeder mean weight per year/species) - this
  had been computed and written to its own CSV but not merged into the
  master dataset; fixed per Inbal's request. NA where a species/year has
  no confirmed breeders (Little Tern 2024-2025).

- **Issue #5 task 3 done**: `scripts/03_mass_trends.Rmd` (renders to
  `output/03_mass_trends.html`). Per Inbal's request, extended beyond a
  single per-species trend to 3 groups per species: **Juvenile** (age 3,
  Jun-Aug), **Adult breeder** and **Adult non-breeder** (spring weight,
  task 2c any-year confirmed-breeder split). Individual-level
  `Weight ~ year` regression per group/species, plus a `Weight ~ year *
  group` interaction test to check whether the trend itself differs across
  groups. Striking result: **confirmed breeders show a significantly
  steeper mass decline than juveniles or non-breeders, in both species**:
  - Common Tern: breeder slope -0.55 g/year (p=1.6e-06); non-breeder -0.17
    g/year (p=0.007, much weaker); juvenile -0.11 g/year (p=0.16, not
    significant). Interaction p=0.0065 - the trends are genuinely
    different, not just noise.
  - Little Tern: breeder slope -0.24 g/year (p=0.007); non-breeder -0.11
    g/year (p=0.13, not significant); juvenile +0.09 g/year (p=0.27, not
    significant). Interaction p=0.030.
  This directly touches the paper's core question - breeding adults'
  body condition is declining over time specifically (not the population
  broadly), a plausible mechanistic link to the breeding-success collapse.
  Writes `data_processed/mass_trends_by_group.csv` and
  `data_processed/mass_trends_stats.csv`.
  - **Added same session**: a 4th group, **All adults (unsplit)** - the
    plain version of task 3 (spring adults, no breeder/non-breeder split),
    shown alongside the other 3 for reference but excluded from the
    interaction test (not a mutually-exclusive category vs. the split
    groups). Illustrates why the split matters: Common Tern's unsplit
    trend is -0.27 g/year (p=3.1e-06) - masks the much steeper -0.55
    g/year breeder-only decline. Little Tern unsplit: -0.16 g/year
    (p=0.0036).

- **Issue #5 task 4 done**: `scripts/04_within_season_mass.Rmd` (renders
  to `output/04_within_season_mass.html`). Scoped per Inbal: Little Tern
  gets only a pooled (no year-split) within-season check, since task 3
  found no year effect for this species; Common Tern gets the pooled
  check plus a check of whether the trajectory differs by year, motivated
  by a 2026 field observation (terns bringing fish they couldn't eat, not
  seen in prior years). Population = task 2c confirmed breeders; season
  window Jun-Aug (broader than task 2's Jun-Jul, to have an "early vs.
  late" contrast); x-axis = day-of-season (days since Jun 1).
  - Bug caught and fixed mid-build: `day_of_season` was initially computed
    as a `POSIXct - Date` difftime, which defaults to **seconds**, not
    days (readxl reads `Date` as POSIXct even with no time component) -
    coefficients were coming out as ~1e-9 g/"day". Fixed by coercing both
    sides to `Date` class before subtracting.
  - **Important data-availability finding**: a confirmed breeder only
    needs *any* Jun/Jul record (resighting counts); this task needs an
    actual **weighed** Jun-Aug record, which is much rarer. The most
    recent weighed within-season record for a confirmed Common Tern
    breeder is from **2023** - none in 2024, 2025, or 2026. Little Tern:
    one record in 2025, none in 2021/2023/2024/2026. **The 2026 field
    observation cannot currently be tested against mass data** - flagged
    prominently in the report rather than silently comparing 2023-vs-prior
    and implying it answers the 2026 question.
  - Results: Little Tern pooled slope -0.01 g/day (p=0.686, no pattern).
    Common Tern pooled slope **+0.14 g/day (p=0.0075)** - mass
    *increases* over the season (opposite of the original task
    hypothesis that incubation/chick-rearing costs would show up as a
    *decline*; plausibly pre-migration fattening by August instead).
    Year x day-of-season interaction (all years with data, 2010-2023):
    p=0.616, not significant, but likely underpowered (n=75 total,
    spread across 14 years).

- **Issue #6 done (2026-09-20, updated same day)**:
  `scripts/05_normalized_mass_trends.Rmd` (renders to
  `output/05_normalized_mass_trends.html`). Per Yosef's suggestion, re-ran
  issue #5 task 3's trend analysis using mass normalized to wing chord
  length instead of raw mass. **Common Tern** split into Juvenile / Adult
  breeder / Adult non-breeder as in task 3; **Little Tern adults kept as a
  single unsplit `Adult` group** (not breeder/non-breeder) - per Inbal,
  since #5 task 2 already found no significant mass difference between
  Little Tern breeders and non-breeders, so splitting an already-small
  sample here adds nothing (this matches the same choice made in #7). Two
  normalization methods computed side by side: **simple ratio**
  (`Weight/Wing`) and **SMI** (scaled mass index, Peig & Green 2009 -
  rescales each bird's mass to the group's mean wing length using an SMA
  slope fit per species x group on log-log axes). Also checked whether
  `Wing` itself trends over time per group, before normalizing.
  - **Wing itself trends upward over time in Common Tern non-breeders**
    (p=0.0015) **and Little Tern adults** (p=0.044, driven mostly by the
    non-breeder-like majority of that unsplit group) **and marginally in
    juveniles, but is flat in Common Tern confirmed breeders** (p=0.70).
    This matters: normalizing mass by a wing-length that's itself
    drifting will change the apparent trend more in non-breeders/
    juveniles than in true breeders.
  - **Result: this weakens the issue #5 headline finding for Common
    Tern specifically.** Under raw mass, Common Tern breeders showed the
    steepest decline and the year x group interaction was significant
    (p=0.0086 - breeders decline meaningfully faster than juveniles/
    non-breeders). Under **both** normalized metrics, that interaction is
    **no longer significant** (ratio p=0.064, SMI p=0.17). Reason:
    normalization made the Common Tern non-breeder and juvenile declines
    *larger and newly significant* (e.g. juvenile SMI slope -0.29 g/year,
    p=0.0003, vs. raw p=0.16 n.s.; non-breeder SMI p=1.6e-06 vs. raw
    p=0.007), so all three groups decline together rather than breeders
    standing out. Breeders themselves still decline significantly under
    every metric (SMI: -0.60 g/year, p=2e-05) - it's specifically the
    *breeder-is-different* claim that doesn't survive, not "mass is
    declining" generally.
  - **Little Tern (unsplit Adult vs. Juvenile)**: the Juvenile-vs-Adult
    interaction is significant under raw mass (p=0.018) but not under
    either normalized metric (ratio p=0.44, SMI p=0.11) - same pattern as
    Common Tern, normalization erases the interaction. The Adult group
    itself declines significantly under every metric (raw -0.16 g/year
    p=0.0044; ratio p=0.00027; SMI -0.28 g/year p=2.1e-05) - stronger and
    more significant than either the old breeder-only or non-breeder-only
    split, simply from the larger unsplit sample (n=406 vs. 182/224).
  - **Open interpretation question, not yet resolved**: is this telling
    us the raw-mass breeder-specific finding was partly a body-size
    artifact (i.e. wing-normalization is doing its job correctly and the
    true condition signal is a general decline, not breeder-specific)?
    Or is normalizing by a wing measurement that's itself drifting
    upward in non-breeders introducing noise/bias into exactly the
    groups being compared against breeders (i.e. the ratio/SMI approach
    is the artifact here)? Worth discussing with Yosef - this is a
    genuine methods fork, not a bug, and changes which claim the paper
    can make about breeders vs. the wider population. See also #7's
    finding that part of the Common Tern non-breeder decline itself may
    be a sampling-timing artifact, which complicates this further.
  - Writes `data_processed/normalized_mass_records.csv` and
    `data_processed/normalized_mass_trends_stats.csv`.

- **Issue #7 done (2026-09-20)**: `scripts/06_spring_timing_check.Rmd`
  (renders to `output/06_spring_timing_check.html`). Yosef raised whether
  measurement-timing effort affects the mass-decline finding - not having
  time to weigh every bird he catches. Confirmed with Inbal that *which*
  birds get weighed when time is short is effectively random (whenever he
  has a free moment), not targeted at particular individuals, so
  selection bias itself isn't a live concern. What this checks instead:
  whether *when within the spring season (Mar-May)* weighed birds were
  caught has drifted over the years, and whether that could explain (or
  mask) the mass-decline trend from issue #5 task 3. **Little Tern kept
  as a single unsplit `Adult` group throughout** (not breeder/non-breeder)
  - per Inbal, since #5 task 2 already found no significant mass
  difference between Little Tern breeders and non-breeders under either
  definition, so splitting an already-small sample here adds nothing.
  Common Tern still split into breeder/non-breeder.
  - **Within-season pattern**: mass *increases* with day-of-season within
    spring for Common Tern (non-breeder +0.131 g/day, p=1.75e-10; breeder
    +0.085 g/day, p=0.017) - later-spring birds are heavier. No pattern
    for Little Tern adults (+0.019 g/day, p=0.35, n.s.).
  - **Date shift**: the day-of-season of weighed birds has shifted
    significantly *earlier* over the years, in all 3 species x group
    combinations (Common Tern non-breeder -1.43 days/year p=1e-83; Common
    Tern breeder -0.41 days/year p=0.006; Little Tern adult -0.86
    days/year p=8.6e-11).
  - **Combined (within-season slope x date shift = implied yearly
    contribution to the mass trend), compared to the actual observed
    slope from issue #5 task 3** (Little Tern compared against task 3's
    "All adults (unsplit)" slope, -0.164 g/year, p=0.0036):
    - **Common Tern non-breeder: implied contribution -0.188 g/year vs.
      observed -0.173 g/year - effectively 108% of the observed
      non-breeder decline.** This significant secondary-group decline
      looks like it could be almost entirely a within-season timing
      artifact, not a real mass change.
    - **Common Tern breeder: implied contribution -0.034 g/year vs.
      observed -0.554 g/year - only 6.2%.** The breeder-specific decline
      (the paper's headline finding) is essentially untouched by this
      artifact.
    - **Little Tern adult: implied contribution -0.017 g/year vs.
      observed -0.164 g/year - 10.1%.** Small contribution, and the
      within-season slope itself isn't significant (p=0.35), so this is a
      low-confidence estimate - but either way it doesn't explain much of
      the Little Tern decline.
  - **Net read: good news for the paper's core claim.** The
    breeder-specific decline in Common Tern survives this check almost
    entirely intact, and the Little Tern decline (already the weaker of
    the two headline results) isn't meaningfully explained by timing
    either. What's newly suspect is the **Common Tern non-breeder decline
    specifically** - it may be largely a sampling-date artifact rather
    than a true trend. If anything this *strengthens* the
    breeder-vs-non-breeder contrast for Common Tern: it's not that
    breeders and non-breeders are both declining for the same reason, it's
    that breeders show a real decline while the non-breeder "decline" may
    be substantially artifactual - two genuinely different patterns, not
    one shared artifact.
  - Worth reconciling with #6: the wing-normalized (SMI) version made the
    Common Tern non-breeder decline larger and more significant
    (-0.386 g/year, p=1.58e-06) than raw mass. If that non-breeder decline
    is itself partly a timing artifact, its amplification under
    normalization deserves a second look before leaning on the #6
    interaction-test result too heavily - flagged for a future session,
    not resolved here.
  - Writes `data_processed/spring_timing_within_season_stats.csv`,
    `spring_timing_date_shift_stats.csv`, `spring_timing_combined_check.csv`.

- **Issue #8 done (2026-09-20)**: `scripts/07_summer_breeder_mass_trends.Rmd`
  (renders to `output/07_summer_breeder_mass_trends.html`). All mass-trend
  work so far (#5 task 3, #6, #7) used spring-caught adults with
  "confirmed breeder" status requiring a separate Jun/Jul sighting - a
  small, and in recent years very small, sample. This looks directly at
  adults caught **in the colony during Jun-Jul itself** - by construction
  all breeders, so **no breeder/non-breeder split** (single "Summer adult"
  group per species, matching how Little Tern is already treated
  everywhere else). **Includes recaptures as well as new ringings** (per
  Inbal - #5 task 2 only used new ringings). Much bigger and more evenly
  distributed sample: Common Tern n=1283 (vs. 485 spring-confirmed),
  Little Tern n=683 (vs. 406) - no coverage collapse in recent years the
  way the spring data had (see #7).
  - **Result: no significant mass trend at all, under any metric, for
    either species.** Common Tern: raw p=0.80, ratio p=0.45, SMI p=0.19.
    Little Tern: raw p=0.38, ratio p=0.19, SMI p=0.10. Slopes are all
    small and inconsistently signed (near zero, slightly positive for raw
    mass in both species) - visually flat/noisy year-to-year scatter, no
    directional pattern (see plot).
  - **This does not match the spring-based "confirmed breeder" decline**
    from #5 task 3 (Common Tern -0.55 g/year p=1.6e-06; Little Tern -0.24
    g/year p=0.007). Two very different pictures of "breeding adult mass
    over time" depending on how the breeding population is sampled -
    worth discussing directly with Yosef before deciding which one (if
    either) the paper should lead with. Possible explanations, none
    confirmed: (a) the spring "confirmed breeder" definition is itself
    capturing something real that a same-summer catch doesn't (e.g. early
    arrival condition specifically); (b) the spring-based decline is
    partly an artifact of its shrinking/changing sample (per #7's finding
    that timing drift explains ~100% of the Common Tern non-breeder
    decline - worth checking if something similar affects the breeder
    figure); (c) summer catch composition has its own uncontrolled
    variation (e.g. which sub-colony, which net, time within the 2-month
    window) that could be masking a real trend. Not resolved here -
    flagging as the key open question rather than picking one explanation.
  - Writes `data_processed/summer_breeder_mass_records.csv` and
    `data_processed/summer_breeder_mass_trends_stats.csv`.

- **Issue #9 done (2026-09-20)**: `scripts/08_summer_chick_mass_trends.Rmd`
  (renders to `output/08_summer_chick_mass_trends.html`). Same approach as
  #8 but for chicks: this-year juveniles (age 3), Jun-Aug (matching the
  established juvenile window, wider than #8's Jun-Jul adult window),
  **including recaptures as well as new ringings** (#5/#6 used new
  ringings only). n: Common Tern 1274, Little Tern 220 (with Wing).
  - **Common Tern: raw mass not significant (p=0.19), but both
    normalized metrics are** (ratio p=0.0005; SMI -0.29 g/year, p=0.0002)
    - matches #6's finding almost exactly (SMI -0.29 g/year, p=0.0003
      there too) despite the different sample (recaptures now included,
      slightly different n). Wing-normalization reveals a chick decline
      that raw mass alone doesn't detect for this species.
  - **Little Tern: no significant trend under any metric** (raw p=0.06,
    borderline positive; ratio p=0.30; SMI p=0.38). **Caveat: 2024 and
    2025 each have only n=1** - essentially no chick weight data for
    Little Tern in the last two years, so recent-year values are not
    meaningful on their own (visible as isolated high/low points in the
    plot, not a real signal).
  - Writes `data_processed/summer_chick_mass_records.csv` and
    `summer_chick_mass_trends_stats.csv`.

### Next session - pick up here
- **Issue #9 interpretation note (2026-09-20, not yet written into the
  issue as analysis, just discussed)**: wing-length normalization makes
  more sense for chicks than it does for adults, for a different reason
  than in the adult case. In adults, wing length is fixed structural
  size; in **growing chicks, wing chord is still lengthening through the
  nestling period, so it's effectively an age/developmental-stage proxy**
  - a chick caught in early June (short wing) weighs much less than one
  caught in August (long wing, near-fledging) for reasons that have
  nothing to do with condition. This means issue #9's raw-mass-vs-
  normalized-mass split for Common Tern (raw p=0.19 n.s., SMI/ratio
  p<0.001) isn't normalization introducing an artifact - it's raw mass
  being too noisy (dominated by which growth stage each year's catch
  happened to sample) to detect a real signal that normalization reveals.
  Strengthens confidence in the Common Tern chick decline being real.
  Considered but not done: checking whether the age-at-capture itself
  (mean chick wing length per year) has drifted over time, the same way
  #7 checked date-drift for adults - would help confirm this
  interpretation directly. Skipped this session per Inbal ("it's ok") -
  available to pick up later if useful.
- **Issue #9 data point worth flagging to Yosef**: Common Tern 2026 chick
  mean raw mass (110.4g, n=40) is the **4th-lowest of the 17 years on
  record** (2014, 2019, 2017 are lower; 2026 is close behind). Solid
  sample size, not a small-n fluke. Little Tern has **no 2026 chick
  weight data at all** (last Little Tern chick weights are from 2024,
  n=1 - see #9's n=1 caveat), so this specific "recent year is low"
  observation only applies to Common Tern.
- **Issue #8 follow-up**: reconcile the flat summer-breeder trend with
  the significant spring-confirmed-breeder decline from #5/#6/#7 - see
  note above. This is now the central open question for the mass-decline
  story and should probably be discussed with Yosef before more analysis
  variants are built.
- **Issue #7 follow-up**: reconcile the Common Tern non-breeder
  timing-artifact finding above with issue #6's SMI results before citing
  either in the paper - see the note above.
- **Issue #6 (new, 2026-09-20)**: decide with Yosef whether the
  breeder-specific decline (issue #5's headline result) or the
  general-decline-across-groups picture (what survives wing
  normalization) is the more defensible framing for the paper - see the
  issue #6 write-up above. This is a real open question, not resolved by
  this session's analysis alone.
- Issue #5 tasks 1-4 all done. Consider: does the 2026 fish-provisioning
  observation need a different proxy than ringing-database mass (e.g.
  field condition notes, chick weight/growth data) since no confirmed
  breeder has been weighed in-hand during summer since 2023?
- Whether the same confirmed-breeder refinement should also inform which
  individuals count toward the breeding-season (task 2) metric is still
  an open design question.
- Issue #1/#3 still need Yosef's input: weather/predation/Newcastle for
  2021-2026 (no documentation of his original data source found anywhere -
  need to ask him directly), and confirmation of the 2026 Little Tern chick
  count.
- Issue #2 (lit review) not started - can run independently whenever.
- Issue #4: still waiting on Yosef for the `סיכום טיבוע` 2026 column, and
  on the 2022 pairs gap.
