#' Show importance of features in a xgbar model
#' 
#' This is a light wrapper for \code{xgboost::xbg.importance} to make it easier to use with objects of class \code{xgbar}
#' @export
#' @param object An object of class \code{xgbar}, usually created with \code{xgbar()}
#' @param ... Extra parameters passed through to \code{xgb.importance}
#' @return A \code{data.table} of the features used in the model with their average gain 
#' (and their weight for boosted tree model) in the model.
#' @seealso \code{\link[xgboost]{xgb.importance}}, \code{\link{summary.xgbar}}, \code{\link{xgbar}}.
#' @author Peter Ellis
xgbar_importance <- function(object, ...){
  if(class(object) != "xgbar"){
    stop("'object' should be an object of class xgbar.")
  }
  xgb.importance(colnames(object$x), model = object$model, ...)
}

#' Summary of an xgbar object
#' 
#' summary method for an object created by xgbar
#' @aliases print.summary.xgbar
#' @export
#' @param object An object created by \code{\link{xgbar}}
#' @param ... Ignored.
#' @author Peter Ellis
#' @seealso  \code{\link{xgbar}}
#' @examples
#' \dontrun{
#' # Half-hourly electricity demand in England and Wales, takes a few minutes
#' electricity_model <- xgbar(taylor)
#' summary(electricity_model)
#' electricity_fc <- forecast(electricity_model, h = 500)
#' plot(electricity_fc)
#' }
summary.xgbar <- function(object, ...){
  ans <- object
  ans$importance <- xgbar_importance(object)
  ans$n <- length(object$y)
  ans$effectn <- length(object$y2)
  ans$ncolx <- ncol(object$x)
  class(ans) <- "summary.xgbar"
  return(ans)
}
  
#' @export
#' @method print summary.xgbar
print.summary.xgbar <- function(x, ...){
  
  cat("\nImportance of features in the xgboost model:\n")
  print(x$importance)
  
  cat(paste("\n", x$ncolx, "features considered.\n"))
  cat(paste0(x$n, " original observations.\n", 
            x$effectn, " effective observations after creating lagged features.\n"))
}


#' Plot xgbar object
#' 
#' plot method for an object created by xgbar
#' @export
#' @import graphics
#' @method plot xgbar
#' @param x An object created by \code{xgbar}
#' @param ... Additional arguments passed through to \code{plot()}
#' @author Peter Ellis
#' @seealso  \code{\link{xgbar}}
#' @examples
#' model <- xgbar(AirPassengers)
#' plot(model)
plot.xgbar <- function(x, ...){
  ts.plot(x$y, col = "brown", ...)
  lines(x$fitted, col = "blue")
  
}


#' Tourism forecasting results
#' 
#' Summary data from four models, and 11 combinations of models, against the data from the 2010 tourism forecasting competition.
#' 
#' Full details of how this was generated are in the Vignette.  This shows the average mean absolute scaled error 
#' (MASE) from using \code{xgbar} (x), \code{auto.arima} (a), \code{nnetar} (n) and \code{thetaf} (f) to generate forecasts of 1,311 tourism data series.
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
#' n: Neural network; forecast::nnetar\nx: Extreme gradient boosting; forecastxgb::xgbar"
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



#' M3 forecasting results
#' 
#' Summary data from four models, and 11 combinations of models, against the data from the M3 forecasting competition.
#' 
#' Full details are in the vignette of how a similar series with tourism competition data was generated.  
#' The data shows the average mean absolute scaled error 
#' (MASE) from using \code{xgbar} (x), \code{auto.arima} (a), \code{nnetar} (n) and \code{thetaf} (f) to 
#' generate forecasts of 3,003 data series from a range of sectors, in the M3 forecasting competition.
#' 
#' 
#' \itemize{
#' \item MASE A mean mean absolute squared error
#' \item model model, or ensemble of models, to which the MASE applies
#' \item Frequency The frequency of the subset of data from which the mean MASE was calculated.
#' }
#' @format A data frame with 75 rows and three columns.
#' @author Peter Ellis
#' @examples
#' if(require(ggplot2)){
#' leg <- "f: Theta; forecast::thetaf\na: ARIMA; forecast::auto.arima
#' n: Neural network; forecast::nnetar\nx: Extreme gradient boosting; forecastxgb::xgbar"
#' 
#' ggplot(Mcomp_results, aes(x = model, y =  MASE, colour = Frequency, label = model)) +
#'   geom_text(size = 4) +
#'   geom_line(aes(x = as.numeric(model)), alpha = 0.25) +
#'   annotate("text", x = 2, y = 3.5, label = leg, hjust = 0) +
#'   ggtitle("Average error of four different timeseries forecasting methods
#'M3 Forecasting Competition data") +
#'   labs(x = "Model, or ensemble of models
#'(further to the left means better overall performance)",
#'   y = "Mean scaled absolute error\n(smaller numbers are better)") +
#'   theme_grey(9)
#'   }
"Mcomp_results"


