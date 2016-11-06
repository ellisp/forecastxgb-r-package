library(forecastxgb)
library(Mcomp)
library(foreach)
library(doParallel)


cluster <- makeCluster(4) 
registerDoParallel(cluster)

clusterEvalQ(cluster, {
  library(Tcomp)
  library(forecastxgb)
  library(Mcomp)
})

collection <- M1


#================identify best maxlags for a collection=====================
bestlags <- matrix(0, nrow = length(collection), ncol = 3)
colnames(bestlags) <- c("bestlag", "n", "frequency")

for(i in 1:length(collection)){
  cat(paste("Dataset", i, "\n"))
  thedata <- collection[[i]]
  bestacc <- 100
  
  n <- length(thedata$x)
  f <- frequency(thedata$x)
  keepgoing <- TRUE
  thedata_mases <- numeric()
  
  for(j in (f + 1):(n - 1 - f * 2)){
    if(keepgoing){
      mod <- xgbts(thedata$x, maxlag = j, nrounds_method = "cv")
      fc <- forecast(mod, h = thedata$h)
      thisacc <- accuracy(fc, thedata$xx)[2, 6]
      print(thisacc)
      thedata_mases[j] <- thisacc
      if(j > 5 & thisacc >= bestacc){
        # finished with this dataset
        lastacc <- 100
        keepgoing <- FALSE
      } else {
        bestacc <- min(thisacc, bestacc)
      }
    }
  }
  thedata_mases <- round(thedata_mases, 2)
  bl <- min(which(thedata_mases == min(thedata_mases, na.rm = TRUE)))

  bestlags[i, ] <- c(bl, n, f)
  print(bestlags[i, ])
}
# TODO - need to force it to move only in increments of f
# TODO - probably should let it go up for a couple of times in a row before giving up on increasing lag? (but see below)
# TODO - better to calculate and keep *all* the MASES and inspect them rather than just the "best"


