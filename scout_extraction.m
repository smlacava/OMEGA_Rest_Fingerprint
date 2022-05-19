%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extracts scouts from sources files
% • Extracts scout time series for each ROI from each source file
% 
% INPUT:
% • sourceFiles is the cell array containing the structures related to
%   sources estimated from each subject's epoch (one cell per subject)
% • scout is the type of scouts which have to be considered
% • ROIs is the cell array containing the ROIs which have to be considered
% • inDir is the Brainstorm project directory
% • protocolName is the name of the protocol which will be used
% • outDir is the output directory in which scouts have to be saved
%
% OUTPUT:
% • scoutFiles is the cell array containing the structures related to
%   scout time series estimated from each subject's epoch (one cell per 
%   subject)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function scoutFiles = scout_extraction(sourceFiles, scout, ROIs, inDir, ...
    protocolName, outDir)
    
    scoutFiles = {};
    if nargin < 4
        inDir = '';
        outDir = '';
        protocolName = [];
    end
    outDir = strcat(outDir, filesep, protocolName);
    inDir = strcat(inDir, filesep, protocolName, filesep, 'data');
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
        if not(isempty(protocolName))
            for k = 1:length(aux)
                if k == 1
                    try
                        mkdir(strcat(outDir, filesep, ...
                            aux(k).SubjectName))
                        mkdir(strcat(outDir, filesep, ...
                            aux(i).SubjectName, filesep, ...
                            aux(k).Condition))
                    catch
                    end
                    descName = strcat(outDir, filesep, 'Description.mat');
                    if not(exist(descName, 'file'))
                        load(strcat(inDir, filesep, aux(k).FileName), ...
                            'Description')
                        save(descName, 'Description')
                    end
                end
                vars = rmfield(load(strcat(inDir, filesep, ...
                    aux(k).FileName)), {'Std', 'Time', 'nAvg', 'Leff', ...
                    'Events', 'Atlas', 'History', 'DisplayUnits', ...
                    'ChannelFlag', 'Description'});
                save(strcat(outDir, filesep, aux(k).FileName), ...
                    '-struct', 'vars');
                delete(strcat(inDir, filesep, aux(k).FileName));

            end
        end
        if nargout > 0
            scoutFiles = [scoutFiles, aux];
        end
    end
end