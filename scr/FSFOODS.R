rm(list=ls())

library(ggplot2)
library(RColorBrewer)
library(tidyverse) # for plotting
library(pROC)
library(glmnet) # for fitting lasso, ridge regressions (GLMs)
library(lubridate) # for easily manipulating dates
library(sf)
library(dplyr) 
library(tigris)

# Loading the Data
source("code/clean_cps.R") # clean CPS
source("code/clean_acs.R") # clean ACS

# 
cps_data = subset(cps_data, select = -c(FSTOTXPNC_perpers, FSSTATUSMD, FSSTATUS, FSWROUTY, FSBAL, FSRAWSCRA, FSTOTXPNC))
cps_data = cps_data[complete.cases(cps_data), ]

##### EXPLORATORY ANALYSIS #####

# Potential X Variables:
# hhsize, female, hispanic, black, kids, elderly, education, married, faminc

cps_data = cps_data %>% 
  mutate(FSFOODS_factor = as.factor(FSFOODS))

ggplot(data=cps_data)+
  geom_bar(aes(x=married, fill=FSFOODS_factor), position="fill") +
  labs(x="Number of People who are Married", y="Proportion") +
  ggtitle("Food Insecurity Over Marriage") +
  scale_fill_grey("Food Variety\nInsecurity") +
  theme_minimal()

ggplot(data=cps_data)+
  geom_histogram(aes(x=female/hhsize, fill = FSFOODS_factor), binwidth = 0.1, position = "fill") +
  labs(x="Percentage of Women in a Household", y="Proportion") +
  ggtitle("Food Insecurity Over Women Proportion Size") +
  scale_fill_grey("Food Variety\nInsecurity") +
  theme_minimal()

ggplot(data=cps_data)+
  geom_histogram(aes(x=hispanic/hhsize, fill = FSFOODS_factor), binwidth = 0.1, position = "fill") +
  labs(x="Percentage of Women in a Household", y="Proportion") +
  ggtitle("Food Insecurity Over Women Proportion Size") +
  scale_fill_grey("Food Variety\nInsecurity") +
  theme_minimal()

ggplot(data=cps_data)+
  geom_histogram(aes(x=black/hhsize, fill = FSFOODS_factor), binwidth = 0.1, position = "fill") +
  labs(x="Percentage of Women in a Household", y="Proportion") +
  ggtitle("Food Insecurity Over Women Proportion Size") +
  scale_fill_grey("Food Variety\nInsecurity") +
  theme_minimal()

ggplot(data=cps_data)+
  geom_histogram(aes(x=kids/hhsize, fill = FSFOODS_factor), binwidth = 0.1, position = "fill") +
  labs(x="Percentage of Women in a Household", y="Proportion") +
  ggtitle("Food Insecurity Over Women Proportion Size") +
  scale_fill_grey("Food Variety\nInsecurity") +
  theme_minimal()

ggplot(data=cps_data)+
  geom_histogram(aes(x=elderly/hhsize, fill = FSFOODS_factor), binwidth = 0.1, position = "fill") +
  labs(x="Percentage of Women in a Household", y="Proportion") +
  ggtitle("Food Insecurity Over Women Proportion Size") +
  scale_fill_grey("Food Variety\nInsecurity") +
  theme_minimal()

ggplot(data=cps_data)+
  geom_bar(aes(x=married, fill = FSFOODS_factor)) +
  labs(x="Number of People with a Collage Degree", y="Proportion") +
  ggtitle("Food Insecurity by Education Level") +
  scale_fill_grey("Food Variety\nInsecurity") +
  theme_minimal()

ggplot(data=cps_data)+
  geom_histogram(aes(x=married/hhsize, fill = FSFOODS_factor), binwidth = 0.1) +
  labs(x="Percentage of Women in a Household", y="Proportion") +
  ggtitle("Food Insecurity Over Women Proportion Size") +
  scale_fill_grey("Food Variety\nInsecurity") +
  theme_minimal()

##### SPLITTING DATA ########## SPLIFSFOODS_factorTTING DATA #####

# Setting the seed to make sure the code can be reproduced on other machines
RNGkind(sample.kind = "default")
set.seed(122111598)

# Splitting up the data into test and train data.  70% of the data will be going
# to train the data and 30% will go to testing the data

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

x.train = model.matrix(FSFOODS ~ hhsize + female + hispanic + black  + kids + elderly + education + married, data = train.df)[, -1]
x.test = model.matrix(FSFOODS ~ hhsize + female + hispanic + black  + kids + elderly + education + married, data = test.df)[, -1]

# x.train and x.test have the same infor as train.df and test.df, but 
# they are matrices

# also need to make VECTORS of the 0/1 y variable
y.train = as.vector(train.df$FSFOODS)
y.test = as.vector(test.df$FSFOODS)

#Use cross validation to fit (LOTS OF) lasso and ridge regressions
lr_lasso_cv = cv.glmnet(x.train, # train MATRIX - without y 
                        y.train, # train y VECTOR = y column
                        family=binomial(link=logit),
                        weights = as.integer(train.df$weight),
                        alpha = 1)

lr_ridge_cv = cv.glmnet(x.train, # train MATRIX - without y 
                        y.train, # train y VECTOR = y column
                        family=binomial(link=logit),
                        weights = as.integer(train.df$weight),
                        alpha = 0)  

# these models try a range of lambda values (differing penalty parameters)
# and then use CV to resitmate out of sample error of each lambda
plot(lr_lasso_cv)
# choose the lambda value that minimizes out of sample error, i.e.,
# GLM deviance

plot(lr_ridge_cv)

best_lasso_lambda = lr_lasso_cv$lambda.min

best_ridge_lambda = lr_ridge_cv$lambda.min

##### COEFFICIENTS #####
# see the coeffiencets for the model that minimizes our of sample error
# note: you woud't have to do this is RL, but it helps to understand

lr_lasso_coeff = coef(lr_lasso_cv, s = "lambda.min") %>%  as.matrix()
lr_ridge_coeff = coef(lr_ridge_cv, s = "lambda.min") %>%  as.matrix()

(lr_lasso_coeff)
(lr_ridge_coeff)

# again. undestanding 

ggplot() +
  geom_point(aes(lr_lasso_coeff, lr_lasso_coeff)) + 
  geom_abline(aes(slope=1, intercept = 0)) +
  xlim(c(-10, 10)) + ylim(c(-10, 10))

# if time allows compare to MLE coessifcents too

#So while the mdoels (random +_ systematic ) are all the same
# but the coefficenta are vasly different because fo penalized methos

##### FIT FINAL MODELS #####

final_lasso = glmnet(x.train, y.train,
                     family = binomial(link = "logit"),
                     weights = as.integer(train.df$weight),
                     alpha = 1,
                     lambda = best_lasso_lambda)

final_ridge = glmnet(x.train, y.train,
                     family = binomial(link = "logit"),
                     weights = as.integer(train.df$weight),
                     alpha = 0,
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


lasso_rocCurve = roc(response = as.factor(test.df.preds$FSFOODS),
                     predictor = test.df.preds$lasso_pred,
                     levels = c("0", "1"))

ridge_rocCurve = roc(response = as.factor(test.df.preds$FSFOODS),
                     predictor = test.df.preds$ridge_pred,
                     levels = c("0", "1"))

plot(lasso_rocCurve, print.thres = TRUE, print.auc = TRUE)


plot(ridge_rocCurve, print.thres = TRUE, print.auc = TRUE)

lasso_pi_star = coords(lasso_rocCurve, "best", ret = "threshold")$threshold[1]
test.df$lasso_pred = as.factor(ifelse(test.df.preds$lasso_pred > lasso_pi_star, "1", "0"))

ridge_pi_star = coords(ridge_rocCurve, "best", ret = "threshold")$threshold[1]
test.df$ridge_pred = as.factor(ifelse(test.df.preds$ridge_pred > ridge_pi_star, "1", "0"))


# Calculate the ROC data as you did before
lasso_rocCurve = roc(response = as.factor(test.df.preds$FSFOODS),
                     predictor = test.df.preds$lasso_pred,
                     levels = c("0", "1"))
ridge_rocCurve = roc(response = as.factor(test.df.preds$FSFOODS),
                     predictor = test.df.preds$ridge_pred,
                     levels = c("0", "1"))

# Create data frames for Lasso and Ridge ROC information
lasso_data <- data.frame(
  Model = "Lasso",
  Specificity = lasso_rocCurve$specificities,
  Sensitivity = lasso_rocCurve$sensitivities,
  AUC = as.numeric(lasso_rocCurve$auc)
)

ridge_data <- data.frame(
  Model = "Ridge",
  Specificity = ridge_rocCurve$specificities,
  Sensitivity = ridge_rocCurve$sensitivities,
  AUC = as.numeric(ridge_rocCurve$auc)
)

# Combine Lasso and Ridge data into a single data frame
roc_data <- rbind(lasso_data, ridge_data)

# Add a column 'text_y' to specify the y position for text labels
roc_data <- roc_data %>%
  mutate(text_y = case_when(
    Model == "Lasso" ~ 0.75,  # For Lasso model, position label at y = 0.75
    Model == "Ridge" ~ 0.65   # For Ridge model, position label at y = 0.65
  ))

# Plot the data
ggplot() +
  geom_line(aes(x = 1 - Specificity, y = Sensitivity, color = Model), data = roc_data, size =1.5, alpha = 0.75) +
  geom_text(data = roc_data %>% group_by(Model) %>% slice(1), 
            aes(x = 0.75, y = text_y, color = Model,
                label = paste0(Model, " AUC = ", round(AUC, 3)))) +
  scale_colour_brewer(palette = "Set2") +
  labs(title = "Lasso and Ridge Regression for Food Variety",x = "1 - Specificity", y = "Sensitivity", color = "Model") +
  theme_minimal()

# IF we set pi* = 0.861, we can achieve a specificity of 0.857
# and sensitivity of 0.905

# That is, we'll predict a loff 85.7% of the time when Serena actually loses
# We'll predict a win 90.5% of the time when Serena actually wins 
# Area under the curve is 0.928


##### PREDICTING ACS #####

acs_test = subset(acs_data, select = c(hhsize, female, hispanic, black, kids, elderly, education, married))
acs_test = as.matrix(acs_test)

acs_data = acs_data %>% 
  mutate(
    # note: ridge and lasso get the MATRIX
    lasso_pred_prob = predict(final_lasso, acs_test, type = "response")[,1],
    ridge_pred_prob = predict(final_ridge, acs_test, type = "response")[,1]
    # note: all need tyoe = "response" so we don;t get log-odds
  )

acs_data$lasso_pred = as.factor(ifelse(acs_data$lasso_pred_prob > lasso_pi_star, "1", "0"))
acs_data$ridge_pred = as.factor(ifelse(acs_data$ridge_pred_prob > ridge_pi_star, "1", "0"))

acs_data

puma_acs = acs_data %>% 
  filter(elderly > 0) %>% 
  group_by(PUMA=as.factor(PUMA)) %>%
  summarise(mean_lasso_prob = weighted.mean(lasso_pred_prob, weights = weight),
            #mean = weighted.mean(lasso_pre... , weights = weights in ACS)
            mean_ridge_prob = weighted.mean(ridge_pred_prob, weights = weight),
            senior_count = sum(elderly)) %>%ungroup()




puma_acs[max(puma_acs$mean_lasso_prob) == puma_acs$mean_lasso_prob,]
puma_acs[max(puma_acs$mean_ridge_prob) == puma_acs$mean_ridge_prob,]



##### PUMA Map #####


# Set tigris options
options(tigris_class = "sf")
options(tigris_use_cache = TRUE)

# Get PUMA shapefile for a specific state (e.g., Iowa)
pumas <- pumas(state = "IA", year = 2022)

# Add PUMA labels with color spectrum for senior_population
ggplot(data = pumas) +
  geom_sf(aes(fill = puma_acs$mean_lasso_prob), color = "black") +
  scale_fill_gradient(
    low = "lightblue", high = "darkblue",  # 
    name = "Mean Lasso Probability"     
  ) +
  labs(
    title = "PUMA Map for Food Security & Variety",
    subtitle = "Public Use Microdata Areas (PUMAs) for Iowa",
    caption = "Source: TIGER/Line Shapefiles"
  ) +
  theme_minimal()







