%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                     %
% TWO_STEP SPIDNLE DETECTION          %
% Maryam Mofrad + Lyle Muller         %
% 22 March 2022                       %
%                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Step 0: preprocessing
%%%%%%%%%% load sleep recordings file
file = dir('data/*.mat');
load(sprintf('%s/%s', file.folder, file.name));

%%%%%%%%%% initialization
%%%%% average reference control
params.average_reference_control = 1;
if params.average_reference_control == 1
    x = x - repmat(nanmean(x),[size(x,1) 1]);
end

%%%%% frequency parameters
params.freq = [9 18]; % spidnle frequency (Hz)
params.freq_wide = [1 100]; % Wideband frequency (Hz)
params.filter_order = 4; % filter order
params.n1 = 59.5; params.n2 = 60.5; % lower and upper bound of line noise
params.notch_order = 4; % notch filter order

%%%%% sliding window params
params.window_size = floor(params.Fs/2); %samp
params.window_offset = floor(params.window_size/5); %samp
params.merge_threshold = params.window_offset;


%%%%%%%%%% preprocess recording
x = notch_filter_matrix( x, params.n1, params.n2, params.notch_order, params.Fs );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Step 1: detect spindle - SNR approach
[X, y, ~] = SNR_detection(x, params.Fs, params.window_size, params.window_offset, ...
    params.merge_threshold, params.freq, params.freq_wide, params.filter_order, []);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Step 2: train the CNN model
%%%%% split data to train, validation and test set
[Xtrain, ytrain, Xval, yval, Xtest, ytest] = split_train_val_test(X, y, [0.36, 0.14, 0.5], 2);


%%%%% set CNN hyperparameter
CNN_hyperparamters = containers.Map({'opt_solver', 'opt_learning_rate', 'opt_max_epoch', ...
    'cov_fsize', 'cov_numf', 'pool_size'}, {'sgdm', 0.001, 15, [2,16,32,16,4], [32,64,128,192,256], 4});

%%%%% fit the CNN model
net = fitCNN(Xtrain, ytrain, Xval, yval, CNN_hyperparamters);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Step 3: post modeling analysis
%%%%% CNN model performance
tb_CNN_res = table();

yprob_test = predict(net, Xtest); 
yhat_test = double(yprob_test(:,2) > 0.5); yhat_test = yhat_test';
ytest = double(ytest) - 1;

[conf_mat,~] = confusionmat(ytest,yhat_test);
tb_CNN_res.TN=conf_mat(1,1); tb_CNN_res.FP=conf_mat(1,2);
tb_CNN_res.FN=conf_mat(2,1); tb_CNN_res.TP=conf_mat(2,2);
tb_CNN_res.accuracy = sum(yhat_test == ytest)/numel(ytest);
tb_CNN_res.precision = sum(yhat_test == ytest & yhat_test == 1)/sum(yhat_test == 1);
tb_CNN_res.recall = sum(yhat_test == ytest & yhat_test == 1)/sum(ytest == 1);
tb_CNN_res.fscore = 2*tb_CNN_res.precision*tb_CNN_res.recall/(tb_CNN_res.precision+tb_CNN_res.recall);
[~,~,~,tb_CNN_res.auc] = perfcurve(ytest, yprob_test(:,2), 1);
tb_CNN_res.Sensitivity = sum(ytest == 1 & yhat_test == 1)/sum(ytest == 1);
tb_CNN_res.Specificity = sum(ytest == 0 & yhat_test == 0)/sum(ytest == 0);

