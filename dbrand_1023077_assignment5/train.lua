--[[
Daniel Brand
Matr.-Nr.: 1023077
Computer Vision Assignment #5

This file is for training the model and saving to the
file system.

For this project I used the Skin Segmentation Data Set from:
https://archive.ics.uci.edu/ml/datasets/Skin+Segmentation

It is a 2-class data set (skin or no skin) with 3 features per pattern and include
245057 instances. The data set is provided as a txt file. I created
a CSV file out of it which is in the folder dataset.

For testing the model just run test.lua

Example output of the testing:

ConfusionMatrix:
   10454    2203   82.595% 
    2658   45949  94.532% 
 + average row correct: 88.56312930584% 
 + average rowUcol correct (VOC measure): 79.346430301666% 
 + global correct: 92.065487072343%
--]]

require 'csvigo'    -- Importing the CSV-Dataset
require 'nn'	  -- Neural Network Layers
require 'optim'	  -- Optimizitation 

-- read in the data
dataset = csvigo.load('dataset/skin.csv')

classes = torch.Tensor(dataset.class)
r = torch.Tensor(dataset.r)
b = torch.Tensor(dataset.b)
g = torch.Tensor(dataset.g)

-- Construct training/test data

input_data = torch.Tensor( (#classes)[1],3 )
input_data[{ {},1 }] = r
input_data[{ {},2 }] = b
input_data[{ {},3 }] = g

-- Labels 
output_data = classes

-- Number of different classes
number_classes = torch.max(output_data) - torch.min(output_data) + 1

-- number of instances in the data set
number_data_samples = input_data:size(1)

--number of feature dimension
number_feat_dim = input_data:size(2)

-- Split data into training and test data 
splits = torch.randperm(number_data_samples):split(number_data_samples/4)

training_indices = torch.cat({splits[1], splits[2], splits[3]})

test_indices = splits[4]

training_features = input_data:index(1, training_indices:long())
test_features = input_data:index(1, test_indices:long())
training_labels = output_data:index(1, training_indices:long())
test_labels = output_data:index(1, test_indices:long())

-- save test data
torch.save('test_features', test_features)
torch.save('test_labels', test_labels)

-- define our network for logistic regression

-- linear layer, 3 inputs (R, B, G), 2 outputs - skin or no skin :D
linearLayer = nn.Linear(number_feat_dim, number_classes)
softMaxLayer = nn.LogSoftMax()

model = nn.Sequential() -- sequential model
model:add(linearLayer)  -- add lineare layer
model:add(softMaxLayer) -- add logsoftmax layer

-- lets define the loss
criterion = nn.ClassNLLCriterion() -- class negative log

local theta, gradTheta = model:getParameters()

local x -- feature mini batch
local y -- label mini batch

local batchSize = 2048 -- our batch size

local opfunc = function(params)
	if theta ~= params then
		theta:copy(params)
	end

	gradTheta:zero()

    -- run the mini batch through the model
    local x_hat = model:forward(x)

    -- lets compute  the loss of x wrt y 
    local loss = criterion:forward(x_hat, y)

    --comute the gradient of the loss
    local grad_loss = criterion:backward(x_hat, y)

    --backprop gradients
    model:backward(x, grad_loss)

    return loss, gradTheta
end

 -- write the model update part

model:training()

number_training = training_features:size(1)

epochs = 2e3
learn_params = { 
	learningRate = 1e-3,
	learningRateDecay = 1e-4,
	weightDecay = 0,
	momentum = 0
}

for i=1, epochs do

	local indices = torch.randperm(number_training):long():split(batchSize)

	indices[#indices] = nil -- delete last index :)
	sum_loss = 0

 	-- construct the mini batch
 	for t,v in pairs(indices) do

		-- v are the actual indices at position t
		x = training_features:index(1, v)
		y = training_labels:index(1, v)
		
		_, batch_loss = optim.adam(
			opfunc,  -- function to do backprop
			theta, 	-- model parameter
			learn_params) -- learning parameters

		sum_loss = sum_loss + batch_loss[1]

	end
end	

-- save the trained model to the file
torch.save('saved_model', model)

-- Execute testfile
dofile 'test.lua'