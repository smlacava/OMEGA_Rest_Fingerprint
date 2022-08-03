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


%% EER
% NO1vsNO2: standard EER (all compared with their own head and sources)
% NO1vsPRJ12: EER of a subject with himself projected on other heads
% NO1vsPRJ21: comparison using a single head of a subject within the study
% PRJ13vsPRJ23: comparison using the head of an excluded subject

%% TO ADD:
% - A check when using sources on their own anatomy to see if epochs are
%   bad (brainstorm study)
bsDir = 'D:\Ricerca';
ProtocolName = 'FP_MOUS_res';
epTime = 2;
nEpochs = 10;
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
 
anatEER = zeros(1, N); 
anatAUC = zeros(1, N);
anatCAR = zeros(1, N);

srcEER = zeros(1, N);
srcAUC = zeros(1, N);
srcCAR = zeros(1, N);

del_idx = [];
threshold = 0.01;

count = 0;
default_EER = [];
default_CAR = [];
default_AUC = [];
if exist(strcat(dataDir, filesep, "status.mat"), 'file')
    load(strcat(dataDir, filesep, "status.mat"));
end
%save(strcat(dataDir, filesep, "status.mat"), "count", "default_EER")
if isempty(default_EER)
    performance = default_analysis(dataDir, cases, nEpochs, conn_fun, ...
        threshold);
    default_EER = performance.eer;
    default_CAR = performance.car;
    default_AUC = performance.auc;
    save(strcat(dataDir, filesep, "status.mat"), "count", "cases", ...
        "default_EER", "default_AUC", "default_CAR")
end
if not(exist("start_idx", "var"))
    start_idx = 1;
end
if start_idx < N+1
    for i = start_idx:N
        if contains(string(cases(i).name), "sub") && ...
                not(contains(string(cases(i).name), "@")) && ...
                not(contains(string(cases(i).name), "emptyroom"))
    
            performance = single_sources_analysis(dataDir, cases, ...
                cases(i).name, nEpochs, conn_fun, threshold);
            srcEER(i) = performance.eer;
            srcAUC(i) = performance.auc;
            srcCAR(i) = performance.car;
            
            performance = single_anatomy_analysis(dataDir, cases, ...
                cases(i).name, nEpochs, conn_fun, threshold);
            anatEER(i) = performance.eer;
            anatAUC(i) = performance.auc;
            anatCAR(i) = performance.car;
    
            count = count+1;
            disp(count/N)
        else
            del_idx = [del_idx, i];
        end
        start_idx = i+1;
        save(strcat(dataDir, filesep, "status.mat"), "count", "del_idx", ...
            "default_EER", "default_AUC", "default_CAR", "anatEER", ...
            "anatCAR", "anatAUC", "srcCAR", "srcAUC", "srcEER", ...
            "cases", "start_idx");
    end
end

disp(defaultEER)

%% Descriptive statistics
[anatEER_mn, anatEER_mdn, anatEER_sd] = describe(anatEER, del_idx);
[srcEER_mn, srcEER_mdn, srcEER_sd] = describe(srcEER, del_idx);

box_plots({{"Same Anatomy",[anatEER_mn, anatEER_mdn, anatEER_sd]}, ...      
    {"Same Sources", [srcEER_mn, srcEER_mdn, srcEER_sd]}}) 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Analysis on single subjects' anatomy
% - srcEER: EER using the same anatomy of an excluded subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ù

function performance = single_anatomy_analysis(dataDir, cases, ...
    anatSubject, nEpochs, conn_fun, threshold)

    if nargin < 6
        threshold = 0.01;
    end
    
    performance = initialize_performance();
    N = length(cases);
    genuines = zeros(N*nEpochs, 1);
    impostors = zeros(round(N*N*nEpochs/2), 1);
    countI = 0;
    countG = 0;
    for i = 1:N
        if not(strcmpi(string(anatSubject), string(cases(i).name))) && ...
                contains(string(cases(i).name), "sub") && ...
                not(contains(string(cases(i).name), "@")) && ...
                not(contains(string(cases(i).name), "emptyroom"))

            data = access_projected_data(dataDir, anatSubject, ...
                cases(i).name);                          
            if isempty(data)
                continue
            end
            conn = {};
            for ep = 1:nEpochs
                conn = [conn, conn_fun(data{ep}')];
            end
            for ep = 1:nEpochs-1
                for ep2 = ep+1:nEpochs
                    countG = countG+1;
                    genuines(countG) = similarity_score(conn{ep}, conn{ep2});
                end
            end
            if i == N
                break;
            end
            for j = i+1:N
                if not(strcmpi(string(anatSubject), string(cases(j).name))) && ...
                    contains(string(cases(j).name), "sub") && ...
                    not(contains(string(cases(j).name), "@")) && ...
                    not(contains(string(cases(j).name), "emptyroom"))
        
                    data = access_projected_data(dataDir, anatSubject, ...
                        cases(j).name);                            
                    conn2 = {};
                    if isempty(data)
                        continue
                    end
                    for ep = 1:nEpochs
                        conn2 = [conn2, conn_fun(data{ep}')];
                    end
                    for ep = 1:nEpochs
                        for ep2 = ep:nEpochs
                            countI = countI+1;
                            impostors(countI) = ...
                                similarity_score(conn{ep}, conn2{ep2});
                        end
                    end
                end
            end
        end
    end
    if countI > 0 && countG > 0
        performance = compute_performance(genuines(1:countG), ...
            impostors(1:countI), threshold);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Analysis on single subjects' sources
% - srcEER: EER using the same sources of an excluded subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ù

function performance = single_sources_analysis(dataDir, cases, ...
    srcSubject, nEpochs, conn_fun, threshold)

    if nargin < 6
        threshold = 0.01;
    end
    
    performance = initialize_performance();
    N = length(cases);
    genuines = zeros(N*nEpochs, 1);
    impostors = zeros(round(N*N*nEpochs/2), 1);
    countI = 0;
    countG = 0;
    for i = 1:N
        if not(strcmpi(string(srcSubject), string(cases(i).name))) && ...
                contains(string(cases(i).name), "sub") && ...
                not(contains(string(cases(i).name), "@")) && ...
                not(contains(string(cases(i).name), "emptyroom"))

            data = access_projected_data(dataDir, cases(i).name, ...
                srcSubject);                            % PRJ2to1

            if isempty(data)
                continue
            end
            conn = {};
            for ep = 1:nEpochs
                conn = [conn, conn_fun(data{ep}')];
            end
            for ep = 1:nEpochs-1
                for ep2 = ep+1:nEpochs
                    countG = countG+1;
                    genuines(countG) = similarity_score(conn{ep}, conn{ep2});
                end
            end
            if i == N
                break;
            end
            for j = i+1:N
                if not(strcmpi(string(srcSubject), string(cases(j).name))) && ...
                    contains(string(cases(j).name), "sub") && ...
                    not(contains(string(cases(j).name), "@")) && ...
                    not(contains(string(cases(j).name), "emptyroom"))
        
                    data = access_projected_data(dataDir, cases(j).name, ...
                        srcSubject);                            % PRJ2to1
                    conn2 = {};
                    if isempty(data)
                        continue
                    end
                    for ep = 1:nEpochs
                        conn2 = [conn2, conn_fun(data{ep}')];
                    end
                    for ep = 1:nEpochs
                        for ep2 = ep:nEpochs
                            countI = countI+1;
                            impostors(countI) = ...
                                similarity_score(conn{ep}, conn2{ep2});
                        end
                    end
                end
            end
        end
    end
    if countI > 0 && countG > 0
        performance = compute_performance(genuines(1:countG), ...
            impostors(1:countI), threshold);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Default analysis
% - EER: EER considering each subject with its own sources and anatomy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ù

function performance = default_analysis(dataDir, cases, nEpochs, ...
    conn_fun, threshold)

    if nargin < 5
        threshold = 0.01;
    end
    
    EER = NaN;
    N = length(cases);
    genuines = zeros(N*nEpochs, 1);
    impostors = zeros(round(N*N*nEpochs/2), 1);
    countI = 0;
    countG = 0;
    for i = 1:N
        if contains(string(cases(i).name), "sub") && ...
                not(contains(string(cases(i).name), "@")) && ...
                not(contains(string(cases(i).name), "emptyroom"))

            data = access_projected_data(dataDir, cases(i).name, ...
                cases(i).name);                            % PRJ2to1

            if isempty(data)
                continue
            end
            conn = {};
            for ep = 1:nEpochs
                conn = [conn, conn_fun(data{ep}')];
            end
            for ep = 1:nEpochs-1
                for ep2 = ep+1:nEpochs
                    countG = countG+1;
                    genuines(countG) = similarity_score(conn{ep}, conn{ep2});
                end
            end
            if i == N
                break;
            end
            for j = i+1:N
                if contains(string(cases(j).name), "sub") && ...
                    not(contains(string(cases(j).name), "@")) && ...
                    not(contains(string(cases(j).name), "emptyroom"))
        
                    data = access_projected_data(dataDir, cases(j).name, ...
                        cases(j).name);                            
                    conn2 = {};
                    if isempty(data)
                        continue
                    end
                    for ep = 1:nEpochs
                        conn2 = [conn2, conn_fun(data{ep}')];
                    end
                    for ep = 1:nEpochs
                        for ep2 = ep:nEpochs
                            countI = countI+1;
                            impostors(countI) = ...
                                similarity_score(conn{ep}, conn2{ep2});
                        end
                    end
                end
            end
        end
    end
    if countI > 0 && countG > 0
        performance = compute_performance(genuines(1:countG), ...
            impostors(1:countI), threshold);
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

function [mn, mdn, sd] = describe(val, del_idx)
    if nargin < 2
        del_idx = [];
    end
    val(del_idx) = [];
    val(find(isnan(val))) = [];
    mn = mean(val);
    mdn = median(val);
    sd = std(val);
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
    ylabel("EER")
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
    [r, ~] = size(conn1);
    d = 0;
    for i = 1:r 
        for j = i:r
            d = d+(conn1(i, j)-conn2(i, j))^2;
        end
    end
    score = 1/(1+sqrt(d));
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


function [eer, car, crr] = equal_error_rate(far, frr)
    [~, idx] = min(abs(far-frr));
    eer = (far(idx)+frr(idx))/2;
    car = 1-frr(idx);
    crr = 1-far(idx);
end


function performance = compute_performance(genuine_scores, ...
    impostor_scores, threshold)
    frr = false_rejection_rate(genuine_scores, threshold);
    far = false_acceptance_rate(impostor_scores, threshold);
    performance = struct();
    [eer, car, crr] = equal_error_rate(far, frr);
    auc=abs(trapz(far,frr));
    performance.eer = eer;
    performance.car = car;
    performance.crr = crr;
    performance.auc = auc;
end

function performance = initialize_performance()
    performance = struct();
    performance.eer = NaN;
    performance.car = NaN;
    performance.crr = NaN;
    performance.auc = NaN;
end

