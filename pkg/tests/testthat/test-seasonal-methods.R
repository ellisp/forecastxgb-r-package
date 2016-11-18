
test_that("different seasonal methods give different results", {
  y <- AirPassengers
  
  
  set.seed(123)
  obj1 <- xgbar(y, seas_method = "dummies")
  set.seed(123)
  obj2 <- xgbar(y, seas_method = "dummie")
  set.seed(123)  
  obj3 <- xgbar(y, seas_method = "decompose")
  expect_equal(obj1, obj2)
  expect_false(isTRUE(all.equal(obj1, obj3)))
  expect_lt(accuracy(obj3$fitted, obj2$fitted)[ , "RMSE"], 8)
})