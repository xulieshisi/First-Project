% Recreate the attached figure using the recovered source and RTM volumes.
run(fullfile(fileparts(mfilename('fullpath')), 'reproduce_attached_figure_matlab.m'));

for k = 1:numel(panelAxes)
    ax = panelAxes(k);
    [row,col] = ind2sub(size(panelAxes), k);
    % Compact 3-by-3 layout with extra space beneath the last row so the
    % oblique Y-axis labels are not clipped by the figure canvas.
    ax.Units = 'normalized';
    ax.Position = [0.035 + (col-1)*0.305, ...
                   0.690-(row-1)*0.310, 0.270, 0.250];
    surfaces = findall(ax, 'Type','surface');
    for ih = 1:numel(surfaces)
        h = surfaces(ih);
        if h.FaceAlpha == 1
            set(h, 'FaceLighting','flat', 'AmbientStrength',0.9, ...
                'DiffuseStrength',0, 'SpecularStrength',0);
            if range(h.YData(:)) < 1e-8 && abs(h.YData(1)-1)<0.11
                h.AmbientStrength = 0.3;
            elseif range(h.ZData(:)) < 1e-8 && abs(h.ZData(1))<0.11
                % Match the light top-face appearance without editing volumes.
                originalCData = h.CData;
                setappdata(h,'OriginalScalarCData',originalCData);
                cmap = colormap(ax);
                idx = floor((originalCData-ax.CLim(1))/diff(ax.CLim)*size(cmap,1))+1;
                idx = max(1,min(size(cmap,1),idx));
                rgb = reshape(cmap(idx(:),:),[size(idx),3]);
                h.CData = 0.65*rgb + 0.35;
                h.FaceLighting = 'none';
            elseif range(h.XData(:)) < 1e-8 && max(h.XData(:))>14.1
                h.AmbientStrength = 1;
            end
        else
            h.AmbientStrength = 0.4;
        end
    end
end
drawnow;
figFile = fullfile(outputDir,'clipboard_figure_matlab.fig');
pdfFile = fullfile(outputDir,'clipboard_figure_matlab.pdf');
emfFile = fullfile(outputDir,'clipboard_figure_matlab.emf');
savefig(fig,figFile);
% Rasterized PDF keeps the large 3-D surface export responsive while the
% accompanying FIG and EMF remain editable/vector deliverables.
exportgraphics(fig,pdfFile,'ContentType','image','Resolution',150);
print(fig,emfFile,'-dmeta');
assert(numel(findall(fig,'Type','axes')) == 9);
assert(numel(findall(fig,'Type','surface')) == 99);
assert(isempty(findall(fig,'Type','image')));
set(fig,'Visible','on');
fprintf('MATLAB_REPRODUCTION_READY: %s\n',figFile);
fprintf('PDF_READY: %s\n',pdfFile);
fprintf('FIG_READY: %s\nEMF_READY: %s\n',figFile,emfFile);
