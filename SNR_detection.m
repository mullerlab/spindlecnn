function [w, sw_label, s] = SNR_detection(x, Fs, window_size, window_offset, ...
    merge_threshold, freq, freq_wide, filter_order, flag_boundry)

%
% DETECT SPINDLE USING SIGNAL TO NOISE RATIO
% 22 MARCH 2022
%
% PARAMETERS
% x - signal
% Fs - sampling rate
% window_size - detection window size
% window_offset - detection window offset
% merge_threshold - threshold to merge detected spindles
% freq - oscillation frequency e.g., [9, 18]
% fre_wide - wideband frequency e.g., [1, 100]
% filter_order - filter order
% boundary flag - 1 add boundary windows with high SNR to the sp; 0,
% otherwise
%
% OUTPUTS
% w - signal windows
% sw - label - spindle labels
% s - signal to noise ratio
%

%%%%% initialization
if nargin == 9; flag_boundry = 0; end
if isempty(window_size); window_size = floor(params.Fs/2); end
if isempty(window_offset); window_offset = floor(window_size/5); end
if isempty(merge_threshold); merge_threshold = window_offset; end
if isempty(freq_wide); freq_wide = [1,100]; end 
number_windows = floor( ( size(x,2) - window_size ) ./ window_offset ); % number of detection windows    
s = zeros( size(x,1),number_windows );
w = zeros( size(x,1), window_size, number_windows);

%%%%% bandpas data
if length(freq_wide)== 1
    xw = hipass_filter_matrix( x, freq_wide, filter_order, Fs );
    if freq(1) == freq_wide
        xb = hipass_filter_matrix( x, freq(2), filter_order, Fs );
    else
        xb = xw;
        xb = notch_filter_matrix( xb, freq(1), freq(2), filter_order, Fs );
    end
else
    xw = bandpass_filter_matrix( x, freq_wide(1), freq_wide(2), filter_order, Fs );
    if freq(1) == freq_wide(1)
        xb = bandpass_filter_matrix( x, freq(2), freq_wide(2), filter_order, Fs );
    else
        xb = xw;
        xb = notch_filter_matrix( xb, freq(1), freq(2), filter_order, Fs );
    end
end
xf = bandpass_filter_matrix( x, freq(1), freq(2), filter_order, Fs );

%%%%% calculate SNR values
for kk = 1:number_windows
    times = (1:window_size) + ( (kk-1)*window_offset );
    for rr = 1:size(x,1)
        s(rr,kk) = snr(squeeze(xf(rr,times)), squeeze(xb(rr,times)) );
        w(rr,:,kk) = squeeze(xw(rr,times));
    end
end

%%%%% detect spindles using 99% of the SNR distribution
snr_threshold = prctile(reshape(s,1,[]), 99);
sw_label = zeros(size(s));
sw_label(find( s > snr_threshold )) = 1;

% add windows with aboundries about 2bd to the spindles SNR threshold
if flag_boundry == 1
    % add right boundries
    for kk = 2:number_windows
        for rr = 1:size(x,1)
            if sw_label(rr,kk) == 0  && sw_label(rr,kk-1) == 1
                if s(rr,kk) > max(snr_threshold-2, 2)
                    sw_label(rr,kk) = 1;
                end
            end
        end
    end
    
    % add left boundries
    for kk = number_windows-1:-1:1
        for rr = 1:size(x,1)
            if sw_label(rr,kk) == 0 && sw_label(rr,kk+1) == 1
                if s(rr,kk) > max(snr_threshold-2, 2)
                    sw_label(rr,kk) = 1;
                end
            end
        end
    end
end


%%%%% remove spindles longer tha 3 minutes
for rr = 1:size(x,1)
    tmp = squeeze(sw_label(rr,:));
    if sum(tmp) == 0; continue; end
    
    % remove sp with duration longer than 3000
    [sp_time, sp_dur, ~] = sp_epoch(tmp', Fs, window_size, window_offset, merge_threshold);
    ind = find(sp_dur > 3);
    for ii = 1:length(ind)
        ind_kk = ((sp_time(ind(ii),1) - 1)/window_offset + 1): ...
            ((sp_time(ind(ii),2) - window_size)/window_offset + 1);
        sw_label(rr,ind_kk) = 0;
    end
end
sw_label = categorical(sw_label);

end