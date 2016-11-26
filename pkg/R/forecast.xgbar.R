#' Forecasting using xgboost models
#' 
#' Returns forecasts and other information for xgboost timeseries modesl fit with \code{xbgts}
#' 
#' @export
#' @import forecast
#' @import xgboost
#' @importFrom utils tail
#' @method forecast xgbar
#' @param object An object of class "\code{xgbar}".  Usually the result of a call to \code{\link{xgbar}}.
#' @param h Number of periods for forecasting.  If \code{xreg} is provided, the number of rows of \code{xreg} will be 
#' used and \code{h} is ignored with a warning.  If both \code{h} and \code{xreg} are \code{NULL} then 
#' \code{h = ifelse(frequency(object$y) > 1, 2 * frequency(object$y), 10)}
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
  lambda <- object$lambda
  seas_method <- object$seas_method
  
  # forecast time x variable
  htime <- time(ts(rep(0, h), frequency = f, start = max(time(object$y)) + 1 / f))

  # forecast fourier pairs
  if(f > 1 & seas_method == "fourier"){
    fxh <- fourier(object$y2, K = object$K, h = h)
  }
    
  forward1 <- function(x, y, model, xregpred, i){
    newrow <- c(
      # latest lagged value:
      y[length(y)], 
      # previous lagged values:
      x[nrow(x), 1:(object$maxlag - 1)])
    if(object$maxlag == 1){
      newrow = newrow[-1]
    }
    
    # seasonal dummies if 'dummies':
    if(f > 1 & seas_method == "dummies"){
      # for dummy variables it's ok to just take the set of dummies from f time periods before:
      newrow <- c(newrow, x[(nrow(x) + 1 - f), (object$maxlag + 1):(object$maxlag + f - 1)])
    }
    # seasonal dummies if 'fourier':
    if(f > 1 & seas_method == 'fourier'){
      # for fourier variables, 
      newrow <- c(newrow, fxh[i, ])
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
    tmp <- forward1(x, y, model = object$model, xregpred = xreg3[i, ], i = i)  
    x <- tmp$x
    y <- tmp$y
  }
  
  # fitted and forecast object, on possibly untransformed, undifferenced and seasonally adjusted scale
  y <- ts(y[-(1:length(object$y2))],
          frequency = f,
          start = max(time(object$y)) + 1 / f) 
  
  # back transform the differencing
  if(object$diffs > 0){
    for(i in 1:object$diffs){
      y <- ts(cumsum(y)  , start = start(y), frequency = f)
    }
    y <- y + JDMod(object$y[length(object$y)], lambda = lambda)
  }
  
  # back transform the seasonal adjustment:
  if(seas_method == "decompose"){
    multipliers <- tail(object$decomp$seasonal, f)
    if(h < f){
      multipliers <- multipliers[1:h]
    }
    y <- y * multipliers
  }
  
  # back transform the modulus power transform:
  y <- InvJDMod(y, lambda = lambda)
  
  output <- list(
    x = object$y,
    mean = y,
    fitted = object$fitted,
    newx = x,
    method = object$method
  )
  class(output) <- "forecast"
  return(output)
  
}
