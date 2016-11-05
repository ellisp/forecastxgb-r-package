library(fpp)
fit1 <- Arima(usconsumption[,1], xreg=usconsumption[,2],
             order=c(2,0,0))
tsdisplay(arima.errors(fit1), main="ARIMA errors")
summary(fit1)
fc1 <- forecast(fit1, xreg = income_future)
names(fc1)
fc$method

fit2 <- xgbts(y = usconsumption[,1], xreg = matrix(usconsumption[,2], dimnames = list(NULL, "Income")))
fit3 <- xgbts(y = usconsumption[,1])
forecast(fit3)
summary(fit2)
fit2$origxreg


income_future <- matrix(forecast(usconsumption[,2], h = 10)$mean, dimnames = list(NULL, "Income"))
fc2 <- forecast(object = fit2, xreg = income_future, h = 4)# should be a warning
fc3 <- forecast(fit3)
plot(fit2)
plot(fc2)
plot(fc3)
names(fc2)
fc2$method
fc1$method
fc2$model
class(fc1$model)

class(xreg)
plot(xreg)
is.numeric(xreg)
as.matrix(xreg)
dim(xreg)
ncol(xreg)
