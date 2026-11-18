function figure4_saved()
%FIGURE4_SAVED Run the previously registered project Figure 4 plot.
% Original entry: LSDTD-RTM图4.m (2026-10-12).

codeRoot = fileparts(mfilename('fullpath'));
projectRoot = fileparts(codeRoot);
addpath(codeRoot);
cd(projectRoot);
plot_figure5_matlab_white();
end
