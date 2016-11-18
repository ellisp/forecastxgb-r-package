# forecastxgb-r-package
The `forecastxgb` package provides time series modelling and forecasting functions that combine the machine learning approach of Chen, He and Benesty's [`xgboost`](https://CRAN.R-project.org/package=xgboost) with the convenient handling of time series and familiar API of Rob Hyndman's [`forecast`](http://github.com/robjhyndman/forecast).  It applies to time series the Extreme Gradient Boosting proposed in [*Greedy Function Approximation: A Gradient Boosting Machine*, by Jermoe Friedman in 2001](http://www.jstor.org/stable/2699986). xgboost has become an important machine learning algorithm; nicely explained in [this accessible documentation](http://xgboost.readthedocs.io/en/latest/model.html).

[![Travis-CI Build Status](https://travis-ci.org/ellisp/forecastxgb-r-package.svg?branch=master)](https://travis-ci.org/ellisp/forecastxgb-r-package)
[![CRAN version](http://www.r-pkg.org/badges/version/forecastxgb)](http://www.r-pkg.org/pkg/forecastxgb)
[![CRAN RStudio mirror downloads](http://cranlogs.r-pkg.org/badges/forecastxgb)](http://www.r-pkg.org/pkg/forecastxgb)


## Installation
Only on GitHub, but plan for a CRAN release in November 2016.  Comments and suggestions welcomed.

This implementation uses as explanatory features: 

* lagged values of the response variable
* numeric time,
* dummy variables for seasons.
* current and lagged values of any external regressors supplied as `xreg`





```r
devtools::install_github("ellisp/forecastxgb-r-package/pkg")
```

## Usage


## Basic usage

The workhorse function is `xgbar`.  This fits a model to a time series.  Under the hood, it creates a matrix of explanatory variables based on lagged versions of the response time series, dummy variables for seasons, and numeric time.  That matrix is then fed as the feature set for `xgboost` to do its stuff.

### Univariate

Usage with default values is straightforward.  Here it is fit to Australian monthly gas production 1956-1995, an example dataset provided in `forecast`:

```r
library(forecastxgb)
model <- xgbar(gas)
```

```
Stopping. Best iteration: 39
```
(Note: the "Stopping. Best iteration..." to the screen is produced by `xgboost::xgb.cv`, which uses `cat()` rather than `message()` to print information on its processing.)

By default, `xgbar` uses row-wise cross-validation to determine the best number of rounds of iterations for the boosting algorithm without overfitting.  A final model is then fit on the full available dataset.  The relative importance of the various features in the model can be inspected by `importance_xgb()` or, more conveniently, the `summary` method for objects of class `xgbar`.



```r
summary(model)
```

```

Importance of features in the xgboost model:
     Feature         Gain        Cover   Frequence
 1:    lag24 4.770928e-01 0.0782463031 0.040650407
 2:     lag1 3.206161e-01 0.1047365989 0.199767712
 3:    lag12 1.893528e-01 0.0863216266 0.061556330
 4:     time 8.961957e-03 0.0556261553 0.029036005
 5:    lag23 8.953940e-04 0.0466612754 0.031358885
 6:    lag11 8.703296e-04 0.0282116451 0.036004646
 7:    lag10 2.570542e-04 0.0356053604 0.036004646
 8:    lag15 2.566150e-04 0.0450439002 0.027874564
 9:     lag8 1.973701e-04 0.0213609057 0.030197445
10:    lag22 1.260024e-04 0.0467190388 0.029036005
11:    lag20 1.170261e-04 0.0213378004 0.012775842
12:    lag21 1.142763e-04 0.0198937153 0.018583043
13:    lag19 1.092708e-04 0.0213724584 0.020905923
14:    lag16 1.028515e-04 0.0583294824 0.034843206
15:     lag5 9.874865e-05 0.0350392791 0.052264808
16:     lag2 9.721764e-05 0.0354667283 0.067363531
17:    lag13 9.523553e-05 0.0178257856 0.022067364
18:    lag14 8.382413e-05 0.0216728281 0.026713124
19:     lag9 8.357240e-05 0.0370725508 0.039488966
20:     lag3 8.295872e-05 0.0224468577 0.046457607
21:    lag18 6.687009e-05 0.0204829020 0.015098722
22:     lag7 6.245799e-05 0.0195702403 0.027874564
23: season10 5.828134e-05 0.0202634011 0.006968641
24:     lag4 4.315718e-05 0.0280268022 0.034843206
25:     lag6 4.307912e-05 0.0164279113 0.022067364
26:    lag17 2.682831e-05 0.0156423290 0.010452962
27:  season4 2.178952e-05 0.0029459335 0.001161440
28:  season8 1.690069e-05 0.0181839187 0.005807201
29:  season5 1.298501e-05 0.0014556377 0.001161440
30: season12 1.202427e-05 0.0007162662 0.001161440
31:  season6 9.629637e-06 0.0082832717 0.003484321
32:  season7 6.573063e-06 0.0001963956 0.001161440
33:  season9 4.527429e-06 0.0002657116 0.002322880
34: season11 3.151527e-06 0.0034311460 0.001161440
35:  season3 3.629424e-07 0.0051178373 0.002322880
     Feature         Gain        Cover   Frequence

 36 features considered.
476 original observations.
452 effective observations after creating lagged features.
```
We see in the case of the gas data that the most important feature in explaining gas production is the production 12 months previously; and then other features decrease in importance from there but still have an impact.

Forecasting is the main purpose of this package, and a `forecast` method is supplied.  The resulting objects are of class `forecast` and familiar generic functions work with them.


```r
fc <- forecast(model, h = 12)
plot(fc)
```

![plot of chunk unnamed-chunk-5](figure/unnamed-chunk-5-1.png)

Note that prediction intervals are not currently available.

See the vignette for more extended examples.

### With external regressors
External regressors can be added by using the `xreg` argument familiar from other forecast functions like `auto.arima` and `nnetar`.  `xreg` can be a vector or `ts` object but is easiest to integrate into the analysis if it is a matrix (even a matrix with one column) with well-chosen column names; that way feature names persist meaningfully.  

The example below, with data taken from the `fpp` package supporting Athanasopoulos and Hyndman's [Forecasting Principles and Practice](https://www.otexts.org/fpp) book, shows income being used to explain consumption.  In the same way that the response variable `y` is expanded into lagged versions of itself, each column in `xreg` is expanded into lagged versions, which are then treated as individual features for `xgboost`.


```r
library(fpp)
consumption <- usconsumption[ ,1]
income <- matrix(usconsumption[ ,2], dimnames = list(NULL, "Income"))
consumption_model <- xgbar(y = consumption, xreg = income)
```

```
Stopping. Best iteration: 15
```

```r
summary(consumption_model)
```

```

Importance of features in the xgboost model:
        Feature         Gain        Cover   Frequence
 1:        lag1 0.3072355152 0.1235149070 0.176966292
 2:        lag2 0.2643423662 0.0812971680 0.132022472
 3: Income_lag0 0.0746265947 0.0817454980 0.056179775
 4:        lag3 0.0551095998 0.0801763431 0.073033708
 5:        time 0.0461121371 0.0932526339 0.061797753
 6:        lag5 0.0457533978 0.0377344392 0.050561798
 7:        lag8 0.0302735816 0.1256818352 0.075842697
 8: Income_lag8 0.0273765884 0.0366883359 0.042134831
 9:        lag7 0.0222697906 0.0421430173 0.033707865
10:        lag6 0.0215621970 0.0539490398 0.056179775
11: Income_lag6 0.0169146201 0.0080699395 0.019662921
12: Income_lag1 0.0164029025 0.0487932452 0.028089888
13: Income_lag2 0.0158772693 0.0302622730 0.036516854
14: Income_lag7 0.0155522401 0.0160651573 0.025280899
15: Income_lag5 0.0150102639 0.0292908914 0.025280899
16:        lag4 0.0133260132 0.0596278861 0.047752809
17: Income_lag4 0.0067224489 0.0165882089 0.025280899
18:     season2 0.0024907762 0.0056788463 0.008426966
19:     season3 0.0015714749 0.0143465591 0.011235955
20: Income_lag3 0.0011878816 0.0147201674 0.011235955
21:     season4 0.0002823407 0.0003736083 0.002808989
        Feature         Gain        Cover   Frequence

 21 features considered.
164 original observations.
156 effective observations after creating lagged features.
```
We see that the two most important features explaining consumption are the two previous quarters' values of consumption; followed by the income in this quarter; and so on.


The challenge of using external regressors in a forecasting environment is that to forecast, you need values of the future external regressors.  One way this is sometimes done is by first forecasting the individual regressors.  In the example below we do this, making sure the data structure is the same as the original `xreg`.  When the new value of `xreg` is given to `forecast`, it forecasts forward the number of rows of the new `xreg`.  

```r
income_future <- matrix(forecast(xgbar(usconsumption[,2]), h = 10)$mean, 
                        dimnames = list(NULL, "Income"))
```

```
Stopping. Best iteration: 1
```

```r
plot(forecast(consumption_model, xreg = income_future))
```

![plot of chunk unnamed-chunk-7](figure/unnamed-chunk-7-1.png)

## Future developments
Future work might include: 

* additional automated time-dependent features (eg dummy variables for trading days, Easter, etc)
* ability to include xreg values that don't get lagged
* some kind of automated multiple variable forecasting, similar to a vector-autoregression.

