
test_that("lagv produces the correct lagged matrix", {
  m <- cbind(6:10, 5:9, 4:8, 3:7, 2:6, 1:5)
  colnames(m) <- c("x", "x_lag1", "x_lag2", "x_lag3", "x_lag4", "x_lag5")
  x <- 1:10
  expect_equal(m, lagv(x, maxlag = 5))
})
