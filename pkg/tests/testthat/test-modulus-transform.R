
test_that("Modulus transform and inverse work", {
  lambda <- BoxCox.lambda(AirPassengers)
  trans1 <- JDMod(AirPassengers, lambda = lambda)
  trans2 <- BoxCox(AirPassengers, lambda = lambda) # should be similar, not identical
  expect_lt(accuracy(trans1, trans2)[ ,"RMSE"], 0.002)
  
  return1 <- InvJDMod(trans1, lambda = lambda)
  expect_equal(AirPassengers, return1)
})

test_that("Modulus transform works with negative and zero data", {
  y <- ts(round(rnorm(100), 1))
  lambda <- BoxCox.lambda(abs(y))
  expect_error(trans1 <- JDMod(y, lambda = lambda), NA)
  expect_error(return1 <- InvJDMod(trans1, lambda = lambda), NA)
  expect_equal(y, return1)
})
  