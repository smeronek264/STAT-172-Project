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
            income= first(AGI),
            weight = weight[1],
  )
            

summary(acs)
