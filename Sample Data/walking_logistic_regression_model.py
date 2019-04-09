#!/usr/bin/env python
# coding: utf-8

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
import coremltools

# Read in the csv.
data = pd.read_csv('training_data.csv')

# Drop iteration column.
data = data.drop('iteration', 1)

# Remove whitespace from column headers.
data.columns = ['wma', 'time_above', 'walking']

# Reverse the DataFrame index to match the original indices.
data.index = reversed(range(1998))

# Add column for rows with wma above 0.8 for at least 1 second.
data['time_above_1'] = data['time_above'].apply(lambda val: val > 1.0)

# Split the data, and train the model.
X = data[['wma', 'time_above', 'time_above_1']] 
y = data['walking']
X_train, X_test, y_train, y_test = train_test_split(X,y,test_size=0.9)
model = LogisticRegression(solver='lbfgs', multi_class="ovr")
model.fit(X_train, y_train)

# Check scores.
print(model.score(X_test,y_test))
print(model.score(X_train,y_train))

# Convert sklearn model to coreml to be used in swift.
coreml_model = coremltools.converters.sklearn.convert(model, ['wma', 'time_above', 'time_above_1'], "walking")
coreml_model.save('Walking.mlmodel')
