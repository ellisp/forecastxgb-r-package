
#' Plot xgbts object
#' 
#' plot method for an object created by xgbts
#' @export
#' @import graphics
#' @param object An object created by \code{xgbts}
#' @param ... Additional arguments passed through to \code{plot()}
plot.xgbts <- function(object, ...){
  ts.plot(object$y, col = "brown")
  lines(object$fitted, col = "blue")
  
}