function plot_psd_spindles(x, yhat, params, output_dir, ch_label)

%
% Plot avergae PSD of spindles vs non-spindles (highpass at 9 Hz)
% 27 Nov 2022
%
% PARAMETERS
% x - raw signal
% yhat - CNN - detected label for input windows
% params - analytical parameters 
% s - SNR value of input windows
% nbr_sp - number of spindles
% output_dir - output directory
% ch_label - save label
%

x = hipass_filter_matrix(x, 1, 2, params.Fs);
[sp_time, ~, ~] = sp_epoch(yhat, params.Fs, params.window_size, params.window_offset, params.merge_threshold);

if ~isempty(sp_time)
    for jj = 1:size(sp_time,1)
        tmp = x(1, sp_time(jj,1):sp_time(jj,2));
        [Pxx_sp(:,jj), Fxx_sp] = pwelch(tmp,[],[],params.Fs,params.Fs,'psd');
    end
end

for jj = 1:size(sp_time,1)
    if jj == 1 &&  sp_time(jj,1) > 1
        tp_st = 1;
    elseif jj == 1 &&  sp_time(jj,1) == 1
        continue;
    else
        tp_st = sp_time(jj-1,2) + 1;
    end
    if jj < size(sp_time,1)
        tp_end  = sp_time(jj,1);
    elseif jj == size(sp_time,1) 
        continue;
    end
    tmp = x(1, tp_st:tp_end);
    [Pxx_nonsp(:,jj), Fxx_nonsp] = pwelch(tmp,[],[],params.Fs,params.Fs,'psd');
end

clf;
tmp = nanmean(Pxx_sp,2);
plot(Fxx_sp,10*log10(tmp), 'Color', [0,0.45,0.75,1], 'LineWidth',2); hold on;

tmp = nanmean(Pxx_nonsp,2);
plot(Fxx_nonsp,10*log10(tmp),'color', [0.85,0.30,0.098,0.5], 'LineWidth',2);

set( gca, 'fontname', 'arial', 'fontsize', 14, 'linewidth', 2 )
set(gca, 'xscale', 'log', 'XGrid', 'on');
xlabel( 'Frequency (Hz)' ); ylabel( 'Power/frequency (dB/Hz)' );

legend(["w/ spindle", "w/o spindle"]);
xlim([5, 100]);
set( gca, 'fontname', 'arial', 'fontsize', 16, 'linewidth', 2)
set( gcf, 'PaperOrientation', 'landscape', 'PaperUnits', 'normalized', 'PaperPosition', [ 0 0 1 1] );
print( gcf, '-djpeg', sprintf( '%s/psd_%s.jpeg', output_dir, ch_label) );


end