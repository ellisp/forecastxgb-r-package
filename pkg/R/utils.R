
# not exported
# function to take a vector and create a matrix of itself and lagged values
lagv <- function(x, maxlag, keeporig = TRUE){
  if(!is.vector(x) & !is.ts(x)){
    stop("x must be a vector or time series")
  }
  x <- as.vector(x)
  n <- length(x)
  z <- matrix(0, nrow = (n - maxlag), ncol = maxlag + 1)
  for(i in 1:ncol(z)){
    z[ , i] <- x[(maxlag + 2 - i):(n + 1 - i)] 
  }
  varname <- "hi-there"
  colnames(z) <- c(varname, paste0(varname, "_lag", 1:maxlag))
  if(!keeporig){
    z <- z[ ,-1]
  }
  return(z)
}

