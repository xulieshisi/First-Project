function run_all_figures(varargin)
%RUN_ALL_FIGURES Run the figure workflows with a low-memory default.
ip = inputParser;
ip.addParameter('RunLargeFigures', false, @(x)islogical(x) || (isnumeric(x) && isscalar(x)));
ip.parse(varargin{:});
packageRoot = fileparts(mfilename('fullpath'));
codeRoot = fullfile(packageRoot, 'code');
addpath(codeRoot);
f2('Recompute', false);
f3('Recompute', false);
if logical(ip.Results.RunLargeFigures)
    f4();
    f5();
    f6();
else
    fprintf(['Figures 4-6 skipped by the low-memory default. The required ', ...
        'data are included; run them one at a time or use ', ...
        'run_all_figures(''RunLargeFigures'',true) if enough memory is available.\n']);
end
end
