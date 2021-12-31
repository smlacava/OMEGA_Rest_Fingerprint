bsDir = 'C:\Users\simon\OneDrive\Desktop\Ricerca\EEGLab';
ProtocolName = 'Omega_Study';
epTime = 15;
nEpochs = 5;
srcSubject = 'sub-0002';

dataDir = strcat(bsDir, filesep, ProtocolName, filesep, 'data', filesep);
cases = dir(dataDir);
for i = 1:length(cases)
    if contains(string(cases(i).name), "sub-0") & ...
            strcmpi(string(srcSubject), string(cases(i).name)) == 0
        data = access_data(dataDir, cases(i).name);
        prjData = access_projected_data(dataDir, cases(i).name, srcSubject);

        %% DO ANALYSIS HERE
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Access subject's scout data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data = access_data(dataDir, subject_name)
    data = access_projected_data(dataDir, subject_name, subject_name);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Access projected subject's scout data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data = access_projected_data(dataDir, subject_name, srcSubject)
    data = {};
    subDir = strcat(dataDir, subject_name, filesep, srcSubject, ...
        '_ses-01_task-rest_run-01_meg_notch_high', filesep);
    cases = dir(subDir);
    for i = 1:length(cases)
        if contains(string(cases(i).name), "matrix_scout")
            a = load(strcat(subDir, cases(i).name));
            data = [data, a.Value];
        end
    end
end