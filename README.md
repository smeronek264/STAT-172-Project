# Analyzing Food Insecurity in Iowa

**Authors**: Sophie Meronek, Samuel Trujillo, and Nolan Henze  
**Date**: 12/12/2024

## Introduction

This repository contains the code and data required for our project analyzing food insecurity in Iowa, with a particular focus on food insecurity among the elderly. The analysis is performed using the R programming language.

The goal of this project is to assess food insecurity across Iowa, specifically among the elderly population. We collaborated with **WesleyLife**, a non-profit organization that provides meals to individuals who are unable to prepare healthy meals or cannot cook at all. The analysis aims to identify potential areas where WesleyLife could expand to help more people.

The recommendations will be based on **Public Use Microdata Areas (PUMAs)** and notable counties within each PUMA.


## Data Source and Preparation

For this project, we used two datasets: **CPS (Current Population Survey)** and **ACS (American Community Survey)**. The links to these datasets can be found found below.

All code involved in cleaning the the data can be found in the files `scr/clean_cps.R` and `scr/clean_acs.R` for the CPS and ACS data respectivly.

### CPS Data

The **Current Population Survey (CPS)** is a monthly survey conducted by the U.S. Bureau of Labor Statistics (BLS). It gathers data on demographics, employment, and program participation. You can access the data at [CPS Website](https://cps.ipums.org/cps/).  The data will be in the format of a CSV (Comma Seperated File).

The CPS dataset includes household identification, demographics, income levels, and survey responses regarding food security. However, the dataset only covers a limited number of counties in Iowa, which makes it insufficient for analyzing the entire state.

Thus, the CPS data will be used to train and test a model for predicting food insecurity, but it will not be used for broader interpretations.

### ACS Data

The **American Community Survey (ACS)** is conducted annually by the U.S. Census Bureau and provides social, economic, housing, and demographic data for geographic areas. You can access the data at [ACS Website](https://www.census.gov/programs-surveys/acs/data.html).  The data will be in the format of a SAS data export.

While the ACS dataset does not include questions on food security, we will apply the model created using CPS data to predict food insecurity for different households, counties, and eventually PUMAs in Iowa.

### Data Preparation


For data preparation, preparing the demographic portion of the data was the same for both CPS and ACS data.  This would involve turning different demographics such as age, race, gender, marital status, and education into a binary term (1 for true and 0 for false). One of the most important categories was ELDERLY since we are wanting to analyze their potential food insecurity.  

Once we had created 



## Repository Structure

The repository contains the following key sections:

- **scr**: Scripts for data analysis and model development.
- **data**: The datasets (CPS and ACS).
- **outputs**: Visualizations and outputs of the analysis. Will also include an example of a code ouput with interpretations.

## Requirements

To run the code in this repository, you will need the following installed:

- R (version 4.0.0 or higher)
- Required R packages (run the following code to install the packages in R)
```r
install.packages(c("tidyverse", "ggthemes", "logistf", "glmnet", "haven",
                   "knitr", "ggplot2", "RColorBrewer", "pROC", "lubridate",
                   "sf", "dplyr", "tigris"))
```

## Methods

The analysis involves the following steps:

1. Data cleaning and preprocessing.
2. Training a predictive model using the CPS data.
3. Applying the model to the ACS data to predict food insecurity in Iowa.





## Code Execution

The main script to run the analysis is `food_insecurity_analysis.R`. Ensure that all necessary data files are in the correct directory before executing the script.



## References

1. U.S. Bureau of Labor Statistics, **Current Population Survey**: [https://www.bls.gov/cps/](https://www.bls.gov/cps/)
2. IPUMS, **Current Population Survey (CPS)**: [https://cps.ipums.org/cps/](https://cps.ipums.org/cps/)
3. U.S. Census Bureau, **American Community Survey (ACS)**: [https://www.census.gov/programs-surveys/acs/data.html](https://www.census.gov/programs-surveys/acs/data.html)

## Disclaimer
This project was for STAT 172: Data Mining and General Linear Model at Drake University.  We were partnered with WesleyLife for the project and all recommendation were targetted to their plans.
