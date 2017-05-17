## ----echo = FALSE, cache = FALSE-----------------------------------------
set.seed(123)
library(knitr)
knit_hooks$set(mypar = function(before, options, envir) {
    if (before) par(bty = "l", family = "serif")
})
opts_chunk$set(comment=NA, fig.width=7, fig.height=5, cache = FALSE, mypar = TRUE)

## ----message = FALSE-----------------------------------------------------
library(forecastxgb)
model <- xgbar(gas)

## ------------------------------------------------------------------------
summary(model)

## ------------------------------------------------------------------------
fc <- forecast(model, h = 12)
plot(fc)

## ----message = FALSE-----------------------------------------------------
library(fpp)
consumption <- usconsumption[ ,1]
income <- matrix(usconsumption[ ,2], dimnames = list(NULL, "Income"))
consumption_model <- xgbar(y = consumption, xreg = income)
summary(consumption_model)

## ------------------------------------------------------------------------
income_future <- matrix(forecast(xgbar(usconsumption[,2]), h = 10)$mean, 
                        dimnames = list(NULL, "Income"))
plot(forecast(consumption_model, xreg = income_future))

## ----echo = FALSE--------------------------------------------------------
model1 <- xgbar(co2, seas_method = "dummies")
model2 <- xgbar(co2, seas_method = "decompose")
model3 <- xgbar(co2, seas_method = "fourier")
plot(forecast(model1), main = "Dummy variables for seasonality")
# plot(forecast(model2), main = "Decomposition seasonal adjustment for seasonality")
plot(forecast(model3), main = "Fourier transform pairs as x regressors")

## ----echo = FALSE--------------------------------------------------------
model1 <- xgbar(co2, seas_method = "decompose", lambda = 1)
model2 <- xgbar(co2, seas_method = "decompose", lambda = BoxCox.lambda(co2))
plot(forecast(model1), main = "No transformation")
plot(forecast(model2), main = "With transformation")

## ------------------------------------------------------------------------
model <- xgbar(AirPassengers, trend_method = "differencing", seas_method = "fourier")
plot(forecast(model, 24))

## ----message = FALSE-----------------------------------------------------
#=============prep======================
library(Tcomp)
library(foreach)
library(doParallel)
library(forecastxgb)
library(dplyr)
library(ggplot2)
library(scales)

## ----eval = FALSE--------------------------------------------------------
#  #============set up cluster for parallel computing===========
#  cluster <- makeCluster(7) # only any good if you have at least 7 processors :)
#  registerDoParallel(cluster)
#  
#  clusterEvalQ(cluster, {
#    library(Tcomp)
#    library(forecastxgb)
#  })
#  
#  
#  #===============the actual analytical function==============
#  competition <- function(collection, maxfors = length(collection)){
#    if(class(collection) != "Mcomp"){
#      stop("This function only works on objects of class Mcomp, eg from the Mcomp or Tcomp packages.")
#    }
#    nseries <- length(collection)
#    mases <- foreach(i = 1:maxfors, .combine = "rbind") %dopar% {
#      thedata <- collection[[i]]
#      seas_method <- ifelse(frequency(thedata$x) < 6, "dummies", "fourier")
#      mod1 <- xgbar(thedata$x, trend_method = "differencing", seas_method = seas_method, lambda = 1, K = 2)
#      fc1 <- forecast(mod1, h = thedata$h)
#      fc2 <- thetaf(thedata$x, h = thedata$h)
#      fc3 <- forecast(auto.arima(thedata$x), h = thedata$h)
#      fc4 <- forecast(nnetar(thedata$x), h = thedata$h)
#      # copy the skeleton of fc1 over for ensembles:
#      fc12 <- fc13 <- fc14 <- fc23 <- fc24 <- fc34 <- fc123 <- fc124 <- fc134 <- fc234 <- fc1234 <- fc1
#      # replace the point forecasts with averages of member forecasts:
#      fc12$mean <- (fc1$mean + fc2$mean) / 2
#      fc13$mean <- (fc1$mean + fc3$mean) / 2
#      fc14$mean <- (fc1$mean + fc4$mean) / 2
#      fc23$mean <- (fc2$mean + fc3$mean) / 2
#      fc24$mean <- (fc2$mean + fc4$mean) / 2
#      fc34$mean <- (fc3$mean + fc4$mean) / 2
#      fc123$mean <- (fc1$mean + fc2$mean + fc3$mean) / 3
#      fc124$mean <- (fc1$mean + fc2$mean + fc4$mean) / 3
#      fc134$mean <- (fc1$mean + fc3$mean + fc4$mean) / 3
#      fc234$mean <- (fc2$mean + fc3$mean + fc4$mean) / 3
#      fc1234$mean <- (fc1$mean + fc2$mean + fc3$mean + fc4$mean) / 4
#      mase <- c(accuracy(fc1, thedata$xx)[2, 6],
#                accuracy(fc2, thedata$xx)[2, 6],
#                accuracy(fc3, thedata$xx)[2, 6],
#                accuracy(fc4, thedata$xx)[2, 6],
#                accuracy(fc12, thedata$xx)[2, 6],
#                accuracy(fc13, thedata$xx)[2, 6],
#                accuracy(fc14, thedata$xx)[2, 6],
#                accuracy(fc23, thedata$xx)[2, 6],
#                accuracy(fc24, thedata$xx)[2, 6],
#                accuracy(fc34, thedata$xx)[2, 6],
#                accuracy(fc123, thedata$xx)[2, 6],
#                accuracy(fc124, thedata$xx)[2, 6],
#                accuracy(fc134, thedata$xx)[2, 6],
#                accuracy(fc234, thedata$xx)[2, 6],
#                accuracy(fc1234, thedata$xx)[2, 6])
#      mase
#    }
#    message("Finished fitting models")
#    colnames(mases) <- c("x", "f", "a", "n", "xf", "xa", "xn", "fa", "fn", "an",
#                          "xfa", "xfn", "xan", "fan", "xfan")
#    return(mases)
#  }

## ----eval = FALSE--------------------------------------------------------
#  #========Fit models==============
#  system.time(t1  <- competition(subset(tourism, "yearly")))
#  system.time(t4 <- competition(subset(tourism, "quarterly")))
#  system.time(t12 <- competition(subset(tourism, "monthly")))
#  
#  # shut down cluster to avoid any mess:
#  stopCluster(cluster)

## ----eval = FALSE--------------------------------------------------------
#  #==============present results================
#  results <- c(apply(t1, 2, mean),
#               apply(t4, 2, mean),
#               apply(t12, 2, mean))
#  
#  results_df <- data.frame(MASE = results)
#  results_df$model <- as.character(names(results))
#  periods <- c("Annual", "Quarterly", "Monthly")
#  results_df$Frequency <- rep.int(periods, times = c(15, 15, 15))
#  
#  best <- results_df %>%
#    group_by(model) %>%
#    summarise(MASE = mean(MASE)) %>%
#    arrange(MASE) %>%
#    mutate(Frequency = "Average")
#  
#  Tcomp_results <- results_df %>%
#    rbind(best) %>%
#    mutate(model = factor(model, levels = best$model)) %>%
#    mutate(Frequency = factor(Frequency, levels = c("Annual", "Average", "Quarterly", "Monthly")))

## ---- fig.width = 8, fig.height = 6--------------------------------------
leg <- "f: Theta; forecast::thetaf\na: ARIMA; forecast::auto.arima
n: Neural network; forecast::nnetar\nx: Extreme gradient boosting; forecastxgb::xgbar"

Tcomp_results %>%
  ggplot(aes(x = model, y =  MASE, colour = Frequency, label = model)) +
  geom_text(size = 4) +
  geom_line(aes(x = as.numeric(model)), alpha = 0.25) +
  scale_y_continuous("Mean scaled absolute error\n(smaller numbers are better)") +
  annotate("text", x = 2, y = 3.5, label = leg, hjust = 0) +
  ggtitle("Average error of four different timeseries forecasting methods\n2010 Tourism Forecasting Competition data") +
  labs(x = "Model, or ensemble of models\n(further to the left means better overall performance)") +
  theme_grey(9)

