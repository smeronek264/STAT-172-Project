# NOTE: CHATGPT was utilized to add comments throughout the code
# CHATGPT was also used to create the categorization of faminc 

# Clear the environment
# Uncomment the following line only if you are testing the code
# rm(list = ls())

# Load necessary libraries
library(tidyverse)  # Comprehensive data manipulation and visualization
library(ggthemes)   # Themes for ggplot2
library(logistf)    # Logistic regression with Firth correction
library(glmnet)     # Regularization for regression models
library(haven)      # Reading and writing SPSS, Stata, and SAS files
library(knitr)      # Dynamic report generation
library(dplyr)      # Data manipulation

# Load the data
cps <- read.csv("data/cps_00006.csv")

# Check the distribution of the target variable
table(cps$FSFOODS)

##### CLEAN CPS DATA #####

# Create derived variables
cps <- cps %>%
  mutate(
    SEX = SEX - 1,  # Convert SEX to a dummy variable (0 = Male, 1 = Female)
    CHILD = ifelse(AGE < 18, 1, 0),  # Identify children under 18
    ELDERLY = ifelse(AGE > 60, 1, 0),  # Elderly defined as 60+
    BLACK = ifelse(RACE == 200, 1, 0),  # Dummy variable for Black race
    HISPANIC = ifelse(HISPAN > 0, 1, 0),  # Dummy variable for Hispanic ethnicity
    EDUC = as.integer(EDUC %in% c(91, 92, 111, 123, 124, 125)),  # High school or higher education
    EMP = as.integer(EMPSTAT %in% c(1, 10, 12)),  # Employment status
    MARRIED = as.integer(MARST %in% c(1, 2)),  # Married or partnered
    DIFF = ifelse(DIFFANY == 2, 1, 0),  # Difficulty variable
    COUNTY = as.factor(COUNTY)  # Convert COUNTY to a factor
  )

# Categorize family income into meaningful groups
cps <- cps %>%
  mutate(
    FAMINC_category = case_when(
      FAMINC == 100 ~ "Under $5,000",
      FAMINC == 210 ~ "$5,000 - $7,499",
      FAMINC == 300 ~ "$7,500 - $9,999",
      FAMINC == 430 ~ "$10,000 - $12,499",
      FAMINC == 470 ~ "$12,500 - $14,999",
      FAMINC == 500 ~ "$15,000 - $19,999",
      FAMINC == 600 ~ "$20,000 - $24,999",
      FAMINC == 710 ~ "$25,000 - $29,999",
      FAMINC == 720 ~ "$30,000 - $34,999",
      FAMINC == 730 ~ "$35,000 - $39,999",
      FAMINC == 740 ~ "$40,000 - $49,999",
      FAMINC == 820 ~ "$50,000 - $59,999",
      FAMINC == 830 ~ "$60,000 - $74,999",
      FAMINC == 841 ~ "$75,000 - $99,999",
      FAMINC == 842 ~ "$100,000 - $149,999",
      FAMINC == 843 ~ "$150,000 and over",
      FAMINC %in% c(995, 996, 997, 999) ~ "Missing/Refused/Don't know",
      TRUE ~ "Unknown"
    )
  )

# Aggregate data to the household level
cps_data <- cps %>%
  group_by(CPSID = as.factor(CPSID)) %>%
  summarise(
    COUNTY = first(COUNTY),
    weight = first(HWTFINL),  # Family-level weight
    hhsize = n(),  # Household size
    FSTOTXPNC_perpers = FSTOTXPNC / hhsize,  # Expenditures per person
    FSSTATUS = first(FSSTATUS),  # Food security status
    FSSTATUSMD = first(FSSTATUSMD),  # Food security moderate status
    FSFOODS = first(FSFOODS),  # Food insecurity indicator
    FSWROUTY = first(FSWROUTY),  # Food worry indicator
    FSBAL = first(FSBAL),  # Food balance indicator
    FSRAWSCRA = first(FSRAWSCRA),  # Raw food score
    FSTOTXPNC = first(FSTOTXPNC),  # Total food expenditure
    female = sum(SEX),  # Count of females in the household
    hispanic = sum(HISPANIC),  # Count of Hispanic individuals
    black = sum(BLACK),  # Count of Black individuals
    kids = sum(CHILD),  # Count of children
    elderly = sum(ELDERLY),  # Count of elderly individuals
    education = sum(EDUC),  # Count of educated individuals
    married = sum(MARRIED),  # Count of married individuals
    income = first(FAMINC_category)  # Family income category
  ) %>%
  ungroup()

# Handle missing values in food security variables
cps_data <- cps_data %>%
  mutate(
    FSSTATUS = ifelse(FSSTATUS %in% c(98, 99), NA, FSSTATUS),
    FSSTATUSMD = ifelse(FSSTATUSMD %in% c(98, 99), NA, FSSTATUSMD),
    FSFOODS = ifelse(FSFOODS %in% c(98, 99), NA, FSFOODS),
    FSWROUTY = ifelse(FSWROUTY %in% c(96, 97, 98, 99), NA, FSWROUTY),
    FSBAL = ifelse(FSBAL %in% c(96, 97, 98, 99), NA, FSBAL),
    FSRAWSCRA = ifelse(FSRAWSCRA %in% c(98, 99), NA, FSRAWSCRA),
    FSTOTXPNC = ifelse(FSTOTXPNC %in% c(999), NA, FSTOTXPNC)
  ) %>%
  mutate(
    FSSTATUS = ifelse(FSSTATUS > 1, 1, 0),
    FSSTATUSMD = ifelse(FSSTATUSMD > 1, 1, 0),
    FSFOODS = ifelse(FSFOODS > 1, 1, 0),
    FSWROUTY = ifelse(FSWROUTY > 1, 1, 0),
    FSBAL = ifelse(FSBAL > 1, 1, 0),
    FSRAWSCRA = ifelse(FSRAWSCRA > 1, 1, 0)
  )
