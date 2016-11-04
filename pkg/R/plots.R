
#' Plot xgbts object
#' 
#' plot method for an object created by xgbts
#' @export
#' @import graphics
#' @method plot xgbts
#' @param x An object created by \code{xgbts}
#' @param ... Additional arguments passed through to \code{plot()}
plot.xgbts <- function(x, ...){
  ts.plot(x$y, col = "brown", ...)
  lines(x$fitted, col = "blue")
  
}