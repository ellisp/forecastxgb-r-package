test_that("forecast works with maxlag = 1", {
  mod <- xgbts(Nile, maxlag = 1)
  expect_error(fc <- forecast(mod, h = 10), NA)
})