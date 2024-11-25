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
# this code should probably go in clean_acs.R...
acs<-read_sas("data/spm_pu_2022.sas7bdat")
# to calculate weights (go ahead and just copy/paste this):
acs<-acs%>%
  filter(st =="19")%>%
  group_by(serialno=as.factor(serialno))%>%
  arrange(desc(Sex), desc(Age)) %>%
  mutate(weight= first(wt))%>%select(-wt) %>%ungroup()

