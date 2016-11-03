# forecastxgb-r-package
An R package for time series models and forecasts with xgboost compatible with {forecast} S3 classes

Only on GitHub.  Incomplete.  


```r
devtools::install_github("ellisp/forecastxgb-r-package/pkg")
```

Seems to overfit rather severely:

```r
model <- xgbts(AirPassengers)
```

```
## Starting cross-validation
```

```
## Stopping. Best iteration: 54
```

```
## Fitting xgboost model
```

```r
fc <- forecast(model, h = 12)
accuracy(fc)
```

```
##                        ME       RMSE        MAE           MPE       MAPE
## Training set 0.0003279368 0.05035866 0.03653628 -0.0005760288 0.01332563
##                     MASE       ACF1
## Training set 0.001140679 -0.1669532
```

```r
plot(fc)
```

![plot of chunk unnamed-chunk-2](figure/unnamed-chunk-2-1.png)

