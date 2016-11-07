validate_xgbts <- function(y, xreg = NULL, nrounds = 50, ...){
  n <- length(y)
  spl <- round(0.8 * n)
  
  trainy <- ts(y[1:spl], start = start(y), frequency = frequency(y))
  testy <- y[(spl + 1):n]
  h <- length(testy)
  
  if(!is.null(xreg)){
    trainxreg <- xreg[1:spl, ]
    testxreg <- xreg[(spl + 1):n, ]  
  }

  grunt <- function(nrounds){
    if(!is.null(xreg)){
      trainmod <- xgbts(trainy, xreg = xreg, nrounds_method = "manual", nrounds = nrounds)
    } else {
      trainmod <- xgbts(trainy, nrounds_method = "manual", nrounds = nrounds)  
    }
    fc <- forecast(trainmod, h = h)
    result <- accuracy(fc, testy)[2,6]  
    return(result)
  }
    
  mases <- sapply(as.list(1:nrounds), grunt)
  
  best_nrounds <- min(which(mases == min(mases)))
  output <- list(
    best_nrounds = best_nrounds,
    best_mase = min(mases)
  )
  return(output)
}


