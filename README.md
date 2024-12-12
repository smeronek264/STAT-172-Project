# Analyzing Food Insecurity in Iowa

**Authors**: Sophie Meronek, Samuel Trujillo, and Nolan Henze  
**Date**: 12/12/2024

## Introduction

This repository contains the code and data required for our project analyzing food insecurity in Iowa, with a particular focus on food insecurity among the elderly. The analysis is performed using the R programming language.

The goal of this project is to assess food insecurity across Iowa, specifically among the elderly population. We collaborated with **WesleyLife**, a non-profit organization that provides meals to individuals who are unable to prepare healthy meals or cannot cook at all. The analysis aims to identify potential areas where WesleyLife could expand to help more people.

The recommendations will be based on **Public Use Microdata Areas (PUMAs)** and notable counties within each PUMA.

## Data Source and Preparation

For this project, we used two datasets: **CPS (Current Population Survey)** and **ACS (American Community Survey)**. The links to these datasets can be found below.

All code involved in cleaning the data can be found in the files `scr/clean_cps.R` and `scr/clean_acs.R` for the CPS and ACS data, respectively.

### CPS Data

The **Current Population Survey (CPS)** is a monthly survey conducted by the U.S. Bureau of Labor Statistics (BLS). It gathers data on demographics, employment, and program participation. You can access the data at [CPS Website](https://cps.ipums.org/cps/). The data will be in the format of a CSV (Comma Separated File).

The CPS dataset includes household identification, demographics, income levels, and survey responses regarding food security. However, the dataset only covers a limited number of counties in Iowa, which makes it insufficient for analyzing the entire state.

Thus, the CPS data will be used to train and test a model for predicting food insecurity, but it will not be used for broader interpretations.

### ACS Data

The **American Community Survey (ACS)** is conducted annually by the U.S. Census Bureau and provides social, economic, housing, and demographic data for geographic areas. You can access the data at [ACS Website](https://www.census.gov/programs-surveys/acs/data.html). The data will be in the format of a SAS data export.

While the ACS dataset does not include questions on food security, we will apply the model created using CPS data to predict food insecurity for different households, counties, and eventually PUMAs in Iowa.

### Data Preparation

For data preparation, preparing the demographic portion of the data was the same for both CPS and ACS data. This involves turning different demographics such as age, race, gender, marital status, and education into binary terms (1 for true and 0 for false). One of the most important categories was **ELDERLY**, since we are focusing on analyzing their potential food insecurity.

Once we had created these binary variables, we needed to aggregate the individual data to the household level. This was done by grouping each household together and then taking the sum of all demographic attributes to determine how many of each category were in the household. For example, if 4 individuals had a 1 in the value for **ELDERLY**, then the household demographic would show 4 elderly individuals.

Since CPS data is our cleaned data, it holds the target variable (Y). For cleaning the Y variables, we use 1 to denote the existence of food insecurity. For example, **FSFOODS**, which is the food variety and the amount of food indicator, is marked as 1 if they don't have enough food or enough variety of food. These variables are the same for the entire household, so we only need to take the first entry.

At the start of each analysis script, we would choose the Y variable we were predicting and remove the others. Following that, we would remove observations with missing Y data, as we wouldn't be able to test the accuracy. Then, we would split our data into 70% for training and 30% for testing our model. Since we are using lasso and ridge regression, we would need to turn our data frames into matrices.

## Repository Structure

The repository contains the following key sections:

- **scr**: Scripts for data analysis and model development.
- **data**: The datasets (CPS and ACS).
- **outputs**: Visualizations and outputs of the analysis. Will also include an example of a code output with interpretations.

## Requirements

To run the code in this repository, you will need the following installed:

- R (version 4.0.0 or higher)
- Required R packages (run the following code to install the packages in R)

```r
install.packages(c("tidyverse", "ggthemes", "logistf", "glmnet", "haven",
                   "knitr", "ggplot2", "RColorBrewer", "pROC", "lubridate",
                   "sf", "dplyr", "tigris"))
```

## Variables

Below is a list of predictor (X) variables used to predict the outcome (Y) variables.

### Predictor Variables (X)
- **hhsize**: The number of people in a household.
- **female**: The number of females in a household.
- **hispanic**: The number of Hispanics in a household.
- **black**: The number of Black individuals in a household.
- **kids**: The number of children (under 18) in a household.
- **elderly**: The number of seniors (over 60) in a household.
- **education**: The number of people with a college degree in a household.
- **married**: The number of married individuals in a household.

### Outcome Variables (Y)
- **FSFOODS**: The household lacks enough food and/or variety.
- **FSSTATUS**: The household lacks food security.

## Methods

The analysis follows these steps:

1. **Data Cleaning and Preprocessing**: Preparing the data for analysis.
2. **Model Training**: Training a predictive model using the CPS data.
3. **Model Application**: Applying the model to ACS data to predict food insecurity in Iowa.
4. **Aggregation**: Aggregating household-level predictions to the PUMA level.

The model is trained using the CPS data and tested for accuracy. For each outcome variable (Y), two Bernoulli models are trained with a logit link function using Lasso (where unimportant variables have coefficients set to zero) and Ridge (where unimportant variables have coefficients close to zero). Since food insecurity is a binary outcome (insecurity exists or not), the logit link ensures the output remains between 0 and 1. The models are evaluated using testing data, and the one with the highest Area Under the Curve (AUC) on a ROC plot is selected as the best model. Finally, the best model is used to predict food insecurity in the ACS data, and weighted means are calculated for each PUMA to identify regions with the highest probabilities of food insecurity.

## Code Execution

To reproduce the results:

1. Download the CPS and ACS data from the provided links.
2. Download the files into the `src/` directory.
3. Install the required packages by running the setup script.
4. Run the scripts `src/FSFOODS.R` and `src/FSSTATUS_Analysis.R`.
5. All interpretations are commented within the code.
6. Compare the results with those in the `outputs/` directory to verify the accuracy of the predictions.

## References

1. U.S. Bureau of Labor Statistics, **Current Population Survey**: [https://www.bls.gov/cps/](https://www.bls.gov/cps/)
2. IPUMS, **Current Population Survey (CPS)**: [https://cps.ipums.org/cps/](https://cps.ipums.org/cps/)
3. U.S. Census Bureau, **American Community Survey (ACS)**: [https://www.census.gov/programs-surveys/acs/data.html](https://www.census.gov/programs-surveys/acs/data.html)

## Disclaimer

This project was completed for STAT 172: Data Mining and General Linear Model at Drake University. We partnered with WesleyLife for this project, and all recommendations were tailored to their plans and needs.
