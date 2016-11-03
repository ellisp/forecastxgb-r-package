library(forecastxg)

fc1 <- forecast(AirPassengers)

object <- xgbts(AirPassengers, maxlag = 12)
fc2 <- forecast.xgbts(object)

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



