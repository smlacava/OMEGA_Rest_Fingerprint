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
% • condition identifies the folder of preprocessed data
% • srcType is the type of source estimation measure
%
% OUTPUT:
% • newSourceFiles is the cell array containing the names of the files
%   containing the projected sources (one cell per subject)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function newSourceFiles = sources_projection(subFiles, srcSubject, ...
    bsDir, ProtocolName, condition, srcType)
    if nargin < 5 
        condition = [];
    end
    if nargin < 6
        srcType = "";
    end

    if contains(string(srcType), "dspm")
        measure = 'dSPM';
    elseif contains(string(srcType), "sloreta")
        measure = 'sLORETA';
    else
        measure = 'MN';
    end
    subDir = strcat(bsDir, filesep, ProtocolName, filesep, ...
        'data', filesep, srcSubject);

    % Searches for imported (i.e., non raw) data directories
    if isempty(condition)
        dirFiles = dir(subDir);
        auxN = length(srcSubject)+1;
        for i = 1:length(dirFiles)
            if not(contains(string(dirFiles(i).name), "@")) && ...
                    contains(string(dirFiles(i).name), string(srcSubject))
                condition = dirFiles(i).name(auxN:end);
                break;
            end
        end
    end
    dirFiles = dir(strcat(subDir, filesep, srcSubject, condition));
    res = {};
    for i = 1:length(dirFiles)
        % Searches for projectable sources (the ones computed on the
        % average are not projectable), avoiding doplicates from multiple
        % trials
        if contains(string(dirFiles(i).name), "results") && ...
                contains(string(dirFiles(i).name), string(measure)) && ...
                not(contains(dirFiles(i).date, 'mar-2022'))
            fname = strcat(dirFiles(i).folder, filesep, dirFiles(i).name);
            clear DataFile
            load(fname, 'DataFile') 
            if not(isempty(DataFile))
                res = [res, strcat(srcSubject, filesep, srcSubject, ...
                    condition, filesep, dirFiles(i).name)];
            end
        end
    end
    newSourceFiles = {};
    N = length(res);
    for i = 1:length(subFiles)
        if iscell(subFiles) % Compatibility across different versions
            aux = subFiles{i};
        else
            aux = subFiles(i);
        end
        if strcmpi(string(aux(i).SubjectName), string(srcSubject))
            continue;
        end
        auxProjected = {};
        for j = 1:N
            destSurfFile = strcat(aux(i).SubjectName, filesep, ...
                'tess_cortex_pial_low.mat');
            auxProjected = [auxProjected, ...
                bst_project_sources({res{j}}, destSurfFile)];
        end
        newSourceFiles = [newSourceFiles, {auxProjected}];
    end

    %% Remotion of original sources when they are no more useful
    N = length(res);
    for i = 1:N
        delete(strcat(bsDir, filesep, ProtocolName, filesep, 'data', ...
            filesep, res{i}))
    end
end
