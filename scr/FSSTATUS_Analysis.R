rm(list=ls())

# Loading the Data
source("code/clean_cps.R") # clean CPS
source("code/clean_acs.R") # clean ACS

library(ggplot2)
library(RColorBrewer)
library(tidyverse) # for plotting
library(pROC)
library(glmnet) # for fitting lasso, ridge regressions (GLMs)
library(lubridate) # for easily manipulating dates



##### EXPLORATORY ANALYSIS #####

# Potential X Variables:
# hhsize, female, hispanic, black, kids, elderly, education, married, faminc

ggplot(data = cps_data) +
  geom_bar(aes(x=hhsize))

ggplot(data = cps_data) +
  geom_bar(aes(x=female))

ggplot(data = cps_data) +
  geom_bar(aes(x=hispanic))

ggplot(data = cps_data) +
  geom_bar(aes(x=black))

ggplot(data = cps_data) +
  geom_bar(aes(x=kids))

ggplot(data = cps_data) +
  geom_bar(aes(x=elderly))

ggplot(data = cps_data) +
  geom_bar(aes(x=education))

ggplot(data = cps_data) +
  geom_histogram(aes(x=faminc))

ggplot(data = cps_data) +
  geom_bar(aes(x=married))




#####Random Forest #####
# Using the random forest to figure out important x variables

cps_data = subset(cps_data, select = -c(FSTOTXPNC_perpers, FSSTATUSMD, FSFOODS, FSWROUTY, FSBAL, FSRAWSCRA, FSTOTXPNC))

cps_data = cps_data[complete.cases(cps_data), ]

RNGkind(sample.kind = "default")

set.seed(122111598)

train.idx = sample(x=1:nrow(cps_data), size = floor(.7*nrow(cps_data)))

train.df = cps_data[train.idx,]

test.df = cps_data[-train.idx,]




##### LASSO RIDGE #####

# These regressions systamtically shrink "unimportant" coefficents to 0
# "unimportant" - they don;t help the model predict OUT OF SAMPLE

# note:recall that RG, trees, logisitc regression with MLE, all took
# in training/testing DATA FRAMES 
# hat changes with lasso/ridge = the REQUIRE MATRICES
# psty of that means one-hot-coding ary factors

x.train = model.matrix(FSSTATUS ~ weight + hhsize + female + hispanic + black  + kids + elderly + education + married + faminc, data = train.df)[, -1]
x.test = model.matrix(FSSTATUS ~., data = test.df)[, -1]

# x.train and x.test have the same infor as train.df and test.df, but 
# they are matrices

# also need to make VECTORS of the 0/1 y variable
y.train = as.vector(train.df$FSSTATUS)
y.test = as.vector(test.df$FSSTATUS)

#Use cross validation to fit (LOTS OF) lasso and ridge regressions
lr_lasso_cv = cv.glmnet(x.train, # train MATRIX - without y 
                        y.train, # train y VECTOR = y column
                        family=binomial(link=logit),
                        alpha = 1)

lr_ridge_cv = cv.glmnet(x.train, # train MATRIX - without y 
                        y.train, # train y VECTOR = y column
                        family=binomial(link=logit),
                        alpha = 0)                        

# these models try a range of lambda values (differing penalty parameters)
# and then use CV to resitmate out of sample error of each lambda
plot(lr_lasso_cv)
# choose the lambda value that minimizes out of sample error, i.e.,
# GLM deviance

plot(lr_ridge_cv)

best_lasso_lambda = lr_lasso_cv$lambda.min
# lambda is around 0.00015836

best_ridge_lambda = lr_ridge_cv$lambda.min
# lambda is around 0.00735024

##### COEFFICIENTS #####
# see the coeffiencets for the model that minimizes our of sample error
# note: you woud't have to do this is RL, but it helps to understand

lr_lasso_coeff = coef(lr_lasso_cv, s = "lambda.min") %>%  as.matrix()
lr_ridge_coeff = coef(lr_ridge_cv, s = "lambda.min") %>%  as.matrix()

lr_lasso_coeff
lr_ridge_coeff

# again. undestanding 

ggplot() +
  geom_point(aes(lr_lasso_coeff, lr_lasso_coeff)) + 
  geom_abline(aes(slope=1, intercept = 0)) +
  xlim(c(-10, 10)) + ylim(x(-10, 10))

# if time allows compare to MLE coessifcents too

#So while the mdoels (random +_ systematic ) are all the same
# but the coefficenta are vasly different because fo penalized methos

##### FIT FINAL MODELS #####

final_lasso = glmnet(x.train, y.train,
                     family = binomial(link = "logit"),
                     alpha = 1,
                     lambda = best_lasso_lambda)

final_ridge = glmnet(x.train, y.train,
                     family = binomial(link = "logit"),
                     alpha = 1,
                     lambda = best_ridge_lambda)

##### QUANTIFY PREDICTIONS PERFORMANCE OF ALL 3 MODELS ####

test.df.preds = test.df %>% 
  mutate(
    # note: ridge and lasso get the MATRIX
    lasso_pred = predict(final_lasso, x.test, type = "response")[,1],
    ridge_pred = predict(final_ridge, x.test, type = "response")[,1]
    # note: all need tyoe = "response" so we don;t get log-odds
  )

# FYI: you are going to do this TWICE on your final project for a given y variable
# you'tt do it once on you CPS testing data set
# you'll do it again on your ACS (your real testing set without the 'truth)


# FIT ROC CURVE

mle_rocCurve = roc(response = as.factor(test.df.preds$popular_bin),
                   predictor = test.df.preds$mle_pred,
                   levels = c("0", "1"))

lasso_rocCurve = roc(response = as.factor(test.df.preds$popular_bin),
                     predictor = test.df.preds$lasso_pred,
                     levels = c("0", "1"))
ridge_rocCurve = roc(response = as.factor(test.df.preds$popular_bin),
                     predictor = test.df.preds$ridge_pred,
                     levels = c("0", "1"))



#make data frame of MLE ROC info
mle_data <- data.frame(
  Model = "MLE",
  Specificity = mle_rocCurve$specificities,
  Sensitivity = mle_rocCurve$sensitivities,
  AUC = as.numeric(mle_rocCurve$auc)
)
#make data frame of lasso ROC info
lasso_data <- data.frame(
  Model = "Lasso",
  Specificity = lasso_rocCurve$specificities,
  Sensitivity = lasso_rocCurve$sensitivities,
  AUC = lasso_rocCurve$auc %>% as.numeric
)
#make data frame of ridge ROC info
ridge_data <- data.frame(
  Model = "Ridge",
  Specificity = ridge_rocCurve$specificities,
  Sensitivity = ridge_rocCurve$sensitivities,
  AUC = ridge_rocCurve$auc%>% as.numeric
)

# Combine all the data frames
roc_data <- rbind(mle_data, lasso_data, ridge_data)


# Plot the data
ggplot() +
  geom_line(aes(x = 1 - Specificity, y = Sensitivity, color = Model),data = roc_data) +
  geom_text(data = roc_data %>% group_by(Model) %>% slice(1), 
            aes(x = 0.75, y = c(0.75, 0.65, 0.55), colour = Model,
                label = paste0(Model, " AUC = ", round(AUC, 3)))) +
  scale_colour_brewer(palette = "Paired") +
  labs(x = "1 - Specificity", y = "Sensitivity", color = "Model") +
  theme_minimal()
