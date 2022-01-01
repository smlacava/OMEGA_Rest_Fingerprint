%% PIPELINE
% 1) Data is imported
% 2) Data is preprocessed (notch and high-pass filtered at 0.3 Hz, cleaned
%    from ECG artifacts
% 3) Preprocessed data is resampled and divided into epochs
% 4) Sources are estimated from each epoch
% 5) Scouts are extracted from such sources
% 6) Sources are reprojected from a subject onto other subject's cortices
% 7) Scouts are extracted from reprojected sources

bsDir = 'C:\Users\simon\OneDrive\Desktop\Ricerca\EEGLab\';
inDir = 'D:\MEG\OMEGA_OpenNeuro';
ProtocolName = 'Omega_Study';
epTime = 15;
nEpochs = 5;
resample = 240;
EventsTimeRange = [-0.1, 3];
srcSubject = 'sub-0002';

scout = 'Desikan-Killiany';
ROIs = {'bankssts L','bankssts R','caudalanteriorcingulate L',...
        'caudalanteriorcingulate R','caudalmiddlefrontal L',...
        'caudalmiddlefrontal R','cuneus L','cuneus R',...
        'entorhinal L','entorhinal R','frontalpole L','frontalpole R',...
        'fusiform L','fusiform R','inferiorparietal L',...
        'inferiorparietal R','inferiortemporal L','inferiortemporal R',...
        'insula L','insula R','isthmuscingulate L',...
        'isthmuscingulate R','lateraloccipital L','lateraloccipital R',...
        'lateralorbitofrontal L','lateralorbitofrontal R','lingual L',...
        'lingual R','medialorbitofrontal L','medialorbitofrontal R',...
        'middletemporal L','middletemporal R','paracentral L',...
        'paracentral R','parahippocampal L','parahippocampal R',...
        'parsopercularis L','parsopercularis R','parsorbitalis L',...
        'parsorbitalis R','parstriangularis L','parstriangularis R',...
        'pericalcarine L','pericalcarine R','postcentral L',...
        'postcentral R','posteriorcingulate L','posteriorcingulate R',...
        'precentral L','precentral R','precuneus L','precuneus R',...
        'rostralanteriorcingulate L','rostralanteriorcingulate R',...
        'rostralmiddlefrontal L','rostralmiddlefrontal R',...
        'superiorfrontal L','superiorfrontal R','superiorparietal L',...
        'superiorparietal R','superiortemporal L','superiortemporal R',...
        'supramarginal L','supramarginal R','temporalpole L',...
        'temporalpole R','transversetemporal L','transversetemporal R'};

[rawFiles, fs, t] = initialization(ProtocolName, inDir, bsDir, epTime, ...
    nEpochs, resample);
filtFiles = preprocessing(rawFiles);
cleanFiles = artifact_cleaning();
importFiles = import_raws(cleanFiles, t, epTime, EventsTimeRange, fs, ...
    nEpochs);
sourceFiles = source_estimation(importFiles);
scoutFiles = scout_extraction(sourceFiles, scout, ROIs);
newSourceFiles = sources_projection(sourceFiles, srcSubject, bsDir, ...
    ProtocolName);
projectedScoutFiles = scout_extraction_reprojected(newSourceFiles, ...
    scout, ROIs, srcSubject, epTime);
%psdSourcesFiles = power_maps(sourceFiles);
disp(1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Sets the protocol, loads M/EEGs, and estimates time-frequency parameters
% • Initializes brainstorm without GUI
% • Deletes previous protocol with the same name (ProtocolName)
% • Creates the protocol (bsDir\ProtocolName)
% • Imports data stored in inDir
% • Computes the minimum sampling frequency value among the ones related to
%   the imported files and the input sampling frequency (resample)
% • Find the minimum time window among the ones related to the imported
%   files and the one equal to the input number of epochs (epTime*nEpochs)
% • Returns the structures related to the imported files (rawFiles), the
%   minimum resampling frequency (fs) and the minimum time window (t)
%
% INPUT:
% • ProtocolName is the name of the protocol which will be used
% • inDir is the path to the data files
% • bsDir is the directory containing the Brainstorm protocols
% • epTime is the time related to each epoch
% • nEpochs is the required number of epochs (if available in all the
%   files)
% • resample is the resampling frequency (if lower to the ones related to
%   the input files)
%
% OUTPUT:
% • rawFiles is the array of structures related to the imported files
% • fs is the resampling frequency (for external uses)
% • t is the time window (for external uses)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [rawFiles, fs, t] = initialization(ProtocolName, inDir, bsDir, ...
    epTime, nEpochs, resample)
    if ~brainstorm('status')
        brainstorm nogui
    end
    try
        gui_brainstorm('DeleteProtocol', ProtocolName);
    catch
    end
    gui_brainstorm('CreateProtocol', ProtocolName, 0, 0);
    bst_report('Start');
    rawFiles = bst_process('CallProcess', 'process_import_bids', [], ...
        [], 'bidsdir', {inDir, 'BIDS'}, 'nvertices', 15000, ...
        'channelalign', 0);
    t = epTime*nEpochs;
    fs = resample;
    for i = 1:length(rawFiles)
        if contains(string(rawFiles(i).FileName), "sub-0")
            load(strcat(bsDir, filesep, ProtocolName, filesep, 'data', ...
                filesep, rawFiles(i).FileName))
            fs = min([F.prop.sfreq, fs]);
            t = min([t, F.header.gSetUp.epoch_time]);
        end
    end
    t = floor(t/epTime)*epTime;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initial preprocessing required in OMEGA
% • Adjusts headpoints
% • Converts to continuous
% • Filters files with a notch filter and a high-pass filter at 0.3 Hz
% • Deletes unfiltered files
% • Returns filtered files
%
% INPUT:
% • rawFiles is the array of structures related to the imported files
%
% OUTPUT:
% • filtFiles is the array of structures related to the filtered files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function filtFiles = preprocessing(rawFiles)
    rawFiles = bst_process('CallProcess', 'process_headpoints_remove', ...
        rawFiles, [], 'zlimit', 0);
    bst_process('CallProcess', 'process_headpoints_refine', ...
        rawFiles, []);
    rawFiles = bst_process('CallProcess', 'process_ctf_convert', ...
        rawFiles, [], 'rectype', 2);
    filtFiles = filter(rawFiles);
    bst_process('CallProcess', 'process_delete', [rawFiles], [], ...
        'target', 2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Filters a time window through a notch filter and a highpass filter
% • Filters files with a notch filter to 60 Hz (and multipliers)
% • Filters files with a high-pass filter at 0.3 Hz
%
% INPUT:
% • rawFiles is the array of structures related to the imported files
%
% OUTPUT:
% • filtered is the array of structures related to the filtered files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function filtered = filter(rawFiles)
    aux = bst_process('CallProcess', 'process_notch', rawFiles, [], ...
        'freqlist', [60, 120, 180, 240, 300], 'sensortypes', ...
        'MEG, EEG', 'read_all', 1);

    filtered = bst_process('CallProcess', 'process_bandpass', aux, [], ...
        'sensortypes', 'MEG, EEG', 'highpass', 0.3, 'lowpass', 0, ...
        'attenuation', 'strict', 'mirror',  0, 'useold', 0, 'read_all', 1);
    bst_process('CallProcess', 'process_delete', [aux], [], 'target', 2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Removes ECG artifacts
% • Clears ECG-related artifacts
%
% OUTPUT:
% • cleanFiles is the array containing structures related to cleaned files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function cleanFiles = artifact_cleaning()
    filtered = bst_process('CallProcess', 'process_select_files_data', ...
        [], [], 'subjectname', 'All');
    cleanFiles = bst_process('CallProcess', 'process_select_tag', ...
        filtered, [], 'tag', 'task-rest', 'search', 1, 'select', 1); 
    bst_process('CallProcess', 'process_evt_detect_ecg', cleanFiles, ...
        [], 'channelname', 'ECG', 'timewindow', [], 'eventname', ...
        'cardiac');
    bst_process('CallProcess', 'process_ssp_ecg', cleanFiles, [], ...
        'eventname', 'cardiac', 'sensortypes', 'MEG', 'usessp', 1, ...
        'select', 1);
    bst_process('CallProcess', 'process_snapshot', cleanFiles, [], ...
        'target', 1, 'modality', 1, 'orient', 1);
    bst_process('CallProcess', 'process_snapshot', cleanFiles, [], ...
        'target', 2, 'modality', 1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Imports time windows from each subject's M/EEG
% • Imports into database a resampled time window (t resampled to resample)
%   divided into epochs (nEpochs) from files
%
% INPUT:
% • files is the array of structures related to data files which have to be
%   processed
% • t is the time window which has to be extracted from each file
% • epTime is the time of each epoch
% • EventsTimeRange is the time range of events (set in database)
% • resample is the resampling frequency
% • nEpochs is the total number of epochs
%
% OUTPUT:
% • importFiles is the cell array containing the structures related to
%   epochs of each subject (one cell per subject)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function importFiles = import_raws(files, t, epTime, EventsTimeRange, ...
    resample, nEpochs)
    N = length(files);
    TimeRange = [0, t];
    importFiles = {};
    data = struct();
    data.iStudy = files(1).iStudy+N;
    data.item = 0;
    data.FileName = '';
    data.FileType = 'data';
    data.Comment = '';
    data.Condition = '';
    data.SubjectFile = '';
    data.SubjectName = '';
    data.DataFile = [];
    data.ChannelFile = '';
    data.ChannelTypes = {};
    for i = 1:N
        auxFiles = import_raw_brainstorm(files(i).FileName, TimeRange, ...
            epTime, EventsTimeRange, resample, nEpochs);
        subFiles = [];
        data.iStudy = data.iStudy+i;
        data.Condition = split(string(files(i).Condition), "@raw");
        data.Condition = char(data.Condition(2));
        data.ChannelTypes = files(i).ChannelTypes;
        data.SubjectFile = files(i).SubjectFile;
        data.ChannelFile = split(string(files(i).ChannelFile), "@raw");
        data.ChannelFile = char(strcat(data.ChannelFile(1), ...
            data.ChannelFile(2)));
        data.SubjectName = files(i).SubjectName;
        M = min([nEpochs, length(auxFiles)]);
        for j = 1:M
            data.item = j;
            block = string(j);
            if length(char(block)) == 1
                block = strcat("00", block);
            elseif length(char(block)) == 2
                block = strcat("0", block);
            end
            data.FileName = char(strcat(data.SubjectName, filesep, ...
                data.SubjectName, ...
                "_ses-01_task-rest_run-01_meg_notch_high", filesep, ...
                "data_block", block, ".mat"));
            data.Comment = char(strcat("Raw (", string(epTime*(j-1)), ...
                ".00s,", string(epTime*j), ".00s)"));
            subFiles = [subFiles, data];
        end
        importFiles = [importFiles, subFiles];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Estimates noise covariance, head model and sources from each time window
% • Estimates noise covariance for each subject
% • Computes head model for each subject
% • Estimates sources from each epoch of each subject
% • Returns structures related to the estimated sources
%
% INPUT:
% • importFiles is the cell array containing the structures related to
%   epochs of each subject (one cell per subject)
%
% OUTPUT:
% • sourceFiles is the cell array containing the structures related to
%   sources estimated from each subject's epoch (one cell per subject)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sourceFiles = source_estimation(importFiles)
    sourceFiles = {};
    for i = 1:length(importFiles)
        bst_process('CallProcess', 'process_noisecov', importFiles{i}, ...
            [], 'baseline', [], 'sensortypes', 'MEG', 'target', 1, ... 
            'dcoffset', 1, 'identity', 0, 'copycond', 1, 'copysubj', 1, ...
            'copymatch', 1, 'replacefile', 1);
        bst_process('CallProcess', 'process_headmodel', ...
            importFiles{i}, [], 'sourcespace', 1, 'meg', 3);
        sourceFiles = [sourceFiles, bst_process('CallProcess',...
            'process_inverse_2018', importFiles{i}, [], 'output', 2, ...
            'inverse', struct('Comment', 'dSPM: MEG', 'InverseMethod', ...
            'minnorm',  'InverseMeasure', 'dspm2018', 'SourceOrient', ...
            {{'fixed'}}, 'Loose', 0.2, 'UseDepth', 1, 'WeightExp', 0.5, ...
            'WeightLimit', 10, 'NoiseMethod', 'reg', 'NoiseReg', 0.1, ...
            'SnrMethod', 'fixed', 'SnrRms', 1e-06, 'SnrFixed', 3, ...
            'ComputeKernel', 1, 'DataTypes', {{'MEG'}}))];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Projects sources of a subject to the cortex of another subject
% • Projects sources from each epochs of a chosen subject (srcSubject) onto
%   cortices of other subjects
%
% INPUT:
% • sourceFiles is the cell array containing the structures related to
%   sources estimated from each subject's epoch (one cell per subject)
% • srcSubject is the subject from which sources have to be projected
% • bsDir is the directory containing the Brainstorm protocols
% • ProtocolName is the name of the protocol which will be used
%
% OUTPUT:
% • newSourceFiles is the cell array containing the names of the files
%   containing the projected sources (one cell per subject)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function newSourceFiles = sources_projection(sourceFiles, srcSubject, ...
    bsDir, ProtocolName)
    
    files = dir(strcat(bsDir, filesep, ProtocolName, filesep, 'data', ...
        filesep, srcSubject, filesep, srcSubject, ...
        '_ses-01_task-rest_run-01_meg_notch_high'));
    res = {};
    for i = 1:length(files)
        if contains(string(files(i).name), "results")
            res = [res, strcat(srcSubject, filesep, srcSubject, ...
                    '_ses-01_task-rest_run-01_meg_notch_high', filesep, ...
                    files(i).name)];
        end
    end
    newSourceFiles = {};
    N = length(res);
    for i = 1:length(sourceFiles)
        aux = sourceFiles{i};
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute power maps (NOT USED)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function psdSourcesFiles = power_maps(sourceFiles)
    freqs = {{'delta', '2, 4', 'mean'; 'theta', '5, 7', 'mean'; ...
        'alpha', '8, 12', 'mean'; 'beta', '15, 29', 'mean'; 'gamma1', ...
        '30, 59', 'mean'; 'gamma2', '60, 90', 'mean'}};

    psdFiles = bst_process('CallProcess', 'process_psd', ...
        sourceFiles, [], 'timewindow', [0, 100], 'win_length',  4, ...
        'win_overlap', 50, 'clusters', {}, 'scoutfunc', 1, ... 
        'edit', struct('Comment', 'Power,FreqBands', 'TimeBands', [], ...
        'Freqs', freqs, 'ClusterFuncTime', 'none', 'Measure', 'power', ...
        'Output', 'all', 'SaveKernel', 0));
    psdNormFiles = bst_process('CallProcess', 'process_tf_norm', ...
        psdFiles, [], 'normalize', 'relative', 'overwrite', 0);
    projFiles = bst_process('CallProcess', 'process_project_sources', ...
        psdNormFiles, [], 'headmodeltype', 'surface');
    projFiles = bst_process('CallProcess', 'process_ssmooth_surfstat', ...
        projFiles, [], 'fwhm', 3,  'overwrite', 1);
    psdSourcesFiles = bst_process('CallProcess', 'process_average', ...
        projFiles, [], 'avgtype', 1, 'avg_func', 1, 'weighted', 0, ...
        'matchrows', 0, 'iszerobad', 0);
end

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
    epTime, iStudy)
    if nargin < 6
        iStudy = 100;
    end
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
    for i = 1:length(sourceFiles)
        auxFiles = sourceFiles{i};
        name = split(string(auxFiles{1}), '/');
        if length(name) == 1
            name = split(auxFiles, '\');
        end
        sInputs.SubjectName = char(name(1));
        sInputs.SubjectFile = char(strcat(name(1), '/brainstormsubject.mat'));
        sInputs.Condition = char(name(2));
        subFiles = {};
        for j = 1:length(auxFiles)
            sInputs.iStudy=sInputs.iStudy+1;
            sInputs.Comment = char(strcat(srcSubject, '/Raw (', ...
                string((j-1)*epTime), '.00s,', string(j*epTime), '.00s)'));
            sInputs.FileName = auxFiles{j};
            subFiles = [subFiles, ...
                bst_process('Run', sProcess, sInputs, [], 1)];
        end
        projectedScoutFiles = [projectedScoutFiles, subFiles];
    end
end
    
    