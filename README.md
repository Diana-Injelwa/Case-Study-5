# Case-Study-5
## Introduction
Data Mart, an online supermarket specializing in fresh produce, underwent significant transformations in June 2020. They implemented sustainable packaging methods across their entire product range i.e. from the farm all the way to the customer. In this case study, I explored an analysis of Data Mart's sales performance, both pre- and post-implementation of these changes. The aim of this analysis is to quantify the impact brought about by this strategic shift.
Some of the key business questions that l addressed in order to provide valuable insights to the Data Mart team include:
* What was the quantifiable impact of the changes introduced in June 2020?
* Which platform, region, segment and customer types were the most impacted by this change?
* What can we do about future introduction of similar sustainability updates to the business to minimize impact on sales?

### Data Cleaning
* Converted the week_date to a DATE format.
* Added a week_number as the second column for each week_date value, for instance values from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc.
* Added a month_number with the calendar month for each week_date value as the 3rd column.
* Appended a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values.
* Introduced a new column called age_band after the original segment column. The assignment was based on a mapping of the numbers within the segment value: 1 = Young Adult, 2 = Middle Aged, 3 or 4 = Retirees
* Added a new demographic column, utilizing a mapping system that considers the first letter in the segment values: C = Couples, F = Families
* Ensured all null string values in the original segment column, as well as the new age_band and demographic columns, were replaced with "Unknown" string values..
* Generated a new avg_transaction column, derived from the sales value divided by transactions rounded to two decimal places for each record

  ### Data Exploration
* What day of the week is used for each week_date value?
* What range of week numbers are missing from the dataset?
* How many total transactions were there for each year in the dataset?
* What is the total sales for each region for each month?
* What is the total count of transactions for each platform
* What is the percentage of sales for Retail vs Shopify for each month?
* What is the percentage of sales by demographic for each year in the dataset?
* Which age_band and demographic values contribute the most to Retail sales?
* Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

  ### Before and After Analysis
* What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
* What about the entire 12 weeks before and after?

  Tools: MySQL
