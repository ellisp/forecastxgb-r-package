#' Show importance of features in a xgbts model
#' 
#' This is a light wrapper for \code{xgboost::xbg.importance} to make it easier to use with objects of class \code{xgbts}
#' @export
#' @param object An object of class \code{xgbts}, usually created with \code{xgbts()}
#' @param ... Extra parameters passed through to \code{xgb.importance}
#' @return A \code{data.table} of the features used in the model with their average gain 
#' (and their weight for boosted tree model) in the model.
#' @seealso \code{\link[xgboost]{xgb.importance}}
importance <- function(object, ...){
  xgb.importance(colnames(object$x), model = object$model, ...)
}