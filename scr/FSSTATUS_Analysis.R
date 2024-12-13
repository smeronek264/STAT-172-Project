# NOTE: CHATGPT was utilized to add comments throughout the code
# It was also used to create the PUMA maps

##### CLEARING THE ENVIRONMENT AND LOADING NECESSARY LIBRARIES #####
# Removing all objects from the environment to ensure a clean workspace
rm(list=ls())

# Loading necessary libraries for data manipulation, visualization, and modeling
library(ggplot2)           # For creating various plots
library(RColorBrewer)      # For color palettes
library(tidyverse)         # For efficient data manipulation and plotting
library(pROC)              # For ROC curve analysis
library(glmnet)            # For lasso and ridge regression models
library(lubridate)         # For easy manipulation of date and time variables
library(sf)                # For spatial data handling (shapefiles)
library(dplyr)             # For data manipulation
library(tigris)            # For working with US Census shapefiles

# Loading the data cleaning scripts for CPS and ACS data
source("src/clean_cps.R")  # Clean CPS data
source("src/clean_acs.R")  # Clean ACS data

# Remove unnecessary columns and handle missing values from the CPS dataset
cps_data = subset(cps_data, select = -c(FSTOTXPNC_perpers, FSSTATUSMD, FSFOODS, FSWROUTY, FSBAL, FSRAWSCRA, FSTOTXPNC))
cps_data = cps_data[complete.cases(cps_data), ]  # Removing rows with NA values

##### EXPLORATORY ANALYSIS #####
# We define potential explanatory variables (X Variables) based on domain knowledge:
# hhsize, female, hispanic, black, kids, elderly, education, married.

# Converting FSSTATUS to a factor for better visualization in plots
cps_data = cps_data %>% 
  mutate(FSSTATUS_factor = as.factor(FSSTATUS))

# Creating bar plots and histograms to explore relationships between X variables and FSSTATUS (food insecurity)

##### EXPLORATORY ANALYSIS: Plotting food insecurity (FSSTATUS) against various variables #####

# 1. Food Insecurity Over Marital Status:
# This plot shows the proportion of food insecurity across different marital status groups
ggplot(data=cps_data) +
  geom_bar(aes(x=hhsize, fill=FSSTATUS_factor), position="fill") +
  labs(x="Number of People", y="Proportion") +
  ggtitle("Food Insecurity Over Household Size") +
  scale_fill_grey("Household Food\nInsecurity") +
  theme_minimal()

# 2. Food Insecurity Over the Number of Women in the Household:
# This plot visualizes food insecurity in relation to the number of women in the household (female)
ggplot(data=cps_data) +
  geom_histogram(aes(x=female, fill = FSSTATUS_factor), binwidth = 1, position = "fill") +
  labs(x="Number of Women in Household", y="Count of People") +
  ggtitle("Food Insecurity Over Number of Women in Household") +
  scale_fill_grey("Household Food\nInsecurity") +
  theme_minimal()

# 3. Food Insecurity Over the Number of Hispanics in the Household:
# Visualizes food insecurity in relation to the number of Hispanics in the household (hispanic)
ggplot(data=cps_data) +
  geom_histogram(aes(x=hispanic, fill = FSSTATUS_factor), binwidth = 1, position = "fill") +
  labs(x="Number of Hispanics in Household", y="Count of People") +
  ggtitle("Food Insecurity Over Number of Hispanics in Household") +
  scale_fill_grey("Household Food\nInsecurity") +
  theme_minimal()

# 4. Food Insecurity Over the Number of African Americans in the Household:
# Shows food insecurity related to the number of African Americans in the household (black)
ggplot(data=cps_data) +
  geom_histogram(aes(x=black, fill = FSSTATUS_factor), binwidth = 1, position = "fill") +
  labs(x="Number of African Americans in Household", y="Count of People") +
  ggtitle("Food Insecurity Over Number of African Americans in Household") +
  scale_fill_grey("Household Food\nInsecurity") +
  theme_minimal()

# 5. Food Insecurity Over the Number of Kids in the Household:
# Visualizes food insecurity in relation to the number of kids in the household (kids)
ggplot(data=cps_data) +
  geom_histogram(aes(x=kids, fill = FSSTATUS_factor), binwidth = 1, position = "fill") +
  labs(x="Number of Kids in Household", y="Count of People") +
  ggtitle("Food Insecurity Over Number of Kids in Household") +
  scale_fill_grey("Household Food\nInsecurity") +
  theme_minimal()

# 6. Food Insecurity Over the Number of Elderly in the Household:
# Shows food insecurity in relation to the number of elderly individuals in the household (elderly)
ggplot(data=cps_data) +
  geom_histogram(aes(x=elderly, fill = FSSTATUS_factor), binwidth = 1, position = "fill") +
  labs(x="Number of Elderly in Household", y="Count of People") +
  ggtitle("Food Insecurity Over Number of Elderly in Household") +
  scale_fill_grey("Household Food\nInsecurity") +
  theme_minimal()

# 7. Food Insecurity by Education Level:
# Visualizes the relationship between food insecurity and education level of individuals
ggplot(data=cps_data) +
  geom_bar(aes(x=education, fill = FSSTATUS_factor), position = "fill") +
  labs(x="Education Level", y="Count of People") +
  ggtitle("Food Insecurity by Education Level") +
  scale_fill_grey("Household Food\nInsecurity") +
  theme_minimal()

# 8. Food Insecurity Over the Number of Married People in the Household:
# This plot shows food insecurity in relation to the number of married people in the household (married)
ggplot(data=cps_data) +
  geom_histogram(aes(x=married, fill = FSSTATUS_factor), binwidth = 1, position = "fill") +
  labs(x="Number of Married People in Household", y="Count of People") +
  ggtitle("Food Insecurity Over Number of Married People in Household") +
  scale_fill_grey("Household Food\nInsecurity") +
  theme_minimal()


##### SPLITTING THE DATA INTO TRAINING AND TESTING SETS #####
# Set a random seed for reproducibility across different machines
RNGkind(sample.kind = "default")
set.seed(122111598)

# Splitting the data into training (70%) and testing (30%) sets
train.idx = sample(x=1:nrow(cps_data), size = floor(.7*nrow(cps_data)))

# Creating training and testing datasets
train.df = cps_data[train.idx,]
test.df = cps_data[-train.idx,]

##### LASSO AND RIDGE REGRESSION #####
# These regression models help to shrink coefficients of less important variables
# Lasso (alpha = 1) shrinks coefficients to zero, while Ridge (alpha = 0) shrinks them towards zero.

# Creating design matrices for the regression models (X variables as matrices)
x.train = model.matrix(FSSTATUS ~ hhsize + female + hispanic + black + kids + elderly + education + married, data = train.df)[, -1]
x.test = model.matrix(FSSTATUS ~ hhsize + female + hispanic + black + kids + elderly + education + married, data = test.df)[, -1]

# Creating response vectors for the regression models (Y variable as a vector)
y.train = as.vector(train.df$FSSTATUS)
y.test = as.vector(test.df$FSSTATUS)

# Performing cross-validation to tune lambda (penalty parameter) for Lasso and Ridge regressions
lr_lasso_cv = cv.glmnet(x.train, y.train, family = binomial(link = logit), weights = as.integer(train.df$weight), alpha = 1)
lr_ridge_cv = cv.glmnet(x.train, y.train, family = binomial(link = logit), weights = as.integer(train.df$weight), alpha = 0)

# Plotting the cross-validation results to choose the best lambda values
plot(lr_lasso_cv)
plot(lr_ridge_cv)

# Extracting the best lambda values for both models
best_lasso_lambda = lr_lasso_cv$lambda.min
best_ridge_lambda = lr_ridge_cv$lambda.min

##### FITTING FINAL MODELS #####
# Fitting the final models using the best lambda values
final_lasso = glmnet(x.train, y.train, family = binomial(link = "logit"), weights = as.integer(train.df$weight), alpha = 1, lambda = best_lasso_lambda)
final_ridge = glmnet(x.train, y.train, family = binomial(link = "logit"), weights = as.integer(train.df$weight), alpha = 0, lambda = best_ridge_lambda)

##### MODEL PERFORMANCE AND PREDICTIONS #####
# Adding the predicted values (probabilities) for each model (Lasso and Ridge) to the test dataset
test.df.preds = test.df %>% 
  mutate(
    lasso_pred = predict(final_lasso, x.test, type = "response")[,1],
    ridge_pred = predict(final_ridge, x.test, type = "response")[,1]
  )

# Generating ROC curves for both Lasso and Ridge models to assess predictive performance
lasso_rocCurve = roc(response = as.factor(test.df.preds$FSSTATUS), predictor = test.df.preds$lasso_pred, levels = c("0", "1"))
ridge_rocCurve = roc(response = as.factor(test.df.preds$FSSTATUS), predictor = test.df.preds$ridge_pred, levels = c("0", "1"))

# Plotting the ROC curves with the best thresholds and AUC values
plot(lasso_rocCurve, print.thres = TRUE, print.auc = TRUE)
plot(ridge_rocCurve, print.thres = TRUE, print.auc = TRUE)

# Extracting optimal thresholds (best classification thresholds) for both models
lasso_pi_star = coords(lasso_rocCurve, "best", ret = "threshold")$threshold[1]
test.df$lasso_pred = as.factor(ifelse(test.df.preds$lasso_pred > lasso_pi_star, "1", "0"))

ridge_pi_star = coords(ridge_rocCurve, "best", ret = "threshold")$threshold[1]
test.df$ridge_pred = as.factor(ifelse(test.df.preds$ridge_pred > ridge_pi_star, "1", "0"))

# Re-calculating ROC curves with adjusted thresholds
lasso_rocCurve = roc(response = as.factor(test.df.preds$FSSTATUS), predictor = test.df.preds$lasso_pred, levels = c("0", "1"))
ridge_rocCurve = roc(response = as.factor(test.df.preds$FSSTATUS), predictor = test.df.preds$ridge_pred, levels = c("0", "1"))

# Organizing ROC curve results into a data frame for easy comparison
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

# Combining Lasso and Ridge results for comparison
roc_data <- rbind(lasso_data, ridge_data)

# Adding a column for text placement in the plot for AUC values
roc_data <- roc_data %>%
  mutate(text_y = case_when(
    Model == "Lasso" ~ 0.75,
    Model == "Ridge" ~ 0.65
  ))

# Plotting ROC curves to compare Lasso and Ridge models
ggplot() +
  geom_line(aes(x = 1 - Specificity, y = Sensitivity, color = Model), data = roc_data, size =1.5, alpha = 0.75) +
  geom_text(data = roc_data %>% group_by(Model) %>% slice(1), 
            aes(x = 0.75, y = text_y, color = Model,
                label = paste0(Model, " AUC = ", round(AUC, 3)))) +
  scale_colour_brewer(palette = "Set2") +
  labs(title = "Lasso and Ridge Regression for Household Food Insecurity", x = "1 - Specificity", y = "Sensitivity", color = "Model") +
  theme_minimal()

##### COEFFICIENTS AND INTERPRETATION #####
# Extracting the coefficients of the models to understand the influence of each predictor variable
lr_lasso_coeff = coef(lr_lasso_cv, s = "lambda.min") %>% as.matrix()
lr_ridge_coeff = coef(lr_ridge_cv, s = "lambda.min") %>% as.matrix()

# Displaying the coefficients for interpretation
(lr_lasso_coeff)
(lr_ridge_coeff)

##### PREDICTING ON ACS DATA #####
# Preparing ACS data for prediction by selecting relevant features
acs_test = subset(acs_data, select = c(hhsize, female, hispanic, black, kids, elderly, education, married))
acs_test = as.matrix(acs_test)

# Generating predicted probabilities for the ACS data using Lasso and Ridge models
acs_data = acs_data %>% 
  mutate(
    lasso_pred_prob = predict(final_lasso, acs_test, type = "response")[,1],
    ridge_pred_prob = predict(final_ridge, acs_test, type = "response")[,1]
  )

# Aggregating predictions to the PUMA level (Public Use Microdata Area) using weighted averages
puma_acs = acs_data %>% 
  filter(elderly > 0) %>% 
  group_by(PUMA = as.factor(PUMA)) %>%
  summarise(
    mean_lasso_prob = weighted.mean(lasso_pred_prob, weights = weight),
    mean_ridge_prob = weighted.mean(ridge_pred_prob, weights = weight),
    senior_count = sum(elderly)
  ) %>% ungroup()

# Finding the PUMA with the highest predicted probability from both Lasso and Ridge models
puma_acs[max(puma_acs$mean_lasso_prob) == puma_acs$mean_lasso_prob,]
puma_acs[max(puma_acs$mean_ridge_prob) == puma_acs$mean_ridge_prob,]

##### MAPPING PUMA AREAS #####
# Using TIGER/Line shapefiles to create maps of PUMA areas (Public Use Microdata Areas)
options(tigris_class = "sf")
options(tigris_use_cache = TRUE)

# Fetching PUMA shapefile data for Iowa (or another state if needed)
pumas <- pumas(state = "IA", year = 2022)

# Creating a map of PUMAs colored by the mean Lasso predicted probabilities
ggplot(data = pumas) +
  geom_sf(aes(fill = puma_acs$mean_lasso_prob), color = "black") +
  scale_fill_gradient(
    low = "lightblue", high = "darkblue",  # Color gradient representing mean probabilities
    name = "Mean Lasso Probability"
  ) +
  labs(
    title = "PUMA Map for Household Food Security",
    subtitle = "Public Use Microdata Areas (PUMAs) for Iowa",
    caption = "Source: TIGER/Line Shapefiles"
  ) +
  theme_minimal()
