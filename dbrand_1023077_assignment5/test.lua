--[[
Daniel Brand
Matr.-Nr.: 1023077
Computer Vision Assignment #5

This file is for loading the trained model and also 
loading the training patterns from the dataset.

After the loading I calculate the confusion matrix with
the model and the training data
--]]

-- Import required packages
require 'nn'	  -- Neural Network Layers
require 'optim'	  -- Optimizitation 

-- load data from file
test_features = torch.load('test_features')
test_labels = torch.load('test_labels')

model = torch.load('saved_model')

-- test model
probs = torch.exp(model:forward(test_features))
sorted_probs, sorted_idx = torch.sort(probs,2)

cm = optim.ConfusionMatrix(2)
cm:zero()
cm:batchAdd(sorted_idx[{{},2}],test_labels)
print(cm) -- print confusion Matrix