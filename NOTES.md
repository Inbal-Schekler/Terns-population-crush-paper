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

### Next session - pick up here
- Continue the file-by-file walkthrough in `data_raw/README.md`:
  `data1_2012-2020_legacy.csv` next (has the bug - good one to walk through
  the fix on), then `data2_method_check_legacy.csv`, then the
  `summary_2026.xlsx` sheets.
- Nothing blocking - can also start issue #2 (lit review) independently
  whenever, or wait until file walkthrough is done.
