%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extracts scouts from reprojected sources
% • Extracts scout time series for each ROI from each reprojected source 
%   file
% 
% INPUT:
% • sourceFiles is the cell array containing the structures related to
%   sources estimated from each subject's epoch (one cell per subject)
% • scout is the type of scouts which have to be considered
% • ROIs is the cell array containing the ROIs which have to be considered
% • srcSubject is the subject from which sources have to be projected
% • epTime is the time of each epoch
% • iStudy is the number of operations performed on the Brainstorm protocol
%   (optional)
%
% OUTPUT:
% • projectedScoutFiles is the cell array containing the structures related
%   to reprojected scout time series estimated from each subject's epoch 
%   (one cell per subject)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function projectedScoutFiles = ...
    scout_extraction_reprojected(sourceFiles, scout, ROIs, srcSubject, ...
    epTime, inDir, protocolName, outDir, iStudy)
    if nargin < 9
        iStudy = 100;
    end
    if nargin < 6
        inDir = '';
        outDir = '';
        protocolName = [];
    end
    outDir = strcat(outDir, filesep, protocolName);
    inDir = strcat(inDir, filesep, protocolName, filesep, 'data');
    sProcess = struct();
    sProcess.Function = @process_extract_scout;
    sProcess.Comment = 'Scouts time series';
    sProcess.FileTag = '';
    sProcess.Description = ...
        'https://neuroimage.usc.edu/brainstorm/Tutorials/Scouts';
    sProcess.Category = 'Custom';
    sProcess.SubGroup = 'Extract';
    sProcess.Index = 352;
    sProcess.isSeparator = 0;
    sProcess.InputTypes = {'results', 'timefreq'};
    sProcess.OutputTypes = {'matrix', 'matrix'};
    sProcess.nInputs = 1;
    sProcess.nOutputs = 1;
    sProcess.nMinFiles = 1;
    sProcess.isPaired = 0;
    sProcess.isSourceAbsolute = 0;
    sProcess.processDim = [];

    sProcess.options = struct();
    sProcess.options.timewindow = struct();
    sProcess.options.scouts = struct();
    sProcess.options.scoutfunc = struct();
    sProcess.options.isflip = struct();
    sProcess.options.isnorm = struct();
    sProcess.options.concatenate = struct();
    sProcess.options.save = struct();
    sProcess.options.addrowcomment = struct();
    sProcess.options.addfilecomment = struct();

    sProcess.options.timewindow.Comment = 'Time window:';
    sProcess.options.timewindow.Type = 'timewindow';
    sProcess.options.timewindow.Value = {[], 's', []};

    sProcess.options.scouts.Comment = '';
    sProcess.options.scouts.Type = 'scout';
    sProcess.options.scouts.Value = {scout, ROIs};

    sProcess.options.scoutfunc.Comment = {'Mean', 'Max', 'PCA', 'Std', ...
        'All', 'Scout function:'};
    sProcess.options.scoutfunc.Type = 'radio_line';
    sProcess.options.scoutfunc.Value = 1;
    
    sProcess.options.isflip.Comment = ...
        'Flip the sign of sources with opposite directions';
    sProcess.options.isflip.Type = 'checkbox';
    sProcess.options.isflip.Value = 1;
    sProcess.options.isflip.InputTypes = {'results'};

    sProcess.options.isnorm.Comment = ...
        'Unconstrained sources: Norm of the three orientations (x,y,z)';
    sProcess.options.isnorm.Type = 'checkbox';
    sProcess.options.isnorm.Value = 0;
    sProcess.options.isnorm.InputTypes = 'results';

    sProcess.options.concatenate.Comment = ...
        'Concatenate output in one unique matrix';
    sProcess.options.concatenate.Type = 'checkbox';
    sProcess.options.concatenate.Value = 1;

    sProcess.options.save.Comment = '';
    sProcess.options.save.Type = 'ignore';
    sProcess.options.save.Value = 1;

    sProcess.options.addrowcomment.Comment = '';
    sProcess.options.addrowcomment.Type = 'ignore';
    sProcess.options.addrowcomment.Value = 1;

    sProcess.options.addfilecomment.Comment = '';
    sProcess.options.addfilecomment.Type = 'ignore';
    sProcess.options.addfilecomment.Value = 1;
    
    sInputs = struct();
    sInputs.iStudy = iStudy+1;
    sInputs.iItem = 1;
    sInputs.FileType = 'results';
    sInputs.DataFile = [];
    sInputs.ChannelFile = [];
    sInputs.ChannelTypes = [];
    projectedScoutFiles = {};
    L = length(sourceFiles);
    for i = 1:L
        auxFiles = sourceFiles{i};
        name = split(string(auxFiles{1}), '/');
        if length(name) == 1
            name = split(auxFiles, '\');
        end
        sInputs.SubjectName = char(name(1));
        sInputs.SubjectFile = char(strcat(name(1), filesep, ...
            'brainstormsubject.mat'));
        sInputs.Condition = char(name(2));
        subFiles = {};
        for j = 1:length(auxFiles)
            sInputs.iStudy=sInputs.iStudy+1;
            sInputs.Comment = char(strcat(srcSubject, '/Raw (', ...
                string((j-1)*epTime), '.00s,', string(j*epTime), '.00s)'));
            sInputs.FileName = auxFiles{j};
            subFiles = [subFiles, ...
                bst_process('Run', sProcess, sInputs, [], 1)];
            %delete(strcat(inDir, filesep, auxFiles{j}));
        end
        nSub = length(subFiles);
        if not(isempty(protocolName))
            for k = 1:nSub
                if k == 1
                    try
                        mkdir(strcat(outDir, filesep, ...
                            subFiles{k}.SubjectName))
                        mkdir(strcat(outDir, filesep, ...
                            subFiles{k}.SubjectName, filesep, ...
                            subFiles{k}.Condition))
                    catch
                    end
                end
                copyfile(strcat(inDir, filesep, subFiles{k}.FileName), ...
                    strcat(outDir, filesep, subFiles{k}.FileName));
                delete(strcat(inDir, filesep, subFiles{k}.FileName));
            end
        end
        if nargout > 0
            projectedScoutFiles = [projectedScoutFiles, subFiles];
        end
    end
    N = length(sourceFiles);
    M = length(sourceFiles{1});
    for i = 1:N
        for j = 1:M
            delete(strcat(inDir, filesep, sourceFiles{i}{j}))
        end
    end
end