
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
#' @param nrounds Maximum number of iterations \code{xgboost} will perform.  If \code{cv = TRUE}, the value 
#' of \code{nrounds} passed to \code{xgboost} is chosen by cross-validation; if it is \code{FALSE} then 
#' \code{nrounds} is passed straight through.
#' @param nfold Number of equal size subsamples during cross validation.
#' @param maxlag The maximum number of lags of \code{y} and \code{xreg} (if included) to be considered as features.
#' @param verbose Passed on to \code{xgboost} and \code{xgb.cv}.
#' @param cv Should cross-validation be used to choose the nrounds actually passed to xgboost? (recommended)
#' @param ... Additional arguments passed to \code{xgboost}.
#' @return An object of class \code{xgbts}.
#' @author Peter Ellis
xgbts <- function(y, xreg = NULL, maxlag = max(8, 2 * frequency(y)), nrounds = 100, 
                  cv = TRUE, nfold = 10, verbose = FALSE, ...){
  # y <- AirPassengers # for dev

  # check y is a univariate time series
  if(class(y) != "ts"){
    stop("y must be a univariate time series")
  }
  
  # check xreg, if it exists, is a numeric matrix
  if(!is.null(xreg)){
    if(class(xreg) == "ts" | "data.frame" %in% class(xreg)){
      message("Converting xreg into a matrix")
      xreg <- as.matrix(xreg)
    }
    
    if(!is.numeric(xreg) | !is.matrix(xreg)){
      stop("xreg should be a numeric and able to be coerced to a matrix")
    }
  }

  f <- stats::frequency(y)
  if(maxlag < f){
    stop("At least one full period of lags needed.")
  }
  
  orign <- length(y)
  origy <- y
  n <- orign - maxlag
  y2 <- ts(origy[-(1:(maxlag))], start = time(origy)[maxlag + 1], frequency = f)
  
  #----------------------------creating x--------------------
  # create lagged versions of y to be part of x
  x <- matrix(0, nrow = n, ncol = maxlag + f)
  for(i in 1:maxlag){
    x[ ,i] <- origy[(orign - i - n + 1)    :  (orign - i)]
  }
  
  # add a linear time variable for x
  x[ , maxlag + 1] <- time(y2)
  
  # one hot encoding of seasons
  if(f > 1){
    tmp <- data.frame(y = 1, x = as.character(rep_len(1:f, n)))
    seasons <- model.matrix(y ~ x, data = tmp)[ ,-1]
    x[ , maxlag + 2:f] <- seasons
    
    # rename columns of x
    colnames(x) <- c(paste0("lag", 1:maxlag), "time", paste0("season", 2:f))
  } else {
    colnames(x) <- c(paste0("lag", 1:maxlag), "time")
  }
  #---------------model fitting--------------------
  if(cv){
    message("Starting cross-validation")
    cv <- xgb.cv(data = x, label = y2, nrounds = nrounds, nfold = nfold, 
                 early.stop.round = 5, maximize = FALSE, verbose = verbose)
    # TODO - xgb.cv uses cat() to give messages, very poor practice.  Sink them somewhere if verbose = FALSE
    
    nrounds_use <- min(which(cv$test.rmse.mean == min(cv$test.rmse.mean)))
  } else {
    nrounds_use <- nrounds
  }  
  message("Fitting xgboost model")
  model <- xgboost(data = x, label = y2, nrounds = nrounds_use, verbose = verbose, ...)
  
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
#' @import forecast
#' @import xgboost
#' @method forecast xgbts
#' @param object An object of class "\code{xgbts}".  Usuall the result of a call to \code{\link{xgbts}}.
#' @param h Number of periods for forecasting
#' @param xreg Future values of regression variables.
#' @param ... Ignored.
#' @return An object of class \code{forecast}
#' @author Peter Ellis
forecast.xgbts <- function(object, 
                          h = ifelse(frequency(object$y) > 1, 2 * frequency(object$y), 10),
                          xreg = NULL, ...){
  # object <- xgbts(AirPassengers)
  f <- frequency(object$y)
  
  # forecast times
  htime <- time(ts(rep(0, h), frequency = f, start = max(time(object$y)) + 1 / f))
  
  forward1 <- function(x, y, timepred, model){
   newrow <- c(
     # latest lagged value:
     y[length(y)], 
     # previous lagged values:
     x[nrow(x), 1:(object$maxlag - 1)], 
     # linear time:
     timepred)
   if(f > 1){
     # seasons:
     newrow <- c(newrow, x[(nrow(x) + 1 - f), (object$maxlag + 2):(object$maxlag + f)])
   }
     
   newrow <- matrix(newrow, nrow = 1)
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
    tmp <- forward1(x, y, timepred = htime[i], model = object$model)  
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