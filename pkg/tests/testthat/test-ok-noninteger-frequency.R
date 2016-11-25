

test_that("xgbar can fit models to time series with a non-integer frequency", {
  expect_error(model <- xgbar(seaice_ts, maxlags = 366), NA)  
})



