# Clear the environment
# Uncomment the line below only if testing the code to remove all objects
# rm(list = ls())

# Install required packages (only if not already installed)
# Commented out because the packages are assumed to be installed
# install.packages("tidyverse")
# install.packages("ggthemes")
# install.packages("logistf")
# install.packages("glmnet")
# install.packages("haven")
# install.packages("knitr")

# Load required libraries
library(tidyverse)  # Comprehensive data manipulation and visualization
library(ggthemes)   # Themes for ggplot2
library(logistf)    # Logistic regression with Firth correction
library(glmnet)     # Regularization methods for regression
library(haven)      # Read SAS, SPSS, Stata files
library(knitr)      # Dynamic reporting

# Load the ACS data (Assuming the SAS data file is in "data" directory)
acs <- read_sas("data/spm_pu_2022.sas7bdat")

# Filter for a specific state (e.g., Iowa, "19") and calculate weights
acs <- acs %>%
  filter(st == "19") %>%  # Filter for state code
  group_by(serialno = as.factor(serialno)) %>%
  arrange(desc(Sex), desc(Age)) %>%
  mutate(weight = first(wt)) %>%  # Assign household weight
  select(-wt) %>%  # Drop individual weight column
  ungroup()

# Create derived variables matching the CPS definitions
acs <- acs %>%
  mutate(
    SEX = Sex - 1,  # Convert SEX to dummy variable (0 = Male, 1 = Female)
    CHILD = ifelse(Age < 18, 1, 0),  # Children under 18
    ELDERLY = ifelse(Age > 60, 1, 0),  # Elderly defined as age > 64
    BLACK = ifelse(Race == 2, 1, 0),  # Black race dummy variable
    HISPANIC = ifelse(Hispanic > 0, 1, 0),  # Hispanic ethnicity dummy variable
    EDUC = as.integer(Education %in% c(3, 4)),  # Education level (e.g., high school or higher)
    MARRIED = as.integer(Mar %in% c(1)),  # Married or partnered
    PUMA = as.factor(PUMA)  # Convert PUMA to a factor
  )

# Aggregate data to the family level
acs_data <- acs %>%
  group_by(serialno = as.factor(serialno)) %>%
  summarise(
    PUMA = first(PUMA),  # Retain PUMA for household
    hhsize = length(serialno),  # Household size
    female = sum(SEX),  # Number of females
    hispanic = sum(HISPANIC),  # Number of Hispanic individuals
    black = sum(BLACK),  # Number of Black individuals
    kids = sum(CHILD),  # Number of children
    elderly = sum(ELDERLY),  # Number of elderly individuals
    education = sum(EDUC),  # Number of educated individuals
    married = sum(MARRIED),  # Number of married individuals
    AGI = first(AGI),  # Adjusted Gross Income
    weight = weight[1]  # Household weight
  )

# Create income categories
acs_data <- acs_data %>%
  mutate(
    income = case_when(
      AGI < 5000 ~ "Under $5,000",
      AGI >= 5000 & AGI <= 7499 ~ "$5,000 - $7,499",
      AGI >= 7500 & AGI <= 9999 ~ "$7,500 - $9,999",
      AGI >= 10000 & AGI <= 12499 ~ "$10,000 - $12,499",
      AGI >= 12500 & AGI <= 14999 ~ "$12,500 - $14,999",
      AGI >= 15000 & AGI <= 19999 ~ "$15,000 - $19,999",
      AGI >= 20000 & AGI <= 24999 ~ "$20,000 - $24,999",
      AGI >= 25000 & AGI <= 29999 ~ "$25,000 - $29,999",
      AGI >= 30000 & AGI <= 34999 ~ "$30,000 - $34,999",
      AGI >= 35000 & AGI <= 39999 ~ "$35,000 - $39,999",
      AGI >= 40000 & AGI <= 49999 ~ "$40,000 - $49,999",
      AGI >= 50000 & AGI <= 59999 ~ "$50,000 - $59,999",
      AGI >= 60000 & AGI <= 74999 ~ "$60,000 - $74,999",
      AGI >= 75000 & AGI <= 99999 ~ "$75,000 - $99,999",
      AGI >= 100000 & AGI <= 149999 ~ "$100,000 - $149,999",
      AGI >= 150000 ~ "$150,000 and over",
      TRUE ~ "Unknown"  # Catch undefined or NA cases
    )
  )
