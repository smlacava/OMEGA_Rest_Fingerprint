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