function figure5_saved()
%FIGURE5_SAVED Run the previously registered project Figure 5 plot.
% Original entry: LSDTD-RTM图5.m (2026-10-30).

projectRoot = fileparts(fileparts(mfilename('fullpath')));
cd(projectRoot);
codeRoot = fullfile(projectRoot, 'code');
addpath(codeRoot);
run(fullfile(codeRoot, 'plot_figure5_compact_rtm_3x3.m'));
end
