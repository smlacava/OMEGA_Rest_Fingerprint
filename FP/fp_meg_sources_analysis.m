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

%% TO ADD:
% - A check when using sources on their own anatomy to see if epochs are
%   bad (brainstorm study)
bsDir = 'C:\Users\simon\Downloads\fp';
ProtocolName = 'fp';
epTime = 2;
nEpochs = 5;
condition = '_task-rest_meg_clean_resample_high';
conn_fun = @amplitude_envelope_correlation_orth;


dataDir = strcat(bsDir, filesep, ProtocolName, filesep, 'data', filesep);
cases = dir(dataDir);
N = length(cases);

single_RHO = zeros(1, N); 
single_prjRHO = zeros(1, N); 
single_bothRHO = zeros(1, N); 
single_sesRHO = zeros(1, N);
default_RHO = zeros(1, N);
default_sameRHO = zeros(1, N);
anat_RHO = zeros(1, N);
anat_sameRHO = zeros(1, N);
del_idx = [];

count = 0;
for i = 1:N
    if contains(string(cases(i).name), "sub")
        [aux_RHO, aux_prjRHO, aux_bothRHO, aux_sesRHO] = ...
            single_subjects_analysis(dataDir, cases, cases(i).name, ...
            nEpochs, conn_fun);
        single_prjRHO(i) = aux_prjRHO;   % same head, diff src, same ep
        single_bothRHO(i) = aux_bothRHO; % same head, same prj src, diff ep
        single_sesRHO(i) = aux_sesRHO;   % same head, diff src, same ep
        single_RHO(i) = aux_RHO;         % same head, same src, diff ep

        [aux_RHO, aux_sameRHO] = ...
            paired_subject_default_analysis(dataDir, cases, cases(i).name, ...
            nEpochs, conn_fun);
        default_RHO(i) = aux_RHO;
        default_sameRHO(i) = aux_sameRHO;

        [aux_RHO, aux_sameRHO] = ...
            paired_subject_default_anat_analysis(dataDir, cases, ...
            cases(i).name, nEpochs, conn_fun);
        anat_RHO(i) = aux_RHO;
        anat_sameRHO(i) = aux_sameRHO;

        count = count+1;
        close all
    else
        del_idx = [del_idx, i];
    end
end


[RHO, noRHO, noSameRHO, prjSameRHO, prj2SameRHO, prjRHO, prj2RHO] = ...
    paired_subjects_analysis(dataDir, cases, nEpochs, conn_fun);
close all

%% Descriptive statistics
[single_prjRHO_mn, single_prjRHO_mdn, single_prjRHO_sd] = ...
    describe(single_prjRHO, del_idx);
[single_bothRHO_mn, single_bothRHO_mdn, single_bothRHO_sd] = ...
    describe(single_bothRHO, del_idx);
[single_sesRHO_mn, single_sesRHO_mdn, single_sesRHO_sd] = ...
    describe(single_sesRHO, del_idx);
[single_RHO_mn, single_RHO_mdn, single_RHO_sd] = describe(single_RHO, ...
    del_idx);

[default_sameRHO_mn, default_sameRHO_mdn, default_sameRHO_sd] = ...
    describe(default_sameRHO, del_idx);
[default_RHO_mn, default_RHO_mdn, default_RHO_sd] = ...
    describe(default_RHO, del_idx);

[anat_sameRHO_mn, anat_sameRHO_mdn, anat_sameRHO_sd] = ...
    describe(anat_sameRHO, del_idx);
[anat_RHO_mn, anat_RHO_mdn, anat_RHO_sd] = ...
    describe(anat_RHO, del_idx);

[RHO_mn, RHO_mdn, RHO_sd] = describe(RHO);
[noRHO_mn, noRHO_mdn, noRHO_sd] = describe(noRHO);
[noSameRHO_mn, noSameRHO_mdn, noSameRHO_sd] = describe(noSameRHO);
[prjSameRHO_mn, prjSameRHO_mdn, prjSameRHO_sd] = describe(prjSameRHO);
[prj2SameRHO_mn, prj2SameRHO_mdn, prj2SameRHO_sd] = describe(prj2SameRHO);
[prjRHO_mn, prjRHO_mdn, prjRHO_sd] = describe(prjRHO);
[prj2RHO_mn, prj2RHO_mdn, prj2RHO_sd] = describe(prj2RHO);

%% Si is Sources i on Anatomy i, SiAj is Sources i on Anatomy j 
box_plots({{"S1 vs S1, different sess",[RHO_mn, RHO_mdn, RHO_sd]},...                                 % same head, same src, diff ep (mean per subject's sources)
    {"S1 vs S2, different sess", [noRHO_mn, noRHO_mdn, noRHO_sd]}, ...                                % diff head, diff src, diff ep (mean per subject's sources)
    {"S1 vs S2, same sess", [noSameRHO_mn, noSameRHO_mdn, noSameRHO_sd]},...                          % diff head, diff src, same ep (mean per subject's sources)
    {"S1 vs S2A1, same sess", [prjSameRHO_mn, prjSameRHO_mdn, prjSameRHO_sd]}, ...                    % same head, diff src, same ep (mean per subject's sources)
    {"S2 vs S2A1, same sess", [prj2SameRHO_mn, prj2SameRHO_mdn, prj2SameRHO_sd]}, ...                 % diff head, same src, same ep (mean per subject's sources)
    {"S1 vs S2A1, different sess", [prjRHO_mn, prjRHO_mdn, prjRHO_sd]}, ...                           % same head, diff src, diff ep (mean per subject's sources)
    {"S2 vs S2A1, different sess", [prj2RHO_mn, prj2RHO_mdn, prj2RHO_sd]}, ...                        % diff head, same src, diff ep (mean per subject's sources)
    {"S1 vs S2A1, different sess", [single_prjRHO_mn, single_prjRHO_mdn, single_prjRHO_sd]}, ...      % same head, diff src, same ep (mean per subject's sources)
    {"S2A1 vs S2A1, different sess", [single_bothRHO_mn, single_bothRHO_mdn, single_bothRHO_sd]}, ... % same head, same prj src, diff ep (mean per subject's sources)
    {"S1 vs S2A1, same sess", [single_sesRHO_mn, single_sesRHO_mdn, single_sesRHO_sd]}, ...           % same head, diff src, same ep (mean per subject's sources)
    {"S1A3 vs S2A3, same sess", [anat_sameRHO_mn, anat_sameRHO_mdn, anat_sameRHO_sd]}, ...            % same head, diff prj src, same ep (mean per subject's head)
    {"S1A3 vs S2A3, different sess", [anat_RHO_mn, anat_RHO_mdn, anat_RHO_sd]}, ...                   % same head, diff prj src, diff ep (mean per subject's head)
    {"S3A1 vs S3A2, same sess", [default_sameRHO_mn, default_sameRHO_mdn, default_sameRHO_sd]}, ...   % diff head, same prj src, same ep (mean per subject's sources)
    {"S3A1 vs S3A2, different sess", [default_RHO_mn, default_RHO_mdn, default_RHO_sd]}})             % diff head, same prj src, diff ep (mean per subject's sources)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Analysis on single subjects' anatomy (sources and session effect)
% - NOvsNO (same subject, same head) in different sessions (session effect)
% - NOvsPRJ (different subjects, same head) in the same session (sources
%   effect)
% - NOvsPRJ (different subjects, same head) in different sessions (session
%   and sources effect)
% - PRJvsPRJ (same head, same third-party sources) in different sessions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ù

function [single_RHO, single_prjRHO, single_bothRHO, single_sameRHO] = ...
    single_subjects_analysis(dataDir, cases, srcSubject, nEpochs, ...
    conn_fun, printFLAG)

    if nargin < 6
        printFLAG = 0;
    end
    
    N = length(cases);

    % NOvsNo, same head, same sources, different sessions
    single_RHO = 0;
    single_P = 0;
    
    % NOvsPRJ, same head, different sources, different sessions
    single_prjRHO = 0;
    single_prjP = 0;

    % PRJvsPRJ, same head, same proj sources, different session
    single_bothP = 0;
    single_bothRHO = 0;

    % NOvsPRJ, same head, different sources, same session
    single_sameP = 0;
    single_sameRHO = 0;
    
    count = 0;    % count number of combinations in different sessions
    countSes = 0; % count number of sessions (epochs)

    for i = 1:N
        if contains(string(cases(i).name), "sub-A") & ...
                strcmpi(string(srcSubject), string(cases(i).name)) == 0

            data = access_data(dataDir, cases(i).name); % N1
            projData = access_projected_data(dataDir, cases(i).name, ...
                srcSubject);                            % PRJ2to1

            conn = {};
            projConn = {};
            for j = 1:nEpochs
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
                        single_P = single_P+auxP;
                        single_RHO = single_RHO+auxRHO;
                        hold on
                        scatter(conn{j}(:), projConn{k}(:), 1, 'g', '.')
                        [auxRHO, auxP] = corr(conn{j}(:), projConn{k}(:));
                        single_prjP = single_prjP+auxP;
                        single_prjRHO = single_prjRHO+auxRHO;
                        [auxRHO, auxP] = corr(projConn{j}(:), projConn{k}(:));
                        single_bothP = single_bothP+auxP;
                        single_bothRHO = single_bothRHO+auxRHO;
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
                        single_sameP = single_sameP+auxP;
                        single_sameRHO = single_sameRHO+auxRHO;
                        countSes = countSes+1;
                    end
                end
            end
        end
    end
    single_P = single_P/count;
    single_prjP = single_P/count;
    single_RHO = single_RHO/count;
    single_prjRHO = single_prjRHO/count;
    single_bothP = single_bothP/count;
    single_bothRHO = single_bothRHO/count;
    single_sameRHO = single_sameRHO/countSes;
    single_sameP = single_sameP/countSes;
    if printFLAG == 1
        disp("SINGLE SUBJECTS ANALYSIS: ")
        disp("session effect, head effect, head dominance")
        disp(strcat("RHO: NOvsNO=", string(single_RHO), ...
            " NOvsPRJ(diff sess)=", string(single_prjRHO), " PRJvsPRJ=", ...
            string(single_bothRHO), " NOvsPRJ(same sess)=", string(single_sameRHO)))
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Analysis on pairs of subjects (mean on sources)
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
    RHO = zeros(1,N);
    P = zeros(1, N);

    % NO1 vs NO2, different
    noRHO = zeros(1,N);
    noP = zeros(1, N);

    %NO1 vs NO2, same
    noSameRHO = zeros(1, N);
    noSameP = zeros(1,N);

    % NO1 vs PRJ2 on 1, same
    prjSameRHO = zeros(1, N);
    prjSameP = zeros(1, N);

    % NO2 vs PRJ2 on 1, same
    prj2SameRHO = zeros(1, N);
    prj2SameP = zeros(1, N);

    % NO1 vs PRJ2 on 1, different
    prjRHO = zeros(1, N);
    prjP = zeros(1, N);

    % NO2 vs PRJ2 on 1, different
    prj2RHO = zeros(1, N);
    prj2P = zeros(1, N);

    del_idx = [];

    for s = 1:N %SUB1
        if not(contains(string(cases(s).name), "sub-A"))
            del_idx = [del_idx, s];
            continue;
        end
        noData = access_data(dataDir, cases(s).name);
        noConn = {};
        for j = 1:nEpochs
            noConn = [noConn, conn_fun(noData{j}')];
        end     
        single_RHO = 0;
        single_P = 0;
        single_noRHO = 0;
        single_noP = 0;
        single_noSameRHO = 0;
        single_noSameP = 0;
        single_prjSameRHO = 0;
        single_prjSameP = 0;
        single_prj2SameRHO = 0;
        single_prj2SameP = 0;
        single_prjRHO = 0;
        single_prjP = 0;
        single_prj2RHO = 0;
        single_prj2P = 0;
        count = 0;
        countSes = 0;


        for i = 1:N %SUB2
            if i == s
                continue;
            end
            if contains(string(cases(i).name), "sub-A")
                data = access_data(dataDir, cases(i).name);
                projData = access_projected_data(dataDir, cases(i).name, cases(s).name);

                %% DO ANALYSIS HERE
                conn = {};
                projConn = {};
                for j = 1:nEpochs
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

                            [single_P, single_RHO] = ...
                                correlation_update(conn{j}(:), ...
                                conn{k}(:), single_P, single_RHO);
                            scatter(conn{j}(:), conn{k}(:), 1, 'r', '.')
                            hold on

                            [single_noP, single_noRHO] = ...
                                correlation_update(conn{j}(:), ...
                                noConn{k}(:), single_noP, single_noRHO);
                            scatter(conn{j}(:), noConn{k}(:), 1, 'g', '.')
                            
                            [single_prjP, single_prjRHO] = ...
                                correlation_update(conn{j}(:), ...
                                projConn{k}(:), single_prjP, single_prjRHO);
                            scatter(conn{j}(:), projConn{k}(:), 1, ...
                                'b', '.')

                            [single_prj2P, single_prj2RHO] = ...
                                correlation_update(noConn{j}(:), ...
                                projConn{k}(:), single_prj2P, single_prj2RHO);
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

                            [single_noSameP, single_noSameRHO] = ...
                                correlation_update(conn{j}(:), ...
                                noConn{j}(:), single_noSameP, single_noSameRHO);
                            scatter(conn{j}(:), noConn{j}(:), 1, ...
                                'g', '.')

                            [single_prjSameP, single_prjSameRHO] = ...
                                correlation_update(conn{j}(:), ...
                                projConn{j}(:), single_prjSameP, single_prjSameRHO);
                            scatter(conn{j}(:), projConn{j}(:), 1, ...
                                'b', '.')

                            [single_prj2SameP, single_prj2SameRHO] = ...
                                correlation_update(noConn{j}(:), ...
                                projConn{j}(:), single_prj2SameP, single_prj2SameRHO);
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
        prjP(s) = single_prjP/count;
        prjRHO(s) = single_prjRHO/count;
        prj2P(s) = single_prj2P/count;
        prj2RHO(s) = single_prj2RHO/count;
        noRHO(s) = single_noRHO/count;
        noP(s) = single_noP/count;
        P(s) = single_P/count;
        RHO(s) = single_RHO/count;
        noSameP(s) = single_noSameP/countSes;
        noSameRHO(s) = single_noSameRHO/countSes;
        prjSameP(s) = single_prjSameP/countSes;
        prjSameRHO(s) = single_prjSameRHO/countSes;
        prj2SameP(s) = single_prj2SameP/countSes;
        prj2SameRHO(s) = single_prj2SameRHO/countSes;
    end

    prjP(del_idx) = [];
    prjRHO(del_idx) = [];
    prj2P(del_idx) = [];
    prj2RHO(del_idx) = [];
    noRHO(del_idx) = [];
    noP(del_idx) = [];
    P(del_idx) = [];
    RHO(del_idx) = [];
    noSameP(del_idx) = [];
    noSameRHO(del_idx) = [];
    prjSameP(del_idx) = [];
    prjSameRHO(del_idx) = [];
    prj2SameP(del_idx) = [];
    prj2SameRHO(del_idx) = [];

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
%% Analysis on pairs of subjects using default sources
% - Sources projected on 2 anatomies in same session (about equal if data
%   effect is dominant over head)
% - Sources projected on 2 anatomies in different sessions (about equal if 
%   data effect is dominant overall)
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
        for j = 1:nEpochs
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
                for j = 1:nEpochs
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
%% Analysis on pairs of subjects using a default anatomy
% - 2 subjects PRJ on the same head same session (about equal if 
%   head effect is dominant over data)
% - 2 subjects PRJ on the same head same session (about equal if 
%   head effect is dominant overall)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [RHO, sameRHO] = paired_subject_default_anat_analysis(dataDir, ...
    cases, anatSubject, nEpochs, conn_fun, printFLAG)


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
                contains(string(cases(s).name), string(anatSubject))
            continue;
        end
        conn = {};
        projData = access_projected_data(dataDir, anatSubject, ...
            cases(s).name);
        for j = 1:nEpochs
            conn = [conn, conn_fun(projData{j}')];
        end
        for i = s+1:N
            if contains(string(cases(i).name), "sub-A") & ...
                    not(contains(string(cases(s).name), ...
                    string(anatSubject)))
                projData2 = access_projected_data(dataDir, anatSubject, ...
                    cases(i).name);

                %% DO ANALYSIS HERE
                conn2 = {};
                for j = 1:nEpochs
                    conn2 = [conn2, conn_fun(projData2{j}')];
                end
                figure('Name',strcat(cases(s).name, " vs ", ...
                    cases(i).name, ", projected on ", anatSubject))
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
%% Access projected subject's source data
% subject_name identify the subject to which the anatomy belongs
% srcSubject identify the subject to which the source data belongs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data = access_projected_data(dataDir, anatSubject, srcSubject)
    data = {};
    subDir = strcat(dataDir, anatSubject, filesep, srcSubject, ...
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Evaluate descriptive statistics from RHO vectors
% mn:  mean
% mdn: median
% sd:  standard deviation
%
% Each RHO in the vector is related to the average for the single subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [mn, mdn, sd] = describe(RHO, del_idx)
    if nargin < 2
        del_idx = [];
    end
    RHO(del_idx) = [];
    mn = mean(RHO);
    mdn = median(RHO);
    sd = std(RHO);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Box plots mean±std highlighting the median in red
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function box_plots(RHOs)
    figure("Name", "RHO","Color","w")
    ticks = [];
    lbl = [];
    max_dev = 0;
    for i = 1:length(RHOs)
        aux = RHOs{i};
        name = aux{1};
        stats = aux{2};
        mn = stats(1);
        mdn = stats(2);
        sd = stats(3);
        if max_dev < mn+sd
            max_dev = mn+sd;
        end
        dx = i*3;
        plot([1+dx, 1+dx], [mn-sd, mn+sd], 'k')
        hold on
        plot([1+dx, 2+dx], [mn-sd, mn-sd], 'k')
        plot([1+dx, 2+dx], [mn, mn], 'k')
        plot([1+dx, 2+dx], [mn+sd, mn+sd], 'k')
        plot([2+dx, 2+dx], [mn-sd, mn+sd], 'k')
        plot([0.5+dx, 2.5+dx], [mdn, mdn], 'r')
        ticks = [ticks, dx+1.5];
        lbl = [lbl, name];
    end
    hold off
    xticks([4.5:3:dx+1.6])
    xticklabels(lbl)
    xlim([0, dx+3])
    ylim([0, max(1, max_dev+0.1)])
    ylabel("RHO")
end
