srcSubject = 'sub-0002';
anatSubject = 'sub-0003';

sProcess = struct();
sProcess.Function = @process_extract_scout;
sProcess.Comment = 'Scouts time series';
sProcess.FileTag = '';
sProcess.Description = 'https://neuroimage.usc.edu/brainstorm/Tutorials/Scouts';
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
sProcess.isSourceAbsolute = 0;
sProcess.processDim = [];
sProcess.options = struct();

sProcess.options.timewindow = struct(); 
sProcess.options.timewindow.Comment = 'Time window';
sProcess.options.timewindow.Type = 'timewindow';
sProcess.options.timewindow.Value = {[], 's', []};

sProcess.options.scouts = struct(); 
sProcess.options.scouts.Comment = '';
sProcess.options.scouts.Type = 'scout';
sProcess.options.scouts.Value= {scout, ROIs};

sProcess.options.scoutfunc = struct();
sProcess.options.scoutfunc.Comment = {'Mean', 'Max', 'PCA', 'Std', 'All', 'Scout function;'};
sProcess.options.scoutfunc.Type = 'radio_line';
sProcess.options.scoutfunc.Value = 1;

sProcess.options.isflip = struct();
sProcess.options.isflip.Comment = 'Flip the sign of sources with opposite directions';
sProcess.options.isflip.Type = 'checkbox';
sProcess.options.isflip.Value = 1;
sProcess.options.isflip.InputTypes = {'results'};


sProcess.options.isnorm = struct();
sProcess.options.isnorm.Comment = 'Unconstrained sources: Norm of the three orientations (x,y,z)';
sProcess.options.isnorm.Type = 'checkbox';
sProcess.options.isnorm.TValue = 0;
sProcess.options.isnorm.InputTypes = {'results'};

sProcess.options.concatenate = struct();
sProcess.options.concatenate.comment = 'Concatenate output in one unique matrix';
sProcess.options.concatenate.Type = 'checkbox';
sProcess.options.concatenate.Value = 1;

sProcess.options.save = struct();
sProcess.options.save.Comment = '';
sProcess.options.save.Type = 'ignore';
sProcess.options.save.Value = 1;

sProcess.options.addrowcomment = struct();
sProcess.options.addrowcomment.Comment = '';
sProcess.options.addrowcomment.Type = 'ignore';
sProcess.options.addrowcomment.Value = 1;

sProcess.options.addfilecomment = struct(); %
sProcess.options.addfilecomment.Comment = '';
sProcess.options.addfilecomment.Type = 'ignore';
sProcess.options.addfilecomment.Value = 1;

sInput.struct();
sInput.iStudy = 13;
sInput.iItem = 1;
sInput.FileName = strcat(anatSubject, filesep, srcSubject, ...
    '_ses-01_task-rest_run-01_meg_notch_high', filesep, ...
    'results_dSPM-unscaled_MEG_KERNEL_211223_0927.mat');%'sub-0002/@rawsub-0002_ses-01_task-rest_run-01_meg_notch_high/results_dSPM-unscaled_MEG_KERNEL_211223_0927.mat';
sInput.FileType = 'results';
sInput.Comment = 'dSPM: MEG(Constr) 2018';
sInput.Condition = strcat(srcSubject, ...
    '_ses-01_task-rest_run-01_meg_notch_high'); %@rawsub-0002_ses-01_task-rest_run-01_meg_notch_high';
sInput.SubjectFile = strcat(anatSubject, filesep, 'brainstormsubject.mat');
sInput.SubjectName = anatSubject;
sInput.DataFile = 'sub-0002/@rawsub-0002_ses-01_task-rest_run-01_meg_notch_high/data_0raw_sub-0002_ses-01_task-rest_run-01_meg_notch_high.mat';
sInput.ChannelFile = 'sub-0002/@rawsub-0002_ses-01_task-rest_run-01_meg_notch_high/channel_ctf_acc1.mat';
sInput.ChannelTypes = {'ECG', 'HEOG', 'MEG', 'MEG REF', 'SyssClock', 'VEOG'};

bst_process('Run', sProcess, sInput, [], 1)
bst_process('GetNewFilename','sub-0003/@rawsub-0003_ses-01_task-rest_run-01_meg_notch_high','matrix_scout')