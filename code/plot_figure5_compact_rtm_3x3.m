% Project Figure 5 plotting entry point: compact 3-by-3 RTM comparison.
% Reuses the verified MATLAB reconstruction pipeline, then records the
% compact editable deliverables under outputs/f5. No reference bitmap or
% Python post-processing is required for the GitHub release.

codeDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(codeDir);
cd(projectDir);
run(fullfile(codeDir, 'reproduce_clipboard_figure_matlab.m'));

% The reproduction pipeline returns with the project root as the current
% folder and writes the editable figure, EMF, and preview PNG here.
sourceDir = fullfile(pwd, 'outputs', 'attached_figure_matlab');
outputDir = fullfile(pwd, 'outputs', 'f5');
if ~isfolder(outputDir)
    mkdir(outputDir);
end

formats = {'fig','emf','pdf'};
sourceStem = 'clipboard_figure_matlab';
outputStem = 'f5';
for k = 1:numel(formats)
    ext = formats{k};
    sourceFile = fullfile(sourceDir, [sourceStem '.' ext]);
    outputFile = fullfile(outputDir, [outputStem '.' ext]);
    if ~isfile(sourceFile)
        error('Expected output was not produced: %s', sourceFile);
    end
    copyfile(sourceFile, outputFile, 'f');
end
% The reconstruction folder is only an intermediate staging area.
if isfolder(sourceDir)
    rmdir(sourceDir, 's');
end

fprintf('Figure 5 plotting files saved in:\n%s\n', outputDir);
