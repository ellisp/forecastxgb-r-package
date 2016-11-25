

test_that("xgbar can fit models to time series with a non-integer frequency", {
  expect_error(model1 <- xgbar(seaice_ts, seas_method = "dummies"), NA)
  expect_error(model2 <- xgbar(seaice_ts, seas_method = "decompose"), NA)
  expect_error(model3 <- xgbar(seaice_ts, seas_method = "none"), NA)  
  expect_error(model4 <- xgbar(seaice_ts, seas_method = "fourier", maxlag = 50), NA)  
})

test_that("models fit with non-integer frequency work for forecasts",{
 expect_error(fc1 <- forecast(model1, h = 100), NA)
 expect_error(fc2 <- forecast(model2, h = 100), NA)
 expect_error(fc3 <- forecast(model2, h = 100), NA) 
 expect_error(fc4 <- forecast(model2, h = 100), NA) 
})


