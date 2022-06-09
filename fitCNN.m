function [net] = fitCNN(Xtrain, ytrain, Xval, yval, Hyperparams)

%
% FIT A CNN MODEL TO DETECT SPINDLES
% 22 MARCH 2022
%
% PARAMETERS
% Xtrain, ytrain - training set 
% Xval, yval - validation set
% Hyperparams - CNN Hyperparams
    % cov_fsize - convolution layer - filter size
    % cov_numf - convolution layer - number of filters
    % pool_size - pool size
    % opt_solver - solver n,ae
    % opt_learning_rate - learning rate
    % opt_max_epoch - maximum number of epochs to use for training,
%   
%
% OUTPUTS
% net - CNN model
%

% read hyperparamters
keys = Hyperparams.keys;

% CNN filter size
if ismember('cov_fsize', keys)
    cov_fsize = Hyperparams('cov_fsize');
else
    cov_fsize = [2,16,32,16,4];
end

% CNN number of features
if ismember('cov_numf', keys)
    cov_numf = Hyperparams('cov_numf');
else
    cov_numf = [32,64,128,192,256];
end

% pool size
if ismember('pool_size', keys)
    pool_size = Hyperparams('pool_size');
else
    pool_size = 4; 
end

% optimization solver
if ismember('opt_solver', keys)
    opt_solver = Hyperparams('opt_solver');
else
    opt_solver = 'sgdm'; 
end

% learning rate
if ismember('opt_learning_rate', keys)
    opt_learning_rate = Hyperparams('opt_learning_rate');
else
    opt_learning_rate = 0.001; 
end

% maximum epochs
if ismember('opt_max_epoch', keys)
    opt_max_epoch = Hyperparams('opt_max_epoch');
else
    opt_max_epoch = 15; 
end


% 
% input init
inputSize = [1 size(Xtrain,2) 1]; numClasses = 2;

%%%% Create the Array of Layers
layers = [
    imageInputLayer(inputSize,"Name","imageinput")
    convolution2dLayer([1 cov_fsize(1)], cov_numf(1),"Name","conv_1","Padding","same") % 4 is the best number
    maxPooling2dLayer([pool_size pool_size],"Name","maxpool_1","Padding","same","Stride",[1 2])
    reluLayer("Name","relu_1")
    convolution2dLayer([cov_fsize(2) cov_fsize(2)],cov_numf(2),"Name","conv_2","Padding","same")
    maxPooling2dLayer([pool_size pool_size],"Name","maxpool_2","Padding","same","Stride",[1 2])
    reluLayer("Name","relu_2")
    convolution2dLayer([cov_fsize(3) cov_fsize(3)],cov_numf(3),"Name","conv_3","Padding","same")
    maxPooling2dLayer([pool_size pool_size],"Name","maxpool_3","Padding","same","Stride",[1 2])
    reluLayer("Name","relu_3")
    convolution2dLayer([cov_fsize(4) cov_fsize(4)],cov_numf(4),"Name","conv_4","Padding","same")
    maxPooling2dLayer([pool_size pool_size],"Name","maxpool_4","Padding","same","Stride",[1 2])
    reluLayer("Name","relu_4")
    convolution2dLayer([cov_fsize(5) cov_fsize(5)],cov_numf(5),"Name","conv_5","Padding","same")
    maxPooling2dLayer([pool_size pool_size],"Name","maxpool_5","Padding","same","Stride",[1 2])
    reluLayer("Name","relu_5")
    fullyConnectedLayer(128,"Name","fc_1")
    reluLayer("Name","relu_6")
    fullyConnectedLayer(64,"Name","fc_2")
    reluLayer("Name","relu_7")
    fullyConnectedLayer(32,"Name","fc_3")
    reluLayer("Name","relu_8")
    fullyConnectedLayer(numClasses,"Name","fc_4")
    softmaxLayer("Name","softmax")
    classificationLayer("Name","classoutput")];

% set options
options = trainingOptions(opt_solver, 'InitialLearnRate',opt_learning_rate, ...
    'MaxEpochs',opt_max_epoch, 'Shuffle','every-epoch', ...
    'ValidationData',{Xval,yval}, 'ValidationFrequency',200, ...
    'Verbose',false, 'Plots','training-progress');

% train cnn model
rng('default'); net = trainNetwork(Xtrain, ytrain, layers, options);



end