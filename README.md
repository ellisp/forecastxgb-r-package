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
## Stopping. Best iteration: 59
```

```
## Fitting xgboost model
```

```r
fc <- forecast(model, h = 12)
accuracy(fc)
```

```
##                        ME       RMSE        MAE           MPE        MAPE
## Training set 0.0005597432 0.03079609 0.02244008 -8.814484e-05 0.008078876
##                      MASE       ACF1
## Training set 0.0007005892 -0.1795438
```

```r
plot(fc)
```

![plot of chunk unnamed-chunk-2](figure/unnamed-chunk-2-1.png)


## Tourism data example

```r
library(Tcomp)

thedata <- tourism[[1]]

x <-thedata$x
h <- thedata$h

model <- xgbts(x)
```

```
## Starting cross-validation
```

```
## Stopping. Best iteration: 18
```

```
## Fitting xgboost model
```

```r
fc <- forecast(model, h = h)
plot(fc, bty = "l")
lines(thedata$xx, col = "red")
legend("topleft", legend = c("xgb forecast", "actual"), lty = 1, col = c("blue", "red"), bty ="n")
```

![plot of chunk unnamed-chunk-3](figure/unnamed-chunk-3-1.png)

```r
accuracy(fc, thedata$xx)
```

```
##                      ME      RMSE       MAE       MPE      MAPE      MASE
## Training set   9.443368  30.26095  20.57932 0.2722262 0.8535777 0.1082913
## Test set     247.664745 383.39113 291.86403 6.7443169 8.8075372 1.5358296
##                      ACF1 Theil's U
## Training set -0.008168322        NA
## Test set      0.110661922 0.4039669
```

```r
xgbts_importance(fc)
```

```
## Error in readLines(filename_dump): 'con' is not a connection
```

## Non-seasonal data


```r
obj <- xgbts(Nile)
```

```
## Starting cross-validation
```

```
## Stopping. Best iteration: 16
```

```
## Fitting xgboost model
```

```r
xgbts_importance(obj)
```

```
##    Feature       Gain      Cover  Frequence
## 1:    time 0.30243836 0.20312975 0.11290323
## 2:    lag1 0.19279690 0.16104527 0.17338710
## 3:    lag6 0.15579016 0.10832574 0.12903226
## 4:    lag4 0.10230534 0.14995442 0.10080645
## 5:    lag2 0.06979245 0.10954117 0.15322581
## 6:    lag8 0.05925490 0.08720754 0.07661290
## 7:    lag5 0.05015732 0.05591006 0.09274194
## 8:    lag3 0.04338225 0.07292616 0.10080645
## 9:    lag7 0.02408232 0.05195989 0.06048387
```

```r
fc <- forecast(obj, 30)
plot(fc, bty = "l")
```

![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4-1.png)

