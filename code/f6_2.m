function outputs = f6_2(varargin)
% Figure 6(2): x=14 m, y=5 m
% Plot one RTM trace using the Figure 6 style.

ip = inputParser;
packageRoot = fileparts(fileparts(mfilename('fullpath')));
ip.addParameter('ResultDir', fullfile(packageRoot, ...
    'data'));
ip.addParameter('OutputDir', fullfile(packageRoot, 'outputs', 'f6_2'));
ip.addParameter('SliceX', 14.0);
ip.addParameter('TargetY', 5.0);
ip.addParameter('GridSpacing', 0.10);
ip.addParameter('Frequency', 100e6);
ip.addParameter('ApplyDepthGain', true);
ip.addParameter('PlotDepthStep', 0.005);
ip.parse(varargin{:});
opt = ip.Results;

validateattributes(opt.PlotDepthStep, {'numeric'}, ...
    {'scalar','real','finite','positive'});

if ~isfolder(opt.OutputDir)
    mkdir(opt.OutputDir);
end

tag = local_numeric_tag(opt.GridSpacing, 4);
methodCodes = ["m2", "m3"];
methodNames = ["LSDTD", "Adaptive-LSDTD"];
results = cell(1, numel(methodCodes));
for im = 1:numel(methodCodes)
    resultFile = fullfile(opt.ResultDir, sprintf( ...
        'herten_%s_ds%s.mat', methodCodes(im), tag));
    local_require_file(resultFile);
    loaded = load(resultFile, 'result');
    results{im} = loaded.result;
end

caseFile = fullfile(opt.ResultDir, sprintf('herten_case_ds%s.mat', tag));
local_require_file(caseFile);
loaded = load(caseFile, 'caseData');
caseData = loaded.caseData;

x = double(results{1}.meta.x(:));
y = double(results{1}.meta.y(:));
z = double(results{1}.meta.z(:));
[~, ix] = min(abs(x-opt.SliceX));
xActual = x(ix);

for im = 2:numel(results)
    local_assert_axes_match(results{1}, results{im});
end
if numel(caseData.x) ~= numel(x) || numel(caseData.y) ~= numel(y) || ...
        numel(caseData.z) ~= numel(z)
    error('The model and RTM result grids do not have matching sizes.');
end

if opt.ApplyDepthGain
    gainScale = max(z(end)/5, eps);
    depthGain = 1 - 1./(1 + (z./gainScale).^5);
else
    depthGain = ones(size(z));
end

nz = numel(z);
% Select the grid trace nearest the requested target coordinate y=5 m.
[~, selectedIndex] = min(abs(y-opt.TargetY));

ySelected = y(selectedIndex);
tracesSelected = zeros(nz, numel(methodCodes));
for im = 1:numel(methodCodes)
    trace = double(squeeze(results{im}.image(selectedIndex,ix,:))) .* depthGain;
    tracesSelected(:,im) = trace ./ max(max(abs(trace)), eps);
end
epsrTrace = double(squeeze(caseData.epsr(selectedIndex,ix,:)));
referenceSelected = local_bandlimited_reference( ...
    z, epsrTrace, caseData.tBack, opt.Frequency) .* depthGain;
referenceSelected = referenceSelected ./ max(max(abs(referenceSelected)), eps);
% RTM polarity is arbitrary, so use one common sign for both methods.
if dot(tracesSelected(:,1), referenceSelected) + ...
        dot(tracesSelected(:,2), referenceSelected) < 0
    referenceSelected = -referenceSelected;
end
nccSelected = [local_ncc(tracesSelected(:,1), referenceSelected), ...
    local_ncc(tracesSelected(:,2), referenceSelected)];
rmseSelected = [sqrt(mean((tracesSelected(:,1)-referenceSelected).^2)), ...
    sqrt(mean((tracesSelected(:,2)-referenceSelected).^2))];
metrics = table(methodNames(:), nccSelected(:), rmseSelected(:), ...
    'VariableNames', {'method','ncc','rmse'});

numberOfPlotSamples = ceil((max(z)-min(z))/opt.PlotDepthStep) + 1;
zPlot = linspace(min(z), max(z), numberOfPlotSamples).';
tracesPlot = interp1(z, tracesSelected, zPlot, 'makima');
referencePlot = interp1(z, referenceSelected, zPlot, 'makima');

fig = figure('Visible','off', 'Color','w', ...
    'Position',[100 100 864 210]);
ax = axes(fig);
hold(ax, 'on');
plot(ax, zPlot, tracesPlot(:,1), '-', ...
    'Color',[0.00 0.45 0.74], 'LineWidth',1.6, ...
    'DisplayName','LSDTD');
plot(ax, zPlot, tracesPlot(:,2), '-', ...
    'Color',[0.85 0.20 0.10], 'LineWidth',1.6, ...
    'DisplayName','Adaptive-LSDTD');
plot(ax, zPlot, referencePlot, '--', ...
    'Color',[0.55 0.10 0.65], 'LineWidth',1.8, ...
    'DisplayName','100 MHz band-limited reference');
yline(ax, 0, ':', 'Color',[0.45 0.45 0.45], 'LineWidth',0.8, ...
    'HandleVisibility','off');

set(ax, 'FontName','Times New Roman', 'FontSize',8, ...
    'LineWidth',1.0, 'Box','on', 'XGrid','on', 'YGrid','on', ...
    'GridAlpha',0.18, 'MinorGridAlpha',0.10);
xlabel(ax, 'Z(m)', 'FontName','Times New Roman', 'FontSize',8);
ylabel(ax, 'Normalized amplitude', 'FontName','Times New Roman', 'FontSize',8);
title_handle = title(ax, sprintf('(a) Single RTM trace at X = %.3f m, Y = %.3f m', ...
    xActual, ySelected), 'FontName','Times New Roman', 'FontSize',8, 'FontWeight','normal');
title_handle.Units = 'normalized';
title_handle.HorizontalAlignment = 'center';
title_handle.Position(1) = 0.5;
title_handle.Position(2) = 1.02;
xlim(ax, [min(z), max(z)]);
ylim(ax, [-1.5, 1.5]);
xticks(ax, 0:0.5:max(z));
yticks(ax, -1.5:0.5:1.5);
legend_handle = legend(ax, 'Location','southeast', ...
    'FontName','Times New Roman', 'FontSize',6, 'Box','on', ...
    'Color','white', 'EdgeColor','white');
legend_handle.Orientation = 'vertical';
legend_handle.NumColumns = 1;
set(ax, 'XTickLabelRotation',0);

baseName = 'f6_2';
outputs = struct();
outputs.pdf = fullfile(opt.OutputDir, baseName + ".pdf");
outputs.emf = fullfile(opt.OutputDir, baseName + ".emf");
outputs.fig = fullfile(opt.OutputDir, baseName + ".fig");
outputs.ySelected = ySelected;
outputs.xActual = xActual;
outputs.metrics = metrics;

exportgraphics(fig, outputs.pdf, 'ContentType','vector');
exportgraphics(fig, outputs.emf, 'ContentType','vector');
savefig(fig, outputs.fig);
close(fig);


fprintf(['Selected Y = %.3f m: NCC %.4f -> %.4f, RMSE %.4f -> %.4f; ' ...
    'minimum Adaptive-LSDTD fit RMSE %.4f.\n'], ySelected, nccSelected(1), ...
    nccSelected(2), rmseSelected(1), rmseSelected(2), rmseSelected(2));
fprintf('Saved horizontal single-trace plot to:\n%s\n%s\n%s\n', ...
    outputs.pdf, outputs.emf, outputs.fig);
end

function reference = local_bandlimited_reference(z, epsrTrace, tBack, frequency)
c0 = 299792458;
impedance = 1 ./ sqrt(epsrTrace);
reflectivity = (impedance(2:end)-impedance(1:end-1)) ./ ...
    (impedance(2:end)+impedance(1:end-1));
velocity = c0 ./ sqrt(epsrTrace);

twt = zeros(size(z));
for iz = 2:numel(z)
    averageSlowness = 0.5 .* ...
        (1./velocity(iz-1) + 1./velocity(iz));
    twt(iz) = twt(iz-1) + ...
        2 .* (z(iz)-z(iz-1)) .* averageSlowness;
end
twtInterface = 0.5 .* (twt(1:end-1)+twt(2:end));

dt = median(diff(double(tBack(:))));
paddingTime = 2 / frequency;
tFine = (-paddingTime:dt:twt(end)+paddingTime).';
reflectivityFine = zeros(size(tFine));
for ir = 1:numel(reflectivity)
    [~, index] = min(abs(tFine-twtInterface(ir)));
    reflectivityFine(index) = reflectivityFine(index) + reflectivity(ir);
end

waveletTime = (-paddingTime:dt:paddingTime).';
wavelet = (1-2.*(pi.*frequency.*waveletTime).^2) .* ...
    exp(-(pi.*frequency.*waveletTime).^2);
bandlimitedFine = conv(reflectivityFine, wavelet, 'same');
reference = interp1(tFine, bandlimitedFine, twt, 'linear', 0);
end

function value = local_ncc(a, b)
a = double(a(:));
b = double(b(:));
value = dot(a,b) / max(norm(a).*norm(b), eps);
end

function local_assert_axes_match(reference, current)
fields = {'x','y','z'};
for ifield = 1:numel(fields)
    fieldName = fields{ifield};
    a = double(reference.meta.(fieldName)(:));
    b = double(current.meta.(fieldName)(:));
    if ~isequal(size(a),size(b)) || any(abs(a-b) > 1e-10)
        error('RTM result grids do not match along axis %s.', fieldName);
    end
end
end

function tag = local_numeric_tag(value, decimals)
tag = strrep(sprintf(['%0.', num2str(decimals), 'f'], value), '.', 'p');
end

function local_require_file(fileName)
if ~isfile(fileName)
    error('Required data file not found: %s', fileName);
end
end
