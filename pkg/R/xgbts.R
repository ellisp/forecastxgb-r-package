
#' xgboost time series modelling
#' 
#' Fit a model to a time series using xgboost
#' 
#' @export
#' @import xgboost
#' @import forecast
#' @import stats
#' @param y A univariate time series.
#' @param xreg Optionally, a vector or matrix of external regressors, which must have the same number of rows as y.
#' @param nrounds Maximum number of iterations in cross validation to determine.
#' @param nfold Number of equal size subsamples during cross validation.
#' @param maxlag The maximum number of lags of \code{y} and \code{xreg} (if included) to be considered as features.
#' @param verbose Passed on to \code{xgboost} and \code{xgb.cv}.
#' @param ... Additional arguments passed to \code{xgboost}.
#' @return An object of class \code{xgbts}.
#' @author Peter Ellis
xgbts <- function(y, xreg = NULL, maxlag = 2 * frequency(y), nrounds = 100, 
                  nfold = 10, verbose = FALSE, ...){
  # y <- AirPassengers

  # check y is a univariate time series
  
  
  # check xreg, if it exists, is a numeric matrix
  
  
  f <- stats::frequency(y)
  if(maxlag < f){
    stop("Must have at least one full period of lags.")
  }
  
  orign <- length(y)
  origy <- y
  n <- orign - maxlag
  y2 <- origy[-(1:(maxlag))]
  
  x <- matrix(0, nrow = n, ncol = maxlag + 1)
  for(i in 1:maxlag){
    x[ ,i] <- origy[(orign - i - n + 1)    :  (orign - i)]
  }
  x[ , ncol(x)] <- time(y2)
  colnames(x) <- c(paste0("lag", 1:maxlag), "time")
  
  cv <- xgb.cv(data = x, label = y2, nrounds = nrounds, nfold = nfold, 
               early.stop.round = 5, maximize = FALSE, verbose = verbose)
  best <- min(which(cv$test.rmse.mean == min(cv$test.rmse.mean)))
  
  model <- xgboost(data = x, label = y2, nrounds = best, verbose = verbose, ...)
  
  output <- list(
    y = origy,
    y2 = y2,
    x = x,
    model = model,
    fitted = ts(c(rep(NA, maxlag), 
                  predict(model, newdata = x)), 
                frequency = f, start = min(time(origy))), 
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
#' @param object An object of class "\code{xgbts}".  Usuall the result of a call to \code{\link{xgbts}}.
#' @param h Number of periods for forecasting
#' @param xreg Future values of regression variables.
#' @return An object of class \code{forecast}
#' @author Peter Ellis
forecast.xgbts <- function(object, 
                          h = ifelse(frequency(object$y) > 1, 2 * frequency(object$y), 10),
                          xreg = NULL){
  # object <- xgbts(AirPassengers)
  f <- frequency(object$y)
  
  # forecast times
  htime <- time(ts(rep(0, h), frequency = f, start = max(time(object$y)) + 1 / f))
  
  forward1 <- function(x, y, time, model){
   newrow <- matrix(c(y[length(y)], x[nrow(x), 1:(ncol(x) - 2)], time), nrow = 1)
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
    tmp <- forward1(x, y, time = htime[i], model = object$model)  
    x <- tmp$x
    y <- tmp$y
  }
  
  y <- ts(y[-(1:length(object$y2))],
          frequency = f,
          start = max(time(object$y)) + 1 / f) 
  
  output <- list(
    x = object$y,
    mean = y,
    fitted = object$fitted,
    method = "xgboost"
  )
  class(output) <- "forecast"
  return(output)

}