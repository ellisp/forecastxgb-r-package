#' Show importance of features in a xgbts model
#' 
#' This is a light wrapper for \code{xgboost::xbg.importance} to make it easier to use with objects of class \code{xgbts}
#' @export
#' @param object An object of class \code{xgbts}, usually created with \code{xgbts()}
#' @param ... Extra parameters passed through to \code{xgb.importance}
#' @return A \code{data.table} of the features used in the model with their average gain 
#' (and their weight for boosted tree model) in the model.
#' @seealso \code{\link[xgboost]{xgb.importance}}
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
summary.xgbts <- function(object){
  ans <- object
  ans$importance <- xgbts_importance(object)
  ans$n <- length(object$y)
  ans$effectn <- length(object$y2)
  ans$ncolx <- ncol(object$x)
  class(ans) <- "summary.xgbts"
  return(ans)
}
  
#' @export
print.summary.xgbts <- function(ans){
  
  cat("\nImportance of features in the xgboost model:\n")
  print(ans$importance)
  
  cat(paste("\n", ans$ncolx, "features considered.\n"))
  cat(paste0(ans$n, " original observations.\n", 
            ans$effectn, " effective observations after creating lagged features.\n"))
}
