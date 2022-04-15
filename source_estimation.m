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

function sourceFiles = source_estimation(importFiles, anatCHECK, ...
    measure)
    if nargin < 2
        anatCHECK = 0;
    end
    if nargin < 3
        measure = 'dspm2018';
    end

    if contains(string(measure), "dspm")
        comment = 'dSPM: MEG';
    elseif contains(string(measure), "sloreta")
        comment = 'sLORETA: MEG';
    else
        comment = 'MN: MEG';
    end

    sourceFiles = {};
    for i = 1:length(importFiles)
        if anatCHECK == 0
            bst_process('CallProcess', 'process_noisecov', ...
                importFiles{i}, [], 'baseline', [], 'sensortypes', ...
                'MEG', 'target', 1, 'dcoffset', 1, 'identity', 0, ...
                'copycond', 1, 'copysubj', 1, 'copymatch', 1, ...
                'replacefile', 1);
            bst_process('CallProcess', 'process_headmodel', ...
                importFiles{i}, [], 'sourcespace', 1, 'meg', 3);
        end
        sourceFiles = [sourceFiles, bst_process('CallProcess',...
            'process_inverse_2018', importFiles{i}, [], 'output', 2, ...
            'inverse', struct('Comment', comment, 'InverseMethod', ...
            'minnorm',  'InverseMeasure', measure, 'SourceOrient', ...
            {{'fixed'}}, 'Loose', 0.2, 'UseDepth', 1, 'WeightExp', 0.5, ...
            'WeightLimit', 10, 'NoiseMethod', 'reg', 'NoiseReg', 0.1, ...
            'SnrMethod', 'fixed', 'SnrRms', 1e-06, 'SnrFixed', 3, ...
            'ComputeKernel', 1, 'DataTypes', {{'MEG'}}))];
    end
end