#' Show importance of features in a xgbts model
#' 
#' This is a light wrapper for \code{xgboost::xbg.importance} to make it easier to use with objects of class \code{xgbts}
#' @export
#' @param object An object of class \code{xgbts}, usually created with \code{xgbts()}
#' @param ... Extra parameters passed through to \code{xgb.importance}
#' @return A \code{data.table} of the features used in the model with their average gain 
#' (and their weight for boosted tree model) in the model.
#' @seealso \code{\link[xgboost]{xgb.importance}}. \code{\link{summary.xgbts}}
#' @author Peter Ellis
xgbts_importance <- function(object, ...){
  if(class(object) != "xgbts"){
    stop("'object' should be an object of class xgbts.")
  }
  xgb.importance(colnames(object$x), model = object$model, ...)
}

#' Summary of an xgbts object
#' 
#' summary method for an object created by xgbts
#' @aliases print.summary.xgbts
#' @export
#' @param object An object created by \code{xgbts}
#' @param ... Ignored.
#' @author Peter Ellis
#' @examples
#' \dontrun{
#' # Half-hourly electricity demand in England and Wales, takes a few minutes
#' electricity_model <- xgbts(taylor)
#' summary(electricity_model)
#' electricity_fc <- forecast(electricity_model, h = 500)
#' plot(electricity_fc)
#' }
summary.xgbts <- function(object, ...){
  ans <- object
  ans$importance <- xgbts_importance(object)
  ans$n <- length(object$y)
  ans$effectn <- length(object$y2)
  ans$ncolx <- ncol(object$x)
  class(ans) <- "summary.xgbts"
  return(ans)
}
  
#' @export
#' @method print summary.xgbts
print.summary.xgbts <- function(x, ...){
  
  cat("\nImportance of features in the xgboost model:\n")
  print(x$importance)
  
  cat(paste("\n", x$ncolx, "features considered.\n"))
  cat(paste0(x$n, " original observations.\n", 
            x$effectn, " effective observations after creating lagged features.\n"))
}


#' Plot xgbts object
#' 
#' plot method for an object created by xgbts
#' @export
#' @import graphics
#' @method plot xgbts
#' @param x An object created by \code{xgbts}
#' @param ... Additional arguments passed through to \code{plot()}
#' @author Peter Ellis
#' @examples
#' model <- xgbts(AirPassengers)
#' plot(model)
plot.xgbts <- function(x, ...){
  ts.plot(x$y, col = "brown", ...)
  lines(x$fitted, col = "blue")
  
}


#' Tourism forecasting results
#' 
#' Summary data from four models, and 11 combinations of models, against the data from the 2010 tourism forecasting competition.
#' 
#' Full details of how this was generated are in the Vignette.  This shows the average mean absolute scaled error 
#' (MASE) from using \code{xgbts} (x), \code{auto.arima} (a), \code{nnetar} (n) and \code{thetaf} (f) to generate forecasts of 1,311 tourism data series.
#' 
#' 
#' \itemize{
#' \item MASE A mean mean absolute squared error
#' \item model model, or ensemble of models, to which the MASE applies
#' \item Frequency The frequency of the subset of data from which the mean MASE was calculated.
#' }
#' @format A data frame with 60 rows and three columns.
#' @author Peter Ellis
#' @examples
#' if(require(ggplot2)){
#' leg <- "f: Theta; forecast::thetaf\na: ARIMA; forecast::auto.arima
#' n: Neural network; forecast::nnetar\nx: Extreme gradient boosting; forecastxgb::xgbts"
#' 
#' ggplot(Tcomp_results, aes(x = model, y =  MASE, colour = Frequency, label = model)) +
#'   geom_text(size = 4) +
#'   geom_line(aes(x = as.numeric(model)), alpha = 0.25) +
#'   annotate("text", x = 2, y = 3.5, label = leg, hjust = 0) +
#'   ggtitle("Average error of four different timeseries forecasting methods
#'2010 Tourism Forecasting Competition data") +
#'   labs(x = "Model, or ensemble of models
#'(further to the left means better overall performance)",
#'   y = "Mean scaled absolute error\n(smaller numbers are better)") +
#'   theme_grey(9)
#'   }
"Tcomp_results"




