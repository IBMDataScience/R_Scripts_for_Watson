###################################################### 
### Experimental Code. R Interface for IBM Watson Services 
### Focus: PERSONALITY INSIGHTS - USER PERSONAE SEGMENTATION - R Programming Language Interface
### Adapting the PERSONALITY INSIGHTS APIs https://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/apis/ to RCURL and HTTR
### DOCS: https://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/doc/personality-insights/
### REFERENCE https://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/personality-insights/api/v2/ 
### Before you begin you will need (1) An IBM Bluemix demo account (2) A dialog App and (3) Credentials to that Service and confirm you're able to CURL service with
######################################################

## this is a code snippet for educational purposes only 
 
library(RCurl) # install.packages("RCurl") # if the package is not already installed
library(httr)

# Personality-Insights-Service-Blue - credentials"
pi_url="https://gateway.watsonplatform.net/personality-insights/api/v2/profile"
username = "5555555-5555-5555-5555-5555555555" # yours goes here from service credentials
password = "4444444444" # yours goes here from service credentials
username_password = paste(username,":",password,sep="")


###### FUNCTION - ANalyze text with Personality Insights service
watson.personality_insights.analyze <- function(TEXT)
{
  return(POST(url=pi_url,
          authenticate(username,password),
          add_headers("Content-Type"="text/plain","charset"="utf-8" ),
          body = TEXT
          ))
}
# hope this helps you with syntax!

## Works at command line : ## curl -X POST -u $USERNAME:$PASSWORD -H "Content-Type: text/plain" -d "$PROFILE" "https://gateway.watsonplatform.net/personality-insights/api/v2/profile"


#### FUNCTION TO TIDY UP THE PI RESPONSE TO TABLE - not pretty at 11:30pm - but it works
tidyResponse <- function(data) 
{
  data <- as.data.frame(strsplit(as.character(data),"\"id\":\""))
  data <- data[-c(1:5), ] # remove dud first row
  data <- data.frame(matrix(data)) 
  data[,1]  <- gsub("\"","",data[,1] ) 
  data <- data.frame(do.call('rbind', strsplit(as.character(data$matrix.data),',',fixed=TRUE)))
  data <- data[!grepl('name:',data$X5),]
  data <- data[!grepl('children:',data$X5),]
  data <- data[,-c(2,6), ] # remove columns we dont need - duplicates or dont care for SAMPLING ERROR (now) but mght later
  setnames(data,c("trait","category","percentage","error"))
  data$percentage <- gsub("percentage:","",data$percentage) 
  data$category <- gsub("category:","",data$category) 
  data$error <- gsub("sampling_error:","",data$error) 
  data$error <- gsub("}","",data$error) # crude but effective
  data$error <- gsub("]","",data$error) # crude but effective
  data$percentage <- round((as.numeric(data$percentage)),4) # if you prefer % format like this
  data$error <- round((as.numeric(data$error)),4) # if you prefer % format like this
  rownames(data) <- NULL # resets row names to remove 'gaps'
  data$row <- as.numeric(rownames(data))
  return(data)
} # warning - this code seems to work but has not been verified - please be careful


### OK - let's test!

TEXT_TO_ANALYZE="Call me Ishmael. Some years ago-never mind how long precisely-having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation. Whenever I find myself growing grim about the mouth; whenever it is a damp, drizzly November in my soul; whenever I find myself involuntarily pausing before coffin warehouses, and bringing up the rear of every funeral I meet; and especially whenever my hypos get such an upper hand of me, that it requires a strong moral principle to prevent me from deliberately stepping into the street, and methodically knocking people's hats off-then, I account it high time to get to sea as soon as I can."

# it's better if you have more words - better if 3500+ or 5k plus...
# see the SCIENCE BEHIND THE SERVICE HERE - http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/doc/personality-insights/science.shtml
response <- watson.personality_insights.analyze(TEXT_TO_ANALYZE)  # send text to function that queries the Watson API

response # this should be a status 200 if it went well - if not, check your authentication  or look at content(response,"text")
PI_analysis <- content(response,"text") # pull the analysis trait and % (X52)
PI_analysis <- tidyResponse(PI_analysis) # hacky way to tidy up in table format - there are certainly better ways than this :) 
PI_analysis

## Should look like this:
#       trait           category        percentage  error   row
# 1     Openness        personality     0.7052      0.0653   1
# 2     Adventurousness personality     0.2427      0.0545   2
# 3     Artistic interests personality  0.1043      0.1106   3