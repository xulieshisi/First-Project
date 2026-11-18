function f5()
%F5 Reproduce the compact 3-by-3 RTM comparison for Figure 5.
% The final compact layout is shown in MATLAB and saved under outputs/f5.
% It uses the included RTM volumes and does not read a reference image.
addpath(fileparts(mfilename('fullpath')));
run(fullfile(fileparts(mfilename('fullpath')), ...
    'plot_figure5_compact_rtm_3x3.m'));
end
