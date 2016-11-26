


model1 <- xgbar(AirPassengers, maxlag = 24, trend_method = "none", seas_method = "dummies")
model2 <- xgbar(AirPassengers, maxlag = 24, trend_method = "none", seas_method = "decompose")
model3 <- xgbar(AirPassengers, maxlag = 24, trend_method = "none", seas_method = "fourier")
model4 <- xgbar(AirPassengers, maxlag = 24, trend_method = "none", seas_method = "none")

model5 <- xgbar(AirPassengers, maxlag = 24, trend_method = "differencing", seas_method = "dummies")
model6 <- xgbar(AirPassengers, maxlag = 24, trend_method = "differencing", seas_method = "decompose")
model7 <- xgbar(AirPassengers, maxlag = 24, trend_method = "differencing", seas_method = "fourier")
model8 <- xgbar(AirPassengers, maxlag = 24, trend_method = "differencing", seas_method = "none")

fc1 <- forecast(model1, h = 24)
fc2 <- forecast(model2, h = 24)
fc3 <- forecast(model3, h = 24)
fc4 <- forecast(model4, h = 24)

fc5 <- forecast(model5, h = 24)
fc6 <- forecast(model6, h = 24)
fc7 <- forecast(model7, h = 24)
fc8 <- forecast(model8, h = 24)


par(mfrow = c(2, 2), bty = "l")
plot(fc1, main = "dummies"); grid()
plot(fc2, main = "decompose"); grid()
plot(fc3, main = "fourier"); grid()
plot(fc4, main = "none"); grid()


par(mfrow = c(2, 2), bty = "l")
plot(fc5, main = "dummies"); grid()
plot(fc6, main = "decompose"); grid()
plot(fc7, main = "fourier"); grid()
plot(fc8, main = "none"); grid()


summary(model3)
