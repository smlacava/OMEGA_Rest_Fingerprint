%% FUNCTION IMPORT_RAW_BRAINSTORM
function NewFiles = import_raw_brainstorm(DataFile, TimeRange, epTime, ...
    EventsTimeRange, fs, nEpochs)
[sStudy, iStudy, iData] = bst_get('DataFile', DataFile);
if isempty(sStudy)
    error('File is not registered in the database.');
end
% Is it a "link to raw file" or not
isRaw = strcmpi(sStudy.Data(iData).DataType, 'raw');
% Get subject index
[sSubject, iSubject] = bst_get('Subject', sStudy.BrainStormSubject);
% Progress bar
bst_progress('start', 'Import raw file', 'Processing file header...');
% Read file descriptor
DataMat = in_bst_data(DataFile);
% Read channel file
ChannelFile = bst_get('ChannelFileForStudy', DataFile);
ChannelMat = in_bst_channel(ChannelFile);
% Get sFile structure
if isRaw
    sFile = DataMat.F;
else
    sFile = in_fopen(DataFile, 'BST-DATA');
end
% Import file
NewFiles = import_data(sFile, ChannelMat, sFile.format, [], iSubject, [], sStudy.DateOfStudy, TimeRange, epTime, ...
    EventsTimeRange, fs, nEpochs);

% If only one file imported: Copy linked videos in destination folder
if (length(NewFiles) == 1) && ~isempty(sStudy.Image)
    process_import_data_event('CopyVideoLinks', NewFiles{1}, sStudy);
end
% Save database
db_save();
end



%% FUNCTION IMPORT_DATA
function NewFiles = import_data(DataFiles, ChannelMat, FileFormat, iStudyInit, iSubjectInit, ImportOptions, DateOfStudy, TimeRange, epTime, ...
    EventsTimeRange, fs, nEpochs)
if (nargin < 7) || isempty(DateOfStudy)
    DateOfStudy = [];
end
if (nargin < 6) || isempty(ImportOptions)
    ImportOptions = db_template('ImportOptions');
end
if (nargin < 5) || isempty(iSubjectInit)
    iSubjectInit = 0;
end
if (nargin < 4) || isempty(iStudyInit) || (iStudyInit == 0)
    iStudyInit = 0;
else
    % If study indice is provided: override subject definition
    sStudTarg = bst_get('Study', iStudyInit);
    [tmp__, iSubjectInit] = bst_get('Subject', sStudTarg.BrainStormSubject);
end
if (nargin < 3)
    FileFormat = [];
end
sFile = [];
if (nargin < 1)
    DataFiles = [];
elseif isstruct(DataFiles)
    sFile = DataFiles;
    DataFiles = {sFile.filename};
    % Check channel file
    if isempty(ChannelMat)
        error('ChannelMat must be provided when calling in_data() with a sFile structure.');
    end
elseif ischar(DataFiles)
    DataFiles = {DataFiles};
end
% Some verifications
if ~isempty(DataFiles) && isempty(FileFormat)
    error('If you pass the filenames in input, you must define also the FileFormat argument.');
end
% Get Protocol information
ProtocolInfo = bst_get('ProtocolInfo');
% Initialize returned variable
NewFiles = {};
if isempty(DataFiles) 
    % Get default import directory and formats
    LastUsedDirs = bst_get('LastUsedDirs');
    DefaultFormats = bst_get('DefaultFormats');
    % Get MRI file
    [DataFiles, FileFormat, FileFilter] = java_getfile( 'open', ...
        'Import EEG/MEG recordings...', ...    % Window title
        LastUsedDirs.ImportData, ...           % Last used directory
        'multiple', 'files_and_dirs', ...      % Selection mode
        bst_get('FileFilters', 'data'), ...    % Get all the available file formats
        DefaultFormats.DataIn);                % Default file format
    % If no file was selected: exit
    if isempty(DataFiles)
        return
    end
    % Save default import directory
    LastUsedDirs.ImportData = bst_fileparts(DataFiles{1});
    bst_set('LastUsedDirs', LastUsedDirs);
    % Save default import format
    DefaultFormats.DataIn = FileFormat;
    bst_set('DefaultFormats',  DefaultFormats);
    % Process the selected directories :
    %    1) If they are .ds/ directory with .meg4 and .res4 files : keep them as "files to open"
    %    2) Else : add all the data files they contains (subdirectories included)
    DataFiles = file_expand_selection(FileFilter, DataFiles);
    if isempty(DataFiles)
        error(['No data ' FileFormat ' file in the selected directories.']);
    end
    
    % ===== SUB-CATEGORIES IN FILE FORMAT =====
    if strcmpi(FileFormat, 'EEG-NEUROSCAN')
        [tmp, tmp, fileExt] = bst_fileparts(DataFiles{1});
        % Switch between different Neuroscan formats
        switch (lower(fileExt))
            case '.cnt',  FileFormat = 'EEG-NEUROSCAN-CNT';
            case '.eeg',  FileFormat = 'EEG-NEUROSCAN-EEG';
            case '.avg',  FileFormat = 'EEG-NEUROSCAN-AVG';
            case '.dat',  FileFormat = 'EEG-NEUROSCAN-DAT';
        end
    end
end
bst_progress('start', 'Import MEG/EEG recordings', 'Emptying temporary directory...');
gui_brainstorm('EmptyTempFolder');
nbCall = 0;
iNewAutoSubject = [];
isReinitStudy = 0;
iAllStudies = [];
iAllSubjects = [];

% Process all the selected data files
for iFile = 1:length(DataFiles)  
    nbCall = nbCall + 1;
    DataFile = DataFiles{iFile};
    [DataFile_path, DataFile_base] = bst_fileparts(DataFile);
    % Check file location (a file cannot be directly inside the brainstorm directories)
    itmp = strfind(DataFile_path, ProtocolInfo.STUDIES);
    if isempty(sFile) && ~isempty(itmp) && (itmp(1) == 1) 
         error(['You are not supposed to put your original files in the Brainstorm data directory.' 10 ...
                'This directory is part of the Brainstorm database and its content can be altered only' 10 ...
                'by the Brainstorm GUI.' 10 10 ...
                'Please create a new folder somewhere else, move all you original recordings files in it, ' 10 ...
                'and then try again to import them.']);
    end
    
    % List or directories where to copy the channel file
    iStudyCopyChannel = [];
    % If needed: reinitialize target study
    if isReinitStudy
        iStudyInit = 0;
    end
    
    % ===== CONVERT DATA FILE =====
    bst_progress('start', 'Import MEG/EEG recordings', ['Loading file "' DataFile '"...']);
    % Load file
    if ~isempty(sFile)
        [ImportedDataMat, ChannelMat, nChannels, nTime, ImportOptions] = in_data(sFile, ChannelMat, FileFormat, ImportOptions, nbCall, TimeRange, epTime, EventsTimeRange, fs, nEpochs);
        % Importing data from a RAW file already in the DB: the re-alignment is already done
        ImportOptions.ChannelReplace = 0;
        ImportOptions.ChannelAlign = 0;
        % Creation date: use input value, or try to get it from the sFile structure
        if ~isempty(DateOfStudy)
            studyDate = DateOfStudy;
        elseif isfield(sFile, 'acq_date') && ~isempty(sFile.acq_date)
            studyDate = sFile.acq_date;
        else
            studyDate = [];
        end
    else
        % If importing files in an existing folder: adapt to the existing channel file
        if ~isempty(iStudyInit) && ~isnan(iStudyInit) && (iStudyInit > 0)
            sStudyInit = bst_get('Study', iStudyInit);
            if ~isempty(sStudyInit) && ~isempty(sStudyInit.Channel) && ~isempty(sStudyInit.Channel(1).FileName)
                ChannelMatInit = in_bst_channel(sStudyInit.Channel(1).FileName);
            else
                ChannelMatInit = [];
            end
        else
            ChannelMatInit = [];
        end
        [ImportedDataMat, ChannelMat, nChannels, nTime, ImportOptions, studyDate] = in_data(DataFile, ChannelMatInit, FileFormat, ImportOptions, nbCall, TimeRange, epTime, EventsTimeRange, fs, nEpochs);
        % Creation date: use input value
        if ~isempty(DateOfStudy)
            studyDate = DateOfStudy;
        end
    end
    if isempty(ImportedDataMat)
        break;
    end
    % Detect differences in epoch sizes
    if (length(DataFiles) == 1) && ~isempty(nTime) && any(nTime ~= nTime(1)) && (ImportOptions.IgnoreShortEpochs >= 1)
        % Get the epochs that are too short
        iTooShort = find(nTime < max(nTime));
        % Ask user if the epochs that are too short should be removed
        if (ImportOptions.IgnoreShortEpochs == 1)
            res = java_dialog('confirm', sprintf('Some epochs (%d) are shorter than the others, ignore them?', length(iTooShort)), 'Import MEG/EEG recordings');
            if res
                ImportOptions.IgnoreShortEpochs = 2;
            else
                ImportOptions.IgnoreShortEpochs = 0;
            end
        end
        % Remove epochs that are too short
        if (ImportOptions.IgnoreShortEpochs >= 1)
            ImportedDataMat(iTooShort) = [];
            bst_report('Warning', 'process_import_data_event', DataFile, sprintf('%d epochs were ignored because they are shorter than the others.', length(iTooShort)));
        end
    end

    % ===== CREATE STUDY (IIF SUBJECT IS DEFINED) =====
    bst_progress('start', 'Import MEG/EEG recordings', 'Preparing output studies...');
    % Check if subject/condition is in filenames
    [SubjectName, ConditionName] = ParseDataFilename(ImportedDataMat(1).FileName);
    % If subj/cond are defined in filenames => default (ignore node that was clicked)
    if ~isempty(SubjectName)
        iSubjectInit = NaN;
    end
    if ~isempty(ConditionName)
        iStudyInit = NaN;
    end
        
    % If study is already known
    if (iStudyInit ~= 0) 
        iStudies = iStudyInit;
    % If a study needs to be created AND subject is already defined
    elseif (iStudyInit == 0) && (iSubjectInit ~= 0) && ~isnan(iSubjectInit)
        % Get the target subject
        sSubject = bst_get('Subject', iSubjectInit, 1);
        % When importing from files that are already in the database: Import by default in the same folder
        if strcmpi(FileFormat, 'BST-DATA') && ~isempty(bst_get('DataFile', DataFile))
            [sStudies, iStudies] = bst_get('DataFile', DataFile);
        % Else: Create a new condition based on the filename
        else
            % If importing from a raw link in the database: get the import condition from it
            if ~isempty(sFile) && isfield(sFile, 'condition') && ~isempty(sFile.condition)
                Condition = sFile.condition;
            % Else, use the file name
            else
                Condition = DataFile_base;
            end
            % Try to get default study
            [sStudies, iStudies] = bst_get('StudyWithCondition', bst_fullfile(sSubject.Name, Condition));
            % If does not exist yet: Create the default study
            if isempty(iStudies)
                iStudies = db_add_condition(sSubject.Name, Condition, [], studyDate);
                if isempty(iStudies)
                    error('Default study could not be created : "%s".', Condition);
                end
                isReinitStudy = 1;
            end
        end
        iStudyInit = iStudies;
    % If need to create Subject + Condition + Study : do it file per file
    else
        iSubjectInit = NaN;
        iStudyInit   = NaN;
        iStudies     = [];
    end
    
    % ===== STORE IMPORTED FILES IN DB =====
    bst_progress('start', 'Import MEG/EEG recordings', 'Saving imported files in database...', 0, length(ImportedDataMat));
    strTag = '';
    % Store imported data files in Brainstorm database
    for iImported = 1:length(ImportedDataMat)
        bst_progress('inc', 1);
        % ===== CREATE STUDY (IF SUBJECT NOT DEFINED) =====
        % Need to get a study for each imported file
        if isnan(iSubjectInit) || isnan(iStudyInit)
            % === PARSE FILENAME ===
            % Try to get subject name and condition name out of the filename
            [SubjectName, ConditionName] = ParseDataFilename(ImportedDataMat(iImported).FileName);
            sSubject = [];
            % === SUBJECT NAME ===
            if isempty(SubjectName)
                % If subject is defined by the input node: use this subject's name
                if (iSubjectInit ~= 0) && ~isnan(iSubjectInit)
                    [sSubject, iSubject] = bst_get('Subject', iSubjectInit);
                end
            else
                % Find the subject in DataBase
                [sSubject, iSubject] = bst_get('Subject', SubjectName, 1);
                % If subject is not found in DB: create it
                if isempty(sSubject)
                    [sSubject, iSubject] = db_add_subject(SubjectName);
                    % If subject cannot be created: error: stop everything
                    if isempty(sSubject)
                        error(['Could not create subject "' SubjectName '"']);
                    end
                end
            end
            % If a subject creation is needed
            if isempty(sSubject)
                SubjectName = 'NewSubject';
                % If auto subject was not created yet 
                if isempty(iNewAutoSubject)
                    % Try to get a subject with this name in database
                    [sSubject, iSubject] = bst_get('Subject', SubjectName);
                    % If no subject with automatic name exist in database, create it
                    if isempty(sSubject)
                        [sSubject, iSubject] = db_add_subject(SubjectName);
                        iNewAutoSubject = iSubject;
                    end
                % If auto subject was created for the previous imported file 
                else
                    [sSubject, iSubject] = bst_get('Subject', iNewAutoSubject);
                end
            end
            % === CONDITION NAME ===
            if isempty(ConditionName)
                % If a condition is defined by the input node
                if (iStudyInit ~= 0) && ~isnan(iStudyInit)
                    sStudyInit = bst_get('Study', iStudyInit);
                    ConditionName = sStudyInit.Condition{1};
                else
                    ConditionName = 'Default';
                end
            end
            % Get real subject directory (not the default subject directory, which is the default)
            sSubjectRaw = bst_get('Subject', iSubject, 1);
            % Find study (subject/condition) in database
            [sNewStudy, iNewStudy] = bst_get('StudyWithCondition', bst_fullfile(sSubjectRaw.Name, ConditionName));
            % If study does not exist : create it
            if isempty(iNewStudy)
                iNewStudy = db_add_condition(sSubjectRaw.Name, ConditionName, 0, studyDate);
                if isempty(iNewStudy)
                    warning(['Cannot create condition : "' bst_fullfile(sSubjectRaw.Name, ConditionName) '"']);
                    continue;
                end
            end
            iStudies = [iStudies, iNewStudy];   
        else
            iSubject = iSubjectInit;
            sSubject = bst_get('Subject', iSubject);
            iStudies = iStudyInit;
        end
        % ===== CHANNEL FILE TARGET =====
        % If subject uses default channel
        if (sSubject.UseDefaultChannel)
            % Add the DEFAULT study directory to the list
            [sDefaultStudy, iDefaultStudy] = bst_get('DefaultStudy', iSubject);
            if ~isempty(iDefaultStudy)
                iStudyCopyChannel(iImported) = iDefaultStudy;
            else
                iStudyCopyChannel(iImported) = NaN;
            end
        else
            % Else add study directory in the list
            iStudyCopyChannel(iImported) = iStudies(end);
        end
        sStudy = bst_get('Study', iStudies(end));
        studySubDir = bst_fileparts(sStudy.FileName);
        [importedPath, importedBase, importedExt] = bst_fileparts(ImportedDataMat(iImported).FileName);
        importedBase = removeStudyTags(importedBase);
        finalImportedFile = bst_fullfile(ProtocolInfo.STUDIES, studySubDir, [importedBase, strTag, importedExt]);
        [finalImportedFile, newTag] = file_unique(finalImportedFile);
        if ~isempty(newTag)
            strTag = newTag;
        end
        if ~file_compare(importedPath, bst_fileparts(finalImportedFile))
            file_move(ImportedDataMat(iImported).FileName, finalImportedFile);
            ImportedDataMat(iImported).FileName = file_short(finalImportedFile);
        end
        nbData = length(sStudy.Data) + 1;
        sStudy.Data(nbData) = ImportedDataMat(iImported);
        bst_set('Study', iStudies(end), sStudy);
        iAllSubjects = [iAllSubjects, iSubject];
        if ImportedDataMat(iImported).BadTrial
            process_detectbad('SetTrialStatus', ImportedDataMat(iImported).FileName, 1);
        else
            NewFiles{end+1} = finalImportedFile;
        end
    end
    clear sStudy studySubDir
    iStudies = unique(iStudies(~isnan(iStudies)));
    iStudyCopyChannel = unique(iStudyCopyChannel(~isnan(iStudyCopyChannel)));
    iAllStudies = [iAllStudies, iStudies, iStudyCopyChannel];
    % Create default channel file
    if isempty(ChannelMat)
        ChannelMat = db_template('channelmat');
        ChannelMat.Comment = 'Channel file';
        ChannelMat.Channel = repmat(db_template('channeldesc'), [1, nChannels]);
        % For each channel
        for i = 1:length(ChannelMat.Channel)
            if (length(ChannelMat.Channel) > 99)
                ChannelMat.Channel(i).Name = sprintf('E%03d', i);
            else
                ChannelMat.Channel(i).Name = sprintf('E%02d', i);
            end
            ChannelMat.Channel(i).Type    = 'EEG';
            ChannelMat.Channel(i).Loc     = [0; 0; 0];
            ChannelMat.Channel(i).Orient  = [];
            ChannelMat.Channel(i).Weight  = 1;
            ChannelMat.Channel(i).Comment = [];
        end
        % Save channel file in all the target studies
        for i = 1:length(iStudyCopyChannel)
            db_set_channel(iStudyCopyChannel(i), ChannelMat, 0, 0);
        end
    else
        % Check for empty channels
        iEmpty = find(cellfun(@isempty, {ChannelMat.Channel.Name}));
        for i = 1:length(iEmpty)
            ChannelMat.Channel(iEmpty(i)).Name = sprintf('%04d', iEmpty(i));
        end
        % Check for duplicate channels
        for i = 1:length(ChannelMat.Channel)
            iOther = setdiff(1:length(ChannelMat.Channel), i);
            ChannelMat.Channel(i).Name = file_unique(ChannelMat.Channel(i).Name, {ChannelMat.Channel(iOther).Name});
        end
        % Remove fiducials only from polhemus and ascii files
        isRemoveFid = ismember(FileFormat, {'MEGDRAW', 'POLHEMUS', 'ASCII_XYZ', 'ASCII_NXYZ', 'ASCII_XYZN', 'ASCII_XYZ_MNI', 'ASCII_NXYZ_MNI', 'ASCII_XYZN_MNI', 'ASCII_NXY', 'ASCII_XY', 'ASCII_NTP', 'ASCII_TP'});
        % Perform the NAS/LPA/RPA registration for some specific file formats
        isAlign = ismember(FileFormat, {'NIRS-BRS'});
        % Detect auxiliary EEG channels
        ChannelMat = channel_detect_type(ChannelMat, isAlign, isRemoveFid);
        % Do not align data coming from Brainstorm exported files (already aligned)
        if strcmpi(FileFormat, 'BST-BIN')
            ImportOptions.ChannelAlign = 0;
        % Do not allow automatic registration with head points when using the default anatomy
        elseif (sSubject.UseDefaultAnat) || isempty(sSubject.Anatomy) || any(~cellfun(@(c)isempty(strfind(lower(sSubject.Anatomy(sSubject.iAnatomy).Comment), c)), {'icbm152', 'colin27', 'bci-dni', 'uscbrain', 'fsaverage', 'oreilly', 'kabdebon'}))
            ImportOptions.ChannelAlign = 0;
        end
        % Save channel file in all the target studies (need user confirmation for overwrite)
        for i = 1:length(iStudyCopyChannel)
            [ChannelFile, tmp, ImportOptions.ChannelReplace, ImportOptions.ChannelAlign] = db_set_channel(iStudyCopyChannel(i), ChannelMat, ImportOptions.ChannelReplace, ImportOptions.ChannelAlign);
        end
    end
end
bst_progress('stop');
if ~isempty(iAllSubjects)
    iAllSubjects = unique(iAllSubjects);
    for i = 1:length(iAllSubjects)
        db_links('Subject', iAllSubjects(i));
    end
end
% Update tree
if ~isempty(iAllStudies)
    iAllStudies = unique(iAllStudies);
    panel_protocols('UpdateNode', 'Study', iAllStudies);
    if (length(NewFiles) == 1)
        panel_protocols('SelectNode', [], NewFiles{1});
    elseif (length(iAllStudies) == 1)
        panel_protocols('SelectStudyNode', iAllStudies(1));
    end
end
% Edit new subject (if a new subject was created automatically)
if ~isempty(iNewAutoSubject)
    db_edit_subject(iNewAutoSubject);
end
% Save database
db_save();
return
end


%% FUNCTION PARSEDATAFILENAME
function [SubjectName, ConditionName] = ParseDataFilename(filename)
    SubjectName   = '';
    ConditionName = '';
    % Get only short filename without extension
    [fPath, fName, fExt] = bst_fileparts(filename);
    
    % IMPORTED FILENAMES : '....___SUBJsubjectname___CONDcondname___...'
    % Get subject tag
    iTag_subj = strfind(fName, '___SUBJ');
    if ~isempty(iTag_subj)
        iStartSubj = iTag_subj + 7;
        % Find closing tag
        iCloseSubj = strfind(fName(iStartSubj:end), '___');
        % Find closing tag
        if ~isempty(iCloseSubj)
            SubjectName = fName(iStartSubj:iStartSubj + iCloseSubj - 2);
        end
    end
    
    % Get condition tag
    iTag_cond = strfind(fName, '___COND');
    if ~isempty(iTag_cond)
        iStartCond = iTag_cond + 7;
        % Find closing tag
        iCloseCond = strfind(fName(iStartCond:end), '___');
        % Find closing tag
        if ~isempty(iCloseCond)
            ConditionName = fName(iStartCond:iStartCond + iCloseCond - 2);
        end
    end
end


%% FUNCTION REMOVESTUDYTAGS
function fname = removeStudyTags(fname)
    iTags = strfind(fname, '___');
    if iTags >= 2
        iStart = iTags(1);
        if (iTags(end) + 2 == length(fname))
            iStop  = iTags(end) + 2;
        else
            % Leave at least one '_' as a separator
            iStop  = iTags(end) + 1;
        end
        fname(iStart:iStop) = [];
    end
end

%% FUNCTION IN_DATA
function [ImportedData, ChannelMat, nChannels, nTime, ImportOptions, DateOfStudy] = in_data( DataFile, ChannelMat, FileFormat, ImportOptions, nbCall, TimeRange, epTime, EventsTimeRange, fs, nEpochs)
if (nargin < 5) || isempty(nbCall)
    nbCall = 1;
end
if (nargin < 4) || isempty(ImportOptions)
    ImportOptions = db_template('ImportOptions');
end
% Define structure sFile 
sFile = [];
nChannels = 0;
if (nargin < 3)
    error('Invalid call.');
elseif isstruct(DataFile)
    sFile = DataFile;
    DataFile = sFile.filename;
    % Check channel file
    if isempty(ChannelMat)
        error('ChannelMat must be provided when calling in_data() with a sFile structure.');
    end
elseif ~isempty(strfind(DataFile, '_0raw'))
    FileMat = in_bst_data(DataFile, 'F');
    sFile   = FileMat.F;
    % Read channel file
    if isempty(ChannelMat)
        ChannelFile = bst_get('ChannelFileForStudy', DataFile);
        ChannelMat = in_bst_channel(ChannelFile);
    end
    DataFile = sFile.filename;
elseif ~file_exist(DataFile)
    error('File does not exist: "%s"', DataFile);
end
ImportedData = [];
nTime = [];
DateOfStudy = [];
% Get temporary directory
tmpDir = bst_get('BrainstormTmpDir');
[filePath, fileBase, fileExt] = bst_fileparts(DataFile);
% Reading as raw continuous?
isRaw = ismember(FileFormat, {'FIF', 'CTF', 'CTF-CONTINUOUS', '4D', 'KIT', 'RICOH', 'KDF', 'ITAB', ...
    'MEGSCAN-HDF5', 'EEG-ANT-CNT', 'EEG-ANT-MSR', 'EEG-AXION', 'EEG-BRAINAMP', 'EEG-DELTAMED', 'EEG-COMPUMEDICS-PFS', ...
    'EEG-EGI-RAW', 'EEG-NEUROSCAN-CNT', 'EEG-NEUROSCAN-EEG', 'EEG-NEUROSCAN-AVG', 'EEG-EDF', 'EEG-BDF', ...
    'EEG-EEGLAB', 'EEG-GTEC', 'EEG-MANSCAN', 'EEG-MICROMED', 'EEG-NEURALYNX', 'EEG-BLACKROCK', 'EEG-RIPPLE', 'EEG-NEURONE', ...
    'EEG-NEUROSCOPE', 'EEG-NICOLET', 'EEG-NK', 'EEG-SMR', 'EEG-SMRX', 'SPM-DAT', 'NIRS-BRS', 'BST-DATA', 'BST-BIN', ...
    'EYELINK', 'EEG-EDF', 'EEG-EGI-MFF', 'EEG-INTAN', 'EEG-PLEXON', 'EEG-TDT', 'NWB', 'NWB-CONTINUOUS', 'EEG-CURRY', ...
    'EEG-OEBIN', 'EEG-ADICHT'});
if isRaw
    % Initialize list of file blocks to read
    BlocksToRead = repmat(struct('iEpoch',      [], ...
                                 'iTimes',      '', ...
                                 'FileTag',     '', ...
                                 'Comment',     '', ...
                                 'TimeOffset',  0, ...
                                 'isBad',       [], ...
                                 'ChannelFlag', [], ...
                                 'ImportTime',  ''), 0);
    % If file not open yet: Open file
    if isempty(sFile)
        [sFile, ChannelMat, errMsg] = in_fopen(DataFile, FileFormat, ImportOptions);
        if isempty(sFile)
            return
        end
        % Yokogawa non-registered warning
        if ~isempty(errMsg) && ImportOptions.DisplayMessages
            java_dialog('warning', errMsg, 'Open raw EEG/MEG recordings');
        end
    end
    % Get acquisition dateTimeRange
    if isfield(sFile, 'acq_date') && ~isempty(sFile.acq_date)
        DateOfStudy = sFile.acq_date;
    end

    % Display import GUI
    if (nbCall == 1) && ImportOptions.DisplayMessages
        comment = ['Import ' sFile.format ' file'];
        ImportOptions = get_import_options(TimeRange, epTime, ...
            EventsTimeRange, fs);
        ImportOptions.ImportMode = 'Time';

        % If user canceled the process
        if isempty(ImportOptions)
            bst_progress('stop');
            return
        end
    % Check number of epochs
    elseif strcmpi(ImportOptions.ImportMode, 'Epoch')
        if isempty(sFile.epochs)
            error('This file does not contain any epoch. Try importing it as continuous, or based on events.');
        elseif ImportOptions.GetAllEpochs
            ImportOptions.iEpochs = 1:length(sFile.epochs);
        elseif any(ImportOptions.iEpochs > length(sFile.epochs)) || any(ImportOptions.iEpochs < 1)
            error(['You selected an invalid epoch index.' 10 ...
                   'To import all the epochs at once, please check the "Use all epochs" option.' 10]);
        end
    end

    % Switch between file types
    switch lower(ImportOptions.ImportMode)
        % ===== EPOCHS =====
        case 'epoch'
            % If all data sets have the same comment: consider them as trials
            isTrials = (length(sFile.epochs) > 1) && all(strcmpi({sFile.epochs.label}, sFile.epochs(1).label));
            % Loop on all epochs
            for ieph = 1:length(ImportOptions.iEpochs)
                % Get epoch number
                iEpoch = ImportOptions.iEpochs(ieph);
                % Import structure
                BlocksToRead(end+1).iEpoch   = iEpoch;
                BlocksToRead(end).Comment    = sFile.epochs(iEpoch).label;
                BlocksToRead(end).TimeOffset = 0;
                BlocksToRead(end).ImportTime = sFile.epochs(iEpoch).times;
                % Copy optional fields
                if isfield(sFile.epochs(iEpoch), 'bad') && (sFile.epochs(iEpoch).bad == 1)
                    BlocksToRead(end).isBad = 1;
                end
                if isfield(sFile.epochs(iEpoch), 'channelflag') && ~isempty(sFile.epochs(iEpoch).channelflag)
                    BlocksToRead(end).ChannelFlag = sFile.epochs(iEpoch).channelflag;
                end
                % Build file tag
                FileTag = BlocksToRead(end).Comment;
                % Add trial number, if considering sets as a list of trials for the same condition
                if isTrials
                    FileTag = [FileTag, sprintf('_trial%03d', iEpoch)];
                end
                % Add condition TAG, if required in input options structure
                if ImportOptions.CreateConditions 
                    CondName = strrep(BlocksToRead(end).Comment, '#', '');
                    CondName = str_remove_parenth(CondName);
                    FileTag = [FileTag, '___COND', CondName, '___'];
                end
                BlocksToRead(end).FileTag = FileTag;
                % Number of averaged trials
                BlocksToRead(end).nAvg = sFile.epochs(iEpoch).nAvg;
            end

        % ===== RAW DATA: READING TIME RANGE =====
        case 'time'
            % Check time window
            if isempty(ImportOptions.TimeRange)
                ImportOptions.TimeRange = sFile.prop.times;
            end
            % If SplitLength not defined: use the whole time range
            if ~ImportOptions.SplitRaw || isempty(ImportOptions.SplitLength)
                ImportOptions.SplitLength = ImportOptions.TimeRange(2) - ImportOptions.TimeRange(1) + 1/sFile.prop.sfreq;
            end
            % Get block size in samples
            blockSmpLength = round(ImportOptions.SplitLength * sFile.prop.sfreq);
            totalSmpLength = round((ImportOptions.TimeRange(2) - ImportOptions.TimeRange(1)) * sFile.prop.sfreq) + 1;
            startSmp = round(ImportOptions.TimeRange(1) * sFile.prop.sfreq);                   
            % Get number of blocks
            nbBlocks = ceil(totalSmpLength / blockSmpLength);
            % For each block
            for iBlock = 1:nbBlocks
                % Get samples indices for this block (start ind = 0)
                smpBlock = startSmp + [(iBlock - 1) * blockSmpLength, min(iBlock * blockSmpLength - 1, totalSmpLength - 1)];
                % Import structure
                BlocksToRead(end+1).iEpoch   = 1;
                BlocksToRead(end).iTimes     = smpBlock;
                BlocksToRead(end).FileTag    = sprintf('block%03d', iBlock);
                BlocksToRead(end).TimeOffset = 0;
                % Build comment (seconds or miliseconds)
                BlocksToRead(end).ImportTime = smpBlock / sFile.prop.sfreq;
                if (BlocksToRead(end).ImportTime(2) > 2)
                    BlocksToRead(end).Comment = sprintf('Raw (%1.2fs,%1.2fs)', BlocksToRead(end).ImportTime);
                else
                    BlocksToRead(end).Comment = sprintf('Raw (%dms,%dms)', round(1000 * BlocksToRead(end).ImportTime));
                end
                % Number of averaged trials
                BlocksToRead(end).nAvg = sFile.prop.nAvg;
            end

        % ===== EVENTS =====
        case 'event'
            isExtended = false;
            % For each event
            for iEvent = 1:length(ImportOptions.events)
                nbOccur = size(ImportOptions.events(iEvent).times, 2);
                % Detect event type: simple or extended
                isExtended = (size(ImportOptions.events(iEvent).times, 1) == 2);
                % For each occurrence of this event
                for iOccur = 1:nbOccur
                    % Samples range to read
                    if isExtended
                        samplesBounds = [0, diff(round(ImportOptions.events(iEvent).times(:,iOccur) * sFile.prop.sfreq))];
                        % Disable option "Ignore shorter epochs"
                        if ImportOptions.IgnoreShortEpochs
                            ImportOptions.IgnoreShortEpochs = 0;
                            bst_report('Warning', 'process_import_data_event', [], 'Importing extended epochs: disabling option "Ignore shorter epochs".');
                        end
                    else
                        samplesBounds = round(ImportOptions.EventsTimeRange * sFile.prop.sfreq);
                    end
                    % Get epoch indices
                    samplesEpoch = round(round(ImportOptions.events(iEvent).times(1,iOccur) * sFile.prop.sfreq) + samplesBounds);
                    if (samplesEpoch(1) < round(sFile.prop.times(1) * sFile.prop.sfreq))
                        % If required time before event is not accessible: 
                        TimeOffset = (round(sFile.prop.times(1) * sFile.prop.sfreq) - samplesEpoch(1)) / sFile.prop.sfreq;
                        samplesEpoch(1) = round(sFile.prop.times(1) * sFile.prop.sfreq);
                    else
                        TimeOffset = 0;
                    end
                    % Make sure all indices are valids
                    samplesEpoch = bst_saturate(samplesEpoch, round(sFile.prop.times * sFile.prop.sfreq));
                    % Import structure
                    BlocksToRead(end+1).iEpoch   = ImportOptions.events(iEvent).epochs(iOccur);
                    BlocksToRead(end).iTimes     = samplesEpoch;
                    BlocksToRead(end).Comment    = sprintf('%s (#%d)', ImportOptions.events(iEvent).label, iOccur);
                    BlocksToRead(end).FileTag    = sprintf('%s_trial%03d', ImportOptions.events(iEvent).label, iOccur);
                    BlocksToRead(end).TimeOffset = TimeOffset;
                    BlocksToRead(end).nAvg       = 1;
                    BlocksToRead(end).ImportTime = samplesEpoch / sFile.prop.sfreq;
                    % Add condition TAG, if required in input options structure
                    if ImportOptions.CreateConditions 
                        CondName = strrep(ImportOptions.events(iEvent).label, '#', '');
                        CondName = str_remove_parenth(CondName);
                        BlocksToRead(end).FileTag = [BlocksToRead(end).FileTag, '___COND' CondName '___'];
                    end
                end
            end
            % In case of extended events: Ignore the EventsTimeRange time range field, and force time to start at 0
            if isExtended
                %ImportOptions.ImportMode = 'time';
                ImportOptions.EventsTimeRange = [0 1];
            end
    end

    % ===== UPDATE CHANNEL FILE =====
    % No CTF Compensation
    if ~ImportOptions.UseCtfComp && ~isempty(ChannelMat)
        ChannelMat.MegRefCoef = [];
        sFile.prop.destCtfComp = sFile.prop.currCtfComp;
    end
    % No SSP
    if ~ImportOptions.UseSsp && ~isempty(ChannelMat) && isfield(ChannelMat, 'Projector') && ~isempty(ChannelMat.Projector)
        % Remove projectors that are not already applied
        iProjDel = find([ChannelMat.Projector.Status] ~= 2);
        ChannelMat.Projector(iProjDel) = [];
    end

    % ===== READING AND SAVING =====
    % Get list of bad segments in file
    [badSeg, badEpochs, badTimes, badChan] = panel_record('GetBadSegments', sFile);
    % Initialize returned variables
    ImportedData = repmat(db_template('Data'), 0);

    initBaselineRange = ImportOptions.BaselineRange;
    % Prepare progress bar
    bst_progress('start', 'Import MEG/EEG recordings', 'Initializing...', 0, length(BlocksToRead));
    % Loop on each recordings block to read
    for iFile = 1:length(BlocksToRead)
        % Set progress bar
        bst_progress('text', sprintf('Importing block #%d/%d...', iFile, length(BlocksToRead)));

        % ===== READING DATA =====
        % If there is a time offset: need to apply it to the baseline range...
        if (BlocksToRead(iFile).TimeOffset ~= 0) && strcmpi(ImportOptions.RemoveBaseline, 'time')
            ImportOptions.BaselineRange = initBaselineRange - BlocksToRead(iFile).TimeOffset;
        end
        % Read data block
        [F, TimeVector,DisplayUnits] = in_fread(sFile, ChannelMat, BlocksToRead(iFile).iEpoch, BlocksToRead(iFile).iTimes, [], ImportOptions);
        
        % If block too small: ignore it
        if (size(F,2) < 3)
            disp(sprintf('BST> Block is too small #%03d: ignoring...', iFile));
            continue
        end
        % Add an addition time offset if defined
        if (BlocksToRead(iFile).TimeOffset ~= 0)
            TimeVector = TimeVector + BlocksToRead(iFile).TimeOffset;
        end
        % Build file structure
        DataMat = db_template('DataMat');
        DataMat.F        = F;
        DataMat.Comment  = BlocksToRead(iFile).Comment;
        DataMat.Time     = TimeVector;
        DataMat.Device   = sFile.device;
        DataMat.nAvg     = double(BlocksToRead(iFile).nAvg);
        DataMat.DisplayUnits = DisplayUnits;
        DataMat.DataType = 'recordings';
        % Channel flag
        if ~isempty(BlocksToRead(iFile).ChannelFlag) 
            DataMat.ChannelFlag = BlocksToRead(iFile).ChannelFlag;
        else
            DataMat.ChannelFlag = sFile.channelflag;
        end

        % ===== GOOD / BAD TRIAL =====
        % By default: segment of data is good
        isBad = 0;
        % If data block has already been marked as bad at an earlier stage, keep it bad 
        if ~isempty(BlocksToRead(iFile).isBad) && BlocksToRead(iFile).isBad
            isBad = 1;
        end
        % Get the block bounds (in samples #)
        iTimes = BlocksToRead(iFile).iTimes;
        % But if there are some bad segments in the file, check that the data we are reading is not overlapping with one of these segments
        if ~isempty(iTimes) && ~isempty(badSeg)
            % Check if this segment is outside of ALL the bad segments (either entirely before or entirely after)
            iBadSeg = find((iTimes(2) >= badSeg(1,:)) & (iTimes(1) <= badSeg(2,:)));
        % For files read by epochs: check for bad epochs
        elseif isempty(iTimes) && ~isempty(badEpochs)
            iBadSeg = find(BlocksToRead(iFile).iEpoch == badEpochs);
        else
            iBadSeg = [];
        end
        % If there are bad segments
        if ~isempty(iBadSeg)
            % Mark trial as bad (if not already set)
            if (isempty(badChan) || any(cellfun(@isempty, badChan(iBadSeg))))
                isBad = 1;
            end
            % Add bad channels defined by events
            if ~isempty(badChan) && ~all(cellfun(@isempty, badChan(iBadSeg))) && ~isempty(ChannelMat)
                iBadChan = find(ismember({ChannelMat.Channel.Name}, unique(cat(2, {}, badChan{iBadSeg}))));
                if ~isempty(iBadChan)
                    DataMat.ChannelFlag(iBadChan) = -1;
                end
            end
        end
        
        % ===== ADD HISTORY FIELD =====
        % This records all the processes applied in in_fread (reset field)
        DataMat = bst_history('reset', DataMat);
        % History: File name
        DataMat = bst_history('add', DataMat, 'import', ['Import from: ' DataFile ' (' ImportOptions.ImportMode ')']);
        % History: Epoch / Time block
        DataMat = bst_history('add', DataMat, 'import_epoch', sprintf('    %d', BlocksToRead(iFile).iEpoch));
        DataMat = bst_history('add', DataMat, 'import_time',  sprintf('    [%1.6f, %1.6f]', BlocksToRead(iFile).ImportTime));
        % History: CTF compensation
        if ~isempty(ChannelMat) && ~isempty(ChannelMat.MegRefCoef) && (sFile.prop.currCtfComp ~= sFile.prop.destCtfComp)
            DataMat = bst_history('add', DataMat, 'import', '    Apply CTF compensation matrix');
        end
        % History: SSP
        if ~isempty(ChannelMat) && ~isempty(ChannelMat.Projector)
            DataMat = bst_history('add', DataMat, 'import', '    Apply SSP projectors');
        end
        % History: Baseline removal
        switch (ImportOptions.RemoveBaseline)
            case 'all'
                DataMat = bst_history('add', DataMat, 'import', '    Remove baseline (all)');
            case 'time'
                DataMat = bst_history('add', DataMat, 'import', sprintf('    Remove baseline: [%d, %d] ms', round(ImportOptions.BaselineRange * 1000)));
        end
        % History: resample
        if ImportOptions.Resample && (abs(ImportOptions.ResampleFreq - sFile.prop.sfreq) > 0.05)
            DataMat = bst_history('add', DataMat, 'import', sprintf('    Resample: from %0.2f Hz to %0.2f Hz', sFile.prop.sfreq, ImportOptions.ResampleFreq));
        end

        % ===== EVENTS =====
        OldFreq = sFile.prop.sfreq;
        NewFreq = 1 ./ (TimeVector(2) - TimeVector(1));
        % Loop on all the events types
        for iEvt = 1:length(sFile.events)
            evtSamples  = round(sFile.events(iEvt).times * sFile.prop.sfreq);
            readSamples = BlocksToRead(iFile).iTimes;
            % If there are no occurrences, or if it the event of interest: skip to next event type
            if isempty(evtSamples) || (strcmpi(ImportOptions.ImportMode, 'event') && any(strcmpi({ImportOptions.events.label}, sFile.events(iEvt).label)))
                continue;
            end
            % Set the number of read samples for epochs
            if isempty(readSamples) && strcmpi(ImportOptions.ImportMode, 'epoch')
                if isempty(sFile.epochs)
                    readSamples = round(sFile.prop.times * sFile.prop.sfreq);
                else
                    readSamples = round(sFile.epochs(BlocksToRead(iFile).iEpoch).times * sFile.prop.sfreq);
                end
            end
            % Apply resampling factor if necessary
            if (abs(OldFreq - NewFreq) > 0.05)
                evtSamples  = round(evtSamples  / OldFreq * NewFreq);
                readSamples = round(readSamples / OldFreq * NewFreq);
            end
            % Simple events
            if (size(evtSamples, 1) == 1)
                if (size(evtSamples,2) == size(sFile.events(iEvt).epochs,2))
                    iOccur = find((evtSamples >= readSamples(1)) & (evtSamples <= readSamples(2)) & (sFile.events(iEvt).epochs == BlocksToRead(iFile).iEpoch));
                else
                    iOccur = find((evtSamples >= readSamples(1)) & (evtSamples <= readSamples(2)));
                    disp(sprintf('BST> Warning: Mismatch in the events structures: size(samples)=%d, size(epochs)=%d', size(evtSamples,2), size(sFile.events(iEvt).epochs,2)));
                end
                % If no occurence found in current time block: skip to the next event
                if isempty(iOccur)
                    continue;
                end
                % Calculate the sample indices of the events in the new file
                iTimeEvt = bst_saturate(evtSamples(:,iOccur) - readSamples(1) + 1, [1, length(TimeVector)]);
                newEvtTimes = round(TimeVector(iTimeEvt) .* NewFreq) ./ NewFreq;
                    
            % Extended events: Get all the events that are not either completely before or after the time window
            else
                iOccur = find((evtSamples(2,:) >= readSamples(1)) & (evtSamples(1,:) <= readSamples(2)) & (sFile.events(iEvt).epochs(1,:) == BlocksToRead(iFile).iEpoch(1,:)));
                % If no occurence found in current time block: skip to the next event
                if isempty(iOccur)
                    continue;
                end
                % Limit to current time window
                evtSamples(evtSamples < readSamples(1)) = readSamples(1);
                evtSamples(evtSamples > readSamples(2)) = readSamples(2);
                % Calculate the sample indices of the events in the new file
                iTimeEvt1 = bst_saturate(evtSamples(1,iOccur) - readSamples(1) + 1, [1, length(TimeVector)]);
                iTimeEvt2 = bst_saturate(evtSamples(2,iOccur) - readSamples(1) + 1, [1, length(TimeVector)]);
                newEvtTimes = [round(TimeVector(iTimeEvt1) .* NewFreq); ...
                               round(TimeVector(iTimeEvt2) .* NewFreq)] ./ NewFreq;
            end
            % Add new event category in the output file
            iEvtData = length(DataMat.Events) + 1;
            DataMat.Events(iEvtData).label    = sFile.events(iEvt).label;
            DataMat.Events(iEvtData).color    = sFile.events(iEvt).color;
            DataMat.Events(iEvtData).times    = newEvtTimes;
            DataMat.Events(iEvtData).epochs   = sFile.events(iEvt).epochs(iOccur);
            DataMat.Events(iEvtData).channels = sFile.events(iEvt).channels(iOccur);
            DataMat.Events(iEvtData).notes    = sFile.events(iEvt).notes(iOccur);
            if ~isempty(sFile.events(iEvt).reactTimes)
                DataMat.Events(iEvtData).reactTimes = sFile.events(iEvt).reactTimes(iOccur);
            end
            DataMat.Events(iEvtData).select = sFile.events(iEvt).select;
        end

        % ===== SAVE FILE =====
        % Add extension, full path, and make valid and unique
        newFileName = ['data_', BlocksToRead(iFile).FileTag, '.mat'];
        newFileName = file_standardize(newFileName);
        newFileName = bst_fullfile(tmpDir, newFileName);
        newFileName = file_unique(newFileName);
        % Save new file
        bst_save(newFileName, DataMat, 'v6');
        % Information to store in database
        ImportedData(end+1).FileName = newFileName;
        ImportedData(end).Comment    = DataMat.Comment;
        ImportedData(end).DataType   = DataMat.DataType;
        ImportedData(end).BadTrial   = isBad;
        % Count number of time points
        nTime(end+1) = length(TimeVector);
        nChannels = size(DataMat.F,1);
        % Increment progress bar
        bst_progress('inc', 1);
    end
else
    % Display ASCII import options
    if ImportOptions.DisplayMessages && (nbCall <= 1) && (ismember(FileFormat, {'EEG-ASCII', 'EEG-BRAINVISION', 'EEG-MAT'}) || (strcmp(FileFormat, 'EEG-CARTOOL') && strcmpi(DataFile(end-2:end), '.ep')))
        gui_show_dialog('Import EEG data', @panel_import_ascii, [], [], FileFormat);
        % Check that import was not aborted
        ImportEegRawOptions = bst_get('ImportEegRawOptions');
        if ImportEegRawOptions.isCanceled
            return;
        end
    end
    % Read file
    [tmp, ChannelMatData, errMsg, DataMat] = in_fopen(DataFile, FileFormat);
    if isempty(DataMat) || ~isempty(errMsg)
        return;
    end
    % If there is no channel file yet, use the one from the input file
    if isempty(ChannelMat) && ~isempty(ChannelMatData)
        ChannelMat = ChannelMatData;
    % Reorganize data to fit the existing channel mat
    elseif ~isempty(ChannelMat) && ~isempty(ChannelMatData) && ~isequal({ChannelMat.Channel.Name}, {ChannelMatData.Channel.Name})
        % Get list of channels in the format of the existing channel file 
        DataMatReorder = DataMat;
        DataMatReorder.F = zeros(length(ChannelMat.Channel), size(DataMat.F,2));
        DataMatReorder.ChannelFlag = -1 * ones(length(ChannelMat.Channel),1);
        for i = 1:length(ChannelMat.Channel)
            iCh = find(strcmpi(ChannelMat.Channel(i).Name, {ChannelMatData.Channel.Name}));
            % If the channel is not found: try a different convention if it is a bipolar channel
            if isempty(iCh) && any(ChannelMat.Channel(i).Name == '-')
                iDash = find(ChannelMat.Channel(i).Name == '-',1);
                chNameBip = [ChannelMat.Channel(i).Name(iDash+1:end), ChannelMat.Channel(i).Name(1:iDash-1)];
                iCh = find(strcmpi(chNameBip, {ChannelMatData.Channel.Name}));
            end
            if ~isempty(iCh)
                DataMatReorder.F(i,:) = DataMat.F(iCh,:);
                DataMatReorder.ChannelFlag(i) = DataMat.ChannelFlag(iCh);
            end
        end
        DataMat = DataMatReorder;
        % Empty the channel file matrix, so it is not saved in the destination folder
        ChannelMat = [];
    end
    
    % ===== SAVE DATA MATRIX IN BRAINSTORM FORMAT =====
    % Get imported base name
    importedBaseName = strrep(fileBase, 'data_', '');
    importedBaseName = strrep(importedBaseName, '_data', '');
    % Process all the DataMat structures that were created
    ImportedData = repmat(db_template('Data'), [1, length(DataMat)]);
    nTime = zeros(1, length(DataMat));
    for iData = 1:length(DataMat)
        if isfield(DataMat, 'SubjectName') && ~isempty(DataMat(iData).SubjectName) && isfield(DataMat, 'Condition') && ~isempty(DataMat(iData).Condition)
            newFileName = [importedBaseName '___SUBJ' DataMat(iData).SubjectName '___COND' DataMat(iData).Condition, '___'];
        else
            newFileName = importedBaseName;
        end
        % Produce a default data filename          
        BstDataFile = bst_fullfile(tmpDir, ['data_' newFileName '_' sprintf('%04d', iData) '.mat']);
        
        % Add History: File name
        FileMat = DataMat(iData); 
        FileMat = bst_history('add', FileMat, 'import', ['Import from: ' DataFile ' (Format: ' FileFormat ')']);
        FileMat.DataType = 'recordings';
        % Save new MRI in Brainstorm format
        bst_save(BstDataFile, FileMat, 'v6');
        
        % Create returned data structure
        ImportedData(iData).FileName = BstDataFile;
        % Add a Comment field (from DataMat if possible)
        if isfield(DataMat(iData), 'Comment') && ~isempty(DataMat(iData).Comment)
            ImportedData(iData).Comment = DataMat(iData).Comment;
        else
            DataMat(iData).Comment = [fileBase ' (' FileFormat ')'];
        end
        ImportedData(iData).DataType = FileMat.DataType;
        ImportedData(iData).BadTrial = 0;
        % Count number of time points
        nTime(iData) = length(FileMat.Time);
        nChannels = size(FileMat.F,1);
    end
end
if ~isempty(ChannelMat)
    ChannelMat = bst_history('add', ChannelMat, 'import', ['Import from: ' DataFile ' (Format: ' FileFormat ')']);
end


end


%% FUNCTION GET_IMPORT_OPTIONS
function ImportOptions = get_import_options(TimeRange, epTime, ...
    EventsTimeRange, fs)
    ImportOptions = struct();
    ImportOptions.ImportMode = 'Time';
    ImportOptions.UseEvents = false;
    ImportOptions.TimeRange = TimeRange;
    ImportOptions.EvantsTimeRange = EventsTimeRange;
    ImportOptions.GetAllEpochs = 0;
    ImportOptions.iEpochs = 1;
    ImportOptions.SplitRaw = true;
    ImportOptions.SplitLength = epTime;
    ImportOptions.Resample = true;
    ImportOptions.ResampleFreq = fs;
    ImportOptions.UseCtfComp = true;
    ImportOptions.UseSsp = true;
    ImportOptions.RemoveBaseline = 'no';
    ImportOptions.BaselineRange = true;
    ImportOptions.events = [];
    ImportOptions.CreateConditions = false;
    ImportOptions.ChannelReplace = 1;
    ImportOptions.ChannelAlign = 1;
    ImportOptions.IgnoreShortEpochs = 1;
    ImportOptions.EventsMode = 'ask';
    ImportOptions.EventsTrackMode = 'ask';
    ImportOptions.EventsTypes = '';
    ImportOptions.DisplayMessages = 1;
    ImportOptions.Precision = [];
end
