function [Xtrain, ytrain, Xval, yval, Xtest, ytest] = split_train_val_test(X, y, prct, sp_ratio)

%
% SPLIT THE RECORDINGs TO TRAINING, VALIDATION AND TEST DATA
% 22 MARCH 2022
%
% PARAMETERS
% X - detection windows 
% y - detected activities
% prct - percentage of train, validation and test set, e.g., [0.36, 0.16,
% 0.5]
% sp_ratio - balanced training: sp_ratio > 0 ratio of non-spindles vs spindles window; (sp_ratio = 0; unbalanced training set) 
%
% OUTPUTS
% w - signal windows
% sw - label - spindle labels
% s - signal to noise ratio
%

%%%%%%%%%% initialization
Xtest = []; ytest = []; % test set
Xtrain = []; ytrain= []; % downsample training set
Xval = []; yval = []; % evaluation set


%%%%%%%%%% train, test and validation split
rng(123)
for rr = 1:size(X,1)
    clearvars -except rr file params Xtest ytest ...
        Xtrain ytrain Xval yval X y
    
    if size(Xtrain,3) > 16000; break; end
    
    X_rs(1,:,1,:) = squeeze(X(rr,:,:));
    y_rs = squeeze(y(rr, :));
    
    %%%%% training set
    if isempty(sp_ratio)
        
        ind = 1:floor(prct(1)*length(y_rs));
        Xtrain_ds_ele = X_rs(1,:,1,ind); 
        ytrain_ds_ele = y_rs(ind);
        
    elseif sp_ratio > 0 % balanced training set
        
        ind = 1:floor(prct(1)*length(y_rs));
        tmp = X_rs(1,:,1,ind); tmp_y = y_rs(ind);
        Xtrain_ds_ele = tmp(1,:,1,tmp_y=='1');
        ytrain_ds_ele = tmp_y(tmp_y=='1');
    
        tmp = tmp(1,:,1,tmp_y=='0');
        size_tmp = min(length(tmp_y(tmp_y=='1'))*sp_ratio, size(tmp,4));
        ind = randperm(size(tmp,4), size_tmp)';
        Xtrain_ds_ele = cat(4, Xtrain_ds_ele, tmp(1,:,1,ind));
        tmp = tmp_y(tmp_y == '0'); ytrain_ds_ele = [ytrain_ds_ele, tmp(ind)];
    else
        error('Error: Spindle ratio must be positive or empty')
    end
    Xtrain = cat(4, Xtrain, Xtrain_ds_ele); ytrain = [ytrain, ytrain_ds_ele];
    
    %%%%% validation sets
    ind = floor(prct(1)*length(y_rs))+1:floor((params.prct(1)+params.prct(2))*length(y_rs));
    Xval = cat(4, Xval, X_rs(1,:,1,ind)); yval = [yval, y_rs(ind)];
    
    %%%%% test set
    ind = floor((prct(1)+prct(2))*length(y_rs))+1:length(y_rs);
    Xtest = cat(4, Xtest, X_rs(1,:,1,ind)); ytest = [ytest, y_rs(ind)];
end

end
