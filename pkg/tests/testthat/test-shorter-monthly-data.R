
test_that("works with series of 35 with frequency 12", {
  bla_1 <- ts(runif(35, min = 5000, max = 10000), start = c(2013,12), frequency = 12)
  expect_error(bla_1_XGB_model <- xgbts(y = bla_1), NA)
})