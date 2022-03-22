%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Projects sources of a subject to the cortex of another subject
% • Projects sources from each epochs of a chosen subject (srcSubject) onto
%   cortices of other subjects
%
% INPUT:
% • files is the cell array containing the structures related to source
%   sources estimated from each subject's epoch (one cell per subject), or
%   the array of structures containing the M/EEG files related to each
%   subject
% • srcSubject is the subject from which sources have to be projected
% • bsDir is the directory containing the Brainstorm protocols
% • ProtocolName is the name of the protocol which will be used
%
% OUTPUT:
% • newSourceFiles is the cell array containing the names of the files
%   containing the projected sources (one cell per subject)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function newSourceFiles = sources_projection(subFiles, srcSubject, ...
    bsDir, ProtocolName, condition, srcType)
    if nargin < 5
        condition = '_ses-01_task-rest_run-01_meg_notch_high';
    end
    if nargin < 6
        srcType = "";
    end
    
    dirFiles = dir(strcat(bsDir, filesep, ProtocolName, filesep, ...
        'data', filesep, srcSubject, filesep, srcSubject, condition));
    res = {};
    for i = 1:length(dirFiles)
        if contains(string(dirFiles(i).name), "results") && ...
                contains(string(dirFiles(i).name), srcType)
            res = [res, strcat(srcSubject, filesep, srcSubject, ...
                    condition, filesep, dirFiles(i).name)];
        end
    end
    newSourceFiles = {};
    N = length(res);
    for i = 1:length(subFiles)
        if iscell(subFiles)
            aux = subFiles{i};
        else
            aux = subFiles(i);
        end
        if strcmpi(string(aux(1).SubjectName), string(srcSubject))
            continue;
        end
        auxProjected = {};
        for j = 1:N
            destSurfFile = strcat(aux(1).SubjectName, filesep, ...
                'tess_cortex_pial_low.mat');
            auxProjected = [auxProjected, ...
                bst_project_sources({res{j}}, destSurfFile)];
        end
        newSourceFiles = [newSourceFiles, {auxProjected}];
    end
end
