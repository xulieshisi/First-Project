function figure6_latest()
%FIGURE6_LATEST Create the current Figure 6 panels.
packageRoot = fileparts(fileparts(mfilename('fullpath')));
outDir = fullfile(packageRoot, 'outputs');
if ~isfolder(outDir), mkdir(outDir); end

dataDir = fullfile(packageRoot, 'data');
required = {'herten_m2_ds0p1000.mat', 'herten_m3_ds0p1000.mat', ...
    'herten_case_ds0p1000.mat'};
if ~all(cellfun(@(n)isfile(fullfile(dataDir, n)), required))
    fprintf(['Figure 6 skipped: place the Herten result files listed in ', ...
        'data/manifest.csv first.\n']);
    return;
end

f6_1('ResultDir', dataDir, ...
    'OutputDir', fullfile(outDir, 'f6_1'), 'SliceX', 14.0, ...
    'TargetY', 7.5);
f6_2('ResultDir', dataDir, ...
    'OutputDir', fullfile(outDir, 'f6_2'));
end
