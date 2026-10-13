# ==============================================================================
# 01_build_weather_inb.R
#
# Builds data_raw/weather_inb_2010_2026.csv from raw IMS (ims.gov.il) 10-minute
# station data for עין כרמל (nearest station to Atlit) - self-computed
# temp37/temp12/meanMAXtemp/meanMINtemp/rainMAY/rainJUN, one consistent method
# across every year Inbal has downloaded raw data for. Originally built
# 2014-2026 only (as far as raw data went then - see NOTES.md Session 7);
# now extended to 2010-2026 now that the 2010-2013 raw files exist too.
#
# Raw files live OUTSIDE this repo (10-min data is large/not needed by anyone
# but this script) at the path below - same convention as before, nothing new.
#
# Method (matches Session 7, validated then against Yosef's real 2014-2020
# values - see NOTES.md and YOSEF_2020_ANALYSIS.md):
#   - timestamps in the raw files are UTC ("שעון עולמי"); convert to Israel
#     local time (Asia/Jerusalem - May/June is entirely within IDT, UTC+3)
#   - group into local calendar days; daily max = max of the per-row
#     "טמפרטורת מקסימום" column, daily min = min of "טמפרטורת מינימום",
#     daily rain = sum of "כמות גשם" over the day
#   - temp37 = count of May-June local days with daily max >= 37C (inclusive)
#   - temp12 = count of May-June local days with daily min < 12C (strict)
#   - meanMAXtemp / meanMINtemp = mean of daily max/min over May-June
#   - rainMAY / rainJUN = sum of daily rain within that calendar month
# ==============================================================================

library(dplyr)
library(lubridate)

raw_dir <- "/home/inbal/Desktop/SACO Inbal/Terns/Yosef_paper/Weather_data"
years <- 2010:2026

to_num <- function(x) suppressWarnings(as.numeric(ifelse(trimws(x) == "-", NA, x)))

read_year <- function(yr) {
  path <- file.path(raw_dir, paste0("data_", yr, ".csv"))
  df <- read.csv(path, skip = 1, header = FALSE, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE,
                  colClasses = "character",
                  col.names = c("station", "datetime_utc", "temp", "temp_max", "temp_min", "rain"))
  # some years use "-" for a missing 10-min reading (confirmed: e.g. 9/8908 rows in 2011) -
  # read everything as character first so that doesn't collide with bind_rows()'s type
  # checking across years, then convert the numeric columns explicitly here.
  df$temp <- to_num(df$temp)
  df$temp_max <- to_num(df$temp_max)
  df$temp_min <- to_num(df$temp_min)
  df$rain <- to_num(df$rain)
  df$year_source <- yr
  df
}

raw_all <- bind_rows(lapply(years, read_year))

daily <- raw_all %>%
  mutate(
    dt_utc = dmy_hm(datetime_utc, tz = "UTC"),
    dt_local = with_tz(dt_utc, tzone = "Asia/Jerusalem"),
    local_date = as_date(dt_local)
  ) %>%
  group_by(local_date) %>%
  summarise(daily_max = max(temp_max, na.rm = TRUE),
            daily_min = min(temp_min, na.rm = TRUE),
            daily_rain = sum(rain, na.rm = TRUE),
            .groups = "drop") %>%
  mutate(year = year(local_date), month = month(local_date))

may_jun <- daily %>% filter(month %in% c(5, 6))

weather_inb <- may_jun %>%
  group_by(year) %>%
  summarise(
    temp37_inb = sum(daily_max >= 37),
    temp12_inb = sum(daily_min < 12),
    meanMAXtemp_inb = round(mean(daily_max), 2),
    meanMINtemp_inb = round(mean(daily_min), 2),
    rainMAY_inb = round(sum(daily_rain[month == 5]), 1),
    rainJUN_inb = round(sum(daily_rain[month == 6]), 1),
    .groups = "drop"
  ) %>%
  arrange(year)

stopifnot(nrow(weather_inb) == length(years), all(years %in% weather_inb$year))

out_path <- "data_raw/weather_inb_2010_2026.csv"
write.csv(weather_inb, out_path, row.names = FALSE)
cat("Wrote", out_path, "\n")
print(weather_inb, n = Inf)
