
#=============prep======================
library(Tcomp)
library(foreach)
library(doParallel)
library(forecastxgb)
library(dplyr)
library(ggplot2)
library(scales)
library(Mcomp)
#============set up cluster for parallel computing===========
cluster <- makeCluster(7) # only any good if you have at least 7 processors :)
registerDoParallel(cluster)

clusterEvalQ(cluster, {
  library(Tcomp)
  library(forecastxgb)
  library(Mcomp)
})


#===============the actual analytical function==============
competition <- function(collection, maxfors = length(collection)){
  if(class(collection) != "Mcomp"){
    stop("This function only works on objects of class Mcomp, eg from the Mcomp or Tcomp packages.")
  }
  nseries <- length(collection)
  mases <- foreach(i = 1:maxfors, .combine = "rbind") %dopar% {
    thedata <- collection[[i]]  
    seas_method <- ifelse(frequency(thedata$x) < 6, "dummies", "fourier")
    mod1 <- xgbar(thedata$x, trend_method = "differencing", seas_method = seas_method, lambda = 1, K = 2)
    fc1 <- forecast(mod1, h = thedata$h)
    fc2 <- thetaf(thedata$x, h = thedata$h)
    fc3 <- forecast(auto.arima(thedata$x), h = thedata$h)
    fc4 <- forecast(nnetar(thedata$x), h = thedata$h)
    # copy the skeleton of fc1 over for ensembles:
    fc12 <- fc13 <- fc14 <- fc23 <- fc24 <- fc34 <- fc123 <- fc124 <- fc134 <- fc234 <- fc1234 <- fc1
    # replace the point forecasts with averages of member forecasts:
    fc12$mean <- (fc1$mean + fc2$mean) / 2
    fc13$mean <- (fc1$mean + fc3$mean) / 2
    fc14$mean <- (fc1$mean + fc4$mean) / 2
    fc23$mean <- (fc2$mean + fc3$mean) / 2
    fc24$mean <- (fc2$mean + fc4$mean) / 2
    fc34$mean <- (fc3$mean + fc4$mean) / 2
    fc123$mean <- (fc1$mean + fc2$mean + fc3$mean) / 3
    fc124$mean <- (fc1$mean + fc2$mean + fc4$mean) / 3
    fc134$mean <- (fc1$mean + fc3$mean + fc4$mean) / 3
    fc234$mean <- (fc2$mean + fc3$mean + fc4$mean) / 3
    fc1234$mean <- (fc1$mean + fc2$mean + fc3$mean + fc4$mean) / 4
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
  message("Finished fitting models")
  colnames(mases) <- c("x", "f", "a", "n", "xf", "xa", "xn", "fa", "fn", "an",
                        "xfa", "xfn", "xan", "fan", "xfan")
  return(mases)
}



## Test on a small set of data, useful during dev
small_collection <- list(tourism[[100]], tourism[[200]], tourism[[300]], tourism[[400]], tourism[[500]], tourism[[600]])
class(small_collection) <- "Mcomp"
test1 <- competition(small_collection)
round(test1, 1)

#========Fit models==============
system.time(t1  <- competition(subset(tourism, "yearly")))
system.time(t4 <- competition(subset(tourism, "quarterly")))
system.time(t12 <- competition(subset(tourism, "monthly")))


system.time(m1  <- competition(subset(M3, "yearly")))
system.time(m4 <- competition(subset(M3, "quarterly")))
system.time(m12 <- competition(subset(M3, "monthly")))
system.time(mo <- competition(subset(M3, "other")))

# shut down cluster to avoid any mess:
stopCluster(cluster)


#==============present tourism results================
results <- c(apply(t1, 2, mean),
             apply(t4, 2, mean),
             apply(t12, 2, mean))

results_df <- data.frame(MASE = results)
results_df$model <- as.character(names(results))
periods <- c("Annual", "Quarterly", "Monthly")
results_df$Frequency <- rep.int(periods, times = c(15, 15, 15))

best <- results_df %>%
  group_by(model) %>%
  summarise(MASE = mean(MASE)) %>%
  arrange(MASE) %>%
  mutate(Frequency = "Average")

Tcomp_results <- results_df %>%
  rbind(best) %>%
  mutate(model = factor(model, levels = best$model)) %>%
  mutate(Frequency = factor(Frequency, levels = c("Annual", "Average", "Quarterly", "Monthly")))

save(Tcomp_results, file = "pkg/data/Tcomp_results.rda")

leg <- "f: Theta; forecast::thetaf\na: ARIMA; forecast::auto.arima
n: Neural network; forecast::nnetar\nx: Extreme gradient boosting; forecastxgb::xgbar"

Tcomp_results %>%
  ggplot(aes(x = model, y =  MASE, colour = Frequency, label = model)) +
  geom_text(size = 6) +
  geom_line(aes(x = as.numeric(model)), alpha = 0.25) +
  scale_y_continuous("Mean scaled absolute error\n(smaller numbers are better)") +
  annotate("text", x = 2, y = 3.5, label = leg, hjust = 0) +
  ggtitle("Average error of four different timeseries forecasting methods\n2010 Tourism Forecasting Competition data") +
  labs(x = "Model, or ensemble of models\n(further to the left means better overall performance)")



# the results for Theta and ARIMA match those at
# https://cran.r-project.org/web/packages/Tcomp/vignettes/tourism-comp.html


#======================Present M3 results========================
results <- c(apply(m1, 2, mean),
             apply(m4, 2, mean),
             apply(m12, 2, mean),
             apply(mo, 2, mean))

results_df <- data.frame(MASE = results)
results_df$model <- as.character(names(results))
periods <- c("Annual", "Quarterly", "Monthly", "Other")
results_df$Frequency <- rep.int(periods, times = c(15, 15, 15, 15))

best <- results_df %>%
  group_by(model) %>%
  summarise(MASE = mean(MASE)) %>%
  arrange(MASE) %>%
  mutate(Frequency = "Average")

Mcomp_results <- results_df %>%
  rbind(best) %>%
  mutate(model = factor(model, levels = best$model)) %>%
  mutate(Frequency = factor(Frequency, levels = c("Annual", "Average", "Quarterly", "Monthly", "Other")))

save(Mcomp_results, file = "pkg/data/Mcomp_results.rda")

leg <- "f: Theta; forecast::thetaf\na: ARIMA; forecast::auto.arima
n: Neural network; forecast::nnetar\nx: Extreme gradient boosting; forecastxgb::xgbar"

Mcomp_results %>%
  ggplot(aes(x = model, y =  MASE, colour = Frequency, label = model)) +
  geom_text(size = 6) +
  geom_line(aes(x = as.numeric(model)), alpha = 0.25) +
  scale_y_continuous("Mean scaled absolute error\n(smaller numbers are better)") +
  annotate("text", x = 2, y = 3.5, label = leg, hjust = 0) +
  ggtitle("Average error of four different timeseries forecasting methods\nM3 Forecasting Competition data") +
  labs(x = "Model, or ensemble of models\n(further to the left means better overall performance)")

