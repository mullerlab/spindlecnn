function [xo] = hipass_filter_matrix( x, f, filter_order, Fs )
% *WAVE* 
%
% LOWPASS FILTER    filter a datacube between frequencies f1 and f2
%
% INPUT: 
% x - datacube
% f - highpass cutoff
% filter_order - filter order
% Fs - sampling frequency
%
% OUTPUT
% xo - output datacube
%

assert(ndims(x) == 2,'matrix input required');
xo = zeros(size(x));

ct = f;
ct = ct / (Fs/2);
[b,a] = butter(filter_order,ct,'high'); % remember, filter_order * 1 for lowpass
for rr = 1:size(x,1)
	xo(rr,:) = filtfilt(b,a,x(rr,:));
end
