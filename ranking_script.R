# Load package and data
library(PortfolioAnalytics)
library(nloptr)
source("data_prep.R")

fig.height <- 450
fig.width <- 950
figures.dir <- "figures"

##### Examples 1 and 2 #####

R <- edhec[,1:4]
funds <- colnames(R)

# Construct initial portfolio with basic constraints.
meanSD.portf <- portfolio.spec(assets=funds)
meanSD.portf <- add.constraint(portfolio=meanSD.portf, type="weight_sum",
                               min_sum=0.99, max_sum=1.01)
meanSD.portf <- add.constraint(portfolio=meanSD.portf, type="box",
                               min=0.05, max=0.5)
meanSD.portf <- add.objective(portfolio=meanSD.portf, type="risk", name="StdDev")
meanSD.portf <- add.objective(portfolio=meanSD.portf, type="return", name="mean")

# Generate random portfolios for use in the optimization.
rp <- random_portfolios(meanSD.portf, 5000)

# Here we express views on the relative rank of the asset returns
# E{ R[,2] < R[,3] < R[,1] < R[,4] }
asset.rank <- c(2, 3, 1, 4)

#' Use Meucci Fully Flexible Views framework to express views on the relative
#' order of asset returns.
#' Define prior probabilities.
p <- rep(1 / nrow(R), nrow(R))

#' Express view on the relative ordering of asset returns
m.moments <- meucci.ranking(R, p, asset.rank)

#' Express views using the method described in Almgren and Chriss,
#' "Portfolios from Sorts".
ac.moments <- list()
ac.moments$mu <- ac.ranking(R, asset.rank)
# Sample estimate for second moment
ac.moments$sigma <- cov(R)

#' Run the optimization using first and second moments estimated from
#' Meucci's Fully Flexible Views framework using the moments we calculated
#' from our view.
opt.meucci <- optimize.portfolio(R, portfolio=meanSD.portf,
                                 optimize_method="random",
                                 rp=rp,
                                 trace=TRUE,
                                 momentargs=m.moments)

#' Run the optimization using first moment estimated based on Almgren and Chriss,
#' "Portfolios from Sorts". The second moment uses the sample estimate.
opt.ac <- optimize.portfolio(R, portfolio=meanSD.portf,
                             optimize_method="random",
                             rp=rp,
                             trace=TRUE,
                             momentargs=ac.moments)

#' For comparison, run the optimization using sample estimates for first and
#' second moments.
opt.sample <- optimize.portfolio(R, portfolio=meanSD.portf,
                                 optimize_method="random",
                                 rp=rp,
                                 trace=TRUE)

png(paste(figures.dir, "weights_ex1.png", sep="/"), height = fig.height, width = fig.width)
#' Here we plot the optimal weights of each optimization.
chart.Weights(combine.optimizations(list(meucci=opt.meucci,
                                         ac=opt.ac,
                                         sample=opt.sample)),
              ylim=c(0,1), plot.type="barplot")
dev.off()
print("Done")
##### Example 2 #####

#' Here we define a custom moment function to estimate moments based on
#' relative ranking views.
#' Asset are ranked according to momentum based on the previous n periods.
moment.ranking <- function(R, n=1, method=c("meucci", "ac")){
  # Moment function to estimate moments based on relative ranking of
  # expected returns.
  method <- match.arg(method)
  
  # Use the most recent n periods of returns
  tmpR <- apply(tail(R, n), 2, function(x) prod(1 + x) - 1)
  
  # Assume that the assets with the highest return will continue to outperform
  asset.rank <- order(tmpR)
  
  switch(method,
         meucci = {
           # Prior probabilities
           p <- rep(1 / nrow(R), nrow(R))
           
           # Relative ordering view
           moments <- meucci.ranking(R, p, asset.rank)
         },
         ac = {
           moments <- list()
           moments$mu <- ac.ranking(R, asset.rank)
           # Sample estimate for second moment
           moments$sigma <- cov(R)
         }
  )
  return(moments)
}

# Here we run out of sample backtests to test the out of sample performance
# using using the different frameworks to express our views on relative
# asset return ranking.
opt.bt.meucci <- optimize.portfolio.rebalancing(R, meanSD.portf,
                                                optimize_method="random",
                                                rebalance_on="quarters",
                                                training_period=72,
                                                rp=rp,
                                                momentFUN="moment.ranking",
                                                n=3,
                                                method="meucci")

opt.bt.ac <- optimize.portfolio.rebalancing(R, meanSD.portf,
                                            optimize_method="random",
                                            rebalance_on="quarters",
                                            training_period=72,
                                            rp=rp,
                                            momentFUN="moment.ranking",
                                            n=3,
                                            method="ac")

opt.bt.sample <- optimize.portfolio.rebalancing(R, meanSD.portf,
                                                optimize_method="random",
                                                rebalance_on="quarters",
                                                training_period=72,
                                                rp=rp)

#' Compute returns and chart performance summary.
ret.meucci <- Return.portfolio(R, extractWeights(opt.bt.meucci))
ret.ac <- Return.portfolio(R, extractWeights(opt.bt.ac))
ret.sample <- Return.portfolio(R, extractWeights(opt.bt.sample))
ret <- cbind(ret.meucci, ret.ac, ret.sample)
colnames(ret) <- c("meucci.rank", "ac.rank", "sample")

png(paste(figures.dir, "ret_ex2.png", sep="/"), height = fig.height, width = fig.width)
charts.PerformanceSummary(ret, main="Ranking Views Performance")
dev.off()

table.AnnualizedReturns(ret)

##### Example 3 #####

# Data
R.raw <- ret.sector
R <- Return.clean(R.raw, "boudt")
funds <- colnames(R)

# Construct initial portfolio with basic constraints.
ES.portf <- portfolio.spec(assets=funds)
ES.portf <- add.constraint(portfolio=ES.portf, type="weight_sum",
                           min_sum=0.99, max_sum=1.01)
ES.portf <- add.constraint(portfolio=ES.portf, type="long_only")
ES.portf <- add.objective(portfolio=ES.portf, type="risk", name="ES",
                          arguments=list(p=0.95))
ES.portf <- add.objective(portfolio=ES.portf, type="risk_budget", 
                          name="ES", max_prisk=0.25, 
                          arguments=list(p=0.95))
# Generate random portfolios
rp <- random_portfolios(ES.portf, 5000)

# This is not necessary for the optimization, but demonstrates how the
# moments are estimated using portfolio.moments.boudt.
fit <- statistical.factor.model(R, k=3)

# Here we extract the moments.
sigma <- extractCovariance(fit)
m3 <- extractCoskewness(fit)
m4 <- extractCokurtosis(fit)

fm.moments <- function(R, k=1){
  fit <- statistical.factor.model(R=R, k=k)
  momentargs <- list()
  # momentargs$mu <- matrix( as.vector(apply(R,2,'mean')),ncol=1)
  momentargs$mu <- matrix(rep(0, ncol(R)),ncol=1)
  momentargs$sigma <- extractCovariance(fit)
  momentargs$m3 <- extractCoskewness(fit)
  momentargs$m4 <- extractCokurtosis(fit)
  return(momentargs)
}


# Now we run the optimization with statistical factor model estimates of the 
# moments.
system.time({
  minES.boudt <- optimize.portfolio.rebalancing(R=R, portfolio=ES.portf, 
                                                momentFUN=fm.moments, k=3,
                                                optimize_method="random", rp=rp,
                                                rebalance_on="quarters",
                                                training_period=1250,
                                                trace=TRUE)
})

# system.time({
# minES.boudt.raw <- optimize.portfolio.rebalancing(R=ret.sector, portfolio=ES.portf, 
#                                               momentFUN=fm.moments, k=3,
#                                               optimize_method="random", rp=rp,
#                                               rebalance_on="quarters",
#                                               training_period=1250,
#                                               trace=TRUE)
# })

# Here we run the optimization using sample estimates for the moments.
# The default for momentFUN is set.portfolio.moments which computes
# the sample estimates of the moments.
system.time({
  minES.sample <- optimize.portfolio.rebalancing(R=R.raw, portfolio=ES.portf, 
                                                 optimize_method="random", rp=rp,
                                                 rebalance_on="quarters",
                                                 training_period=1250,
                                                 trace=TRUE)
})

png(paste(figures.dir, "weights_boudt_ex3.png", sep="/"), height = fig.height, width = fig.width)
chart.Weights(minES.boudt, main="Boudt")
dev.off()

png(paste(figures.dir, "weights_sample_ex3.png", sep="/"), height = fig.height, width = fig.width)
chart.Weights(minES.sample, main="Sample")
dev.off()

png(paste(figures.dir, "risk_boudt_ex3.png", sep="/"), height = fig.height, width = fig.width)
chart.RiskBudget(minES.boudt, risk.type="percentage", main="Boudt")
dev.off()

png(paste(figures.dir, "risk_sample_ex3.png", sep="/"), height = fig.height, width = fig.width)
chart.RiskBudget(minES.sample, risk.type="percentage", main="Sample")
dev.off()

ret.boudt <- Return.portfolio(R.raw, extractWeights(minES.boudt))
# ret.boudt.raw <- Return.portfolio(ret.sector, extractWeights(minES.boudt.raw))
ret.sample <- Return.portfolio(R.raw, extractWeights(minES.sample))
ret <- cbind(ret.boudt, ret.sample)
colnames(ret) <- c("boudt.moments", "sample.moments")


png(paste(figures.dir, "ret_ex3.png", sep="/"), height = fig.height, width = fig.width)
charts.PerformanceSummary(ret, main="Performance Summary")
dev.off()

table.AnnualizedReturns(ret)
