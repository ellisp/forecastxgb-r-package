
test_that("differencing and decompose work togetherwith data with an irregular set of seasons", {
  y <- subset(Tcomp::tourism, "quarterly")[[36]]$x
  expect_error(mod1 <- xgbar(y, trend_method = "differencing", seas_method = "decompose"), NA)
  plot(forecast(mod1))
})
