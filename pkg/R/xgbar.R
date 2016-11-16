
#' xgboost time series modelling
#' 
#' Fit a model to a time series using xgboost
#' 
#' @export
#' @aliases xgbts
#' @import xgboost
#' @import forecast
#' @import stats
#' @param y A univariate time series.
#' @param xreg Optionally, a vector or matrix of external regressors, which must have the same number of rows as y.
#' @param nrounds Maximum number of iterations \code{xgboost} will perform.  If \code{nrounds_method = 'cv'}, 
#' the value of \code{nrounds} passed to \code{xgboost} is chosen by cross-validation; if it is \code{'v'} 
#' then  the value of \code{nrounds} passed to \code{xgboost} is chosen by splitting the data into a training
#' set (first 80 per cent) and test set (20 per cent) and choosing the number of iterations with the best value.
#' If \code{nrounds_method = 'manual'} then \code{nrounds} iterations will be performed - unless you have chosen
#' it carefully this is likely to lead to overfitting and poor forecasts.
#' @param nfold Number of equal size subsamples during cross validation, used if \code{nrounds_method = 'cv'}.
#' @param maxlag The maximum number of lags of \code{y} and \code{xreg} (if included) to be considered as features.
#' @param verbose Passed on to \code{xgboost} and \code{xgb.cv}.
#' @param nrounds_method Method used to determine the value of nrounds actually given for \code{xgboost} for 
#' the final model.  Options are \code{"cv"} for row-wise cross-validation, \code{"v"} for validation on a testing
#' set of the most recent 20 per cent of data, \code{"manual"} in which case \code{nrounds} is passed through directly.
#' @param ... Additional arguments passed to \code{xgboost}.  Only works if nrounds_method is "cv" or "manual".
#' @details This is the workhorse function for the \code{forecastxgb} package.
#' It fits a model to a time series.  Under the hood, it creates a matrix of explanatory variables 
#' based on lagged versions of the response time series, dummy variables for seasons, and numeric time.  That 
#' matrix is then fed as the feature set for \code{xgboost} to do its stuff.
#' @return An object of class \code{xgbar}.
#' @seealso \code{\link{summary.xgbar}}, \code{\link{plot.xgbar}}, \code{\link{forecast.xgbar}}, \code{\link{xgbar_importance}}.
#' @author Peter Ellis
#' @examples
#' # Univariate example - quarterly production of woolen yarn in Australia
#' woolmod <- xgbar(woolyrnq)
#' summary(woolmod)
#' plot(woolmod)
#' fc <- forecast(woolmod, h = 8)
#' plot(fc)
#' 
#' # Bivariate example - quarterly income and consumption in the US
#' if(require(fpp)){
#' consumption <- usconsumption[ ,1]
#' income <- matrix(usconsumption[ ,2], dimnames = list(NULL, "Income"))
#' consumption_model <- xgbar(y = consumption, xreg = income)
#' summary(consumption_model)
#' }
xgbar <- function(y, xreg = NULL, maxlag = max(8, 2 * frequency(y)), nrounds = 100, 
                  nrounds_method = c("cv", "v", "manual"), 
                  nfold = ifelse(length(y) > 30, 10, 5), verbose = FALSE, ...){
  # y <- AirPassengers; nrounds_method = "cv" # for dev

  nrounds_method = match.arg(nrounds_method)
  
  # check y is a univariate time series
  if(!"ts" %in% class(y)){
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
  
  if(orign < 4){
    stop("Too short. I need at least four observations.")
  }
  
  if(maxlag > (orign - 3)){
    warning(paste("y is too short for the value of maxlag.  Reducing maxlags to", 
                  orign - 3,
                  "instead."))
    maxlag <- orign - 3
  }
  
  origy <- y
  origxreg <- xreg
  n <- orign - maxlag
  y2 <- ts(origy[-(1:(maxlag))], start = time(origy)[maxlag + 1], frequency = f)

  if(nrounds_method == "cv" & n < 15){
    warning("y is too short for cross-validation.  Will validate on the most recent 20 per cent instead.")
    nrounds_method <- "v"
  }
  
  
    
  #----------------------------creating x--------------------
  # create lagged versions of y to be part of x
  x <- matrix(0, nrow = n, ncol = maxlag + f)
  x[ , 1:maxlag] <- lagv(origy, maxlag, keeporig = FALSE)
  
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
  
  # add xreg, if present
  if(!is.null(xreg)){
    xreg <- lagvm(xreg, maxlag = maxlag)
    x <- cbind(x, xreg[ , , drop = FALSE])
  }
  
  
  #---------------model fitting--------------------
  if(nrounds_method == "cv"){
    if(verbose){message("Starting cross-validation")}
    cv <- xgb.cv(data = x, label = y2, nrounds = nrounds, nfold = nfold, 
                 early.stop.round = 5, maximize = FALSE, verbose = verbose, ...)
    # TODO - xgb.cv uses cat() to give messages, very poor practice.  Sink them somewhere if verbose = FALSE?
    
    nrounds_use <- min(which(cv$test.rmse.mean == min(cv$test.rmse.mean)))
  } else {if(nrounds_method == "v"){
      nrounds_use <- validate_xgbar(y, xreg = xreg, ...) $best_nrounds
  } else { 
    nrounds_use <- nrounds
      }
  }  
  if(verbose){message("Fitting xgboost model")}
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
  if(!is.null(xreg)){
    output$ origxreg = origxreg
    output$ncolxreg <- ncol(origxreg)
  }
  class(output) <- "xgbar"
  return(output)

}

#`` @export
xgbts <- function(...){
  warning("xgbts is deprecated terminology and will soon be removed.
Please use xgbar instead.")
  xgbar(...)
}

#' Forecasting using xgboost models
#' 
#' Returns forecasts and other information for xgboost timeseries modesl fit with \code{xbgts}
#' 
#' @export
#' @import forecast
#' @import xgboost
#' @method forecast xgbar
#' @param object An object of class "\code{xgbar}".  Usuall the result of a call to \code{\link{xgbar}}.
#' @param h Number of periods for forecasting
#' @param xreg Future values of regression variables.
#' @param ... Ignored.
#' @return An object of class \code{forecast}
#' @author Peter Ellis
#' @seealso \code{\link{xgbar}}, \code{\link[forecast]{forecast}}
#' @examples
#' # Australian monthly gas production
#' gas_model <- xgbar(gas)
#' summary(gas_model)
#' gas_fc <- forecast(gas_model, h = 12)
#' plot(gas_fc)
forecast.xgbar <- function(object, 
                          h = NULL,
                          xreg = NULL, ...){
  # validity checks on xreg
  if(!is.null(xreg)){
    if(is.null(object$ncolxreg)){
      stop("You supplied an xreg, but there is none in the original xgbar object.")
    }
    
    if(class(xreg) == "ts" | "data.frame" %in% class(xreg)){
      message("Converting xreg into a matrix")
      # TODO - not sure this works when it's two dimensional
      xreg <- as.matrix(xreg)
    }
    
    if(!is.numeric(xreg) | !is.matrix(xreg)){
      stop("xreg should be a numeric and able to be coerced to a matrix")
    }
    
    if(ncol(xreg) != object$ncolxreg){
      stop("Number of columns in xreg doesn't match the original xgbar object.")
    }
    
    if(!is.null(h)){
      warning(paste("Ignoring h and forecasting", nrow(xreg), "periods from xreg."))
    }
    
    # add the lagged versions of xreg.  Some of the lags need to come from the original data
    h <- nrow(xreg)
    xreg2 <- lagvm(rbind(xreg, object$origxreg), maxlag = object$maxlag)
    # we just want the last h rows of that big matrix:
    nn <- nrow(xreg2)
    xreg3 <- xreg2[(nn - h + 1):nn, ]
  } 
  
  if(is.null(h)){
    h <- ifelse(frequency(object$y) > 1, 2 * frequency(object$y), 10)
    message(paste("No h provided so forecasting forward", h, "periods."))
  }
  
  # clear up space to avoid using an old xreg3 if it exists
  if(is.null(xreg)){
    xreg3 <- NULL
  }
  
  f <- frequency(object$y)
  
  # forecast times
  htime <- time(ts(rep(0, h), frequency = f, start = max(time(object$y)) + 1 / f))
  
  forward1 <- function(x, y, timepred, model, xregpred){
   newrow <- c(
     # latest lagged value:
     y[length(y)], 
     # previous lagged values:
     x[nrow(x), 1:(object$maxlag - 1)], 
     # linear time:
     timepred)
   if(object$maxlag == 1){
     newrow = newrow[-1]
   }
   
   if(f > 1){
     # seasons:
     newrow <- c(newrow, x[(nrow(x) + 1 - f), (object$maxlag + 2):(object$maxlag + f)])
   }
   if(!is.null(xregpred)){
     newrow <- c(newrow, xregpred)
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
    tmp <- forward1(x, y, timepred = htime[i], model = object$model, xregpred = xreg3[i, ])  
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
    newx = x,
    method = "xgboost"
  )
  class(output) <- "forecast"
  return(output)

}
