fc1 <- forecast(AirPassengers, level = FALSE)
object <- xgbts(AirPassengers, maxlag = 30)
fc2 <- forecast.xgbts(object)


expect_identical(fc1$x, fc2$x)
expect_identical(class(fc1$x), class(fc2$x))
expect_identical(class(fc1$mean), class(fc2$mean))
expect_identical(frequency(fc1$mean), frequency(fc2$mean))




