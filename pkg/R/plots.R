
#' @export
#' @import graphics
plot.xgbts <- function(object, ...){
  ts.plot(object$y, col = "brown")
  lines(object$fitted, col = "blue")
  
}