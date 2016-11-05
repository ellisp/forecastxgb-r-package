library(Tcomp)

collection <- subset(tourism, "quarterly")
nseries <- length(collection)

mases <- matrix(0, nrow = nseries, ncol = 3)

for(i in 1:nseries){
  thedata <- tourism[[i]]  
  mod1 <- xgbts(thedata$x)
  fc1 <- forecast(mod1, h = thedata$h)
  fc2 <- thetaf(thedata$x, h = thedata$h)
  fc3 <- forecast(auto.arima(thedata$x), h = thedata$h)
  mases[i, 1] <- accuracy(fc1, thedata$xx)[2, 6]
  mases[i, 2] <- accuracy(fc2, thedata$xx)[2, 6]
  mases[i, 3] <- accuracy(fc3, thedata$xx)[2, 6]
}
colnames(mases) <- c("xgboost", "theta", "arima")
apply(mases, 2, mean)
