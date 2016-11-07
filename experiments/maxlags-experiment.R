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

collection <- subset(M1, "quarterly")


#================identify best maxlags for a collection=====================
allmases <- list(length(collection))

for(i in 1:length(collection)){
  cat(paste("Dataset", i, "\n"))
  thedata <- collection[[i]]
  
  n <- length(thedata$x)
  f <- frequency(thedata$x)
  maxP <- trunc(n / f / 2)
  thedata_mases <- numeric(maxP)
  
  for(p in 1:maxP){
    mod <- xgbts(thedata$x, maxlag = p * f, nrounds_method = "cv")
    fc <- forecast(mod, h = thedata$h)
    thisacc <- accuracy(fc, thedata$xx)[2, 6]
    print(thisacc)
    thedata_mases[p] <- thisacc
  }
  thedata_mases_rounded <- round(thedata_mases, 1)
  bl <- min(which(thedata_mases_rounded == min(thedata_mases_rounded, na.rm = TRUE))) * f

  allmases[[i]] <- list(mases = thedata_mases, bl = bl, n = n, f = f)
  
}

