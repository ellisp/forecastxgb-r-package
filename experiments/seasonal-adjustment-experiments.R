


model1 <- xgbar(AirPassengers, maxlag = 24, seas_method = "dummies")
model2 <- xgbar(AirPassengers, maxlag = 24, seas_method = "decompose")
model3 <- xgbar(AirPassengers, maxlag = 24, seas_method = "fourier")
model4 <- xgbar(AirPassengers, maxlag = 24, seas_method = "none")

fc1 <- forecast(model1, h = 24)
fc2 <- forecast(model2, h = 24)
fc3 <- forecast(model3, h = 24)
fc4 <- forecast(model4, h = 24)

par(mfrow = c(2, 2), bty = "l")
plot(fc1, main = "dummies"); grid()
plot(fc2, main = "decompose"); grid()
plot(fc3, main = "fourier"); grid()
plot(fc4, main = "none"); grid()

summary(model3)
