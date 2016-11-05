
library(Tcomp)
library(foreach)
library(forecastxgb)


competition <- function(collection){
  nseries <- length(collection)
  mases <- foreach(i = 1:nseries, .combine = "rbind") %dopar% {
    thedata <- collection[[i]]  
    mod1 <- xgbts(thedata$x)
    fc1 <- forecast(mod1, h = thedata$h)
    fc2 <- thetaf(thedata$x, h = thedata$h)
    fc3 <- forecast(auto.arima(thedata$x), h = thedata$h)
    fc4 <- forecast(nnetar(thedata$x), h = thedata$h)
    fc12 <- (fc1$mean + fc2$mean) / 2
    fc13 <- (fc1$mean + fc3$mean) / 2
    fc14 <- (fc1$mean + fc4$mean) / 2
    fc23 <- (fc2$mean + fc3$mean) / 2
    fc24 <- (fc2$mean + fc4$mean) / 2
    fc34 <- (fc3$mean + fc4$mean) / 2
    fc123 <- (fc1$mean + fc2$mean + fc3$mean) / 3
    fc124 <- (fc1$mean + fc2$mean + fc3$mean) / 3
    fc134 <- (fc1$mean + fc2$mean + fc3$mean) / 3
    fc234 <- (fc1$mean + fc2$mean + fc3$mean) / 3
    fc1234 <- (fc1$mean + fc2$mean + fc3$mean + fc4$mean) / 4
    mase <- c(accuracy(fc1, thedata$xx)[2, 6],
              accuracy(fc2, thedata$xx)[2, 6],
              accuracy(fc3, thedata$xx)[2, 6],
              accuracy(fc4, thedata$xx)[2, 6],
              accuracy(fc12, thedata$xx)[2, 6],
              accuracy(fc13, thedata$xx)[2, 6],
              accuracy(fc14, thedata$xx)[2, 6],
              accuracy(fc23, thedata$xx)[2, 6],
              accuracy(fc24, thedata$xx)[2, 6],
              accuracy(fc34, thedata$xx)[2, 6],
              accuracy(fc123, thedata$xx)[2, 6],
              accuracy(fc124, thedata$xx)[2, 6],
              accuracy(fc134, thedata$xx)[2, 6],
              accuracy(fc234, thedata$xx)[2, 6],
              accuracy(fc1234, thedata$xx)[2, 6])
    mase
  }
  colnames(mases) <- c("xgboost", "theta", "arima", "nnetar", "xf", "xa", "xn", "fa", "fn", "an",
                       "xfa", "xfn", "xan", "fan", "xfan")
  return(mases)
}


system.time(t1  <- competition(subset(tourism, "yearly")))
system.time(t4 <- competition(subset(tourism, "quarterly")))
system.time(t12 <- competition(subset(tourism, "monthly")))


apply(t1, 2, mean)
apply(t4, 2, mean)
apply(t12, 2, mean)
