library(fpp)
fit <- Arima(usconsumption[,1], xreg=usconsumption[,2],
             order=c(2,0,0))
tsdisplay(arima.errors(fit), main="ARIMA errors")
summary(fit)

fit2 <- xgbts(y = usconsumption[,1], xreg = matrix(usconsumption[,2], dimnames = list(NULL, "Income")))
summary(fit2)



income_future <- matrix(forecast(usconsumption[,2], h = 10)$mean, dimnames = list(NULL, "Income"))
fc <- forecast(fit2, xreg = income_future)
plot(fit2)
plot(fc)

class(xreg)
plot(xreg)
is.numeric(xreg)
as.matrix(xreg)
dim(xreg)
ncol(xreg)
