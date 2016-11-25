
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
#' @param lambda Value of lambda to be used for modulus power transformation of \code{y} (which is similar to Box-Cox transformation 
#' but works with negative values too), performed before using xgboost (and inverse transformed to the original scale afterwards).
#' Set \code{lambda = 1} if no transformation is desired.  
#' The transformation is only applied to \code{y}, not \code{xreg}.
#' @param seas_method Method for dealing with seasonality.
#' @param ... Additional arguments passed to \code{xgboost}.  Only works if nrounds_method is "cv" or "manual".
#' @details This is the workhorse function for the \code{forecastxgb} package.
#' It fits a model to a time series.  Under the hood, it creates a matrix of explanatory variables 
#' based on lagged versions of the response time series, dummy variables for seasons, and numeric time.  That 
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
                  lambda = BoxCox.lambda(abs(y)), verbose = FALSE, 
                  seas_method = c("dummies", "decompose"), ...){
  # y <- seaice_ts; nrounds_method = "cv"; seas_method = "dummies" # for dev

  nrounds_method = match.arg(nrounds_method)
  seas_method = match.arg(seas_method)
  
  #TODO - implement decomposition
  # maxlags can be much fewer, down to 1, if working with adjusted series
  # if series is < 3*f+1, should force it to use decomposition
  
  # TODO - fourier as a third option for seas_method
  # TODO - "none" as an option for seas_method
  
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
  untransformedy <- y
  origy <- JDMod(y, lambda = lambda)
  
  # not sure whether transformation should be before or after seasonal adjustment...
  if(seas_method == "decompose"){
    decomp <- decompose(origy, type = "multiplicative")
    origy <- seasadj(decomp)
  }
  

  f <- stats::frequency(y)
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
    warning(paste("Rounding maxlag up to", maxlag))
  }
  
    
  origxreg <- xreg
  n <- orign - maxlag
  y2 <- ts(origy[-(1:(maxlag))], start = time(origy)[maxlag + 1], frequency = f)

  if(nrounds_method == "cv" & n < 15){
    warning("y is too short for cross-validation.  Will validate on the most recent 20 per cent instead.")
    nrounds_method <- "v"
  }
  
  
    
  #----------------------------creating x--------------------
  # create lagged versions of y to be part of x
  ncolx <- ifelse(seas_method == "dummies", maxlag + f, maxlag + 1)
  x <- matrix(0, nrow = n, ncol = ncolx)
  x[ , 1:maxlag] <- lagv(origy, maxlag, keeporig = FALSE)
  
  # add a linear time variable for x
  x[ , maxlag + 1] <- time(y2)
  
  # one hot encoding of seasons
  if(f > 1 & seas_method == "dummies"){
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
  
  fitted <- ts(c(rep(NA, maxlag), 
                 predict(model, newdata = x)), 
               frequency = f, start = min(time(origy)))
  
  # back transform the seasonal adjustment:
  if(seas_method == "decompose"){
    fitted <- fitted * decomp$seasonal
  }
  
  # back transform the modulus power transform:
  fitted <- InvJDMod(fitted, lambda = lambda)
  
  output <- list(
    y =  untransformedy, # original scale
    y2 = y2, # possibly both transformed and seasonally adjusted
    x = x,
    model = model,
    fitted = fitted, # original scale
    maxlag = maxlag,
    seas_method = seas_method,
    lambda = lambda
  )
  if(seas_method == "decompose"){
    output$decomp <- decomp
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

