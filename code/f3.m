function result = f3(varargin)
%F3 Reproduce Figure 3 (300 MHz wavefield comparison).
addpath(fileparts(mfilename('fullpath')));
result = figure3_300MHz(varargin{:});
end
