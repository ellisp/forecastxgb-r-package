#' @import parallel
validate_xgbts <- function(y, xreg = NULL, nrounds = 100, ...){
  cores <- detectCores()
  cluster <- makePSOCKcluster(max(1, cores - 1))
  
  clusterEvalQ(cluster, {
    library(forecastxgb)
  })
  clusterExport(cluster, c("xreg", "trainy", "testy", "h"))
  
  n <- length(y)
  spl <- round(0.8 * n)
  trainy <- ts(y[1:spl], start = start(y), frequency = frequency(y))
  testy <- y[(spl + 1):n]
  h <- length(testy)
  if(!is.null(xreg)){
    trainxreg <- xreg[1:spl, ]
    testxreg <- xreg[(spl + 1):n, ]  
    clusterExport(cluster, c("trainxreg", "testxreg"))
  }
  
  
  grunt <- function(nrounds){
    if(!is.null(xreg)){
      trainmod <- xgbts(trainy, xreg = xreg, cv = FALSE, nrounds = nrounds, ...)
    } else {
      trainmod <- xgbts(trainy, cv = FALSE, nrounds = nrounds)  
    }
    fc <- forecast(trainmod, h = h)
    result <- accuracy(fc, testy)[2,6]  
    return(result)
  }
    
  mases <- unlist(parLapply(cluster, as.list(1:nrounds), grunt) )
  stopCluster(cluster)
  
  best_nrounds <- which(mases == min(mases))
  output <- list(
    best_nrounds = best_nrounds,
    best_mase = min(mases)
  )
  return(output)
}


