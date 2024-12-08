# clear the environment
# rm(list=ls()) Only run this line of code if you are testing the code
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

# load in the data
# this code should probably go in clean_acs.R...
acs<-read_sas("data/spm_pu_2022.sas7bdat")
# to calculate weights (go ahead and just copy/paste this):
acs<-acs%>%
  filter(st =="19")%>%
  group_by(serialno=as.factor(serialno))%>%
  arrange(desc(Sex), desc(Age)) %>%
  mutate(weight= first(wt))%>%select(-wt) %>%ungroup()


#createsamevariablesasinCPS
acs<-acs%>%
  mutate(SEX=Sex-1, #since female=2
         CHILD= ifelse(Age< 18,1, 0),#SAMEascpsdefinition
         ELDERLY= ifelse(Age > 64,1,0),#SAMEascpsdefinition
         BLACK= ifelse(Race==2,1,0), #SAMEascpsdefinition(seedatadictionary)
         HISPANIC=ifelse(Hispanic>0,1,0), #SAMEascpsdefinition(seedatadictionary)
         EDUC= as.integer(Education%in%c(3,4)),
         MARRIED= as.integer(Mar %in%c(1)),
         PUMA= as.factor(PUMA))


#aggregateuptofamilylevel
acs_data<-acs %>%
  group_by(serialno=as.factor(serialno)) %>%
  summarise(PUMA= first(PUMA),
            hhsize= length(serialno),
            #countsofpeoplewithvariousfeatures-justlikeforCPS
            female= sum(SEX),
            hispanic= sum(HISPANIC),
            black= sum(BLACK),
            kids= sum(CHILD),
            elderly= sum(ELDERLY),
            education= sum(EDUC),
            married= sum(MARRIED),
            AGI= first(AGI),
            weight = weight[1],
  )

# Assuming your dataset is called `acs_data`
acs_data = acs_data %>% 
  mutate(
    income = case_when(
      AGI < 5000 ~ "Under $5,000",
      AGI >= 5000 & AGI < 7500 ~ "$5,000 - $7,499",
      AGI >= 5000 & AGI < 6000 ~ "$5,000 - $5,999",
      AGI >= 6000 & AGI < 7000 ~ "$6,000 - $6,999",
      AGI >= 7000 & AGI < 7500 ~ "$7,000 - $7,499",
      AGI >= 5000 & AGI < 8000 ~ "$5,000 - $7,999",
      AGI >= 6000 & AGI < 8000 ~ "$6,000 - $7,999",
      AGI >= 7000 & AGI < 8000 ~ "$7,000 - $7,999",
      AGI >= 7500 & AGI < 10000 ~ "$7,500 - $9,999",
      AGI >= 7500 & AGI < 8000 ~ "$7,500 - $7,999",
      AGI >= 8000 & AGI < 8500 ~ "$8,000 - $8,499",
      AGI >= 8500 & AGI < 9000 ~ "$8,500 - $8,999",
      AGI >= 8000 & AGI < 9000 ~ "$8,000 - $8,999",
      AGI >= 9000 & AGI < 10000 ~ "$9,000 - $9,999",
      AGI >= 10000 & AGI < 11000 ~ "$10,000 - $10,999",
      AGI >= 11000 & AGI < 12000 ~ "$11,000 - $11,999",
      AGI >= 10000 & AGI < 12500 ~ "$10,000 - $12,499",
      AGI >= 10000 & AGI < 12000 ~ "$10,000 - $11,999",
      AGI >= 12000 & AGI < 13000 ~ "$12,000 - $12,999",
      AGI >= 13000 & AGI < 14000 ~ "$13,000 - $13,999",
      AGI >= 14000 & AGI < 15000 ~ "$14,000 - $14,999",
      AGI >= 15000 & AGI < 16000 ~ "$15,000 - $15,999",
      AGI >= 16000 & AGI < 17000 ~ "$16,000 - $16,999",
      AGI >= 17000 & AGI < 18000 ~ "$17,000 - $17,999",
      AGI >= 15000 & AGI < 17500 ~ "$15,000 - $17,499",
      AGI >= 17500 & AGI < 20000 ~ "$17,500 - $19,999",
      AGI >= 18000 & AGI < 20000 ~ "$18,000 - $19,999",
      AGI >= 20000 & AGI < 25000 ~ "$20,000 - $24,999",
      AGI >= 25000 & AGI < 30000 ~ "$25,000 - $29,999",
      AGI >= 30000 & AGI < 35000 ~ "$30,000 - $34,999",
      AGI >= 35000 & AGI < 40000 ~ "$35,000 - $39,999",
      AGI >= 40000 & AGI < 50000 ~ "$40,000 - $49,999",
      AGI >= 50000 & AGI < 60000 ~ "$50,000 - $59,999",
      AGI >= 60000 & AGI < 75000 ~ "$60,000 - $74,999",
      AGI >= 50000 & AGI < 75000 ~ "$50,000 - $74,999",
      AGI >= 75000 & AGI < 100000 ~ "$75,000 - $99,999",
      AGI >= 100000 & AGI < 150000 ~ "$100,000 - $149,999",
      AGI >= 150000 ~ "$150,000 and over",
      is.na(AGI) ~ "Missing/Refused/Don't know",
      TRUE ~ "Other"
    )
  )

