# Walmart Recruiting - Store Sales Forecasting
https://www.kaggle.com/c/walmart-recruiting-store-sales-forecasting

### Dataset
Use historical sales data for 45 Walmart stores located in different regions. Each store contains many departments.

### Target
Forecast the weekly sales for 99 departments at 45 Walmart stores located in different regions.

### Main File
Save my main file as mymain.R

### Data Preprocessing 
I download the train.csv.zip file from Kaggle website. Then use the train&test_generate.R file to generate 10 folds test data as well as train and test csv file. 
In train.csv file, the date ranges from 2010/02 - 2011/02. In test.csv file, the data ranges from 2011/03 - 2011/02. Fold 1 ranges from 2011/03-2011/04. Fold 2 ranges from 2011/05-2011/06...and so on.

### Model Prediction 
After running a 10-fold cross validation for loop , I use simple model , snaive model and tslm model to predict the weekly sales of each store and departments. 
In every time series for loop, it's important to add the previous fold.csv into new train data.

### Result 
- TSLM model

I also include tslm model in mymain.R. TSLM is a method used to fit linear models to time series including trend and seasonality components. 
I can reach a decent result (1653.36) by using tslm.

