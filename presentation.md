---
title       : PortfolioAnalytics
subtitle    : R/Finance 2015
author      : Ross Bennett
date        : May 29, 2015
framework   : io2012 # {io2012, html5slides, shower, dzslides, ...}
ext_widgets : {rCharts: libraries/nvd3}
widgets     : mathjax
mode        : selfcontained
---





## Overview
* Discuss Portfolio Optimization
* Introduce PortfolioAnalytics
* Demonstrate PortfolioAnalytics with Examples

<!--
* Discuss Portfolio Optimization
    * Background and challenges of portfolio theory
* Introduce PortfolioAnalytics
    * What PortfolioAnalytics does and the problems it solves
* Demonstrate PortfolioAnalytics with Examples
    * Brief overview of the examples I will be giving
-->

---

## Modern Portfolio Theory
"Modern" Portfolio Theory (MPT) was introduced by Harry Markowitz in 1952.

In general, MPT states that an investor's objective is to maximize portfolio expected return for a given amount of risk.

General Objectives

* Maximize a measure of gain per unit measure of risk
* Minimize a measure of risk

How do we define risk? What about more complex objectives and constraints?

<!--
Several approaches follow the Markowitz approach using mean return as a measure of gain and standard deviation of returns as a measure of risk. This is an academic approach. 
-->

---

## Portfolio Optimization Objectives
* Minimize Risk
    * Volatility
    * Tail Loss (VaR, ES)
    * Other Downside Risk Measure
* Maximize Risk Adjusted Return
    * Sharpe Ratio, Modified Sharpe Ratio
    * Several Others
* Risk Budgets
    * Equal Component Contribution to Risk (i.e. Risk Parity)
    * Limits on Component Contribution
* Maximize a Utility Function
    * Quadratic, CRRA, etc.

<!--
* Expand on pros/cons of closed-form solvers vs. global solvers and what objectives can be solved.
* The challenge here is knowing what solver to use and the capabilities/limits of the chosen solver. 
* Some of these problems can be formulated as a quadratic or linear programming problem. Constructing the constraint matrix and objective function matrix or vector is not trivial. Limited to the quality of LP and QP solvers available for R. 
-->

---

## PortfolioAnalytics Overview
PortfolioAnalytics is an R package designed to provide numerical solutions and visualizations for portfolio optimization problems with complex constraints and objectives.

* Support for multiple constraint and objective types
* An objective function can be any valid R function
* Modular constraints and objectives
* Support for user defined moment functions
* Visualizations
* Solver agnostic
* Support for parallel computing

<!---
The key points to make here are:
* Flexibility
    * The multiple types and modularity of constraints and objectives allows us to add, remove, combine, etc. multiple constraint and objective types very easily.
    * Define an objective as any valid R function
    * Define a function to compute the moments (sample, robust, shrinkage, factor model, GARCH model, etc.)
    * Estimation error is a significant concern with optimization. Having the ability to test different models with different parameters is critical.
* PortfolioAnalytics comes "out of the box" with several constraint types.
* Visualization helps to build intuition about the problem and understand the feasible space of portfolios
* Periodic rebalancing and analyzing out of sample performance will help refine objectives and constraints
* Framework for evaluating portfolios with different sets of objectives and portfolios through time
-->

---

## Support Multiple Solvers
Linear and Quadratic Programming Solvers

* R Optimization Infrastructure (ROI)
    * GLPK (Rglpk)
    * Symphony (Rsymphony)
    * Quadprog (quadprog)

Global (stochastic or continuous solvers)

* Random Portfolios
* Differential Evolution (DEoptim)
* Particle Swarm Optimization (pso)
* Generalized Simulated Annealing (GenSA)

<!---
Brief explanation of each solver and what optimization problems are supported
-->

---

## Random Portfolios
PortfolioAnalytics has three methods to generate random portfolios.

1. The **sample** method to generate random portfolios is based on an idea by Pat Burns.
2. The **simplex** method to generate random portfolios is based on a paper by W. T. Shaw.
3. The **grid** method to generate random portfolios is based on the `gridSearch` function in the NMOF package.

<!--
* Random portfolios allow one to generate an arbitray number of portfolios based on given constraints. Will cover the edges as well as evenly cover the interior of the feasible space. Allows for massively parallel execution.

* The sample method to generate random portfolios is based on an idea by Patrick Burns. This is the most flexible method, but also the slowest, and can generate portfolios to satisfy leverage, box, group, and position limit constraints.

* The simplex method to generate random portfolios is based on a paper by W. T. Shaw. The simplex method is useful to generate random portfolios with the full investment constraint, where the sum of the weights is equal to 1, and min box constraints. Values for min_sum and max_sum of the leverage constraint will be ignored, the sum of weights will equal 1. All other constraints such as the box constraint max, group and position limit constraints will be handled by elimination. If the constraints are very restrictive, this may result in very few feasible portfolios remaining. Another key point to note is that the solution may not be along the vertexes depending on the objective. For example, a risk budget objective will likely place the portfolio somewhere on the interior.

* The grid method to generate random portfolios is based on the gridSearch function in NMOF package. The grid search method only satisfies the min and max box constraints. The min_sum and max_sum leverage constraint will likely be violated and the weights in the random portfolios should be normalized. Normalization may cause the box constraints to be violated and will be penalized in constrained_objective.
-->

---

## Comparison of Random Portfolio Methods (Interactive!)

RP

<!--

```
Warning: cannot open compressed file 'figures/rp_viz.rda', probable reason
'No such file or directory'
```

```
Error: cannot open the connection
```

```
Error: object 'rp_viz' not found
```

The feasible space is computed using the EDHEC data for a long only portfolio with a search size of 2000.
-->

---

## Random Portfolios: Simplex Method

RP Simplex

<!--
FEV (Face-Edge-Vertex bias values control how concentrated a portfolio is. This can clearly be seen in the plot. As FEV approaches infinity, the portfolio weight will be concentrated on a single asset. PortfolioAnalytics allows you to specify a vector of fev values for comprehensive coverage of the feasible space. 
-->

---

## Workflow: Specify Portfolio

```r
args(portfolio.spec)
```

```
## function (assets = NULL, category_labels = NULL, weight_seq = NULL, 
##     message = FALSE) 
## NULL
```

Initializes the portfolio object that holds portfolio level data, constraints, and objectives

<!--
The portfolio object is an S3 object that holds portfolio-level data, constraints, and objectives. The portfolio-level data includes asset names and initial weights, labels to categorize assets, and a sequence of weights for random portfolios. The main argument is assets which can be a character vector (most common use), named numeric vector, or scalar value specifying number of assets.
-->

---

## Workflow: Add Constraints

```r
args(add.constraint)
```

```
## function (portfolio, type, enabled = TRUE, message = FALSE, ..., 
##     indexnum = NULL) 
## NULL
```

Supported Constraint Types

* Sum of Weights
* Box
* Group
* Factor Exposure
* Position Limit
* and many more

<!--
This adds a constraint object to the portfolio object. Constraints are added to the portfolio object with the add.constraint function. Each constraint added is a separate object and stored in the constraints slot in the portfolio object. In this way, the constraints are modular and one can easily add, remove, or modify the constraints in the portfolio object. Main argument is the type, arguments to the constraint constructor are then passed through the dots (...).
-->

---

## Workflow: Add Objectives

```r
args(add.objective)
```

```
## function (portfolio, constraints = NULL, type, name, arguments = NULL, 
##     enabled = TRUE, ..., indexnum = NULL) 
## NULL
```

Supported Objective types

* Return
* Risk
* Risk Budget
* Weight Concentration

<!--
Objectives are added to the portfolio object with the add.objective function. Each objective added is a separate object and stored in the objectives slot in the portfolio object. In this way, the objectives are modular and one can easily add, remove, or modify the objective objects. The name argument must be a valid R function. Several functions are available in the PerformanceAnalytics package, but custom user defined functions can be used as objective functions.
-->

---

## Workflow: Run Optimization

```r
args(optimize.portfolio)
```

```
## function (R, portfolio = NULL, constraints = NULL, objectives = NULL, 
##     optimize_method = c("DEoptim", "random", "ROI", "pso", "GenSA"), 
##     search_size = 20000, trace = FALSE, ..., rp = NULL, momentFUN = "set.portfolio.moments", 
##     message = FALSE) 
## NULL
```

```r
args(optimize.portfolio.rebalancing)
```

```
## function (R, portfolio = NULL, constraints = NULL, objectives = NULL, 
##     optimize_method = c("DEoptim", "random", "ROI"), search_size = 20000, 
##     trace = FALSE, ..., rp = NULL, rebalance_on = NULL, training_period = NULL, 
##     rolling_window = NULL) 
## NULL
```

<!--
* Notice the similarity between these two functions. You only have to specify a few additional arguments for the backtesting.

* optimize.portfolio: Main arguments for a single period optimization are the returns (R), portfolio, and optimize_method. We take the portfolio object and parse the constraints and objectives according to the optimization method.

* optimize.portfolio.rebalancing: Supports periodic rebalancing (backtesting) to examine out of sample performance. Helps refine constraints and objectives by analyzing out or sample performance. Essentially a wrapper around optimize.portfolio that handles the time interface.
-->

---

## Workflow: Analyze Results

Visualization | Data Extraction
------------- | ----------
plot | extractObjectiveMeasures
chart.Concentration | extractStats
chart.EfficientFrontier | extractWeights
chart.RiskReward | print
chart.RiskBudget | summary
chart.Weights | 

<!--
Brief explanation of each function.
-->

---

## What's New in PortfolioAnalytics

* Pushed to CRAN
* Regime Switching Framework
* Multilayer Optimization
* Rank Based Optimization
* Factor Model Moment Estimates
* More demos, vignettes, and documentation

---

## Regime Switching Framework

Regime Switching Framework

---

## Multilayer Optimization

Multilayer Optimization

---

## Estimating Moments

* sample
* shrinkage
* factor model
* views

---

## Conclusion

* Introduced the goals and summary of PortfolioAnalytics
* Demonstrated the flexibility through examples
* Exciting plans for GSOC 2014
    * Support for regime switching
    * Support for supervised learning
    * many more

#### Acknowledgements
Many thanks to...

* Google: funding Google Summer of Code (GSoC) for 2014 and 2015
* UW CF&RM Program: continued work on PortfolioAnalytics
* GSoC Mentors: Brian Peterson, Peter Carl, Doug Martin, and Guy Yollin
* R/Finance Committee

<!---
- One of the best things about GSoC is the opportunity to work and interact with the mentors.
- Thank the GSoC mentors for offering help and guidance during the GSoC project and after as I continued to work on the PortfolioAnalytics package.
- R/Finance Committee for the conference and the opportunity to talk about PortfolioAnalytics.
- Google for funding the Google Summer of Code for PortfolioAnalytics and many other proposals for R
-->

---

## PortfolioAnalytics Links
PortfolioAnalytics on CRAN

* [PortfolioAnalytics](http://cran.at.r-project.org/web/packages/PortfolioAnalytics/index.html)

PortfolioAnalytics development on R-Forge in the ReturnAnalytics project

* [PortfolioAnalytics](https://r-forge.r-project.org/projects/returnanalytics/)

Source code for the slides

* https://github.com/rossb34/PortfolioAnalyticsPresentation2015

and view it here

* http://rossb34.github.io/PortfolioAnalyticsPresentation2015/

---

## Any Questions?

---

## References and Useful Links

* [ROI](http://cran.r-project.org/web/packages/ROI/index.html)
* [DEoptim](http://cran.r-project.org/web/packages/DEoptim/index.html)
* [pso](http://cran.r-project.org/web/packages/pso/index.html)
* [GenSA](http://cran.r-project.org/web/packages/GenSA/index.html)
* [PerformanceAnalytics](http://cran.r-project.org/web/packages/PerformanceAnalytics/index.html)
* [Patrick Burns Random Portfolios](http://www.burns-stat.com/pages/Finance/randport_practice_theory_annotated.pdf)
* [W.T. Shaw Random Portfolios](http://papers.ssrn.com/sol3/papers.cfm?abstract_id=1856476)
* Martellini paper
* Boudt paper
* [Shiny App](http://spark.rstudio.com/rossbennett3/PortfolioOptimization/)
