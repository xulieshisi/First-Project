% 三维逆时偏移 3x3 对比图
% 参考 adaptive_plot_rtm_model_figure_3d_0025and005.m 修改。
% 行方向：Delta s = 0.050、0.075、0.100 m。
% 列方向：M1-FDTD、M2-LSDTD、M3-Adaptive LSDTD。

close all;
clc;
clear;
% Resolve all input/output paths from this script, rather than MATLAB's
% current folder. This prevents duplicated or stale working-directory paths.
rootDir = fileparts(fileparts(mfilename('fullpath')));
cd(rootDir);

%% 绘图参数
resultDir = fullfile(rootDir, 'data');
outputDir = fullfile(rootDir, 'outputs', 'attached_figure_matlab', 'original');
if ~isfolder(outputDir)
    mkdir(outputDir);
end

gridSpacing = [0.050, 0.075, 0.100];
methodCodes = {'m1', 'm2', 'm3'};

% 与完整 Herten 模型及现有 x=14 m 对比结果保持一致。
sliceX = 14.0;
sliceY = 1.0;
sliceZ = 3.25;

viewAngle = [115, 15];  % 以 YZ 剖面为主体，X 方向向右后方延伸。
colorLimit = 0.20;      % 与文档图6相同，九幅图共用 [-0.2, 0.2]。
outerFaceAlpha = 0.30;
exportResolution = 300;

%% 检查九个偏移结果文件
for ids = 1:numel(gridSpacing)
    for im = 1:numel(methodCodes)
        resultFile = fullfile(resultDir, sprintf('herten_%s_ds%s.mat', ...
            methodCodes{im}, local_ds_tag(gridSpacing(ids))));
        if ~isfile(resultFile)
            error('未找到偏移结果文件：%s', resultFile);
        end
    end
end

%% 3x3 三维偏移结果
fig = figure(6);
set(fig, 'Units','centimeter', 'Position',[0 0 60 32], ...
    'Color','w', 'Visible','off');
set(0, 'DefaultAxesFontName','Times New Roman');
set(0, 'DefaultAxesFontWeight','bold');

layout = tiledlayout(fig, 3, 3, ...
    'TileSpacing','compact', 'Padding','compact');
layout.OuterPosition = [0, 0, 0.90, 1];

panelIndex = 0;
panelAxes = gobjects(numel(gridSpacing), numel(methodCodes));
for ids = 1:numel(gridSpacing)
    for im = 1:numel(methodCodes)
        panelIndex = panelIndex + 1;
        resultFile = fullfile(resultDir, sprintf('herten_%s_ds%s.mat', ...
            methodCodes{im}, local_ds_tag(gridSpacing(ids))));

        loaded = load(resultFile, 'result');
        if ~isfield(loaded, 'result') || ~isfield(loaded.result, 'image')
            error('文件 %s 中缺少 result.image。', resultFile);
        end

        result = loaded.result;
        imageData = double(result.image);
        x = double(result.meta.x(:).');
        y = double(result.meta.y(:).');
        z = double(result.meta.z(:).');

        expectedSize = [numel(y), numel(x), numel(z)];
        actualSize = size(imageData);
        actualSize(end+1:3) = 1;
        if ~isequal(actualSize(1:3), expectedSize)
            error(['文件 %s 的 result.image 尺寸为 [%s]，' ...
                '但 meta.y/x/z 对应尺寸应为 [%s]。'], ...
                resultFile, num2str(actualSize(1:3)), num2str(expectedSize));
        end

        currentSliceX = min(max(sliceX, x(1)), x(end));
        currentSliceY = min(max(sliceY, y(1)), y(end));
        currentSliceZ = min(max(sliceZ, z(1)), z(end));

        ax = nexttile(layout, panelIndex);
        panelAxes(ids,im) = ax;
        adaptive_rtm_section_3d_6polar_no(ax, x, y, z, imageData, ...
            currentSliceX, currentSliceY, currentSliceZ, ...
            x(end), y(end), z(end), outerFaceAlpha);
        hold(ax, 'on');
        grid(ax, 'on');

        view(ax, viewAngle);
        title(ax, sprintf('(%c)', char('a' + panelIndex - 1)), ...
            'FontSize',24, 'FontName','Times New Roman', ...
            'FontWeight','bold', 'Interpreter','tex');
        xlabel(ax, 'X (m)', 'FontWeight','bold', 'FontSize',24);
        if ids == numel(gridSpacing)
            ylabel(ax, 'Y (m)', 'FontWeight','bold', 'FontSize',24);
        else
            ylabel(ax, '');
            ax.YTick = [];
        end
        if im == 1
            zlabel(ax, 'Z (m)', 'FontWeight','bold', 'FontSize',24);
            ax.ZTick = 0:1:3;
        else
            zlabel(ax, '');
            ax.ZTick = [];
        end

        axis(ax, 'tight');
        pbaspect(ax, [1.6, 2.8, 1]);
        clim(ax, [-colorLimit, colorLimit]);
        set(ax, 'FontSize',20, 'FontWeight','bold', ...
            'FontName','Times New Roman', 'XMinorGrid','on', ...
            'YMinorGrid','on', 'ZDir','reverse', 'ZMinorGrid','on', ...
            'LineWidth',0.75, 'Box','on', 'Layer','top');
        camva(ax, 6.8);

        clear loaded result imageData x y z;
        drawnow limitrate;
    end
end

colormap(fig, jet(256));
drawnow;
fAx = panelAxes(2,3);
fPosition = fAx.Position;
colorbarHeight = 1.10*fPosition(4);
colorbarPosition = [fPosition(1)+fPosition(3)+0.010, ...
    fPosition(2) + 0.5*(fPosition(4)-colorbarHeight), ...
    0.009, colorbarHeight];
cb = colorbar(fAx, 'Position',colorbarPosition);
cb.Ticks = [-0.2, -0.1, 0, 0.1, 0.2];
set(cb, 'FontName','Times New Roman', 'FontSize',24, ...
    'FontWeight','bold');

drawnow;

%% 保存结果
figFile = fullfile(outputDir, 'adaptive_figure6_rtm_3d_3x3.fig');
pdfFile = fullfile(outputDir, 'adaptive_figure6_rtm_3d_3x3.pdf');
emfFile = fullfile(outputDir, 'adaptive_figure6_rtm_3d_3x3.emf');

exportgraphics(fig, pdfFile, 'ContentType','image', ...
    'Resolution',exportResolution);
savefig(fig, figFile);
print(fig, emfFile, '-dmeta');

fprintf('3x3三维偏移结果已保存：\n%s\n%s\n%s\n%s\n', ...
    pdfFile, emfFile, figFile);

function adaptive_rtm_section_3d_6polar_no(ax, x, y, z, data, ...
        xslice1, yslice1, zslice1, ~, yslice2, zslice2, outerAlpha)
% 与 rtm_section_3d_6polar_no 相同的剖切形式。
% 使用最近物理坐标定位索引，兼容坐标从 0 开始的 result.meta.x/y/z。

[X,Y,Z] = meshgrid(x,y,z);
hold(ax, 'on');

% 先绘制内部 XZ、XY 剖面；YZ 剖面在最后单独绘制，避免被透明外表面遮挡。
h = slice(ax, X, Y, Z, data, [], yslice1, zslice1);
local_style_slice(h, 1.0);

xlim(ax, [min(x), max(x)]);
ylim(ax, [min(y), max(y)]);
zlim(ax, [min(z), max(z)]);
set(ax, 'ZDir','reverse');
box(ax, 'on');

% 补齐被剖开的体表面。
[~, nxSlice] = min(abs(x-xslice1));
[~, nySlice] = min(abs(y-yslice1));
[~, nzSlice] = min(abs(z-zslice1));

h = slice(ax, X(:,1:nxSlice,:), Y(:,1:nxSlice,:), Z(:,1:nxSlice,:), ...
    data(:,1:nxSlice,:), [], min(y), min(z));
local_style_slice(h, 1.0);

% Y方向镜像剖切：保留正面左侧 y <= yslice1，切开右侧。
h = slice(ax, X(1:nySlice,:,:), Y(1:nySlice,:,:), Z(1:nySlice,:,:), ...
    data(1:nySlice,:,:), max(x), [], min(z));
local_style_slice(h, 1.0);

h = slice(ax, X(:,:,nzSlice:end), Y(:,:,nzSlice:end), Z(:,:,nzSlice:end), ...
    data(:,:,nzSlice:end), max(x), min(y), []);
local_style_slice(h, 1.0);

% 外围透明切片仅保留 Y、Z 方向；不绘制最外侧 X 面，以免遮挡 YZ 剖面。
h = slice(ax, X, Y, Z, data, [], yslice2, zslice2);
local_style_slice(h, outerAlpha);

% 最后绘制不透明的 YZ 剖面（x = xslice1），保证该剖面完整展示。
h = slice(ax, X, Y, Z, data, xslice1, [], []);
local_style_slice(h, 1.0);

grid(ax, 'off');
light(ax, 'Position',[1 0 -1]);
light(ax, 'Position',[0 -1 0]);
light(ax, 'Position',[-1 0 -1]);
end

function local_style_slice(handles, faceAlpha)
for ih = 1:numel(handles)
    set(handles(ih), 'FaceColor','interp', 'EdgeColor','none', ...
        'LineStyle','none', 'FaceAlpha',faceAlpha, 'Tag','V3D:SLICE');
end
end

function tag = local_ds_tag(ds)
tag = strrep(sprintf('%.4f', ds), '.', 'p');
end

