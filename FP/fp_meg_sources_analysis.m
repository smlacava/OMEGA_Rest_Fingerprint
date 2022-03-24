%% ANALYSIS
% 1) Scouts (NO) and reprojected scouts (PRJ) are accessed
% 2) Time series are analyzed
%
% Analyses:
% - NOvsNO in different sessions (session effect)
% - NOvsPRJ in the same session (head effect)
% - NOvsPRJ in different sessions (if similar to NOvsPRJ in the same
%   session, then head effect is dominant with respect to sessions)
% - PRJvsPRJ in different sessions (if similar to NOvsNO then head effect
%   is dominant)
%
% - 2 subjects NO (ability to distinguish between them)
% - NO and another subject PRJ on NO in the same session (about equal if 
%   head effect is dominant)
% - NO and another subject PRJ on NO in different sessions (about equal if
%   head effect is dominant)
% - 2 subjects PRJ on the same head different sessions (about equal if 
%   head effect is dominant)

bsDir = 'C:\Users\simon\Downloads\fp';
ProtocolName = 'fp';
epTime = 2;
nEpochs = 5;
%srcSubject = 'sub-A2004';
condition = '_task-rest_meg_clean_resample_high';
conn_fun = @phase_locking_value;


single_RHO = 0; 
single_prjRHO = 0; 
single_bothRHO = 0; 
single_sesRHO = 0;
default_RHO = 0;
default_sameRHO = 0;

dataDir = strcat(bsDir, filesep, ProtocolName, filesep, 'data', filesep);
cases = dir(dataDir);
N = length(cases);

count = 0;
for i = 1:N
    if contains(string(cases(i).name), "sub")
        [aux_RHO, aux_prjRHO, aux_bothRHO, aux_sesRHO] = ...
            single_subjects_analysis(dataDir, cases, cases(i).name, ...
            nEpochs, conn_fun);
        single_prjRHO = single_prjRHO+aux_prjRHO;
        single_bothRHO = single_bothRHO+aux_bothRHO;
        single_sesRHO = single_sesRHO+aux_sesRHO;
        single_RHO = single_RHO+aux_RHO;

        [aux_RHO, aux_sameRHO] = ...
            paired_subject_default_analysis(dataDir, cases, srcSubject, ...
            nEpochs, conn_fun);
        default_RHO = default_RHO+aux_RHO;
        default_sameRHO = default_sameRHO+aux_sameRHO;

        count = count+1;
        close all
    end
end
single_prjRHO = single_prjRHO/count;
single_bothRHO = single_bothRHO/count;
single_sesRHO = single_sesRHO/count;
single_RHO = single_RHO/count;
default_sameRHO = default_sameRHO/count;
default_RHO = default_RHO/count;

[RHO, noRHO, noSameRHO, prjSameRHO, prj2SameRHO, prjRHO, prj2RHO] = ...
    paired_subjects_analysis(dataDir, cases, nEpochs, conn_fun);
close all

disp("SINGLE SUBJECTS ANALYSIS: ")
disp(strcat("RHO: NOvsNO=", string(single_RHO), " NOvsPRJ(diff sess)=", ...
    string(single_prjRHO), " PRJvsPRJ=", string(single_bothRHO), ...
    " NOvsPRJ(same sess)=", string(single_sesRHO)))
disp("PAIRED SUBJECTS ANALYSIS-SAME SESSION: ")
disp(strcat("RHO: NO1vsNO2=", string(noSameRHO), " NO2vsPRJ2on1=", ...
    string(prjSameRHO)," NO1vsPRJ2on1=", string(prj2SameRHO)))
disp("---")
disp("PAIRED SUBJECTS ANALYSIS-DIFFERENT SESSIONS: ")
disp(strcat("RHO: NO1vsNO1=", string(RHO), " NO1vsNO2=", string(noRHO), ...
    " NO2vsPRJ2on1=", string(prjRHO), " NO1vsPRJ2on1=", string(prj2RHO)))
disp("---")
disp("PAIRED SUBJECTS ANALYSIS-DEFAULT ANATOMY: ")
disp("PRJ1 on 3 vs PRJ2 on 3")
disp(strcat("RHO: same_session=", string(default_sameRHO), ...
    " different_session=", string(default_RHO)))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Analysis on single subjects
% - NOvsNO (same subject, same head) in different sessions (session effect)
% - NOvsPRJ (same subject, different head) in the same session (head 
%   effect)
% - NOvsPRJ (same subject, different head) in different sessions (if 
%   similar to NOvsPRJ in the same)
%   session, then head effect is dominant with respect to sessions)
% - PRJvsPRJ (same subject, same third-party head) in different sessions
%   (if similar to NOvsNO then head effect is dominant)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ù

function [RHO, projRHO, bothRHO, sesRHO] = ...
    single_subjects_analysis(dataDir, cases, srcSubject, nEpochs, ...
    conn_fun, printFLAG)

    if nargin < 6
        printFLAG = 0;
    end
    
    N = length(cases);

    % NOvsNo same subject, same head, different sessions
    RHO = 0;
    P = 0;
    
    % NOvsPRJ same subject, different head, different sessions
    projRHO = 0;
    projP = 0;

    % PRJvsPRJ same subject, same (other) head, different sessions
    bothP = 0;
    bothRHO = 0;

    % NOvsPRJ same subject, different head, same session
    sesP = 0;
    sesRHO = 0;
    
    count = 0;
    countSes = 0;

    for i = 1:N
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
                        if j == 1
                            title(strcat("Ses ", string(k)))
                        end
                        if k == 1
                            ylabel(strcat("Ses ", string(j)))
                        end
                        [auxRHO, auxP] = corr(conn{j}(:), conn{k}(:));
                        P = P+auxP;
                        RHO = RHO+auxRHO;
                        hold on
                        scatter(conn{j}(:), projConn{k}(:), 1, 'g', '.')
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
                        ylabel(strcat("Ses ", string(j)))
                        title(strcat("Ses ", string(k)))
                        legend({'NvsN', 'NvsPRJ'}, 'FontSize', 6)
                        xlim([0, 1])
                        ylim([0, 1])
                        [auxRHO, auxP] = corr(conn{j}(:), projConn{k}(:));
                        sesP = sesP+auxP;
                        sesRHO = sesRHO+auxRHO;
                        countSes = countSes+1;
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
    sesRHO = sesRHO/countSes;
    sesP = sesP/countSes;
    if printFLAG == 1
        disp("SINGLE SUBJECTS ANALYSIS: ")
        disp("session effect, head effect, head dominance")
        disp(strcat("RHO: NOvsNO=", string(RHO), ...
            " NOvsPRJ(diff sess)=", string(projRHO), " PRJvsPRJ=", ...
            string(bothRHO), " NOvsPRJ(same sess)=", string(sesRHO)))
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Analysis on pairs of subjects
% - 2 subjects NO (their own head) in the same session (ability to 
%   distinguish between them)
% - 2 subjects NO (their own head) in different sessions (ability to 
%   distinguish between them)
% - NO and another subject PRJ on NO in the same session (about equal if 
%   head effect is dominant)
% - NO and another subject PRJ on NO in different sessions (about equal if
%   head effect is dominant)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ù

function [RHO, noRHO, noSameRHO, prjSameRHO, prj2SameRHO, prjRHO, ...
    prj2RHO] = paired_subjects_analysis(dataDir, cases, nEpochs, ...
    conn_fun, printFLAG)

    if nargin < 5
        printFLAG = 0;
    end
    
    N = length(cases);
    
    % NO1 vs NO1, different
    RHO = 0;
    P = 0;

    % NO1 vs NO2, different
    noRHO = 0;
    noP = 0;

    %NO1 vs NO2, same
    noSameRHO = 0;
    noSameP = 0;

    % NO1 vs PRJ2 on 1, same
    prjSameRHO = 0;
    prjSameP = 0;

    % NO2 vs PRJ2 on 1, same
    prj2SameRHO = 0;
    prj2SameP = 0;

    % NO1 vs PRJ2 on 1, different
    prjRHO = 0;
    prjP = 0;

    % NO2 vs PRJ2 on 1, different
    prj2RHO = 0;
    prj2P = 0;

    count = 0;
    countSes = 0;

    for s = 1:N %NO1
        if not(contains(string(cases(s).name), "sub-A"))
            continue;
        end
        noData = access_data(dataDir, cases(s).name);
        noConn = {};
        for j = 2:nEpochs+1
            noConn = [noConn, conn_fun(noData{j}')];
        end
        for i = 1:N %NO2
            if i == s
                continue;
            end
            if contains(string(cases(i).name), "sub-A")
                data = access_data(dataDir, cases(i).name);
                projData = access_projected_data(dataDir, cases(i).name, cases(s).name);

                %% DO ANALYSIS HERE
                conn = {};
                projConn = {};
                for j = 2:nEpochs+1
                    conn = [conn, conn_fun(data{j}')];
                    projConn = [projConn, conn_fun(projData{j}')];
                end
                figure('Name',strcat(cases(s).name, " vs ", cases(i).name))
                for j = 1:nEpochs
                    for k = 1:nEpochs
                        if k ~= j
                            subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                            if j == 1
                                title(strcat("Ses ", string(k)))
                            end
                            if k == 1
                                ylabel(strcat("Ses ", string(j)))
                            end

                            [P, RHO] = ...
                                correlation_update(conn{j}(:), ...
                                conn{k}(:), P, RHO);
                            scatter(conn{j}(:), conn{k}(:), 1, 'r', '.')
                            hold on

                            [noP, noRHO] = ...
                                correlation_update(conn{j}(:), ...
                                noConn{k}(:), noP, noRHO);
                            scatter(conn{j}(:), conn{k}(:), 1, 'g', '.')
                            
                            [prjP, prjRHO] = ...
                                correlation_update(conn{j}(:), ...
                                projConn{k}(:), prjP, prjRHO);
                            scatter(conn{j}(:), projConn{k}(:), 1, ...
                                'b', '.')

                            [prj2P, prj2RHO] = ...
                                correlation_update(noConn{j}(:), ...
                                projConn{k}(:), prj2P, prj2RHO);
                            scatter(noConn{j}(:), projConn{k}(:), 1, ...
                                'k', '.')

                            xlim([0, 1])
                            ylim([0, 1])
                            count = count+1;
                        else
                            subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                            scatter(conn{j}(:), conn{j}(:), 1, ...
                                'r', '.')
                            hold on

                            [noSameP, noSameRHO] = ...
                                correlation_update(conn{j}(:), ...
                                noConn{j}(:), noSameP, noSameRHO);
                            scatter(conn{j}(:), noConn{j}(:), 1, ...
                                'g', '.')

                            [prjSameP, prjSameRHO] = ...
                                correlation_update(conn{j}(:), ...
                                projConn{j}(:), prjSameP, prjSameRHO);
                            scatter(conn{j}(:), projConn{j}(:), 1, ...
                                'b', '.')

                            [prj2SameP, prj2SameRHO] = ...
                                correlation_update(noConn{j}(:), ...
                                projConn{j}(:), prj2SameP, prj2SameRHO);
                            scatter(noConn{j}(:), projConn{j}(:), 1, ...
                                'k', '.')

                            ylabel(strcat("Ses ", string(j)))
                            title(strcat("Ses ", string(k)))
                            legend({'N1vsN1', 'N1vsN2', 'N2vsPRJ2on1', ...
                                'N1vsPRJ2on1'}, ...
                                'FontSize', 6)
                            xlim([0, 1])
                            ylim([0, 1])
                            countSes = countSes+1;
                        end
                    end
                end
            end
        end
    end
    prjP = prjP/count;
    prjRHO = prjRHO/count;
    prj2P = prj2P/count;
    prj2RHO = prj2RHO/count;
    noRHO = noRHO/count;
    noP = noP/count;
    P = P/count;
    RHO = RHO/count;

    noSameP = noSameP/countSes;
    noSameRHO = noSameRHO/countSes;
    prjSameP = prjSameP/countSes;
    prjSameRHO = prjSameRHO/countSes;
    prj2SameP = prj2SameP/countSes;
    prj2SameRHO = prj2SameRHO/countSes;

    if printFLAG == 1
        disp("PAIRED SUBJECTS ANALYSIS-SAME SESSION: ")
        disp("head effect (N1, N2, and PRJ2 on 1)")
        disp(strcat("RHO: NO1vsNO2=", string(noSameRHO), " NO2vsPRJ2on1=", ...
            string(prjSameRHO)," NO1vsPRJ2on1=", string(prj2SameRHO)))
        disp("")
        disp("PAIRED SUBJECTS ANALYSIS-DIFFERENT SESSIONS: ")
        disp("head effect, session effect (N1, N2, and PRJ2 on 1)")
        disp(strcat("RHO: NO1vsNO1=", string(RHO), " NO1vsNO2=", ...
            string(noRHO), " NO2vsPRJ2on1=", string(prjRHO), ...
            " NO1vsPRJ2on1=", string(prj2RHO)))
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Analysis on pairs of subjects using a default anatomy
% - 2 subjects PRJ on the same head same session (about equal if 
%   head effect is dominant over data)
% - 2 subjects PRJ on the same head same session (about equal if 
%   head effect is dominant overall)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [RHO, sameRHO] = paired_subject_default_analysis(dataDir, ...
    cases, srcSubject, nEpochs, conn_fun, printFLAG)


    if nargin < 6
        printFLAG = 0;
    end
    
    N = length(cases);
    
    % PRJ1on3 vs PRJ2on3, same session
    sameRHO = 0;
    sameP = 0;

    % PRJ1on3 vs PRJ2on3, different sessions
    RHO = 0;
    P = 0;

    count = 0;
    countSes = 0;

    for s = 1:N-1
        if not(contains(string(cases(s).name), "sub-A")) | ...
                contains(string(cases(s).name), string(srcSubject))
            continue;
        end
        conn = {};
        projData = access_projected_data(dataDir, cases(s).name, ...
            srcSubject);
        for j = 2:nEpochs+1
            conn = [conn, conn_fun(projData{j}')];
        end
        for i = s+1:N
            if contains(string(cases(i).name), "sub-A") & ...
                    not(contains(string(cases(s).name), ...
                    string(srcSubject)))
                projData2 = access_projected_data(dataDir, ...
                    cases(i).name, srcSubject);

                %% DO ANALYSIS HERE
                conn2 = {};
                for j = 2:nEpochs+1
                    conn2 = [conn2, conn_fun(projData2{j}')];
                end
                figure('Name',strcat(cases(s).name, " vs ", ...
                    cases(i).name, ", projected on ", srcSubject))
                for j = 1:nEpochs
                    for k = 1:nEpochs
                        if k ~= j
                            subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                            if j == 1
                                title(strcat("Ses ", string(k)))
                            end
                            if k == 1
                                ylabel(strcat("Ses ", string(j)))
                            end

                            [P, RHO] = ...
                                correlation_update(conn{j}(:), ...
                                conn2{k}(:), P, RHO);
                            scatter(conn{j}(:), conn2{k}(:), 1, 'r', '.')
                            xlim([0, 1])
                            ylim([0, 1])
                            count = count+1;
                        else
                            subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                            [sameP, sameRHO] = ...
                                correlation_update(conn{j}(:), ...
                                conn2{j}(:), sameP, sameRHO);
                            scatter(conn{j}(:), conn2{j}(:), 1, ...
                                'r', '.')
                            hold on
                            xlim([0, 1])
                            ylim([0, 1])
                            countSes = countSes+1;
                        end
                    end
                end
            end
        end
    end
    P = P/count;
    RHO = RHO/count;
    sameP = sameP/countSes;
    sameRHO = sameRHO/countSes;

    if printFLAG == 1
        disp("PAIRED SUBJECTS ANALYSIS-DEFAULT ANATOMY: ")
        disp("PRJ1 on 3 vs PRJ2 on 3")
        disp(strcat("RHO: same_session=", string(sameRHO), ...
            " different_session=", string(RHO)))
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
        '_task-rest_meg_clean_resample_high', filesep);
    cases = dir(subDir);
    for i = 1:length(cases)
        if contains(string(cases(i).name), "matrix_scout")
            a = load(strcat(subDir, cases(i).name));
            data = [data, a.Value];
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Perform a correlation analysis and updates RHO and P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [P, RHO] = correlation_update(data1, data2, P, RHO)
    [auxRHO, auxP] = corr(data1, data2);
    P = P+auxP;
    RHO = RHO+auxRHO;
end