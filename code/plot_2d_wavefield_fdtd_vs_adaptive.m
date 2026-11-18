function outputs = plot_2d_wavefield_fdtd_vs_adaptive(varargin)
%PLOT_2D_WAVEFIELD_FDTD_VS_ADAPTIVE Compare 2-D forward wavefields.
% Each panel follows the layout of Ji et al. (2025), Fig. 4: the left
% half shows the modeled wavefield and the right half shows its error
% relative to a fine-grid FDTD reference.

ip = inputParser;
ip.addParameter('ResultFile', fullfile(pwd, ...
    'data', 'herten_m3_ds0p1000.mat'));
ip.addParameter('OutputDir', fullfile(pwd, ...
    'results_2d_wavefield_comparison'));
ip.addParameter('FrequencyHz', []);
ip.addParameter('CoarseDx', 0.10);
ip.addParameter('ReferenceRefinement', 4);
ip.addParameter('ReferenceDx', []);
ip.addParameter('Dt', 1.0e-10);
ip.addParameter('DomainLength', 12.0);
ip.addParameter('DisplayDomainLength', []);
ip.addParameter('SnapshotTimes', [35, 55, 75]*1e-9);
ip.addParameter('SnapshotTimesRelativeToSourcePeak', false);
ip.addParameter('SourceSigma', 0.15);
ip.addParameter('EffectiveEnergy', 0.995);
ip.addParameter('StencilHalfWidth', 4);
ip.addParameter('UseAngularMapping', true);
ip.addParameter('UseWaveletForCoefficients', true);
ip.addParameter('CoefficientRegularization', 0);
ip.addParameter('ColorLimits', [-2, 2]);
ip.addParameter('PermittivityModel', []);
ip.addParameter('ModelName', 'homogeneous_2d_tm_maxwell');
ip.addParameter('SourcePosition', [0, 0]);
ip.addParameter('AdaptiveEpsrSamples', []);
ip.addParameter('IncludeFixedLSDTD', false);
ip.addParameter('FixedLSDTDReferenceEpsr', 30);
ip.addParameter('FixedLSDTDCoefficients', []);
ip.addParameter('FixedLSDTDCoefficientDefinition', '');
ip.addParameter('FineReferenceOutputFile', '');
ip.addParameter('FigurePrefix', '');
ip.parse(varargin{:});
opt = ip.Results;

validateattributes(opt.CoarseDx, {'numeric'}, {'scalar','positive'});
validateattributes(opt.ReferenceRefinement, {'numeric'}, ...
    {'scalar','integer','>=',2});
if ~isempty(opt.ReferenceDx)
    validateattributes(opt.ReferenceDx, {'numeric'}, ...
        {'scalar','positive','finite'});
end
validateattributes(opt.Dt, {'numeric'}, {'scalar','positive'});
validateattributes(opt.DomainLength, {'numeric'}, {'scalar','positive'});
if ~isempty(opt.DisplayDomainLength)
    validateattributes(opt.DisplayDomainLength, {'numeric'}, ...
        {'scalar','positive','finite','<=',opt.DomainLength});
end
validateattributes(opt.SnapshotTimes, {'numeric'}, ...
    {'vector','positive','increasing'});
validateattributes(opt.SnapshotTimesRelativeToSourcePeak, ...
    {'numeric','logical'}, {'scalar'});
opt.SnapshotTimesRelativeToSourcePeak = ...
    logical(opt.SnapshotTimesRelativeToSourcePeak);
validateattributes(opt.SourceSigma, {'numeric'}, {'scalar','positive'});
validateattributes(opt.EffectiveEnergy, {'numeric'}, ...
    {'scalar','>',0,'<',1});
validateattributes(opt.StencilHalfWidth, {'numeric'}, ...
    {'scalar','integer','positive'});
validateattributes(opt.UseWaveletForCoefficients, {'numeric','logical'}, ...
    {'scalar'});
opt.UseWaveletForCoefficients = logical(opt.UseWaveletForCoefficients);
validateattributes(opt.CoefficientRegularization, {'numeric'}, ...
    {'real','finite','scalar','nonnegative'});
validateattributes(opt.ColorLimits, {'numeric'}, ...
    {'real','finite','numel',2});
opt.ColorLimits = double(opt.ColorLimits(:).');
if opt.ColorLimits(1) >= opt.ColorLimits(2)
    error('ColorLimits must be a strictly increasing two-element vector.');
end
if ~isempty(opt.PermittivityModel) && ~isa(opt.PermittivityModel, 'function_handle')
    error('PermittivityModel must be a function handle or empty.');
end
validateattributes(opt.SourcePosition, {'numeric'}, ...
    {'real','finite','numel',2});
opt.SourcePosition = double(opt.SourcePosition(:).');
if ~isempty(opt.AdaptiveEpsrSamples)
    validateattributes(opt.AdaptiveEpsrSamples, {'numeric'}, ...
        {'real','positive','vector'});
    opt.AdaptiveEpsrSamples = unique(double(opt.AdaptiveEpsrSamples(:).'));
end
validateattributes(opt.IncludeFixedLSDTD, {'numeric','logical'}, ...
    {'scalar'});
opt.IncludeFixedLSDTD = logical(opt.IncludeFixedLSDTD);
if ~isempty(opt.FixedLSDTDCoefficients)
    validateattributes(opt.FixedLSDTDCoefficients, {'numeric'}, ...
        {'real','finite','vector','numel',opt.StencilHalfWidth});
    opt.FixedLSDTDCoefficients = ...
        double(opt.FixedLSDTDCoefficients(:).');
else
    validateattributes(opt.FixedLSDTDReferenceEpsr, {'numeric'}, ...
        {'real','positive','finite','scalar'});
end
if ~(ischar(opt.FixedLSDTDCoefficientDefinition) || ...
        (isstring(opt.FixedLSDTDCoefficientDefinition) && ...
        isscalar(opt.FixedLSDTDCoefficientDefinition)))
    error(['FixedLSDTDCoefficientDefinition must be a character ', ...
        'vector or string scalar.']);
end
opt.FixedLSDTDCoefficientDefinition = ...
    char(opt.FixedLSDTDCoefficientDefinition);
if ~(ischar(opt.FineReferenceOutputFile) || ...
        (isstring(opt.FineReferenceOutputFile) && ...
        isscalar(opt.FineReferenceOutputFile)))
    error('FineReferenceOutputFile must be a character vector or string scalar.');
end
opt.FineReferenceOutputFile = char(opt.FineReferenceOutputFile);

if ~exist(opt.OutputDir, 'dir')
    mkdir(opt.OutputDir);
end

sourceResultLoaded = ~isempty(opt.ResultFile) && isfile(opt.ResultFile);
if sourceResultLoaded
    loaded = load(opt.ResultFile, 'result');
    epsr = double(loaded.result.adaptive.epsrTable(end));
else
    if isempty(opt.PermittivityModel) || isempty(opt.FrequencyHz)
        error(['ResultFile is required unless both FrequencyHz and ', ...
            'PermittivityModel are supplied.']);
    end
    epsr = NaN;
end
if isempty(opt.FrequencyHz)
    f0 = double(loaded.result.meta.freq);
else
    validateattributes(opt.FrequencyHz, {'numeric'}, ...
        {'scalar','positive','finite'});
    f0 = double(opt.FrequencyHz);
end

% The Ricker pulse is started smoothly before its main peak.  For a
% peak-referenced figure, retain that pre-roll and shift extraction times.
sourcePeakTime = 1/f0;
if opt.SnapshotTimesRelativeToSourcePeak
    simulationSnapshotTimes = opt.SnapshotTimes + sourcePeakTime;
    snapshotTimeReference = 'source_peak';
else
    simulationSnapshotTimes = opt.SnapshotTimes;
    snapshotTimeReference = 'simulation_start';
end

c0 = 299792458;
mu0 = 4*pi*1e-7;
eps0 = 8.8541878128e-12;
if isempty(opt.ReferenceDx)
    fineDx = opt.CoarseDx/opt.ReferenceRefinement;
else
    fineDx = double(opt.ReferenceDx);
end
if fineDx >= opt.CoarseDx
    error('ReferenceDx must be smaller than CoarseDx.');
end

if isempty(opt.DisplayDomainLength)
    displayDomainLength = opt.DomainLength;
else
    displayDomainLength = double(opt.DisplayDomainLength);
end

coarseGrid = local_make_grid(opt.CoarseDx, opt.DomainLength);
fineGrid = local_make_grid(fineDx, opt.DomainLength);
if isempty(opt.PermittivityModel)
    epsrCoarse = epsr*ones(coarseGrid.numGridPoints, ...
        coarseGrid.numGridPoints);
    epsrFine = epsr*ones(fineGrid.numGridPoints, ...
        fineGrid.numGridPoints);
    modelName = char(opt.ModelName);
else
    [Xc, Zc] = meshgrid(coarseGrid.x, coarseGrid.z);
    [Xf, Zf] = meshgrid(fineGrid.x, fineGrid.z);
    epsrCoarse = double(opt.PermittivityModel(Xc, Zc));
    epsrFine = double(opt.PermittivityModel(Xf, Zf));
    if ~isequal(size(epsrCoarse), size(Xc)) || ...
            ~isequal(size(epsrFine), size(Xf))
        error('PermittivityModel must return an array matching X and Z.');
    end
    modelName = char(opt.ModelName);
end
if any(~isfinite(epsrCoarse), 'all') || any(epsrCoarse <= 0, 'all') || ...
        any(~isfinite(epsrFine), 'all') || any(epsrFine <= 0, 'all')
    error('PermittivityModel must return finite positive relative permittivity.');
end
permittivityCoarse = eps0*epsrCoarse;
permittivityFine = eps0*epsrFine;
maxVelocity = c0/sqrt(min(epsrFine(:)));
minVelocity = c0/sqrt(max(epsrFine(:)));

maxTime = max(simulationSnapshotTimes);
numSteps = round(maxTime/opt.Dt);
time = (1:numSteps).'*opt.Dt;
source = (1 - 2*pi^2*(f0*time - 1).^2) .* ...
    exp(-pi^2*(f0*time - 1).^2);
fmax = local_effective_fmax(source, opt.Dt, opt.EffectiveEnergy);

baseCoefficientArguments = {'Mode', 'forward', ...
    'UseAngularMapping', opt.UseAngularMapping};
if opt.UseWaveletForCoefficients
    baseCoefficientArguments = [baseCoefficientArguments, ...
        {'Wavelet', source, 'Dt', opt.Dt}]; %#ok<AGROW>
end
if opt.CoefficientRegularization > 0
    baseCoefficientArguments = [baseCoefficientArguments, ...
        {'CoefficientRegularization', opt.CoefficientRegularization}]; %#ok<AGROW>
end
adaptiveArguments = [baseCoefficientArguments, {'ReturnCoeffGrid', true}];
if ~isempty(opt.AdaptiveEpsrSamples)
    adaptiveArguments = [adaptiveArguments, ...
        {'EpsrSamples', opt.AdaptiveEpsrSamples}]; %#ok<AGROW>
end
adaptive = gpr_adaptive_lsdtd_coefficients(epsrCoarse, opt.CoarseDx, ...
    fmax, opt.StencilHalfWidth, ...
    adaptiveArguments{:});
adaptiveCoefficients = double(adaptive.coeffTable);
adaptiveCoeffGrid = double(adaptive.coeffGrid);

fixedLsdtdCoefficients = [];
fixedLsdtdDefinition = '';
if opt.IncludeFixedLSDTD
    if isempty(opt.FixedLSDTDCoefficients)
        fixedLsdtd = gpr_adaptive_lsdtd_coefficients( ...
            opt.FixedLSDTDReferenceEpsr, opt.CoarseDx, fmax, ...
            opt.StencilHalfWidth, baseCoefficientArguments{:});
        fixedLsdtdCoefficients = double(fixedLsdtd.coeffTable(1,:));
        fixedLsdtdDefinition = ...
            'frequency_matched_global_coefficients_at_reference_epsr';
    else
        fixedLsdtdCoefficients = opt.FixedLSDTDCoefficients;
        fixedLsdtdDefinition = opt.FixedLSDTDCoefficientDefinition;
        if isempty(fixedLsdtdDefinition)
            fixedLsdtdDefinition = 'explicit_fixed_coefficients';
        end
    end
end

coarseCourant = maxVelocity*opt.Dt/opt.CoarseDx;
fineCourant = maxVelocity*opt.Dt/fineDx;
if sqrt(2)*fineCourant >= 1
    error('The fine-grid two-dimensional Courant number must be below 1.');
end

snapshotIndices = round(simulationSnapshotTimes/opt.Dt);
if any(snapshotIndices < 1 | snapshotIndices > numSteps)
    error('Snapshot times fall outside the simulated time interval.');
end
actualSimulationSnapshotTimes = snapshotIndices*opt.Dt;
if opt.SnapshotTimesRelativeToSourcePeak
    actualSnapshotTimesForCaption = actualSimulationSnapshotTimes - ...
        sourcePeakTime;
else
    actualSnapshotTimesForCaption = actualSimulationSnapshotTimes;
end

[referenceFine, fineGrid] = local_run_2d_tm( ...
    fineDx, opt.Dt, numSteps, source, opt.DomainLength, ...
    opt.SourceSigma, permittivityFine, mu0, 1, snapshotIndices, ...
    opt.SourcePosition);
fineReferenceFile = '';
if ~isempty(opt.FineReferenceOutputFile)
    fineReferenceFile = opt.FineReferenceOutputFile;
    fineReferenceDir = fileparts(fineReferenceFile);
    if ~isempty(fineReferenceDir) && ~exist(fineReferenceDir, 'dir')
        mkdir(fineReferenceDir);
    end
    [referenceSnapshots, displayGrid] = local_crop_single_field( ...
        referenceFine, fineGrid, displayDomainLength);
    referenceDx = fineDx; %#ok<NASGU>
    frequencyHz = f0; %#ok<NASGU>
    dt = opt.Dt; %#ok<NASGU>
    domainLength = opt.DomainLength; %#ok<NASGU>
    sourceSigma = opt.SourceSigma; %#ok<NASGU>
    sourcePosition = opt.SourcePosition; %#ok<NASGU>
    epsrLevels = opt.AdaptiveEpsrSamples; %#ok<NASGU>
    snapshotTimesAfterPeak = actualSnapshotTimesForCaption; %#ok<NASGU>
    referenceType = sprintf('%.12g_m_fine_grid_FDTD_numerical_baseline', ...
        fineDx); %#ok<NASGU>
    referenceNotAnalytic = true; %#ok<NASGU>
    permittivityModelFunction = func2str(opt.PermittivityModel); %#ok<NASGU>
    save(fineReferenceFile, 'referenceSnapshots', 'displayGrid', ...
        'fineGrid', 'referenceDx', 'frequencyHz', 'f0', 'fmax', ...
        'dt', 'domainLength', 'sourceSigma', 'sourcePosition', ...
        'epsrLevels', ...
        'sourcePeakTime', 'snapshotTimesAfterPeak', ...
        'simulationSnapshotTimes', 'actualSimulationSnapshotTimes', ...
        'snapshotIndices', 'source', 'modelName', ...
        'permittivityModelFunction', 'referenceType', ...
        'referenceNotAnalytic', 'displayDomainLength', 'opt', '-v7.3');
    clear referenceSnapshots displayGrid;
end
[fdtdSnapshots, coarseGrid] = local_run_2d_tm( ...
    opt.CoarseDx, opt.Dt, numSteps, source, opt.DomainLength, ...
    opt.SourceSigma, permittivityCoarse, mu0, 1, snapshotIndices, ...
    opt.SourcePosition);
lsdtdSnapshots = [];
if opt.IncludeFixedLSDTD
    [lsdtdSnapshots, lsdtdGrid] = local_run_2d_tm( ...
        opt.CoarseDx, opt.Dt, numSteps, source, opt.DomainLength, ...
        opt.SourceSigma, permittivityCoarse, mu0, ...
        fixedLsdtdCoefficients, snapshotIndices, opt.SourcePosition);
    if ~isequal(coarseGrid.x, lsdtdGrid.x) || ...
            ~isequal(coarseGrid.z, lsdtdGrid.z)
        error('The fixed-LSDTD simulation is not spatially aligned.');
    end
end
[adaptiveSnapshots, adaptiveGrid] = local_run_2d_tm( ...
    opt.CoarseDx, opt.Dt, numSteps, source, opt.DomainLength, ...
    opt.SourceSigma, permittivityCoarse, mu0, adaptiveCoeffGrid, ...
    snapshotIndices, opt.SourcePosition);

if ~isequal(coarseGrid.x, adaptiveGrid.x) || ...
        ~isequal(coarseGrid.z, adaptiveGrid.z)
    error('The two coarse-grid simulations are not spatially aligned.');
end

[referenceSnapshots, referenceAlignment] = local_align_reference( ...
    referenceFine, fineGrid, coarseGrid);
[referenceSnapshots, fdtdSnapshots, lsdtdSnapshots, ...
    adaptiveSnapshots, coarseGrid] = ...
    local_crop_to_display_window(referenceSnapshots, fdtdSnapshots, ...
    lsdtdSnapshots, adaptiveSnapshots, coarseGrid, displayDomainLength);

[fdtdMetrics, lsdtdMetrics, adaptiveMetrics] = local_snapshot_metrics( ...
    fdtdSnapshots, lsdtdSnapshots, adaptiveSnapshots, referenceSnapshots, ...
    actualSnapshotTimesForCaption);
metricsTable = [fdtdMetrics; lsdtdMetrics; adaptiveMetrics];

fig = local_plot_comparison(coarseGrid.x, coarseGrid.z, ...
    referenceSnapshots, fdtdSnapshots, lsdtdSnapshots, ...
    adaptiveSnapshots, opt.StencilHalfWidth, opt.ColorLimits);

if ~isempty(opt.FigurePrefix)
    figureBaseName = char(opt.FigurePrefix);
    matBaseName = figureBaseName;
    metricsBaseName = [figureBaseName, '_metrics'];
    parameterBaseName = [figureBaseName, '_parameters'];
elseif opt.IncludeFixedLSDTD
    figureBaseName = 'figure_2d_wavefield_fdtd_lsdtd_adaptive';
    matBaseName = 'wavefield_snapshots_three_methods';
    metricsBaseName = 'wavefield_snapshot_metrics';
    parameterBaseName = 'wavefield_comparison_parameters';
else
    figureBaseName = 'figure_2d_wavefield_fdtd_vs_adaptive';
    matBaseName = 'wavefield_snapshots_fdtd_vs_adaptive';
    metricsBaseName = 'wavefield_snapshot_metrics';
    parameterBaseName = 'wavefield_comparison_parameters';
end
pdfFile = fullfile(opt.OutputDir, [figureBaseName, '.pdf']);
emfFile = fullfile(opt.OutputDir, [figureBaseName, '.emf']);
figFile = fullfile(opt.OutputDir, [figureBaseName, '.fig']);
exportgraphics(fig, pdfFile, 'ContentType', 'vector');
exportgraphics(fig, emfFile, 'ContentType', 'vector');
savefig(fig, figFile);
close(fig);

metricsCsv = fullfile(opt.OutputDir, [metricsBaseName, '.csv']);
writetable(metricsTable, metricsCsv);

matFile = fullfile(opt.OutputDir, [matBaseName, '.mat']);
save(matFile, 'referenceSnapshots', 'fdtdSnapshots', ...
    'lsdtdSnapshots', 'adaptiveSnapshots', 'coarseGrid', 'fineGrid', ...
    'fixedLsdtdCoefficients', 'adaptiveCoefficients', ...
    'fixedLsdtdDefinition', ...
    'adaptiveCoeffGrid', 'epsrCoarse', 'epsrFine', ...
    'metricsTable', 'epsr', 'f0', 'fmax', 'maxVelocity', ...
    'minVelocity', 'referenceAlignment', 'displayDomainLength', ...
    'modelName', 'opt');

parameterFile = fullfile(opt.OutputDir, [parameterBaseName, '.txt']);
fid = fopen(parameterFile, 'w', 'n', 'UTF-8');
cleanup = onCleanup(@() fclose(fid));
if sourceResultLoaded
    fprintf(fid, 'source_result=%s\n', opt.ResultFile);
else
    fprintf(fid, 'source_result=none\n');
end
fprintf(fid, 'model=%s\n', modelName);
if isempty(opt.PermittivityModel)
    fprintf(fid, 'epsr_reference=%.12g\n', epsr);
elseif sourceResultLoaded
    fprintf(fid, 'source_result_epsr_metadata_unused=%.12g\n', epsr);
end
fprintf(fid, 'epsr_min=%.12g\n', min(epsrCoarse(:)));
fprintf(fid, 'epsr_max=%.12g\n', max(epsrCoarse(:)));
fprintf(fid, 'max_velocity_mps=%.12g\n', maxVelocity);
fprintf(fid, 'f0_hz=%.12g\n', f0);
fprintf(fid, 'fmax_hz=%.12g\n', fmax);
fprintf(fid, 'coarse_dx_m=%.12g\n', opt.CoarseDx);
fprintf(fid, 'reference_dx_m=%.12g\n', fineDx);
fprintf(fid, 'reference_to_coarse_ratio=%.12g\n', ...
    opt.CoarseDx/fineDx);
fprintf(fid, 'reference_alignment=%s\n', referenceAlignment);
fprintf(fid, 'reference_type=%.12g_m_fine_grid_FDTD_numerical_baseline\n', ...
    fineDx);
fprintf(fid, 'reference_not_claimed_as_analytic_solution=1\n');
if ~isempty(fineReferenceFile)
    fprintf(fid, 'fine_reference_cache_file=%s\n', fineReferenceFile);
end
fprintf(fid, 'dt_s=%.12g\n', opt.Dt);
fprintf(fid, 'domain_length_m=%.12g\n', opt.DomainLength);
fprintf(fid, 'display_domain_length_m=%.12g\n', displayDomainLength);
fprintf(fid, 'relative_mu_r=1\n');
fprintf(fid, 'conductivity_S_per_m=0\n');
fprintf(fid, 'source_wavelet=Ricker\n');
fprintf(fid, 'source_injection=additive_gaussian_Ey\n');
fprintf(fid, 'outer_boundary=zero_field_fixed_boundary\n');
fprintf(fid, ['boundary_handling=outer_grid_cells_are_not_updated; ', ...
    'central_display_window_used_for_metrics\n']);
fprintf(fid, 'source_sigma_m=%.12g\n', opt.SourceSigma);
fprintf(fid, 'source_position_xz_m=%.12g, %.12g\n', ...
    opt.SourcePosition);
fprintf(fid, 'source_peak_time_s=%.12g\n', sourcePeakTime);
fprintf(fid, 'snapshot_time_reference=%s\n', snapshotTimeReference);
fprintf(fid, 'snapshot_times_s=%s\n', ...
    strjoin(compose('%.12g', opt.SnapshotTimes), ', '));
fprintf(fid, 'simulation_snapshot_times_s=%s\n', ...
    strjoin(compose('%.12g', simulationSnapshotTimes), ', '));
fprintf(fid, 'actual_simulation_snapshot_times_s=%s\n', ...
    strjoin(compose('%.12g', actualSimulationSnapshotTimes), ', '));
fprintf(fid, 'actual_snapshot_times_for_caption_s=%s\n', ...
    strjoin(compose('%.12g', actualSnapshotTimesForCaption), ', '));
fprintf(fid, 'coarse_ppw_f0=%.12g\n', ...
    maxVelocity/(f0*opt.CoarseDx));
fprintf(fid, 'coarse_ppw_f0_at_epsr_min=%.12g\n', ...
    maxVelocity/(f0*opt.CoarseDx));
fprintf(fid, 'coarse_ppw_f0_at_epsr_max=%.12g\n', ...
    minVelocity/(f0*opt.CoarseDx));
fprintf(fid, 'coarse_ppw_fmax_at_epsr_max=%.12g\n', ...
    minVelocity/(fmax*opt.CoarseDx));
fprintf(fid, 'coarse_courant=%.12g\n', coarseCourant);
fprintf(fid, 'reference_courant=%.12g\n', fineCourant);
fprintf(fid, 'adaptive_use_angular_mapping=%d\n', ...
    opt.UseAngularMapping);
fprintf(fid, 'adaptive_use_wavelet_for_coefficients=%d\n', ...
    opt.UseWaveletForCoefficients);
fprintf(fid, 'adaptive_coefficient_regularization=%.12g\n', ...
    opt.CoefficientRegularization);
fprintf(fid, 'adaptive_epsr_samples=%s\n', ...
    strjoin(compose('%.12g', adaptive.epsrTable), ', '));
fprintf(fid, 'adaptive_stencil_half_width=%d\n', ...
    opt.StencilHalfWidth);
fprintf(fid, 'adaptive_stencil_points=%d\n', ...
    2*opt.StencilHalfWidth);
fprintf(fid, 'include_fixed_lsdtd=%d\n', opt.IncludeFixedLSDTD);
if opt.IncludeFixedLSDTD
    if isempty(opt.FixedLSDTDCoefficients)
        fprintf(fid, 'fixed_lsdtd_reference_epsr=%.12g\n', ...
            opt.FixedLSDTDReferenceEpsr);
    else
        fprintf(fid, 'fixed_lsdtd_reference_epsr=not_applicable\n');
    end
    fprintf(fid, 'fixed_lsdtd_coefficients=%s\n', ...
        strjoin(compose('%.12g', fixedLsdtdCoefficients), ', '));
    fprintf(fid, 'fixed_lsdtd_definition=%s\n', fixedLsdtdDefinition);
end
fprintf(fid, ['adaptive_magnetic_coefficient_interpolation=', ...
    'arithmetic_mean_adjacent_electric_nodes\n']);
fprintf(fid, 'display_color_limits=%.12g, %.12g\n', ...
    opt.ColorLimits);
fprintf(fid, 'adaptive_coefficients=%s\n', ...
    strjoin(compose('%.12g', adaptiveCoefficients), ', '));
clear cleanup;

if ~isempty(opt.FigurePrefix)
    captionFile = fullfile(opt.OutputDir, [char(opt.FigurePrefix), '_caption_zh.md']);
else
    captionFile = fullfile(opt.OutputDir, 'figure_caption_zh.md');
end
fid = fopen(captionFile, 'w', 'n', 'UTF-8');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# 图注建议\n\n');
if opt.SnapshotTimesRelativeToSourcePeak
    timeDescription = '子波峰值后';
else
    timeDescription = '计算起始后';
end
if opt.IncludeFixedLSDTD
    methodDescription = 'FDTD、固定系数LSDTD与Adaptive-LSDTD';
    methodCountDescription = '三种';
else
    methodDescription = 'FDTD与Adaptive-LSDTD';
    methodCountDescription = '两种';
end
fprintf(fid, ['%s二维正演波场对比。', ...
    'Ricker震源主频为%.0f MHz。', ...
    '每个子图的左半部分（X <= 0）显示正演波场，右半部分（X > 0）', ...
    '显示相对于%.3f m细网格FDTD数值基准的误差（不作为解析解）。', ...
    '%s粗网格方法采用', ...
    '相同的介质参数、空间网格、时间步长和Ricker震源，仅空间差分', ...
    '算子不同。各列分别对应%s%.0f、%.0f和%.0f ns；同一列采用', ...
    '相同的归一化因子和色标。粗网格间距为%.3f m，模型名称：%s。', ...
    '实际离散%s为%.2f、%.2f和%.2f ns。\n'], ...
    methodDescription, f0/1e6, fineDx, methodCountDescription, ...
    timeDescription, opt.SnapshotTimes*1e9, ...
    opt.CoarseDx, modelName, timeDescription, ...
    actualSnapshotTimesForCaption*1e9);
clear cleanup;

outputs = struct();
outputs.pdf = pdfFile;
outputs.emf = emfFile;
outputs.fig = figFile;
outputs.metricsCsv = metricsCsv;
outputs.mat = matFile;
outputs.parameters = parameterFile;
outputs.caption = captionFile;
outputs.metrics = metricsTable;
outputs.sourcePeakTime = sourcePeakTime;
outputs.simulationSnapshotTimes = simulationSnapshotTimes;
outputs.actualSimulationSnapshotTimes = actualSimulationSnapshotTimes;
outputs.actualSnapshotTimesForCaption = actualSnapshotTimesForCaption;
outputs.fixedLsdtdCoefficients = fixedLsdtdCoefficients;
outputs.fixedLsdtdDefinition = fixedLsdtdDefinition;
outputs.fineReferenceFile = fineReferenceFile;

fprintf('2-D wavefield comparison written to:\n%s\n', opt.OutputDir);
disp(metricsTable);
end

function [field, displayGrid] = local_crop_single_field( ...
        fieldFull, grid, displayDomainLength)
halfLength = displayDomainLength/2;
tolerance = 100*eps(max(1, halfLength));
xMask = abs(grid.x) <= halfLength + tolerance;
zMask = abs(grid.z) <= halfLength + tolerance;
field = fieldFull(zMask, xMask, :);
displayGrid = grid;
displayGrid.x = grid.x(xMask);
displayGrid.z = grid.z(zMask);
displayGrid.numGridPoints = numel(displayGrid.x);
end

function grid = local_make_grid(dx, domainLength)
numGridPoints = round(domainLength/dx) + 1;
grid = struct('x', linspace(-domainLength/2, domainLength/2, ...
    numGridPoints), 'z', linspace(-domainLength/2, domainLength/2, ...
    numGridPoints), 'dx', dx, 'numGridPoints', numGridPoints);
end

function [snapshots, grid] = local_run_2d_tm(dx, dt, numSteps, ...
        source, domainLength, sourceSigma, epsValue, muValue, ...
        coefficients, snapshotIndices, sourcePosition)
numGridPoints = round(domainLength/dx) + 1;
x = linspace(-domainLength/2, domainLength/2, numGridPoints);
z = x;
[X, Z] = meshgrid(x, z);
spatialSource = exp(-((X-sourcePosition(1)).^2 + ...
    (Z-sourcePosition(2)).^2)/(2*sourceSigma^2));

Ey = zeros(numGridPoints, numGridPoints);
Hx = zeros(numGridPoints, numGridPoints);
Hz = zeros(numGridPoints, numGridPoints);
snapshots = zeros(numGridPoints, numGridPoints, numel(snapshotIndices));

if isvector(coefficients)
    M = numel(coefficients);
    spatiallyAdaptive = false;
else
    if ndims(coefficients) ~= 3 || size(coefficients,1) ~= numGridPoints || ...
            size(coefficients,2) ~= numGridPoints
        error('Adaptive coefficient grid must have size [Nz, Nx, M].');
    end
    M = size(coefficients,3);
    spatiallyAdaptive = true;
end
zH = M:(numGridPoints-M);
xH = M:(numGridPoints-M);
zE = (M+1):(numGridPoints-M+1);
xE = (M+1):(numGridPoints-M+1);
magneticScale = dt/muValue;
if isscalar(epsValue)
    electricScale = dt/epsValue;
else
    if ~isequal(size(epsValue), [numGridPoints, numGridPoints])
        error('Permittivity grid must have size [Nz, Nx].');
    end
    electricScale = dt./epsValue;
end
if isscalar(electricScale)
    electricScaleInterior = electricScale;
else
    electricScaleInterior = electricScale(zE,xE);
end
snapshotNumber = 1;

for it = 1:numSteps
    dEyDz = zeros(numel(zH), numGridPoints);
    dEyDx = zeros(numGridPoints, numel(xH));
    for m = 1:M
        dEyDzTerm = (Ey(zH+m,:) - Ey(zH-m+1,:))/dx;
        dEyDxTerm = (Ey(:,xH+m) - Ey(:,xH-m+1))/dx;
        if spatiallyAdaptive
            coefficientAtHx = 0.5*(coefficients(zH,:,m) + ...
                coefficients(zH+1,:,m));
            coefficientAtHz = 0.5*(coefficients(:,xH,m) + ...
                coefficients(:,xH+1,m));
            dEyDz = dEyDz + coefficientAtHx.*dEyDzTerm;
            dEyDx = dEyDx + coefficientAtHz.*dEyDxTerm;
        else
            dEyDz = dEyDz + coefficients(m).*dEyDzTerm;
            dEyDx = dEyDx + coefficients(m).*dEyDxTerm;
        end
    end
    Hx(zH,:) = Hx(zH,:) + magneticScale*dEyDz;
    Hz(:,xH) = Hz(:,xH) - magneticScale*dEyDx;

    dHxDz = zeros(numel(zE), numel(xE));
    dHzDx = zeros(numel(zE), numel(xE));
    for m = 1:M
        dHxDzTerm = (Hx(zE+m-1,xE) - Hx(zE-m,xE))/dx;
        dHzDxTerm = (Hz(zE,xE+m-1) - Hz(zE,xE-m))/dx;
        if spatiallyAdaptive
            localCoefficients = coefficients(zE,xE,m);
            dHxDz = dHxDz + localCoefficients.*dHxDzTerm;
            dHzDx = dHzDx + localCoefficients.*dHzDxTerm;
        else
            dHxDz = dHxDz + coefficients(m).*dHxDzTerm;
            dHzDx = dHzDx + coefficients(m).*dHzDxTerm;
        end
    end
    Ey(zE,xE) = Ey(zE,xE) + electricScaleInterior .* ...
        (dHxDz - dHzDx);
    Ey = Ey + source(it)*spatialSource;

    if snapshotNumber <= numel(snapshotIndices) && ...
            it == snapshotIndices(snapshotNumber)
        snapshots(:,:,snapshotNumber) = Ey;
        snapshotNumber = snapshotNumber + 1;
    end
end

if snapshotNumber <= numel(snapshotIndices)
    error('Not all requested snapshots were recorded.');
end

grid = struct('x', x, 'z', z, 'dx', dx, ...
    'numGridPoints', numGridPoints);
end

function [reference, alignment] = local_align_reference( ...
        referenceFine, fineGrid, coarseGrid)
ratio = coarseGrid.dx/fineGrid.dx;
stride = round(ratio);
if abs(ratio-stride) <= 1e-10*max(1,abs(ratio))
    candidate = referenceFine(1:stride:end, 1:stride:end, :);
    if isequal(size(candidate,1), numel(coarseGrid.z)) && ...
            isequal(size(candidate,2), numel(coarseGrid.x))
        reference = candidate;
        alignment = 'direct_subsample';
        return;
    end
end

[Xq, Zq] = meshgrid(coarseGrid.x, coarseGrid.z);
reference = zeros(numel(coarseGrid.z), numel(coarseGrid.x), ...
    size(referenceFine,3), 'like', referenceFine);
for isnapshot = 1:size(referenceFine,3)
    reference(:,:,isnapshot) = interp2(fineGrid.x, fineGrid.z, ...
        referenceFine(:,:,isnapshot), Xq, Zq, 'linear');
end
if any(~isfinite(reference), 'all')
    error('Reference interpolation produced non-finite values.');
end
alignment = 'linear_interpolation';
end

function [reference, fdtd, lsdtd, adaptive, grid] = ...
        local_crop_to_display_window(reference, fdtd, lsdtd, adaptive, ...
        grid, displayDomainLength)
halfLength = displayDomainLength/2;
tolerance = 100*eps(max(1, halfLength));
xMask = abs(grid.x) <= halfLength + tolerance;
zMask = abs(grid.z) <= halfLength + tolerance;
if nnz(xMask) < 2 || nnz(zMask) < 2
    error('DisplayDomainLength does not contain enough grid points.');
end

reference = reference(zMask, xMask, :);
fdtd = fdtd(zMask, xMask, :);
if ~isempty(lsdtd)
    lsdtd = lsdtd(zMask, xMask, :);
end
adaptive = adaptive(zMask, xMask, :);
grid.x = grid.x(xMask);
grid.z = grid.z(zMask);
grid.numGridPoints = numel(grid.x);
end

function [fdtdTable, lsdtdTable, adaptiveTable] = ...
        local_snapshot_metrics(fdtd, lsdtd, adaptive, reference, ...
        snapshotTimes)
numSnapshots = size(reference,3);
fdtdNrmse = zeros(numSnapshots,1);
lsdtdNrmse = zeros(numSnapshots,1);
adaptiveNrmse = zeros(numSnapshots,1);
fdtdNcc = zeros(numSnapshots,1);
lsdtdNcc = zeros(numSnapshots,1);
adaptiveNcc = zeros(numSnapshots,1);

for is = 1:numSnapshots
    ref = reference(:,:,is);
    f = fdtd(:,:,is);
    if ~isempty(lsdtd)
        l = lsdtd(:,:,is);
        lsdtdNrmse(is) = 100*norm(l(:)-ref(:))/norm(ref(:));
        lsdtdNcc(is) = sum(l(:).*ref(:)) / ...
            sqrt(sum(l(:).^2)*sum(ref(:).^2));
    end
    a = adaptive(:,:,is);
    fdtdNrmse(is) = 100*norm(f(:)-ref(:))/norm(ref(:));
    adaptiveNrmse(is) = 100*norm(a(:)-ref(:))/norm(ref(:));
    fdtdNcc(is) = sum(f(:).*ref(:)) / ...
        sqrt(sum(f(:).^2)*sum(ref(:).^2));
    adaptiveNcc(is) = sum(a(:).*ref(:)) / ...
        sqrt(sum(a(:).^2)*sum(ref(:).^2));
end

snapshotTimeNs = snapshotTimes(:)*1e9;
method = repmat("FDTD", numSnapshots, 1);
ncc = fdtdNcc;
nrmsePercent = fdtdNrmse;
fdtdTable = table(method, snapshotTimeNs, ncc, nrmsePercent);

lsdtdTable = table();
if ~isempty(lsdtd)
    method = repmat("LSDTD", numSnapshots, 1);
    ncc = lsdtdNcc;
    nrmsePercent = lsdtdNrmse;
    lsdtdTable = table(method, snapshotTimeNs, ncc, nrmsePercent);
end

method = repmat("Adaptive-LSDTD", numSnapshots, 1);
ncc = adaptiveNcc;
nrmsePercent = adaptiveNrmse;
adaptiveTable = table(method, snapshotTimeNs, ncc, nrmsePercent);
end

function fig = local_plot_comparison(x, z, reference, fdtd, lsdtd, ...
        adaptive, stencilHalfWidth, colorLimits)
if isempty(lsdtd)
    fields = {fdtd, adaptive};
    methods = {{'FDTD'}, ...
        {'Adaptive-', 'LSDTD', sprintf('(M = %d)', stencilHalfWidth)}};
    figureHeight = 7.5;
    axesHeight = 0.30;
    rowBottom = [0.58, 0.22];
    colorbarBottom = 0.072;
else
    fields = {fdtd, lsdtd, adaptive};
    methods = {{'FDTD'}, ...
        {'LSDTD', sprintf('(M = %d)', stencilHalfWidth)}, ...
        {'Adaptive-', 'LSDTD', sprintf('(M = %d)', stencilHalfWidth)}};
    figureHeight = 10.5;
    axesHeight = 0.235;
    rowBottom = [0.710, 0.425, 0.140];
    colorbarBottom = 0.050;
end
numMethods = numel(fields);
fig = figure('Color', 'w', 'Units', 'inches', ...
    'Position', [1 1 9.5 figureHeight], 'Renderer', 'painters');

leftMargin = 0.20;
rightMargin = 0.035;
columnGap = 0.025;
axesWidth = (1-leftMargin-rightMargin-2*columnGap)/3;
map = local_diverging_colormap(257);

columnScale = zeros(1,3);
for ic = 1:3
    columnScale(ic) = max(abs(reference(:,:,ic)), [], 'all');
    for ir = 1:numMethods
        columnScale(ic) = max(columnScale(ic), ...
            max(abs(fields{ir}(:,:,ic)), [], 'all'));
    end
end

axesHandles = gobjects(numMethods,3);
for ir = 1:numMethods
    for ic = 1:3
        xPosition = leftMargin + (ic-1)*(axesWidth+columnGap);
        ax = axes(fig, 'Position', ...
            [xPosition rowBottom(ir) axesWidth axesHeight]);
        axesHandles(ir,ic) = ax;

        modeled = fields{ir}(:,:,ic);
        difference = modeled-reference(:,:,ic);
        composite = modeled;
        composite(:,x > 0) = difference(:,x > 0);
        composite = composite/columnScale(ic);

        imagesc(ax, x, z, composite);
        set(ax, 'YDir', 'reverse');
        axis(ax, 'image');
        xlim(ax, [x(1), x(end)]);
        ylim(ax, [z(1), z(end)]);
        clim(ax, colorLimits);
        colormap(ax, map);
        hold(ax, 'on');
        xline(ax, 0, '-', 'Color', [0.25 0.25 0.25], ...
            'LineWidth', 0.65);
        local_style_axis(ax);

        panelLabel = char(double('a') + (ir-1)*3 + ic-1);
        if ir < numMethods
            ax.XTickLabel = [];
        else
            xlabel(ax, 'X (m)', 'FontWeight', 'bold', ...
                'FontSize', 12, 'FontName', 'Times New Roman');
        end
        panelTitleText = sprintf('(%c)', panelLabel);
        panelTitle = title(ax, panelTitleText, ...
            'FontWeight', 'bold', 'FontSize', 14, ...
            'FontName', 'Times New Roman');
        panelTitle.Units = 'normalized';
        panelTitle.Position = [0.5, 1.04, 0];
        if ic == 1
            ylabel(ax, 'Z (m)', 'FontWeight', 'bold', ...
                'FontSize', 12, 'FontName', 'Times New Roman');
        else
            ax.YTickLabel = [];
        end
    end
end

for ir = 1:numMethods
    annotation(fig, 'textbox', ...
        [0.005, rowBottom(ir)+0.5*axesHeight-0.06, 0.16, 0.12], ...
        'String', methods{ir}, 'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontName', 'Times New Roman', 'FontSize', 14, ...
        'FontWeight', 'bold');
end

ic = 2;
xPosition = leftMargin + (ic-1)*(axesWidth+columnGap);
cb = colorbar(axesHandles(numMethods,ic), 'southoutside');
axesHandles(numMethods,ic).Position = ...
    [xPosition rowBottom(numMethods) axesWidth axesHeight];
cb.Position = [xPosition colorbarBottom axesWidth 0.022];
if all(abs(colorLimits-round(colorLimits)) < 1e-12)
    cb.Ticks = colorLimits(1):colorLimits(2);
else
    cb.Ticks = linspace(colorLimits(1), colorLimits(2), 5);
end
cb.FontName = 'Times New Roman';
cb.FontSize = 14;
cb.FontWeight = 'bold';
cb.TickDirection = 'out';
cb.Label.String = 'Normalized amplitude';
cb.Label.FontName = 'Times New Roman';
cb.Label.FontSize = 12;
cb.Label.FontWeight = 'bold';

end

function local_style_axis(ax)
set(ax, 'FontSize', 14, 'FontWeight', 'bold', ...
    'FontName', 'Times New Roman');
set(ax, 'XMinorGrid', 'on', 'YMinorGrid', 'on', ...
    'ZDir', 'reverse', 'ZMinorGrid', 'on');
ax.LineWidth = 0.65;
ax.Box = 'on';
ax.TickDir = 'out';
ax.XTick = [-6, -3, 0, 3, 6];
ax.YTick = [-6, -3, 0, 3, 6];
end

function map = local_diverging_colormap(numColors)
blue = [0.05 0.20 0.78];
white = [1 1 1];
red = [0.82 0.08 0.08];
lowerCount = ceil(numColors/2);
upperCount = numColors-lowerCount+1;
lower = [linspace(blue(1),white(1),lowerCount).', ...
    linspace(blue(2),white(2),lowerCount).', ...
    linspace(blue(3),white(3),lowerCount).'];
upper = [linspace(white(1),red(1),upperCount).', ...
    linspace(white(2),red(2),upperCount).', ...
    linspace(white(3),red(3),upperCount).'];
map = [lower; upper(2:end,:)];
end

function fmax = local_effective_fmax(wavelet, dt, energyFraction)
nfft = 2^nextpow2(max(numel(wavelet)*4, 256));
spectrum = abs(fft(wavelet(:), nfft)).^2;
nf = floor(nfft/2)+1;
spectrum = spectrum(1:nf);
frequency = (0:nf-1).'/(nfft*dt);
cumulativeEnergy = cumsum(spectrum)/sum(spectrum);
index = find(cumulativeEnergy >= energyFraction, 1, 'first');
fmax = frequency(index);
end
