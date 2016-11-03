# TODO - add time as a feature


#' xgboost time series modelling
#' 
#' Fit a model to a time series using xgboost
#' 
#' @export
#' @import xgboost
#' @param nrounds Maximum number of iterations in cross validation to determine
#' @param nfold number of equal size subsamples during cross validation
xgbts <- function(y, xreg = NULL, maxlag = 2 * frequency(y), nrounds = 100, verbose = FALSE, ...){
  # y <- AirPassengers

  # check y is a univariate time series
  
  
  # check xreg, if it exists, is a numeric matrix

  if(maxlag < frequency(y)){
    stop("Must have at least one full period of lags.")
  }
  
  # perhaps turn this lag sequence into a non-exported function
  orign <- length(y)
  origy <- y
  n <- orign - maxlag
  y2 <- origy[-(1:(maxlag))]
  
  x <- matrix(0, nrow = n, ncol = maxlag)
  for(i in 1:maxlag){
    x[ ,i] <- origy[(orign - i - n + 1)    :  (orign - i)]
  }
  colnames(x) <- paste0("lag", 1:maxlag)
  
  cv <- xgb.cv(data = x, label = y2, nrounds = nrounds, nfold = 10, 
               early.stop.round = 5, maximize = FALSE, verbose = verbose)
  best <- min(which(cv$test.rmse.mean == min(cv$test.rmse.mean)))
  
  model <- xgboost(data = x, label = y2, nround = best, verbose = verbose, ...)
  
  output <- list(
    y = origy,
    y2 = y2,
    x = x,
    model = model,
    maxlag = maxlag
  )
  class(output) <- "xgbts"
  return(output)

}

#' Forecasting using xgboost models
#' 
#' Returns forecasts and other information for xgboost timeseries modesl fit with \code{xbgts}
#' 
#' @export
forecast.xgbts <- function(object, 
                          h = ifelse(frequency(object$y) > 1, 2 * frequency(object$y), 10),
                          xreg = NULL){
  f <- frequency(object$y)
  
  forward1 <- function(x, y, model){
   newrow <- matrix(c(y[length(y)], x[nrow(x), -ncol(x)]), nrow = 1)
   colnames(newrow) <- colnames(x)
   pred <- predict(model, newdata = newrow)
   return(list(
     x = rbind(x, newrow),
     y = c(y, pred)
   ))
  }
  
  x <- object$x
  y <- object$y2
  for(i in 1:h){
    tmp <- forward1(x, y, object$model)  
    x <- tmp$x
    y <- tmp$y
  }
  
  y <- ts(y[-(1:length(object$y2))],
          frequency = f,
          start = max(time(object$y)) + 1 / f) 
  
  output <- list(
    x = object$y,
    mean = y,
    fitted = ts(c(rep(NA, object$maxlag), 
                  predict(object$model, newdata = object$x)), 
                frequency = f, start = min(time(object$y))), 
    method = "xgboost"
  )
  class(output) <- "forecast"
  return(output)

}