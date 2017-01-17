
#' xgboost time series modelling
#' 
#' Fit a model to a time series using xgboost
#' 
#' @export
#' @aliases xgbts
#' @import xgboost
#' @import forecast
#' @import stats
#' @importFrom tseries kpss.test
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
#' @param lambda Value of lambda to be used for modulus power transformation of \code{y} (which is similar to Box-Cox transformation 
#' but works with negative values too), performed before using xgboost (and inverse transformed to the original scale afterwards).
#' Set \code{lambda = 1} if no transformation is desired.  
#' The transformation is only applied to \code{y}, not \code{xreg}.
#' @param seas_method Method for dealing with seasonality.
#' @param K if \code{seas_method == 'fourier'}, the value of \code{K} passed through to \code{fourier} for order of Fourier series to be generated as seasonal regressor variables.
#' @param trend_method How should the \code{xgboost} try to deal with trends?  Currently the only options to \code{none} is 
#' \code{auto.arima}-style \code{differencing}, which is based on successive KPSS tests until there is no significant evidence the
#' remaining series is non-stationary.
#' @param ... Additional arguments passed to \code{xgboost}.  Only works if nrounds_method is "cv" or "manual".
#' @details This is the workhorse function for the \code{forecastxgb} package.
#' It fits a model to a time series.  Under the hood, it creates a matrix of explanatory variables 
#' based on lagged versions of the response time series, and (optionally) dummy variables (simple hot one encoding, or Fourier transforms) for seasons.  That 
#' matrix is then fed as the feature set for \code{xgboost} to do its stuff.
#' @return An object of class \code{xgbar}.
#' @seealso \code{\link{summary.xgbar}}, \code{\link{plot.xgbar}}, \code{\link{forecast.xgbar}}, \code{\link{xgbar_importance}},
#' \code{\link[xgboost]{xgboost}}.
#' @author Peter Ellis
#' @references J. A. John and N. R. Draper (1980), "An Alternative Family of Transformations", \emph{Journal of the Royal Statistical
#' Society}.
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
                  nfold = ifelse(length(y) > 30, 10, 5), 
                  lambda = 1, 
                  verbose = FALSE, 
                  seas_method = c("dummies", "decompose", "fourier", "none"), 
                  K =  max(1, min(round(f / 4 - 1), 10)), 
                  trend_method = c("none", "differencing"), ...){
  # y <- AirPassengers; nrounds_method = "cv"; nrounds = 100; seas_method = "fourier"; trend_method = "differencing"; verbose = TRUE; xreg = NULL; maxlag = 8; lambda = 1; K = 1

  nrounds_method = match.arg(nrounds_method)
  seas_method = match.arg(seas_method)
  trend_method = match.arg(trend_method)
  
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
  untransformedy <- y
  origy <- JDMod(y, lambda = lambda)
  
  # seasonal adjustment if asked for
  if(seas_method == "decompose"){
    decomp <- decompose(origy, type = "multiplicative")
    origy <- seasadj(decomp)
  }
  
  # de-trend the y if option was asked for
  # `diffs` is the number of differencing operations done, and is defined even if 
  # trend_method != "differencing"
  diffs <- 0
  if(trend_method == "differencing"){
    alpha = 0.05
    dodiff <- TRUE
    while(dodiff){
      suppressWarnings(dodiff <- tseries::kpss.test(origy)$p.value < alpha)
      if(dodiff){
        diffs <- diffs + 1
        origy <- ts(c(0, diff(origy)), start = start(origy), frequency = f)
      }
    }
  }
  
  if(maxlag < f & seas_method == "dummies"){
    stop("At least one full period of lags needed when seas_method = dummies.")
  }
  
  orign <- length(y)
  
  if(orign < 4){
    stop("Too short. I need at least four observations.")
  }
  
  if(maxlag > (orign - f - round(f / 4))){
    warning(paste("y is too short for", maxlag, "to be the value of maxlag.  Reducing maxlags to", 
                  orign - f - round(f / 4),
                  "instead."))
    maxlag <- orign - f - round(f / 4)
  }

  if (maxlag != round(maxlag)){
    maxlag <- ceiling(maxlag)
    if(verbose){message(paste("Rounding maxlag up to", maxlag))}
  }
  
    
  origxreg <- xreg
  n <- orign - maxlag
  y2 <- ts(origy[-(1:(maxlag))], start = time(origy)[maxlag + 1], frequency = f)

  if(nrounds_method == "cv" & n < 15){
    warning("y is too short for cross-validation.  Will validate on the most recent 20 per cent instead.")
    nrounds_method <- "v"
  }
  
  
    
  #----------------------------creating x--------------------
  # set up the matrix "x" of lagged versions of y, time series trend, and seasonal treatment:
  if(seas_method == "dummies" & f > 1){ncolx <- maxlag + f - 1}
  if(seas_method == "decompose"){ncolx <- maxlag }
  if(seas_method == "fourier" & f > 1){ncolx <- maxlag + K * 2}
  if(seas_method == "none" | f == 1){ncolx <- maxlag}
  x <- matrix(0, nrow = n, ncol = ncolx)
  
  # All models get the lagged values of y as regressors:
  x[ , 1:maxlag] <- lagv(origy, maxlag, keeporig = FALSE)
  
  # Some models get one hot encoding of seasons
  if(f > 1 & seas_method == "dummies"){
    tmp <- data.frame(y = 1, x = as.character(rep_len(1:f, n)))
    seasons <- model.matrix(y ~ x, data = tmp)[ ,-1]
    x[ , maxlag + 1:(f - 1)] <- seasons
    
    colnames(x) <- c(paste0("lag", 1:maxlag), paste0("season", 2:f))
  } 
  
  # Fourier models get fourier cycles:
  if(f > 1 & seas_method == "fourier"){
    fx <- fourier(y2, K = K)
    x[ , (maxlag + 1):ncolx] <- fx
    colnames(x) <- c(paste0("lag", 1:maxlag), colnames(fx))
  }
  
  # Some models get no seasonal treatment at all:
  if(f == 1 || seas_method == "decompose" || seas_method == "none"){
    colnames(x) <- c(paste0("lag", 1:maxlag))
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
                 early_stopping_rounds = 5, maximize = FALSE, verbose = verbose, ...) # should finish with , ...
    # TODO - xgb.cv uses cat() to give messages, very poor practice.  Sink them somewhere if verbose = FALSE?
    
    nrounds_use <- cv$best_iteration
  } else {if(nrounds_method == "v"){
      nrounds_use <- validate_xgbar(y, xreg = xreg, ...) $best_nrounds
  } else { 
    nrounds_use <- nrounds
      }
  }  
  
  if(verbose){message("Fitting xgboost model")}
  model <- xgboost(data = x, label = y2, nrounds = nrounds_use, verbose = verbose)
  
  fitted <- ts(c(rep(NA, maxlag), 
                 predict(model, newdata = x)), 
               frequency = f, start = min(time(origy)))
  
  # back transform the differencing
  if(trend_method == "differencing"){
    for(i in 1:diffs){
      fitted[!is.na(fitted)] <- ts(cumsum(fitted[!is.na(fitted)]), start = start(origy), frequency = f)
    }
    fitted <- fitted + JDMod(untransformedy[maxlag + 1], lambda = lambda)
  }
  
  # back transform the seasonal adjustment:
  if(seas_method == "decompose"){
    fitted <- fitted * decomp$seasonal
  }
  
  
  # back transform the modulus power transform:
  fitted <- InvJDMod(fitted, lambda = lambda)
  
  
  method <- paste0("xgbar(", maxlag, ", ", diffs, ", ")
  
  if(f == 1 | seas_method == "none"){
    method <- paste0(method, "'non-seasonal')")
  } else {
    method <- paste0(method, "'", seas_method, "')")
  }
  
  output <- list(
    y =  untransformedy, # original scale
    y2 = y2, # possibly all three of transformed, differenced and seasonally adjusted
    x = x,
    model = model,
    fitted = fitted, # original scale
    maxlag = maxlag,
    seas_method = seas_method,
    diffs = diffs,
    lambda = lambda,
    method = method
  )
  if(seas_method == "decompose"){
    output$decomp <- decomp
  }
  
  if(seas_method == "fourier" & f != 1){
    output$fx <- fx
    output$K <- K
  }
  
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

