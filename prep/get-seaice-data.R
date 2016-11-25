# This script gets the example Arctic sea ice data
library(dplyr)
library(testthat)
library(lubridate)

mon <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

# https://nsidc.org/data/docs/noaa/g02135_seaice_index/#daily_data_files

# This is the latest incomplete year's "near real time" data:
download.file("ftp://sidads.colorado.edu/DATASETS/NOAA/G02135/north/daily/data/NH_seaice_extent_nrt_v2.csv",
              destfile = "seaice_nrt.csv")

# And this is the earlier, fully definitive years' data
download.file("ftp://sidads.colorado.edu/DATASETS/NOAA/G02135/north/daily/data/NH_seaice_extent_final_v2.csv",
              destfile = "seaice_final.csv")

seaice_nrt <- read.csv("seaice_nrt.csv", skip = 2, header = FALSE)[ , 1:5]
seaice_final <- read.csv("seaice_final.csv", skip = 2, header = FALSE)[ , 1:5]

seaice <- rbind(seaice_final, seaice_nrt)
names(seaice) <- c("year", "month", "day", "extent", "missing")
expect_equal(sum(seaice$missing == 0), nrow(seaice))

seaice <- seaice %>%
  mutate(date = as.Date(paste(year, month, day, sep = "-"))) %>%
  group_by(month) %>%
  mutate(monthday = month + day / max(day)) %>%
  ungroup() %>%
  mutate(month = factor(month, labels = mon)) %>%
  arrange(year, month, day) %>%
  mutate(timediff = c(NA, diff(date)),
         dayofyear = yday(date)) %>%
  filter(timediff == 1)



seaice_ts <- ts(seaice$extent, frequency = 365.25, start = c(1987, 233))
save(seaice_ts, file = "pkg/data/seaice_ts.rda")

# clean up (unless you want to keep the csvs)
unlink("seaice_nrt.csv")
unlink("seaice_final.csv")  