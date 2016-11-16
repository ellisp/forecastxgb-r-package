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
Stopping. Best iteration: 20
```
(Note: the "Stopping. Best iteration..." to the screen is produced by `xgboost::xgb.cv`, which uses `cat()` rather than `message()` to print information on its processing.)

By default, `xgbar` uses row-wise cross-validation to determine the best number of rounds of iterations for the boosting algorithm without overfitting.  A final model is then fit on the full available dataset.  The relative importance of the various features in the model can be inspected by `importance_xgb()` or, more conveniently, the `summary` method for objects of class `xgbar`.



```r
summary(model)
```

```

Importance of features in the xgboost model:
     Feature         Gain       Cover   Frequence
 1:    lag12 4.866644e-01 0.126320210 0.075503356
 2:    lag11 2.793567e-01 0.049217848 0.035234899
 3:    lag13 1.044469e-01 0.037102362 0.030201342
 4:    lag24 7.987905e-02 0.150929134 0.080536913
 5:     time 2.817163e-02 0.125291339 0.077181208
 6:     lag1 1.190114e-02 0.131002625 0.152684564
 7:    lag23 5.306595e-03 0.015685039 0.018456376
 8:     lag2 7.431663e-04 0.072188976 0.063758389
 9:    lag14 5.801733e-04 0.014152231 0.021812081
10:     lag6 4.071911e-04 0.013480315 0.031879195
11:    lag18 3.345186e-04 0.026120735 0.021812081
12:     lag5 2.781746e-04 0.023244094 0.043624161
13:    lag16 2.564357e-04 0.012262467 0.020134228
14:    lag17 2.067079e-04 0.011128609 0.021812081
15:    lag21 1.918721e-04 0.015769029 0.023489933
16:     lag4 1.698715e-04 0.012703412 0.036912752
17:    lag22 1.417012e-04 0.019485564 0.025167785
18:    lag19 1.291178e-04 0.009511811 0.016778523
19:    lag20 1.188570e-04 0.005312336 0.010067114
20:     lag8 1.115240e-04 0.016629921 0.023489933
21:     lag9 1.051375e-04 0.021375328 0.026845638
22:    lag10 1.035566e-04 0.036829396 0.035234899
23:  season7 1.008707e-04 0.006950131 0.008389262
24:     lag7 8.698124e-05 0.007097113 0.021812081
25:     lag3 7.582023e-05 0.006740157 0.038590604
26:    lag15 6.305601e-05 0.006677165 0.013422819
27:  season4 5.440121e-05 0.001805774 0.003355705
28:  season5 7.204729e-06 0.002918635 0.008389262
29:  season8 3.280837e-06 0.003422572 0.003355705
30:  season6 2.090122e-06 0.008923885 0.005033557
31: season10 1.287062e-06 0.007307087 0.001677852
32: season12 5.436832e-07 0.002414698 0.003355705
     Feature         Gain       Cover   Frequence

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
Stopping. Best iteration: 20
```

```r
summary(consumption_model)
```

```

Importance of features in the xgboost model:
        Feature         Gain       Cover   Frequence
 1:        lag2 0.2756514729 0.092637765 0.111353712
 2:        lag1 0.2605180976 0.101230735 0.200873362
 3: Income_lag0 0.0796829151 0.112817386 0.061135371
 4:        lag8 0.0666614841 0.151291717 0.069868996
 5: Income_lag1 0.0482135582 0.063698858 0.041484716
 6:        lag3 0.0445982901 0.073622353 0.080786026
 7:        lag6 0.0379633249 0.050060982 0.043668122
 8:        time 0.0339147177 0.064641313 0.037117904
 9: Income_lag6 0.0306253069 0.027774698 0.030567686
10: Income_lag8 0.0272623976 0.033928373 0.039301310
11: Income_lag4 0.0187267213 0.023173301 0.041484716
12: Income_lag5 0.0186428336 0.020623129 0.030567686
13:        lag5 0.0137730243 0.018738219 0.043668122
14:        lag7 0.0120758940 0.043242045 0.045851528
15:        lag4 0.0104237353 0.064253243 0.048034934
16: Income_lag2 0.0080956267 0.014635769 0.019650655
17: Income_lag7 0.0060837617 0.011586650 0.024017467
18: Income_lag3 0.0045807356 0.005987360 0.013100437
19:     season3 0.0023754560 0.025002772 0.015283843
20:     season4 0.0001306466 0.001053332 0.002183406

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

