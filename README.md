# Terns, population crash paper

Analysis repo for a paper on the collapse in Little Tern (*Sternula albifrons*,
"alb") breeding success at the Atlit salt pans, Israel, and its relationship
to the concurrent rise in Common Tern (*Sterna hirundo*, "hir") numbers and
breeding success. Joint work with Yosef Kiat, continuing an analysis he first
ran in 2020.

## The headline pattern

Little Tern chicks ringed per year (2010-2025/26) fell from double/triple
digits in most years up to 2019 to single digits in 2023-2026, while the
number of breeding **pairs** has stayed roughly flat (~105-240) over the same
period. So this isn't (yet) a collapse in adults showing up to breed - it's a
collapse in their ability to fledge chicks. Over the same period Common Tern
pairs rose roughly 3x (430 -> ~1,300).

## Repo layout

```
data_raw/                     Source files as received from Yosef (do not edit in place)
data_processed/               Derived, tidy datasets - shared by both analyses below
scripts/00_build_dataset.R    Builds the shared master dataset (run first)
survival_analysis/
  yosef_analysis/              Yosef's original 2020 GLM/AICc breeding-success model,
                                kept for reference, plus our bug-fixed replication of it
mass_analysis/
  scripts/                    Mass-trend Rmd reports, numbered in run order (issues #5-#10)
  output/                     Rendered reports + figures for the mass analysis
  docs/                       Narrative summary of the mass-decline findings
```

## Scripts

- `scripts/00_build_dataset.R` - builds
  `data_processed/master_dataset_2010_2026.csv`, one row per year
  (2010-2026), combining chick counts, pair counts +
  counting method, weather, predation/Newcastle-disease flags, and
  pre-breeding body mass. See NOTES.md for exactly which source each column
  comes from and which years are still missing data.
- `survival_analysis/yosef_analysis/01_replicate_2020_baseline.R` - reproduces
  Yosef's original 2020 GLM / AICc model-selection analysis (his original
  script, kept alongside for reference: `GLM_2020_original.R`,
  `plot_2020_original.R`) on the corrected dataset, as a sanity check before
  extending or changing the modeling approach. See NOTES.md for the data bug
  this corrects - fixing it flips Little Tern's reported top model from
  "competition alone" to "predation + competition + heat" (n=9, weights
  unstable at that sample size - a bug-check result, not yet a paper-ready
  finding). Rendered result:
  `survival_analysis/yosef_analysis/output/01_replication_results.txt`. This
  is the starting point for choosing better parameters for the new survival
  analysis, not the new analysis itself.
- `mass_analysis/scripts/02_mass_analysis.Rmd` - knittable report building and comparing
  three mass metrics from the raw ringing database
  (`data_raw/ringing_data_raw.xlsx`, local-only), issue #5 tasks 1-2 plus a
  follow-up refinement:
  1. **Spring mass** - mean `Weight` of new individuals caught Mar-May.
     Reproduces the known 2012-2020 `hirMASS`/`albMASS` almost exactly
     (r=0.9999). Writes `data_processed/spring_mass_by_year_species.csv`
     and updates `master_dataset_2010_2026.csv`'s `hirMASS`/`albMASS`.
  2. **Breeding-season mass** - mean `Weight` of new **adult** individuals
     caught Jun-Jul (excluding EURING age 1/3, i.e. nestlings/this-year
     juveniles - essential, since unfiltered summer catches are dominated
     by chicks). Writes `data_processed/breeding_mass_by_year_species.csv`.
     A separate, comparison metric - not merged into `hirMASS`/`albMASS`.
  3. **Confirmed-breeder spring mass** - any adult weighed in spring (new
     ringing or recapture) further flagged as confirmed if also recorded
     (recapture or resighting) in Jun/Jul, as stronger evidence it stayed
     to breed rather than passing through. Two definitions in the Rmd, both
     kept for transparency: **2b (same-year)** requires the Jun/Jul
     sighting in the *same* year as the spring weighing; **2c (any-year,
     chosen definition as of 2026-09-08)** accepts a Jun/Jul sighting from
     *any* year, on the theory that terns are site-faithful and repeatedly
     return to the same colony - use this one for downstream analysis.
     Compared statistically (t-test, Wilcoxon, and a
     year-controlled linear model) against Yosef's spring parameter in
     both cases. Common Tern confirmed breeders are significantly lighter
     under both definitions (2b: n=180, ~4.5g, p<0.001; 2c: n=490, ~4.4g,
     p as low as 6e-17 - gets *more* significant with the larger any-year
     sample). Little Tern shows no significant difference under either
     (2b: n=86, p=0.32-0.62; 2c: n=184, p=0.61-0.77) - consistent with
     relatively low Little Tern passage volume through Atlit. Writes
     `data_processed/confirmed_breeder_spring_mass.csv` and adds
     `hirMASS_breed`/`albMASS_breed` to `master_dataset_2010_2026.csv`
     (task 2c/any-year values; NA for species/years with no confirmed
     breeders, e.g. Little Tern 2024-2025).

  Rendered report: `mass_analysis/output/02_mass_analysis.html`. Supersedes the former
  `02_reverse_engineer_mass.R` / `03_breeding_mass.R` scripts (deleted -
  logic now consolidated here so results/code/narrative are in one file).

- `mass_analysis/scripts/03_mass_trends.Rmd` - issue #5 task 3 (mass-vs-year trend),
  extended per Inbal's request to compare 4 groups per species: Juvenile
  (age 3, Jun-Aug), Adult breeder, Adult non-breeder (spring weight, task
  2c any-year confirmed-breeder split), and All adults (unsplit, the plain
  version of task 3, shown for reference). Individual-level
  `Weight ~ year` regression per group, plus a `Weight ~ year * group`
  interaction test (breeder/non-breeder/juvenile only - unsplit adults
  excluded, not a mutually-exclusive category). Finding: confirmed
  breeders show a significantly steeper mass decline than
  juveniles/non-breeders in both species (interaction p=0.0065 Common
  Tern, p=0.030 Little Tern); the unsplit trend masks this (Common Tern
  unsplit -0.27 g/year vs. breeder-only -0.55 g/year) - see NOTES.md for
  full slopes/p-values. Rendered report: `mass_analysis/output/03_mass_trends.html`.
  Writes `data_processed/mass_trends_by_group.csv` and
  `data_processed/mass_trends_stats.csv`.
- `mass_analysis/scripts/04_within_season_mass.Rmd` - issue #5 task 4 (within-season
  mass trajectory for task 2c confirmed breeders, Jun-Aug window). Little
  Tern: pooled check only (no year split, per task 3's null year result) -
  no within-season pattern (slope -0.01 g/day, p=0.686). Common Tern:
  pooled check plus year-interaction check - mass *increases* over the
  season (+0.14 g/day, p=0.0075, opposite of the original
  incubation-cost hypothesis), year interaction not significant (p=0.616)
  but likely underpowered (n=75 across 14 years). **Key caveat**: no
  confirmed breeder has a weighed Jun-Aug record after 2023, so the 2026
  field observation motivating this task (fish provisioning that birds
  couldn't eat) cannot currently be tested against mass data - see
  NOTES.md. Rendered report: `mass_analysis/output/04_within_season_mass.html`. Writes
  `data_processed/within_season_mass_records.csv`.

- `mass_analysis/scripts/05_normalized_mass_trends.Rmd` - issue #6 (follow-up to issue #5
  task 3, per Yosef's suggestion): re-runs the mass-trend analysis using
  mass normalized to wing chord length instead of raw mass. Common Tern
  split into Juvenile/Adult breeder/Adult non-breeder as usual; **Little
  Tern adults kept as a single unsplit `Adult` group** (no significant
  breeder/non-breeder mass difference per #5 task 2, matching the same
  choice in #7). Two methods side by side - simple ratio (`Weight/Wing`)
  and SMI (scaled mass index, Peig & Green 2009, log-log SMA regression fit
  per species x group). **Result: weakens the issue #5 headline finding for
  Common Tern** - the year x group interaction (breeders declining faster
  than non-breeders/juveniles) is significant under raw mass (p=0.0086) but
  **not significant under either normalized metric** (ratio p=0.064, SMI
  p=0.17) - normalization makes the non-breeder/juvenile declines newly
  significant too, so breeders no longer stand out. Same pattern for Little
  Tern's Juvenile-vs-Adult interaction (raw p=0.018, ratio p=0.44, SMI
  p=0.11). Breeders/adults still decline significantly under every metric
  on their own, just not distinguishably faster than juveniles anymore.
  Open question for Yosef: is this the normalization correctly removing a
  body-size artifact, or introducing noise from a wing measurement that's
  itself drifting upward over time in non-breeders (p=0.0015 CT, p=0.044
  LT) but flat in Common Tern breeders (p=0.70)? See NOTES.md for full
  numbers, and #7 for a related complication (part of the Common Tern
  non-breeder decline may itself be a sampling-timing artifact). Rendered
  report: `mass_analysis/output/05_normalized_mass_trends.html`. Writes
  `data_processed/normalized_mass_records.csv` and
  `data_processed/normalized_mass_trends_stats.csv`.

- `mass_analysis/scripts/06_spring_timing_check.Rmd` - issue #7 (follow-up to issue #5
  task 3, per Yosef): checks whether *when within the spring season
  (Mar-May)* mass measurements happen has shifted over the years, and
  whether that could explain the mass-decline trend. (Selection of *which*
  birds get weighed when time is short is confirmed random, not a bias
  concern.) Common Tern split into breeder/non-breeder as usual; **Little
  Tern kept as a single unsplit `Adult` group**, since #5 task 2 found no
  significant breeder/non-breeder mass difference for that species.
  **Result: good news for the paper's headline finding.** The day-of-season
  of weighed birds has shifted significantly earlier every year in all
  three groups, and mass increases with day-of-season in Common Tern - so
  timing drift could in principle explain part of a decline. But quantified
  per group, it accounts for only **6.2% of the Common Tern breeder
  decline** and **10.1% of the Little Tern adult decline** (the paper's
  core claims are essentially untouched) - while it accounts for **~108%
  of the Common Tern non-breeder decline**, meaning that secondary-group
  result looks like it may be mostly a sampling-date artifact rather than
  real. See NOTES.md for full numbers and a flagged follow-up (reconcile
  with #6's SMI results, where the non-breeder decline became more
  prominent). Rendered report: `mass_analysis/output/06_spring_timing_check.html`. Writes
  `data_processed/spring_timing_within_season_stats.csv`,
  `spring_timing_date_shift_stats.csv`, `spring_timing_combined_check.csv`.

- `mass_analysis/scripts/07_summer_breeder_mass_trends.Rmd` - issue #8 (follow-up to
  #5/#6/#7): looks directly at adults caught **in the colony during Jun-Jul**
  (new ringings + recaptures), rather than spring-caught "confirmed
  breeders." By construction these are all breeders, so no breeder/non-
  breeder split - single "Summer adult" group per species. Much bigger,
  steadier sample than the spring-confirmed-breeder metric (Common Tern
  n=1283 vs. 485; Little Tern n=683 vs. 406), no coverage collapse in
  recent years. **Result: no significant mass trend at all, under raw
  mass, ratio, or SMI, for either species** (all p>0.10) - flat, noisy
  year-to-year scatter. **This does not match the significant
  spring-confirmed-breeder decline from #5/#6** (Common Tern -0.55 g/year
  p=1.6e-06; Little Tern -0.24 g/year p=0.007) - two different pictures of
  breeding-adult mass depending on how the breeding population is sampled.
  Not resolved - flagged as the central open question for the mass-decline
  story, worth discussing with Yosef before further analysis variants.
  See NOTES.md for possible explanations considered. Rendered report:
  `mass_analysis/output/07_summer_breeder_mass_trends.html`. Writes
  `data_processed/summer_breeder_mass_records.csv`,
  `summer_breeder_mass_trends_stats.csv`.

- `mass_analysis/scripts/08_summer_chick_mass_trends.Rmd` - issue #9 (same approach as
  #8, for chicks): this-year juveniles (age 3), Jun-Aug (matching the
  juvenile window from #5/#6, wider than #8's adult Jun-Jul window),
  including recaptures as well as new ringings. n: Common Tern 1274,
  Little Tern 220 (with Wing). **Common Tern: raw mass not significant
  (p=0.19), but both normalized metrics are** (ratio p=0.0005; SMI -0.29
  g/year, p=0.0002) - matches #6's finding almost exactly. **Little Tern:
  no significant trend under any metric** - and 2024/2025 each have only
  n=1, so recent Little Tern chick values aren't meaningful on their own.
  Rendered report: `mass_analysis/output/08_summer_chick_mass_trends.html`. Writes
  `data_processed/summer_chick_mass_records.csv`,
  `summer_chick_mass_trends_stats.csv`.

- `mass_analysis/scripts/09_summer_adult_within_season.Rmd` - issue #10 (re-asks #5 task
  4 on #8's better-covered summer-adult population): does adult mass
  change over the course of the summer? Two windows run separately, Jun-Jul
  and Jun-Aug. **Common Tern: mass increases significantly over the season
  in both windows** (Jun-Jul +0.074 g/day p=0.0003; Jun-Aug +0.139 g/day
  p=1.5e-30) - matches #5 task 4's old finding almost exactly, now far more
  significant with the bigger sample. The within-season pattern is fairly
  consistent year to year through July (interaction p=0.115) but less so
  once August is included (interaction p=0.0121). **Little Tern: no
  significant pooled trend in either window** (both weakly negative,
  p=0.09-0.07), consistent with #5 task 4's old null result. Rendered
  report: `mass_analysis/output/09_summer_adult_within_season.html`. Writes
  `data_processed/summer_adult_within_season_pooled_stats.csv`,
  `summer_adult_within_season_interaction_stats.csv`.

- `mass_analysis/scripts/10_mass_decline_summary.Rmd` - consolidates every mass result
  from issues #5-#10 into one normalized-only (ratio + SMI) report:
  spring breeder-vs-migrant gap, spring breeder mass over years, summer
  adult mass over years, within-season trajectory (Jun-Jul), and chick
  mass over years - each with a sample-size table, significance test,
  and a test of whether the most recent year deviates from the
  historical trend. Rendered report:
  `mass_analysis/output/10_mass_decline_summary.html`. Narrative summary with embedded
  plots/tables: `mass_analysis/docs/mass_decline_summary.md`.

Run from the `analysis/` directory:

```r
Rscript scripts/00_build_dataset.R
Rscript survival_analysis/yosef_analysis/01_replicate_2020_baseline.R
rmarkdown::render("mass_analysis/scripts/02_mass_analysis.Rmd", output_dir = "mass_analysis/output")
rmarkdown::render("mass_analysis/scripts/03_mass_trends.Rmd", output_dir = "mass_analysis/output")
rmarkdown::render("mass_analysis/scripts/04_within_season_mass.Rmd", output_dir = "mass_analysis/output")
rmarkdown::render("mass_analysis/scripts/05_normalized_mass_trends.Rmd", output_dir = "mass_analysis/output")
rmarkdown::render("mass_analysis/scripts/06_spring_timing_check.Rmd", output_dir = "mass_analysis/output")
rmarkdown::render("mass_analysis/scripts/07_summer_breeder_mass_trends.Rmd", output_dir = "mass_analysis/output")
rmarkdown::render("mass_analysis/scripts/08_summer_chick_mass_trends.Rmd", output_dir = "mass_analysis/output")
rmarkdown::render("mass_analysis/scripts/09_summer_adult_within_season.Rmd", output_dir = "mass_analysis/output")
rmarkdown::render("mass_analysis/scripts/10_mass_decline_summary.Rmd", output_dir = "mass_analysis/output")
```

See `NOTES.md` for data provenance, known issues, and open items.
