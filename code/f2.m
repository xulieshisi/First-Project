function result = f2(varargin)
%F2 Reproduce Figure 2 (200 MHz wavefield comparison).
addpath(fileparts(mfilename('fullpath')));
result = figure2_200MHz(varargin{:});
end
