function plot_example_spindles(x, yhat, s, params, nbr_sp, output_dir, ch_label)

%
% Plot example spindles (highpass at 9 Hz)
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

xhp = hipass_filter_matrix(x, 9, params.filter_order, params.Fs );

[sp_time, ~, ~] = sp_epoch(yhat, params.Fs, params.window_size, params.window_offset, 0);

% find best examples
ind_sp = find(yhat == 1);
[~, ind_sort] = sort(s(yhat == 1), 'descend');
ind_sp_r = randi(max(floor(length(ind_sort)*0.05), nbr_sp), [nbr_sp,1]);

cnt = 0;
for jj = 1:nbr_sp
    if mod(jj,3) == 1
        clf; tiledlayout(3,1,'Padding','compact');
        cnt = cnt + 1;
    end
    
    tp = ind_sp(ind_sort(ind_sp_r(jj)));
    ind = find(sp_time(:,1) <= ((tp-1)*params.window_offset+1),1,"last");
    
    if sp_time(ind,2) - sp_time(ind,1) > 3 * params.Fs; continue; end
    nexttile;

    ind_st = sp_time(ind,1) - params.window_size;
    ind_end = sp_time(ind,2) + params.window_size;
    y_axis = squeeze(xhp(1, ind_st:ind_end));
    x_axis = 0:(1/params.Fs):(length(y_axis)-1)*(1/params.Fs);
    plot(x_axis, y_axis, 'k', 'LineWidth', 1); hold on;

    plot(x_axis(params.window_size+1:end-params.window_size), ...
        y_axis(params.window_size+1:end-params.window_size), 'r', 'LineWidth', 2); hold on;

    plot([0,1], [min(y_axis),min(y_axis)], 'k', 'LineWidth', 2);
    text(0.3, min(y_axis)*1.2, '1 sec', 'FontSize', 16, 'fontname', 'arial');
    lb = abs(floor((min(y_axis)*0.4)/20)*20);
    plot([0,0], [min(y_axis),min(y_axis)+lb], 'k', 'LineWidth', 2);
    text(-0.15, min(y_axis)+lb/3, sprintf("%d \\muV", lb), 'Rotation', 90, 'FontSize', 16, 'fontname', 'arial');
    title('Spindle')
    set( gcf, 'position', [ 1439  842  844  423 ] )
    set( gca, 'box','off','XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[])
    axis off;

    set( gcf, 'PaperOrientation', 'landscape', 'PaperUnits', 'normalized', 'PaperPosition', [ 0 0 1 1 ] );
    print( gcf, '-djpeg', sprintf( '%s/SP_%s_Exp%d.jpeg', output_dir, ch_label, cnt) );
end


end