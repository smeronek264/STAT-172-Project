# clear the environment
# rm(list=ls()) # Only run this line of code if you are testing the code
# otherwise it will erase all contents when doing source()

# install packages (SHOULD ONLY DO THIS IF YOU DON"T HAVE THEM)
# Will comment out the following code since I have all the libraries

# install.packages("tidyverse")
# install.packages("ggthemes")
# install.packages("logistf")
# install.packages("glmnet")
# install.packages("haven")
# install.packages("knitr")


# load the libraries
library(tidyverse)
library(ggthemes)
library(logistf)
library(glmnet)
library(haven)
library(knitr)
library(dplyr)


# load in the data
cps<-read.csv("data/cps_00006.csv")

##### CLEAN CPS DATA #####
cps<-cps%>%
  mutate(SEX=SEX-1, #Create dummy variables
         CHILD= ifelse(AGE < 18,1,0),
         ELDERLY= ifelse(AGE > 60,1,0),#NOTE DEFINITION: 60+ are elderly
         BLACK= ifelse(RACE==200,1,0),
         HISPANIC=ifelse(HISPAN>0,1,0),
         EDUC= as.integer(EDUC %in%c(91,92,111,123,124,125)),
         EMP=as.integer(EMPSTAT%in%c(1,10,12)),
         MARRIED= as.integer(MARST %in%c(1,2)),
         DIFF= ifelse(DIFFANY==2,1,0),
         COUNTY=as.factor(COUNTY))


# Assuming your dataset is called `cps_data`
cps <- cps %>%
  mutate(
    FAMINC_category = case_when(
      # Under $5,000
      FAMINC == 100 ~ "Under $5,000",
      # $5,000 - 7,499
      FAMINC == 210 ~ "$5,000 - $7,499",
      # $7,500 - 9,999
      FAMINC == 300 ~ "$7,500 - $9,999",
      # $10,000 - 12,499
      FAMINC == 430 ~ "$10,000 - $12,499",
      # $12,500 - 14,999
      FAMINC == 470 ~ "$12,500 - $14,999",
      # $15,000 - 19,999
      FAMINC == 500 ~ "$15,000 - $19,999",
      # $20,000 - 24,999
      FAMINC == 600 ~ "$20,000 - $24,999",
      # $25,000 - 29,999
      FAMINC == 710 ~ "$25,000 - $29,999",
      # $30,000 - 34,999
      FAMINC == 720 ~ "$30,000 - $34,999",
      # $35,000 - 39,999
      FAMINC == 730 ~ "$35,000 - $39,999",
      # $40,000 - 49,999
      FAMINC == 740 ~ "$40,000 - $49,999",
      # $50,000 - 59,999
      FAMINC == 820 ~ "$50,000 - $59,999",
      # $60,000 - 74,999
      FAMINC == 830 ~ "$60,000 - $74,999",
      # $75,000 - 99,999
      FAMINC == 841 ~ "$75,000 - $99,999",
      # $100,000 - 149,999
      FAMINC == 842 ~ "$100,000 - $149,999",
      # $150,000 and over
      FAMINC == 843 ~ "$150,000 and over",
      # Missing, Refused, Don't know, Blank
      FAMINC %in% c(995, 996, 997, 999) ~ "Missing/Refused/Don't know",
      # Default case: all other values will be treated as NA
      TRUE ~ "Unknown"
    )
  )


# The data is currently on the individual level, however, we want the data to be
# on the house hold level so we are going to group the data together by CPSID and
# then find the different data points
#currently,onerowofcps=oneindividual
cps_data<-cps %>%
  group_by(CPSID=as.factor(CPSID)) %>%
  summarise(COUNTY= first(COUNTY),
            #familylevelweight
            weight= first(HWTFINL),
            #householdsize
            hhsize= n(),
            #Y variables-i.e.,measures of hunger
            #see CPS website for details
            #FSSTATUS,etc.is the same for each member-just take first value for each family
            FSTOTXPNC_perpers=FSTOTXPNC/hhsize, #In per person terms
            FSSTATUS= first(FSSTATUS),
            FSSTATUSMD= first(FSSTATUSMD),
            FSFOODS= first(FSFOODS),
            FSWROUTY= first(FSWROUTY),
            FSBAL= first(FSBAL),
            FSRAWSCRA= first(FSRAWSCRA),
            FSTOTXPNC= first(FSTOTXPNC),
            FSSTATUS=first(FSSTATUS),
            #count of family members in various categories
            female= sum(SEX),
            hispanic=sum(HISPANIC),
            black= sum(BLACK),
            kids= sum(CHILD),
            elderly= sum(ELDERLY),
            education= sum(EDUC),
            married= sum(MARRIED),
            faminc = first(FAMINC_category)) %>%ungroup()

#each row of cps_data is a FAMILY
#note...we just calculated the number of people in each family that belong

cps_data<-cps_data %>%
  mutate(FSSTATUS=ifelse(FSSTATUS%in%c(98,99),NA,FSSTATUS),
         FSSTATUSMD= ifelse(FSSTATUSMD%in%c(98,99),NA,FSSTATUSMD),
         FSFOODS= ifelse(FSFOODS%in%c(98,99),NA,FSFOODS),
         FSWROUTY=ifelse(FSWROUTY %in%c(96,97,98,99),NA,FSWROUTY),
         FSBAL= ifelse(FSBAL %in%c(96,97,98,99),NA,FSBAL),
         FSRAWSCRA=ifelse(FSRAWSCRA%in%c(98,99),NA,FSRAWSCRA),#rawscore
         FSTOTXPNC=ifelse(FSTOTXPNC%in%c(999),NA,FSTOTXPNC)) %>%
  mutate(FSSTATUS=ifelse(FSSTATUS> 1,1,0),
         FSSTATUSMD= ifelse(FSSTATUSMD > 1,1,0),
         FSFOODS= ifelse(FSFOODS >1,1,0),
         FSWROUTY=ifelse(FSWROUTY> 1,1,0),#more missings
         FSBAL = ifelse(FSBAL > 1, 1, 0),
         FSRAWSCRA=ifelse(FSRAWSCRA > 1, 1, 0))


#Note: many of our y variables contain some NA values.
#Do not use complete.cases or na.omit on the whole dataset.