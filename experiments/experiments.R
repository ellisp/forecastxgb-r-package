library(forecastxg)

fc1 <- forecast(AirPassengers, level = FALSE)

object <- xgbts(AirPassengers, maxlag = 30)
plot.xgbts(object)

fc2 <- forecast.xgbts(object)
plot(fc2)
plot(fc1)

fc1$mean
fc2$mean
fc2$x
fc1$x

names(fc1)

class(fc1$x)
class(fc2$x)
class(fc1$mean)
class(fc2$mean)
frequency(fc1$mean)
frequency(fc2$mean)
fc1$fitted
fc2$fitted
fc1$model
fc2$model
fc1$x
fc2$x
fc1$method
fc2$method
plot(fc1)
plot(fc2)



