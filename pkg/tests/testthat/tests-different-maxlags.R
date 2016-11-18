test_that("forecast works with maxlag = 1", {
  mod <- xgbar(Nile, maxlag = 1)
  expect_error(fc <- forecast(mod, h = 10), NA)
})


test_that("forecast works with maxlag = 12", {
  mod <- xgbar(AirPassengers, maxlag = 12)
  expect_error(fc <- forecast(mod, h = 10), NA)
})


test_that("forecast works with maxlag = 36", {
  mod <- xgbar(AirPassengers, maxlag = 36)
  expect_error(fc <- forecast(mod, h = 10), NA)
})



test_that("forecast works with maxlag = 50", {
  mod <- xgbar(AirPassengers, maxlag = 36)
  expect_error(fc <- forecast(mod, h = 10), NA)
})

