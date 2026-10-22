# ==============================================================================
# 02_build_sst_inb.py
#
# Builds data_raw/sst_inb_2010_2026.csv: sea surface temperature near Atlit,
# from Copernicus Marine (CMEMS) satellite L4 SST, Mediterranean Sea,
# reprocessed, daily, 0.05 deg - dataset
# cmems_SST_MED_SST_L4_REP_OBSERVATIONS_010_021 (variable analysed_sst).
#
# Flagged as a candidate predictor in issue #2's literature review ("sea
# surface temperature" missing from the current predictor set) - added at
# Inbal's request after finding the Copernicus Marine dataset herself.
#
# Point: nearest grid cell to Atlit (32.69N, 34.94E) -> snaps to 32.68N,
# 34.92E (just offshore). Window: May-June each year, matching every other
# weather variable (temp37/temp12/meanMAXtemp/etc.) already in
# master_dataset. Requires `copernicusmarine login` to have been run once
# already (credentials cached in ~/.copernicusmarine/) - this script
# re-downloads via the Python API each time it's run, so it stays
# reproducible without a manual UI step (unlike the IMS air-temp download,
# which has no API and has to be pulled by hand - see
# scripts/01_build_weather_inb.R).
# ==============================================================================

import copernicusmarine
import xarray as xr
import pandas as pd
import os

RAW_DIR = "data_raw"
if not os.path.isdir(RAW_DIR):
    RAW_DIR = "../data_raw"
assert os.path.isdir(RAW_DIR)

NC_PATH = "/tmp/atlit_sst_2010_2026.nc"

copernicusmarine.subset(
    dataset_id="cmems_SST_MED_SST_L4_REP_OBSERVATIONS_010_021",
    variables=["analysed_sst"],
    minimum_longitude=34.94, maximum_longitude=34.94,
    minimum_latitude=32.69, maximum_latitude=32.69,
    start_datetime="2010-01-01T00:00:00",
    end_datetime="2026-09-30T23:59:59",
    output_filename=os.path.basename(NC_PATH),
    output_directory=os.path.dirname(NC_PATH),
    overwrite=True,
)

ds = xr.open_dataset(NC_PATH)
df = ds["analysed_sst"].squeeze().to_dataframe().reset_index()[["time", "analysed_sst"]]
df["sst_c"] = df["analysed_sst"] - 273.15
df["year"] = df["time"].dt.year
df["month"] = df["time"].dt.month

may_jun = df[df["month"].isin([5, 6])]

summary = (
    may_jun.groupby("year")["sst_c"]
    .agg(meanSST_inb="mean", meanMAXsst_inb="max", meanMINsst_inb="min")
    .round(2)
    .reset_index()
)

out_path = os.path.join(RAW_DIR, "sst_inb_2010_2026.csv")
summary.to_csv(out_path, index=False)
print("Wrote", out_path)
print(summary.to_string(index=False))
