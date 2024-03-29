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
bsDir = 'D:\Ricerca';
ProtocolName = 'FP_MOUS_res';
epTime = 2;
nEpochs = 5;
conn_fun = "AEC";%@amplitude_envelope_correlation_orth;
scatter_view = 0;


dataDir = strcat(bsDir, filesep, ProtocolName, filesep, 'data', filesep);
aux_conn_fun = conn_fun;
if isa(conn_fun, "string")
    dataDir = strcat(dataDir, conn_fun, filesep);
    aux_conn_fun = @no_fun;
end

cases = dir(dataDir);
N = length(cases);
if N == 0
    dataDir = strcat(bsDir, filesep, ProtocolName, filesep);
    if isa(conn_fun, "string")
        dataDir = strcat(dataDir, conn_fun, filesep);
        aux_conn_fun = @no_fun;
    end
    cases = dir(dataDir);
    N = length(cases);
end
conn_fun = aux_conn_fun;

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
    if contains(string(cases(i).name), "sub") && ...
            not(contains(string(cases(i).name), "@")) && ...
            not(contains(string(cases(i).name), "emptyroom"))
        [aux_RHO, aux_prjRHO, aux_bothRHO, aux_sesRHO] = ...
            single_subjects_analysis(dataDir, cases, cases(i).name, ...
            nEpochs, conn_fun, scatter_view);
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
        disp(count/N)
    else
        del_idx = [del_idx, i];
    end
end

dips("Paired:")
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
    countProj = 0;

    for i = 1:N
        if not(strcmpi(string(srcSubject), string(cases(i).name))) && ...
                contains(string(cases(i).name), "sub") && ...
                not(contains(string(cases(i).name), "@")) && ...
                not(contains(string(cases(i).name), "emptyroom"))

            data = access_data(dataDir, cases(i).name); % N1
            projData = access_projected_data(dataDir, cases(i).name, ...
                srcSubject);                            % PRJ2to1

            conn = {};
            projConn = {};
            for j = 1:nEpochs
                conn = [conn, conn_fun(data{j}')];
                if not(isempty(projData))
                    projConn = [projConn, conn_fun(projData{j}')];
                end
            end
            if printFLAG == 1
                figure('Name',cases(i).name)
            end
            for j = 1:nEpochs
                for k = 1:nEpochs
                    if k ~= j
                        if printFLAG == 1
                            subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                            scatter(conn{j}(:), conn{k}(:), 1, 'r', '.')
                            if j == 1
                                title(strcat("Ses ", string(k)))
                            end
                            if k == 1
                                ylabel(strcat("Ses ", string(j)))
                            end
                            hold on
                            if not(isempty(projConn))
                                scatter(conn{j}(:), projConn{k}(:), 1, 'g', '.')
                            end
                            xlim([0, 1])
                            ylim([0, 1])
                        end
                        [auxRHO, auxP] = corr(conn{j}(:), conn{k}(:));
                        single_P = single_P+auxP;
                        single_RHO = single_RHO+auxRHO;
                        count = count+1;
                        if not(isempty(projConn))
                            [auxRHO, auxP] = corr(conn{j}(:), projConn{k}(:));
                            single_prjP = single_prjP+auxP;
                            single_prjRHO = single_prjRHO+auxRHO;
                            [auxRHO, auxP] = corr(projConn{j}(:), projConn{k}(:));
                            single_bothP = single_bothP+auxP;
                            single_bothRHO = single_bothRHO+auxRHO;
                            countProj = countProj+1;
                        end
                    else
                        if isempty(projConn)
                            continue;
                        end
                        if printFLAG == 1
                            subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                            scatter(conn{j}(:), conn{k}(:), 1, 'r', '.')
                            hold on
                            lgd = {'NvsN'};
                            if not(isempty(projConn))
                                scatter(conn{j}(:), projConn{j}(:), 1, 'g', '.')
                                lgd = [lgd, 'NvsPRJ'];
                            end
                            ylabel(strcat("Ses ", string(j)))
                            title(strcat("Ses ", string(k)))
                            legend(lgd, 'FontSize', 6)
                            xlim([0, 1])
                            ylim([0, 1])
                        end
                        if not(isempty(projConn))
                            [auxRHO, auxP] = corr(conn{j}(:), projConn{k}(:));
                            single_sameP = single_sameP+auxP;
                            single_sameRHO = single_sameRHO+auxRHO;
                            countSes = countSes+1;
                        end
                    end
                end
            end
        end
    end
    if count == 0
        single_P = NaN;
        single_RHO = NaN;
    else
        single_P = single_P/count;
        single_RHO = single_RHO/count;
    end
    if countProj == 0
        single_prjP = NaN;
        single_prjRHO = NaN;
        single_bothP = NaN;
        single_bothRHO = NaN;
    else
        single_prjP = single_P/countProj;
        single_prjRHO = single_prjRHO/countProj;
        single_bothP = single_bothP/countProj;
        single_bothRHO = single_bothRHO/countProj;
    end
    if countSes == 0
        single_sameRHO = NaN;
        single_sameP = NaN;
    else
        single_sameRHO = single_sameRHO/countSes;
        single_sameP = single_sameP/countSes;
    end
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
        if not(contains(string(cases(s).name), "sub")) |...
                contains(string(cases(s).name), "@") | ...
                contains(string(cases(s).name), "emptyroom")
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
        countProj = 0;
        countProjSes = 0;

    
        for i = 1:N %SUB2
            disp(i/N)
            if i == s
                continue;
            end
            if contains(string(cases(i).name), "sub") && ...
                    not(contains(string(cases(i).name), "@")) && ...
                not(contains(string(cases(i).name), "emptyroom"))
                data = access_data(dataDir, cases(i).name);
                projData = access_projected_data(dataDir, cases(i).name, cases(s).name);

                %% DO ANALYSIS HERE
                conn = {};
                projConn = {};
                for j = 1:nEpochs
                    conn = [conn, conn_fun(data{j}')];
                    if not(isempty(projData))
                        projConn = [projConn, conn_fun(projData{j}')];
                    end
                end
                if printFLAG == 1
                    figure('Name',strcat(cases(s).name, " vs ", cases(i).name))
                end
                for j = 1:nEpochs
                    for k = 1:nEpochs
                        if k ~= j
                            if printFLAG == 1
                                subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                                if j == 1
                                    title(strcat("Ses ", string(k)))
                                end
                                if k == 1
                                    ylabel(strcat("Ses ", string(j)))
                                end
                                scatter(conn{j}(:), conn{k}(:), 1, 'r', '.')
                                hold on
                                scatter(conn{j}(:), noConn{k}(:), 1, 'g', '.')
                                if not(isempty(projConn))
                                    scatter(conn{j}(:), projConn{k}(:), 1, ...
                                        'b', '.')
                                    scatter(noConn{j}(:), projConn{k}(:), 1, ...
                                        'k', '.')
                                end

                                xlim([0, 1])
                                ylim([0, 1])
                            end

                            [single_P, single_RHO] = ...
                                correlation_update(conn{j}(:), ...
                                conn{k}(:), single_P, single_RHO);

                            [single_noP, single_noRHO] = ...
                                correlation_update(conn{j}(:), ...
                                noConn{k}(:), single_noP, single_noRHO);
                            count = count+1;
                            if not(isempty(projConn))
                                [single_prjP, single_prjRHO] = ...
                                    correlation_update(conn{j}(:), ...
                                    projConn{k}(:), single_prjP, single_prjRHO);
    
                                [single_prj2P, single_prj2RHO] = ...
                                    correlation_update(noConn{j}(:), ...
                                    projConn{k}(:), single_prj2P, single_prj2RHO);
                                countProj = countProj+1;
                            end
                        else
                            if printFLAG == 1
                                subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                                scatter(conn{j}(:), conn{j}(:), 1, ...
                                    'r', '.')
                                hold on
                                scatter(conn{j}(:), noConn{j}(:), 1, ...
                                    'g', '.')
                                lgd = {'N1vsN1', 'N1vsN2'};
                                if not(isempty(projConn))
                                    scatter(conn{j}(:), projConn{j}(:), 1, ...
                                        'b', '.')
                                    lgd = [lgd, 'N2vsPRJ2on1', 'N1vsPRJ2on1'];
                                    scatter(noConn{j}(:), projConn{j}(:), 1, ...
                                        'k', '.')
                                end

                                ylabel(strcat("Ses ", string(j)))
                                title(strcat("Ses ", string(k)))
                                legend(lgd, 'FontSize', 6)
                                xlim([0, 1])
                                ylim([0, 1])
                            end

                            [single_noSameP, single_noSameRHO] = ...
                                correlation_update(conn{j}(:), ...
                                noConn{j}(:), single_noSameP, single_noSameRHO);
                            countSes = countSes+1;
                            
                            if not(isempty(projConn))
                                [single_prjSameP, single_prjSameRHO] = ...
                                    correlation_update(conn{j}(:), ...
                                    projConn{j}(:), single_prjSameP, single_prjSameRHO);
    
                                [single_prj2SameP, single_prj2SameRHO] = ...
                                    correlation_update(noConn{j}(:), ...
                                    projConn{j}(:), single_prj2SameP, single_prj2SameRHO);
                                countProjSes = countProjSes+1;
                            end
                        end
                    end
                end
            end
        end
        if count == 0
            noRHO(s) = NaN;
            noP(s) = NaN;
            RHO(s) = NaN;
            P(s) = NaN;
        else
            noRHO(s) = single_noRHO/count;
            noP(s) = single_noP/count;
            P(s) = single_P/count;
            RHO(s) = single_RHO/count;
        end
        if countProj == 0
            prjP(s) = NaN;
            prjRHO(s) = NaN;
            prj2P(s) = NaN;
            prj2RHO(s) = NaN;
        else
            prjP(s) = single_prjP/countProj;
            prjRHO(s) = single_prjRHO/countProj;
            prj2P(s) = single_prj2P/countProj;
            prj2RHO(s) = single_prj2RHO/countProj;
        end
        if countSes == 0
            noSameP(s) = NaN;
            noSameRHO(s) = NaN;
        else
            noSameP(s) = single_noSameP/countSes;
            noSameRHO(s) = single_noSameRHO/countSes;
        end
        if countProjSes == 0
            prjSameP(s) = NaN;
            prjSameRHO(s) = NaN;
            prj2SameP(s) = NaN;
            prj2SameRHO(s) = NaN;
        else
            prjSameP(s) = single_prjSameP/countProjSes;
            prjSameRHO(s) = single_prjSameRHO/countProjSes;
            prj2SameP(s) = single_prj2SameP/countProjSes;
            prj2SameRHO(s) = single_prj2SameRHO/countProjSes;
        end
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
        if not(contains(string(cases(s).name), "sub")) | ...
                contains(string(cases(s).name), string(srcSubject)) | ...
                contains(string(cases(s).name), "@") | ...
                contains(string(cases(s).name), "emptyroom")
            continue;
        end
        conn = {};
        projData = access_projected_data(dataDir, cases(s).name, ...
            srcSubject);
        if isempty(projData)
            continue;
        end
        for j = 1:nEpochs
            conn = [conn, conn_fun(projData{j}')];
        end
        for i = s+1:N
            if not(contains(string(cases(i).name), ...
                    string(srcSubject))) && ...
                    contains(string(cases(i).name), "sub") && ...
                    not(contains(string(cases(i).name), "@")) && ...
                    not(contains(string(cases(i).name), "emptyroom"))
                projData2 = access_projected_data(dataDir, ...
                    cases(i).name, srcSubject);

                %% DO ANALYSIS HERE
                conn2 = {};
                if isempty(projData2)
                    continue;
                end
                for j = 1:nEpochs
                    conn2 = [conn2, conn_fun(projData2{j}')];
                end
                if printFLAG == 1
                    figure('Name',strcat(cases(s).name, " vs ", ...
                        cases(i).name, ", projected on ", srcSubject))
                end
                for j = 1:nEpochs
                    for k = 1:nEpochs
                        if k ~= j
                            if printFLAG == 1
                                subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                                if j == 1
                                    title(strcat("Ses ", string(k)))
                                end
                                if k == 1
                                    ylabel(strcat("Ses ", string(j)))
                                end
                                scatter(conn{j}(:), conn2{k}(:), 1, 'r', '.')
                                xlim([0, 1])
                                ylim([0, 1])
                            end

                            [P, RHO] = ...
                                correlation_update(conn{j}(:), ...
                                conn2{k}(:), P, RHO);
                            count = count+1;
                        else
                            if printFLAG == 1
                                subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                                scatter(conn{j}(:), conn2{j}(:), 1, ...
                                'r', '.')
                                hold on
                                xlim([0, 1])
                                ylim([0, 1])
                            end
                            [sameP, sameRHO] = ...
                                correlation_update(conn{j}(:), ...
                                conn2{j}(:), sameP, sameRHO);
                            countSes = countSes+1;
                        end
                    end
                end
            end
        end
    end
    if count == 0
        P = NaN;
        RHO = NaN;
    else
        P = P/count;
        RHO = RHO/count;
    end
    if countSes == 0
        sameP = NaN;
        sameRHO = NaN;
    else
        sameP = sameP/countSes;
        sameRHO = sameRHO/countSes;
    end

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
        if not(contains(string(cases(s).name), "sub")) | ...
                contains(string(cases(s).name), string(anatSubject)) | ...
                contains(string(cases(s).name), "@") | ...
                contains(string(cases(s).name), "emptyroom")
            continue;
        end
        conn = {};
        projData = access_projected_data(dataDir, anatSubject, ...
            cases(s).name);
        for j = 1:nEpochs
            if not(isempty(projData))
                conn = [conn, conn_fun(projData{j}')];
            end
        end
        for i = s+1:N
            if contains(string(cases(i).name), "sub") && ...
                    not(contains(string(cases(i).name), ...
                    string(anatSubject))) && ...
                    not(contains(string(cases(i).name), "@")) && ...
                    not(contains(string(cases(i).name), "emptyroom"))
                projData2 = access_projected_data(dataDir, anatSubject, ...
                    cases(i).name);

                %% DO ANALYSIS HERE
                conn2 = {};
                if isempty(projData2)
                    continue;
                end
                for j = 1:nEpochs
                    conn2 = [conn2, conn_fun(projData2{j}')];
                end
                if printFLAG == 1
                    figure('Name',strcat(cases(s).name, " vs ", ...
                        cases(i).name, ", projected on ", anatSubject))
                end
                for j = 1:nEpochs
                    for k = 1:nEpochs
                        if k ~= j
                            if printFLAG == 1
                                subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                                if j == 1
                                    title(strcat("Ses ", string(k)))
                                end
                                if k == 1
                                    ylabel(strcat("Ses ", string(j)))
                                end
                                scatter(conn{j}(:), conn2{k}(:), 1, 'r', '.')
                                xlim([0, 1])
                                ylim([0, 1])
                            end

                            [P, RHO] = ...
                                correlation_update(conn{j}(:), ...
                                conn2{k}(:), P, RHO);
                            count = count+1;
                        else
                            if printFLAG == 1
                                subplot(nEpochs, nEpochs, (j-1)*nEpochs+k)
                                scatter(conn{j}(:), conn2{j}(:), 1, ...
                                    'r', '.')
                                hold on
                                xlim([0, 1])
                                ylim([0, 1])
                            end
                            [sameP, sameRHO] = ...
                                correlation_update(conn{j}(:), ...
                                conn2{j}(:), sameP, sameRHO);
                            countSes = countSes+1;
                        end
                    end
                end
            end
        end
    end
    if count == 0
        RHO = NaN;
        P = NaN;
    else
        P = P/count;
        RHO = RHO/count;
    end
    if countSes == 0
        sameP = NaN;
        sameRHO = NaN;
    else
        sameP = sameP/countSes;
        sameRHO = sameRHO/countSes;
    end

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
    subDir = strcat(dataDir, anatSubject, filesep);
    cases = dir(subDir);
    for i = 1:length(cases)
        if contains(string(cases(i).name), string(srcSubject)) && ...
                not(contains(string(cases(i).name), "@")) && ...
                not(contains(string(cases(i).name), "emptyroom"))
            subDir = strcat(subDir, cases(i).name, filesep);
            break;
        end
    end
    cases = dir(subDir);
    for i = 1:length(cases)
        if contains(string(cases(i).name), "matrix_scout")
            data = [data, load_feature(subDir, cases(i).name)];
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
    RHO(find(isnan(RHO))) = [];
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


%% EMPTY FUNCTION
function data = no_fun(data)
    
end


%% RETRO-COMPATIBLE LOADING FUNCTION
function f = load_feature(inDir, name)
    a = load(strcat(inDir, name));
    if isfield(a, "conn")
        f = a.conn;
    else
        f = a.Value;
    end
end


function score = similarity_score(conn1, conn2)
    r, c = size(conn1);
    d = 0;
    for i = 1:r 
        for j = i:r
            d = d+(conn1(i, j)-conn2(i, j))^2;
        end
    end
    score = 1/(1-sqrt(d));
end


function frr = false_rejection_rate(genuine_scores, threshold)
    if nargin < 2
        threshold = 0.01;
    end
    nThr = round(1/threshold);
    nScr = length(genuine_scores);
    frr = zeros(nThr, 1);
    for t = 1:nThr
        aux = 0;
        thr = threshold*t;
        for s = 1:nScr
            if genuine_scores(s) < thr
                aux = aux+1;
            end
        end
        frr(t) = aux/nScr;
    end
end


function far = false_acceptance_rate(impostor_scores, threshold)
    if nargin < 2
        threshold = 0.01;
    end
    nThr = round(1/threshold);
    nScr = length(impostor_scores);
    far = zeros(nThr, 1);
    for t = 1:nThr
        aux = 0;
        thr = threshold*t;
        for s = 1:nScr
            if impostor_scores(s) >= thr
                aux = aux+1;
            end
        end
        far(t) = aux/nScr;
    end
end


function eer = equal_error_rate(far, frr)
    [~, idx] = min(abs(far-frr));
    eer = (far(idx)-frr(idx))/2;
end
