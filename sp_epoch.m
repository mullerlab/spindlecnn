function [sp_time, sp_dur, sp_time_diff] = sp_epoch(y_label, Fs, window_size, window_offset, merge_threshold)

%
% MERGE OVERLAPPING SPINDLES WINDOWS TO FIND SPINDLE DURATION
% 22 MARCH 2022
%
% PARAMETERS
% y_label - snr label
% Fs - sampling frequency
% window_size - detection window size
% window_offset - detection window offset
% merge_threshold - threshold to merge detected spindles
%
% OUTPUTS
% sp_time - start and end time of detected spindles
% sp_dur - spindle duration
% sp_time_diff - time difference between spindles
%

g = y_label;
g_cumsum = cumsum(g);
ind_zero = find(g==0);
ind_zero_after = ind_zero + 1; 
if ~isempty(find(ind_zero_after>length(g)))
    ind_zero_after(find(ind_zero_after>length(g))) = length(g);
end
if g(1) > 0
    ind_zero_after = [1; ind_zero_after];
end
ind_sp = setdiff(ind_zero_after, ind_zero);

ind_zero_pre = ind_zero - 1; 
if ~isempty(find(ind_zero_pre < 1))
    ind_zero_pre(find(ind_zero_pre<1)) = 1;
end
if g(end) > 0
    ind_zero_pre = [ind_zero_pre; length(g)];
end
ind_sp(:,2) = setdiff(ind_zero_pre, ind_zero);

ind_sp_diff = ind_sp(2:end, 1) - ind_sp(1:end-1, 2); 
nbr_w = ((merge_threshold+window_size) / window_offset);
ind_merge = find( ind_sp_diff <= nbr_w) ;

if ~isempty(ind_merge)
    for ii = length(ind_merge):-1:1
        tp_end = ind_sp(ind_merge(ii)+1, 2);
        ind_sp(ind_merge(ii)+1, :) = [];
        ind_sp(ind_merge(ii), 2) = tp_end;
    end
end

ind_sp_diff = ind_sp(2:end, 1) - ind_sp(1:end-1, 2); 
nbr_w = ((merge_threshold+window_size) / window_offset) * 5;
ind_merge = find( ind_sp_diff <= nbr_w) ;

sp_dur = ind_sp(:, 2) - ind_sp(:, 1) + 1;
sp_dur =  (window_size + (sp_dur-1) * window_offset)/Fs;
        
        

% time between sp
w_diff = (ind_sp(2:end, 1) - ind_sp(1:end-1, 2));
sp_time_diff =[nan;  (window_size + (w_diff-1) * window_offset)/Fs];
sp_time = (ind_sp(:,1) - 1) *  window_offset + 1;
sp_time(:,2) = window_size + (ind_sp(:,2) - 1) *  window_offset;
% sp_ep.duration = (sp_ep.end_time - sp_ep.st_time)/Fs;


end