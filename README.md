# forecastxgb-r-package
An R package for time series models and forecasts with xgboost compatible with {forecast} S3 classes

Only on GitHub.  Very early days, incomplete.  So far only works with seasonal univariate continuous time series.  Planned addition is support for `xreg` and for non-seasonal data.

This implementation uses as features lagged values of the target variable, linear time, and dummy variables for seasons.


```r
devtools::install_github("ellisp/forecastxgb-r-package/pkg")
```

## Usage
Seems to overfit rather severely, judging from the in-sample accuracy.  This is despite there being a cross-validation step:

```r
library(forecastxgb)
model <- xgbts(AirPassengers)
```

```
## Starting cross-validation
```

```
## Stopping. Best iteration: 40
```

```
## Fitting xgboost model
```

```r
fc <- forecast(model, h = 12)
accuracy(fc)
```

```
##                      ME      RMSE       MAE         MPE      MAPE
## Training set 0.01076215 0.2486154 0.1879821 0.000896467 0.0685559
##                     MASE       ACF1
## Training set 0.005868881 -0.1446392
```

```r
plot(fc)
```

![plot of chunk unnamed-chunk-2](figure/unnamed-chunk-2-1.png)


## Tourism data example

```r
library(Tcomp)

thedata <- tourism[[1]]
plot(thedata)
```

![plot of chunk unnamed-chunk-3](figure/unnamed-chunk-3-1.png)

```r
x <-thedata$x
h <- thedata$h

model <- xgbts(x)
```

```
## Starting cross-validation
```

```
## Stopping. Best iteration: 21
```

```
## Fitting xgboost model
```

```r
fc <- forecast(model, h = h)
plot(fc, bty = "l")
lines(thedata$xx, col = "red")
```

![plot of chunk unnamed-chunk-3](figure/unnamed-chunk-3-2.png)

```r
accuracy(fc, thedata$xx)
```

```
##                      ME      RMSE       MAE        MPE      MAPE
## Training set   4.244689  20.11645  14.28426 0.09989322 0.6468516
## Test set     241.150926 378.42260 286.04720 6.56172156 8.6439682
##                    MASE       ACF1 Theil's U
## Training set 0.07516579 -0.0595232        NA
## Test set     1.50522066  0.1084859 0.3993886
```

