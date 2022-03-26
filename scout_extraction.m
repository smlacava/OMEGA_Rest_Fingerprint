%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extracts scouts from sources files
% • Extracts scout time series for each ROI from each source file
% 
% INPUT:
% • sourceFiles is the cell array containing the structures related to
%   sources estimated from each subject's epoch (one cell per subject)
% • scout is the type of scouts which have to be considered
% • ROIs is the cell array containing the ROIs which have to be considered
%
% OUTPUT:
% • scoutFiles is the cell array containing the structures related to
%   scout time series estimated from each subject's epoch (one cell per 
%   subject)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function scoutFiles = scout_extraction(sourceFiles, scout, ROIs)
    scoutFiles = {};
    for i = 1:length(sourceFiles)
        aux = [];
        auxSourceFiles = sourceFiles{i};
        for j = 1:length(sourceFiles{i})
            aux = [aux, bst_process('CallProcess', ...
                'process_extract_scout', auxSourceFiles(j), [], ...
                'timewindow', [], 'scouts', {scout, ROIs}, ...
                'scoutfunc', 1, 'isflip', 1, 'isnorm', 0, ...
                'concatenate', 1, 'save', 1, 'addrowcomment', 1, ...
                'addfilecomment', 1)];
        end
        scoutFiles = [scoutFiles, aux];
    end
end