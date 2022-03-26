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