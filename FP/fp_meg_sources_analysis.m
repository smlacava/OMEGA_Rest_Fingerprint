%% ANALYSIS
% 1) Scouts (NO) and reprojected scouts (PRJ) are accessed
% 2) Time series are analyzed

bsDir = 'C:\Users\simon\Downloads\fp';
ProtocolName = 'fp';
epTime = 2;
nEpochs = 5;
srcSubject = 'sub-A2002';
condition = '_task-rest_meg_clean_resample_high';
conn_fun = @phase_lag_index;

dataDir = strcat(bsDir, filesep, ProtocolName, filesep, 'data', filesep);
cases = dir(dataDir);
N = length(cases);
try
    clear P
catch
end
for i = 1:N
    if not(exist("P", "var"))
        RHO = 0;
        P = 0;
        projRHO = 0;
        projP = 0;
        bothP = 0;
        bothRHO = 0;
        count = 0;
    end
    if contains(string(cases(i).name), "sub-A") & ...
            strcmpi(string(srcSubject), string(cases(i).name)) == 0
        data = access_data(dataDir, cases(i).name);
        projData = access_projected_data(dataDir, cases(i).name, srcSubject);

        %% DO ANALYSIS HERE
        conn = {};
        projConn = {};
        for j = 2:nEpochs+1
            conn = [conn, conn_fun(data{j}')];
            projConn = [projConn, conn_fun(projData{j}')];
        end
        figure('Name',cases(i).name)
        for j = 1:nEpochs
            for k = 1:nEpochs
                if k ~= j
                    subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                    scatter(conn{j}(:), conn{k}(:), 1, 'r', '.')
                    [auxRHO, auxP] = corr(conn{j}(:), conn{k}(:));
                    P = P+auxP;
                    RHO = RHO+auxRHO;
                    hold on
                    scatter(conn{j}(:), projConn{j}(:), 1, 'g', '.')
                    [auxRHO, auxP] = corr(conn{j}(:), projConn{k}(:));
                    projP = projP+auxP;
                    projRHO = projRHO+auxRHO;
                    [auxRHO, auxP] = corr(projConn{j}(:), projConn{k}(:));
                    bothP = bothP+auxP;
                    bothRHO = bothRHO+auxRHO;
                    xlim([0, 1])
                    ylim([0, 1])
                    count = count+1;      
                else
                    subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                    scatter(conn{j}(:), conn{k}(:), 1, 'r', '.')
                    hold on
                    scatter(conn{j}(:), projConn{j}(:), 1, 'g', '.')
                    legend({'NvsN', 'NvsPRJ'}, 'FontSize', 6)
                    xlim([0, 1])
                    ylim([0, 1])
                end
            end
        end
    end
end
P = P/count;
projP = P/count;
RHO = RHO/count;
projRHO = projRHO/count;
bothP = bothP/count;
bothRHO = bothRHO/count;
disp(strcat("P:   NOvsNO=", string(P), " NOvsPRJ=", string(projP), ...
    " PRJvsPRJ=", string(bothP)))
disp(strcat("RHO: NOvsNO=", string(RHO), " NOvsPRJ=", string(projRHO), ...
    " PRJvsPRJ=", string(bothRHO)))

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
        '_task-rest_meg_clean_resample_high', filesep);
    cases = dir(subDir);
    for i = 1:length(cases)
        if contains(string(cases(i).name), "matrix_scout")
            a = load(strcat(subDir, cases(i).name));
            data = [data, a.Value];
        end
    end
end