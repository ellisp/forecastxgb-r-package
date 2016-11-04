
test_that("lagv produces the correct lagged matrix", {
  m <- cbind(6:10, 5:9, 4:8, 3:7, 2:6, 1:5)
  colnames(m) <- c("x", "x_lag1", "x_lag2", "x_lag3", "x_lag4", "x_lag5")
  x <- 1:10
  expect_equal(m, lagv(x, maxlag = 5))
})


test_that("lagvm produces the correct lagged matrix", {
  m <- cbind(3:4, 2:3, 1:2, 13:14, 12:13, 11:12)
  test <- cbind(1:4, 11:14)
  expect_equal(m, lagvm(test, maxlag = 2))
})