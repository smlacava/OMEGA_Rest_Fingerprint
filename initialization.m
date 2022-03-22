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
    epTime, nEpochs, resample, subPattern)
    if nargin < 6
        nEpochs = 0;
        resample = 0;
        epTime = 0;
        fs = 0;
        t = 0;
    end
    if nargin < 7
        subPattern = "sub-0";
    end
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
    if nEpochs > 0
        t = epTime*nEpochs;
        fs = resample;
        for i = 1:length(rawFiles)
            if contains(string(rawFiles(i).FileName), subPattern)
                load(strcat(bsDir, filesep, ProtocolName, filesep, ...
                    'data', filesep, rawFiles(i).FileName))
                fs = min([F.prop.sfreq, fs]);
                t = min([t, F.header.gSetUp.epoch_time]);
            end
        end
        t = floor(t/epTime)*epTime;
    end
end