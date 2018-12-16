rm(list=ls())

library(tidyverse)
library(lubridate)
library(lattice)
library(forecast)

source("mymain.R")

# Reference: http://www.learn-r-the-easy-way.tw/chapters/16#part-797ffb2f6d43efb5

# read in train / test dataframes
train <- readr::read_csv('train.csv')
test <- readr::read_csv('test.csv', col_types = list(
  Weekly_Pred1 = col_double(),
  Weekly_Pred2 = col_double(),
  Weekly_Pred3 = col_double()
))

# save weighted mean absolute error WMAE
num_folds <- 10
wae <- tibble(
  Snaive = rep(0, num_folds), 
  tslm = rep(0, num_folds), 
  SimpleModel = rep(0, num_folds)
)

# time-series CV
for (t in 1:num_folds) {
  # *** THIS IS YOUR PREDICTION FUNCTION ***
  mypredict()
  
  # Load fold file 
  # You should add this to your training data in the next call 
  # to mypredict()
  fold_file <- paste0('fold_', t, '.csv')
  new_test <- readr::read_csv(fold_file)
  
  # extract predictions matching up to the current fold
  scoring_tbl <- new_test %>% 
    left_join(test, by = c('Date', 'Store', 'Dept'))
  
  # compute WMAE
  actuals <- scoring_tbl$Weekly_Sales
  preds <- select(scoring_tbl, contains('Weekly_Pred'))
  weights <- if_else(scoring_tbl$IsHoliday.x, 5, 1)
  wae[t, ] <- colSums(weights * abs(actuals - preds)) / sum(weights)
}

##########Run Simple Model ##################

#reset train and test data
train = read.csv('train.csv')
train$Date = as.Date(train$Date)

test= read.csv('test.csv')
test$Date = as.Date(test$Date)

train.wk = train$Date
train.wk = train.wk - train.wk[1]  # date is now 0, 7, 14, ...
train.wk = train.wk/7 + 5  
train.wk = as.numeric(train.wk) %% 52 
train$Wk = train.wk

test.wk = test$Date
test.wk = test.wk - train$Date[1]
test.wk = test.wk/7 + 5
test.wk = as.numeric(test.wk) %% 52
test$Wk = test.wk

train$Yr = year(train$Date)
test$Yr = year(test$Date)

# Wk = 0, Christmas
# Wk = 6, Super Bowl
# Wk = 36, Labor Day
# Wk = 47, Thanksgiving

MySimpleModel = function(test, train){
  # output test with prediction 
  
  store = sort(unique(test$Store))
  n.store = length(store)  # 45
  dept = sort(unique(test$Dept))
  n.dept = length(dept) # 81
  
  for(s in 1:n.store){
    for(d in 1:n.dept){
      
      # find the data for (store, dept) = (s, d)
      test.id = which(test$Store == store[s] & test$Dept == dept[d])
      test.tmp = test[test.id, ]
      train.id = which(train$Store == store[s] & train$Dept == dept[d])
      train.tmp = train[train.id, ]
      
      for (i in 1:length(test.id)){
        id = which(train.tmp$Wk == test.tmp[i,]$Wk & train.tmp$Yr == test.tmp[i,]$Yr - 1)
        #threeWeeksId = c(id - 1, id, id + 1)  ## three weeks in the last year
        #tempSales = train.tmp[threeWeeksId, 'Weekly_Sales']
        tempSales = train.tmp[id, 'Weekly_Sales'] ## same week last year
        if (length(tempSales) == 0){
          test$Weekly_Pred1[test.id[i]] = 0
        }else{
          test$Weekly_Pred1[test.id[i]] = median(tempSales)
        }
      }
    }
  }
  return(test)
}

# time-series CV

num_folds = 10
whole_test = test
for(i in 1:num_folds){
  print(i)
  start_date = ymd("2011-03-01") %m+% months(2 * (i - 1))
  end_date = ymd("2011-05-01") %m+% months(2 * (i - 1))
  fold_ids = which(test$Date >= start_date & test$Date < end_date)
  
  test = test[fold_ids, ]
  #whole_test: (257455 x 9) store,Dept,Date,Weekly_Pred1,Weekly_Pred2,Weekly_Pred3,IsHoliday,Wk,Yr
  whole_test[fold_ids, ] = MySimpleModel(test, train)
  #myfold: (23729 x 5) store,Dept,Date,Weekly_Sales,IsHoliday
  myfold = read.csv(paste('fold_', i, '.csv', sep=""))
  myfold$Date = as.Date(myfold$Date)
  drop_cols = c("Weekly_Pred1", "Weekly_Pred2", "Weekly_Pred3")
  #newdata: (23729 x 7) store,Dept,Date,Weekly_Sales,IsHoliday,Wk,Yr
  newdata = merge(x=myfold, y=test[setdiff(names(test), drop_cols)], all.x=TRUE)
  #train: (421570 x 7) store,Dept,Date,Weekly_Sales,IsHoliday,Wk,Yr
  train = rbind(train, newdata)
  #test: (257455 x 9) store,Dept,Date,Weekly_Pred1,Weekly_Pred2,Weekly_Pred3,IsHoliday,Wk,Yr
  test = whole_test
}

# run evaluation loop
test = dplyr::left_join(test, train)
num_folds = 10
myErr = rep(0, num_folds)
for(i in 1:num_folds){
  start_date = ymd("2011-03-01") %m+% months(2 * (i - 1))
  end_date = ymd("2011-05-01") %m+% months(2 * (i - 1))
  fold_ids = which(test$Date >= start_date & test$Date < end_date)
  tmp = test[fold_ids, ]
  weights = ifelse(tmp$IsHoliday, 5, 1)
  myErr[i] = sum(weights*abs(tmp$Weekly_Pred1 - tmp$Weekly_Sales))/sum(weights)
}

##########Run Simple Model ##################

#Store the result from MySimpleModel into wae
wae$SimpleModel <- myErr

#calculate the mean error 
avg <- colMeans(wae[,1:3])
wae <- rbind(wae, avg)
wae$Fold <- c(rep(1:10),"avg")


# save results to a file for grading
readr::write_csv(wae, 'Error.csv')

