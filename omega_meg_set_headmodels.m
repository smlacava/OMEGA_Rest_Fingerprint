bsDir = 'C:\Users\simon\OneDrive\Desktop\Ricerca\EEGLab';
inDir = 'D:\MEG\OMEGA_OpenNeuro';
ProtocolName = 'Omega_Study';
subject_head = 'sub-0003';
pattern = 'sub-0';  %common pattern in subject names
session = '01'; %fixed
rest_run = '01'; %fixed
set_common_head_model(bsDir, ProtocolName, subject_head, ...
    session, rest_run, pattern)

function set_common_head_model(bsDir, ProtocolName, subject_head, ...
    session, rest_run, pattern)
    head_model = strcat(subject_head, '/@raw', subject_head, '_ses-', ...
        session, '_task-rest_run-', rest_run, ...
        '_meg_notch_high/headmodel_surf_os_meg.mat');
    dataDir = strcat(bsDir, filesep, ProtocolName, filesep, 'data', ...
        filesep);
    cases = dir(fullfile(dataDir));
    for i = 1:length(cases)
        if contains(string(cases(i).name), string(pattern))
            fName = strcat(dataDir, cases(i).name, filesep, '@raw', ...
                cases(i).name, ...
                '_ses-01_task-rest_run-01_meg_notch_high', filesep, ...
                'results_dSPM-unscaled_MEG_KERNEL_211220_2151.mat'); %CHECK IF ERROR
            aux = load(fName);
            aux.HeadModelFile = head_model;
            save(fName,'-struct','aux')
        end
    end
end