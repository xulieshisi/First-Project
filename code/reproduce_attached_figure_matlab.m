% Reproduce the supplied nine-panel figure from the original RTM volumes.
% Run this file in MATLAB; all panels remain editable 3-D surface objects.
cd(fileparts(mfilename('fullpath')));
rootDir = pwd;
run('attached_figure_original_source.m');
rootDir = pwd;

delete(cb);
for k = 1:numel(panelAxes)
    panelAxes(k).Parent = fig;
end
delete(layout);
set(fig, 'Visible','off', 'Units','pixels', ...
    'Position',[50 50 960 510], 'Renderer','opengl');
set(findall(fig,'Type','axes'), 'FontSize',8);
for k = 1:numel(panelAxes)
    ax = panelAxes(k);
    ax.Title.FontSize = 10;
    ax.XLabel.FontSize = 9;
    ax.YLabel.FontSize = 9;
    ax.ZLabel.FontSize = 9;
    [row,col] = ind2sub(size(panelAxes),k);
    ax.Units = 'normalized';
    ax.Position = [0.035+(col-1)*0.305, 0.690-(row-1)*0.310, 0.270, 0.250];
    ax.CameraViewAngleMode = 'auto';
    set(findall(ax,'Type','surface'),'FaceLighting','none');
    surfaces = findall(ax,'Type','surface');
    for ih = 1:numel(surfaces)
        h = surfaces(ih);
        if max(h.YData(:))-min(h.YData(:)) < 1e-8 && abs(h.YData(1)-1)<0.11
            set(h,'FaceLighting','flat','AmbientStrength',0.3,'DiffuseStrength',0);
        elseif h.FaceAlpha < 1
            set(h,'FaceLighting','flat','AmbientStrength',0.65,'DiffuseStrength',0);
        end
    end
    if ~isempty(ax.YTick)
        ax.YTick = 0:2:10;
    end
end
% Recreate a compact shared colorbar at the right edge.
cb = colorbar(panelAxes(2,3), 'Position',[0.925 0.235 0.014 0.530]);
cb.Ticks = [-0.2 -0.1 0 0.1 0.2];
cb.FontName = 'Times New Roman';
cb.FontSize = 8;
cb.FontWeight = 'bold';
% Show only the final compact layout in the MATLAB window.
set(fig, 'Visible','on');
drawnow;
outputDir = fullfile(rootDir,'outputs','attached_figure_matlab');
if ~isfolder(outputDir), mkdir(outputDir); end
set(fig,'PaperUnits','inches','PaperPosition',[0 0 960/96 510/96], ...
    'PaperSize',[960/96 510/96],'InvertHardcopy','off');
figFile = fullfile(outputDir,'attached_figure_reproduced.fig');
savefig(fig,figFile);
assert(numel(findall(fig,'Type','surface')) == 99);
assert(isempty(findall(fig,'Type','image')));
fprintf('ATTACHED_FIGURE_READY: 9 axes, 99 surfaces, 0 images\n%s\n',figFile);
