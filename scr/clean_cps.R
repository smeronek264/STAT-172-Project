# clear the environment
rm(list=ls())

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
cps<-read.csv("data/cps_00005.csv")

# look at a few lines of data
head(cps[,c("CPSID","PERNUM","FSSTATUS","FSSTATUSMD","RACE","EDUC")]) %>% kable

# look at CPS
table(cps$STATEFIP)

##### CLEAN CPS DATA #####

#save this code into a src folder named clean_cps.R
#you'll also save code called clean_acs.R...
#andhopefullymultipleanalysisfiles-oneforeachoftheYvariablesyouchoose tomodel.
#youranalysisfilescansourceclean_cps.Rusingthesource()function
#eachrow ofcpsisaniNDIVIDUALwithinafamily
cps<-cps%>%
  mutate(SEX=SEX-1, #Createdummyvariables
         CHILD= ifelse(AGE < 18,1,0),
         ELDERLY= ifelse(AGE > 60,1,0),#NOTEDEFINITION
         BLACK= ifelse(RACE==200,1,0),
         HISPANIC=ifelse(HISPAN>0,1,0),
         EDUC= as.integer(EDUC %in%c(91,92,111,123,124,125)),
         EMP=as.integer(EMPSTAT%in%c(1,10,12)),
         MARRIED= as.integer(MARST %in%c(1,2)),
         DIFF= ifelse(DIFFANY==2,1,0),
         COUNTY=as.factor(COUNTY))
#currently,onerowofcps=oneindividual
#however,wewanttomakepredictiononthefamilylevel
#aggregatetothefamilylevel-thisiswherewechooseFAMILY-LEVELtraits
#thatwewanttocalculate.Forexample,householdsizeisequaltothe
#numberofrowsforthatfamily.
cps_data<-cps %>%
  group_by(CPSID=as.factor(CPSID)) %>%
  summarise(COUNTY= first(COUNTY),
            #familylevelweight
            weight= first(HWTFINL),
            #householdsize
            hhsize= n(),
            #Yvariables-i.e.,measuresofhunger
            #seeCPSwebsitefordetails
            #FSSTATUS,etc.isthesameforeachmember-justtakefirstvalueforeachfamily
            FSTOTXPNC_perpers=FSTOTXPNC/hhsize, #Inperpersonterms
            FSSTATUS= first(FSSTATUS),
            FSSTATUSMD= first(FSSTATUSMD),
            FSFOODS= first(FSFOODS),
            FSWROUTY= first(FSWROUTY),
            FSBAL= first(FSBAL),
            FSRAWSCRA= first(FSRAWSCRA),
            FSTOTXPNC= first(FSTOTXPNC),
            FSSTATUS=first(FSSTATUS),
            #countoffamilymembers invariouscategories
            female= sum(SEX),
            hispanic=sum(HISPANIC),
            black= sum(BLACK),
            kids= sum(CHILD),
            elderly= sum(ELDERLY),
            education= sum(EDUC),
            married= sum(MARRIED))%>%ungroup()

#each row of cps_data is a FAMILY
#note...we just calculated the number of people in each family that belong
#totheabovegroups.perhapsthatisn'tthebestway?Wouldproportionsbegood
#inadditionorinsteadofsums?!
#summary(cps_data)#seeextremesforfoodsecurityvariables
#https://cps.ipums.org/cps-action/variables/search
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
         FSWROUTY=ifelse(FSWROUTY> 1,1,0),#moremissings
         FSBAL = ifelse(FSBAL > 1, 1, 0),
         FSRAWSCRA=ifelse(FSRAWSCRA > 1, 1, 0))


str(cps_data)
summary(cps_data)

unique(cps_data$COUNTY)
#Note: many of our y variables contain some NA values.
#Do not use complete.cases or na.omit on the whole dataset.