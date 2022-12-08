function plot_ave_spindles(X, yhat, params, output_dir, ch_label)

%
% Plot time-shifted average spindles (highpass at 9 Hz)
% 27 Nov 2022
%
% PARAMETERS
% x - raw signal
% yhat - CNN - detected label for input windows
% params - analytical parameters 
% s - SNR value of input windows
% output_dir - output directory
% ch_label - save label
%


w_len_side = params.window_size/2;
s = [];
g = find(yhat == 1);
[~,ind_max] = max(squeeze(X(1,:,g)));

ind1 = find(ind_max > w_len_side);
ind0 = find(g == size(X,3));
ind1 = setdiff(ind1, ind0);

tmp_X = arrayfun(@(xx) [squeeze(X(1,(ind_max(xx)-w_len_side)+1:params.window_size,g(xx))), ...
    squeeze(X(1,1:(ind_max(xx)-w_len_side),g(xx)+1))], ind1, 'UniformOutput' , false);
tmp_X = cat(1,tmp_X{:});
s = [s; tmp_X];


ind1 = find(ind_max < w_len_side);
ind0 = find(g == 1);
ind1 = setdiff(ind1, ind0);

tmp_X = arrayfun(@(xx) [squeeze(X(1,params.window_size-(w_len_side-ind_max(xx))+1:params.window_size,g(xx)-1)), ...
    squeeze(X(1,1:(ind_max(xx)+w_len_side),g(xx)))], ind1, 'UniformOutput' , false);
tmp_X = cat(1,tmp_X{:});
s = [s; tmp_X];

ind1 = ind_max(find(ind_max == w_len_side));
tmp_X = squeeze(X(1,:,ind1));
if size(tmp_X,2) == size(s,2)
    s = [s; tmp_X];
else
    s = [s; tmp_X'];
end


s = s';
sp_ave = mean(s, 2, 'omitnan');
sp_sd= sqrt(var(s, [], 2, 'omitnan')./size(s,2));

clf;
% plot
nexttile;
yyaxis left
imagesc(s'- mean (s', 2));
tmp = reshape((s' - mean (s', 2)),1, []);
cb = colorbar('southoutside'); caxis([prctile(tmp, 25), prctile(tmp, 75)]);
set( get(cb,'xlabel'), 'string', 'Amplitude (\muV)')
ylabel( 'Events', 'fontsize', 14 );
hold on;
yyaxis right
plot(sp_ave, "k", 'LineWidth', 2); hold on;
set(gca,'XTick', 1:100:params.window_size, 'XTickLabel', ...
    round(1/params.Fs,2):round(100/params.Fs,2):round(params.window_size/params.Fs,3), ...
    'fontname', 'arial', 'fontsize', 14, 'linewidth', 1);
ax = gca; ax.YAxis(1).Color = 'k'; ax.YAxis(2).Color = 'k'; ax.YAxis(1).Exponent = 0;
xlabel( 'Time (sec)' , 'fontsize', 14);
ylabel( 'Amplitude of Average (\muV)', 'fontsize', 14 );
axis square

set( gcf, 'PaperOrientation', 'landscape', 'PaperUnits', 'normalized', 'PaperPosition', [ 0 0 1 1 ] );
print( gcf, '-djpeg', sprintf( '%s/ave_sp_%s.jpeg', output_dir, ch_label) );


end