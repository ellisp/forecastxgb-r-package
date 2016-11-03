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
## Stopping. Best iteration: 64
```

```
## Fitting xgboost model
```

```r
fc <- forecast(model, h = 12)
fc
```

```
##           Jan      Feb      Mar      Apr      May      Jun      Jul
## 1961 454.0357 446.6316 444.8359 503.9461 535.9756 621.7036 621.3882
##           Aug      Sep      Oct      Nov      Dec
## 1961 603.4312 556.1086 474.5876 419.3545 449.9680
```

```r
plot(fc)
```

![plot of chunk unnamed-chunk-2](figure/unnamed-chunk-2-1.png)

