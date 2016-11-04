# forecastxgb-r-package
An R package for time series models and forecasts with xgboost compatible with {forecast} S3 classes

Only on GitHub.  Very early days, incomplete.  Planned addition is support for `xreg`.

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

![plot of chunk unnamed-chunk-5](figure/unnamed-chunk-5-1.png)


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
## Stopping. Best iteration: 16
```

```
## Fitting xgboost model
```

```r
xgbts_importance(model)
```

```
##     Feature         Gain       Cover   Frequence
##  1:   lag12 8.018487e-01 0.391058180 0.184549356
##  2:   lag24 1.918747e-01 0.131393987 0.064377682
##  3:   lag18 1.000142e-03 0.041585318 0.038626609
##  4:   lag15 7.635316e-04 0.031628270 0.060085837
##  5:    time 7.169526e-04 0.060132761 0.068669528
##  6:    lag8 5.964512e-04 0.023916439 0.025751073
##  7:    lag1 4.274108e-04 0.029773526 0.094420601
##  8:    lag2 4.167529e-04 0.025673565 0.072961373
##  9:    lag6 4.058586e-04 0.021183132 0.038626609
## 10:    lag4 2.855754e-04 0.012592737 0.038626609
## 11:   lag20 2.603440e-04 0.029480672 0.034334764
## 12:   lag11 2.330575e-04 0.025380711 0.030042918
## 13:   lag23 2.044214e-04 0.042171027 0.034334764
## 14:    lag9 2.020953e-04 0.026161656 0.025751073
## 15:   lag21 1.509504e-04 0.008883249 0.017167382
## 16:    lag5 1.228632e-04 0.012592737 0.025751073
## 17:   lag16 1.120658e-04 0.014252245 0.025751073
## 18:    lag3 9.880472e-05 0.016790316 0.025751073
## 19:   lag13 8.332815e-05 0.013764155 0.012875536
## 20:   lag14 6.100852e-05 0.012787973 0.025751073
## 21:   lag19 4.578575e-05 0.008004686 0.012875536
## 22:   lag17 3.231468e-05 0.003123780 0.008583691
## 23:   lag10 2.105136e-05 0.008102304 0.012875536
## 24: season3 2.043336e-05 0.005954705 0.004291845
## 25:    lag7 1.296105e-05 0.002342835 0.012875536
## 26:   lag22 2.435939e-06 0.001269036 0.004291845
##     Feature         Gain       Cover   Frequence
```

```r
fc <- forecast(model, h = h)
plot(fc, bty = "l")
lines(thedata$xx, col = "red")
legend("topleft", legend = c("xgb forecast", "actual"), lty = 1, col = c("blue", "red"), bty ="n")
```

![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-1.png)

```r
accuracy(fc, thedata$xx)
```

```
##                     ME      RMSE       MAE      MPE     MAPE      MASE
## Training set  16.44529  40.36934  26.58402 0.492309 1.057617 0.1398889
## Test set     262.53091 393.97171 305.39539 7.215540 9.214990 1.6070336
##                    ACF1 Theil's U
## Training set 0.05805567        NA
## Test set     0.08914576 0.4090183
```

## Non-seasonal data


```r
obj <- xgbts(Nile)
```

```
## Starting cross-validation
```

```
## Stopping. Best iteration: 9
```

```
## Fitting xgboost model
```

```r
xgbts_importance(obj)
```

```
##    Feature       Gain      Cover  Frequence
## 1:    time 0.32993131 0.15049036 0.07070707
## 2:    lag1 0.21164761 0.22827190 0.19191919
## 3:    lag6 0.15271119 0.12783226 0.17171717
## 4:    lag4 0.09909504 0.17078120 0.11111111
## 5:    lag8 0.05869901 0.09638147 0.10101010
## 6:    lag5 0.04873008 0.05918160 0.09090909
## 7:    lag2 0.04157808 0.07778154 0.12121212
## 8:    lag3 0.04131306 0.05850524 0.09090909
## 9:    lag7 0.01629463 0.03077443 0.05050505
```

```r
fc <- forecast(obj, 30)
plot(fc, bty = "l")
```

![plot of chunk unnamed-chunk-7](figure/unnamed-chunk-7-1.png)

