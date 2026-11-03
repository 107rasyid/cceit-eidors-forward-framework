function cceit_plot_pair_series(x,y,ylabel_text,title_text,path)
% CCEIT_PLOT_PAIR_SERIES Export one acquisition-order line plot.
% Purpose: create a readable standalone figure for one pair-wise quantity.
% Inputs: x, pair indices; y, values; labels; output PNG path.
% Outputs: one PNG file.
% Manuscript ref: Section IV, Model A/B pair-response figures.

fig = figure('visible','off','color','w','position',[100 100 1000 600]);
plot(x,y,'o-','linewidth',1.1,'markersize',3);
grid on; xlim([1 numel(x)]);
xlabel('Pair index (acquisition order)'); ylabel(ylabel_text);
title(title_text);
print(fig,path,'-dpng','-r180');
close(fig);
fprintf('Saved: %s\n',path);
end
