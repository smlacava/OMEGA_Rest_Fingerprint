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
            if not(isempty(data.Condition))
                data.FileName = char(strcat(data.SubjectName, filesep, ...
                    data.Condition, filesep, "data_block", block, ".mat"));
            else
                data.FileName = char(strcat(data.SubjectName, filesep, ...
                    data.SubjectName, ...
                    "_ses-01_task-rest_run-01_meg_notch_high", filesep, ...
                    "data_block", block, ".mat"));
            end
            data.Comment = char(strcat("Raw (", string(epTime*(j-1)), ...
                ".00s,", string(epTime*j), ".00s)"));
            subFiles = [subFiles, data];
        end
        importFiles = [importFiles, subFiles];
    end
end