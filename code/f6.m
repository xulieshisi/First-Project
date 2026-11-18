function f6()
%F6 Reproduce the current Figure 6 panels.
codeDir = fileparts(mfilename('fullpath'));
addpath(codeDir);
figure6_latest();
end
