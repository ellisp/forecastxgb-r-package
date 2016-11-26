library(forecastxgb)
library(dplyr)
library(ggplot2)
library(gridExtra)
# rubbish at picking trends.  Why?

#--------simulated data--------------
y <- ts(1:100 * rnorm(100, 1, 0.01), frequency = 1)
plot(y)


mod1 <- auto.arima(y)
mod2 <- naive(y,h = 20)
mod3 <- ets(y)
mod4 <- nnetar(y)
p1 <- autoplot(forecast(mod1, h = 20))
p2 <- autoplot(forecast(mod2, h = 20))
p3 <- autoplot(forecast(mod3, h = 20))
p4 <- autoplot(forecast(mod4, h = 20))

grid.arrange(p1, p2, p3, p4)


mod5 <- xgbar(y, maxlag = 8)
fc5 <- forecast(mod5, h = 20)
p5 <- autoplot(fc5)
p5
fc5$newx
names(fc5)


grid.arrange(p1, p3, p4, p5)

#----------------real data--------------
mod1 <- xgbar(AirPassengers, seas_method = "fourier", trend_method = "differencing")
mod2 <- xgbar(AirPassengers, seas_method = "dummies", trend_method = "differencing")
mod3 <- xgbar(AirPassengers, seas_method = "decompose", trend_method = "differencing")
mod4 <- xgbar(AirPassengers, seas_method = "fourier", trend_method = "none")
mod5 <- xgbar(AirPassengers, seas_method = "dummies", trend_method = "none")
mod6 <- xgbar(AirPassengers, seas_method = "decompose", trend_method = "none")
mod7 <- xgbar(AirPassengers, seas_method = "fourier", trend_method = "differencing", lambda = 1)
mod8 <- xgbar(AirPassengers, seas_method = "dummies", trend_method = "differencing", lambda = 1)
mod9 <- xgbar(AirPassengers, seas_method = "decompose", trend_method = "differencing", lambda = 1)



fc1 <- forecast(mod1, h = 24)
fc2 <- forecast(mod2, h = 24)
fc3 <- forecast(mod3, h = 24)
fc4 <- forecast(mod4, h = 24)
fc5 <- forecast(mod5, h = 24)
fc6 <- forecast(mod6, h = 24)
fc7 <- forecast(mod7, h = 24)
fc8 <- forecast(mod8, h = 24)
fc9 <- forecast(mod9, h = 24)


plot(fc1)
plot(fc2)
plot(fc3)
plot(fc4)
plot(fc5)
plot(fc6)
plot(fc7)
plot(fc8)
plot(fc9)



mod9 <- xgbar(AirPassengers, seas_method = "decompose", trend_method = "differencing")
fc9 <- forecast(mod9, h = 24)
plot(fc9)
