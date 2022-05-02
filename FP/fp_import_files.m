function importFiles = fp_import_files(inDir, epTime, removeBadEpochs, commonFLAG, nMax)
    if nargin < 3
        removeBadEpochs = 0;
    end
    if nargin < 4
        commonFLAG = 0;
    end
    if nargin < 5
        nMax = -1;
    end
    if not(contains(string(inDir), "data"))
        inDir = strcat(inDir, filesep, "data");
    end
    importFiles = {};
    dirs = dir(inDir);
    if nMax == -1
        minEp = 1000000000;
    else
        minEp = nMax;
    end
    for d = 1:length(dirs)
        if contains(string(dirs(d).name), "sub")
            sub_dirs = dir(strcat(inDir, filesep, dirs(d).name));
            for s = 1:length(sub_dirs)
                if contains(string(sub_dirs(s).name), "sub") & ...
                        contains(string(sub_dirs(s).name), string(dirs(d).name))
                    subDir = strcat(dirs(d).name, filesep, ...
                        sub_dirs(s).name);
                    files = dir(strcat(inDir, filesep, subDir));
                    subject = [];
                    item = 1;
                    count_ep = 0;
                    if removeBadEpochs == 1
                        bs = load(strcat(inDir, filesep, subDir, filesep, 'brainstormstudy.mat'));
                        bad_trials = string(bs.BadTrials);
                    end
                    for f = 1:length(files)
                        if contains(string(files(f).name), "data_block")
                            count_ep = count_ep + 1;
                            if removeBadEpochs == 1
                                if sum(strcmpi(bad_trials, string(files(f).name))) == 1
                                    continue;
                                end
                            end
                            aux_subject = struct();
                            aux_subject.iStudy = 20;
                            aux_subject.item = item;
                            aux_subject.FileName = char(strcat(subDir, ...
                                filesep, files(f).name));
                            aux_subject.FileType = 'data';
                            aux_subject.Comment = char(strcat('Raw (', ...
                                string(epTime*(count_ep-1)), ".00s,", ...
                                string(epTime*count_ep),".00s)"));
                            aux_subject.Condition = sub_dirs(s).name;
                            aux_subject.SubjectFile = ...Y
                                char(strcat(dirs(d).name, filesep, ...
                                "brainstormsubject.mat"));
                            aux_subject.SubjectName = dirs(d).name;
                            aux_subject.DataFile = [];
                            aux_subject.ChannelFile = ...
                                char(strcat(subDir, filesep, ...
                                "channel_ctf_acc1.mat"));
                            aux_subject.ChannelTypes = {'ADC A','ADC V',...
                                'DAC','EEG','FitErr','HLU','MEG',...
                                'MEG REF','Other','Stim','SysClock'};
                            subject = [subject, aux_subject];
                            item = item+1;
                        end
                    end
                    if item-1 < minEp
                        minEp = item-1;
                    end
                end
            end
            importFiles = [importFiles, subject];
        end
    end
    if commonFLAG == 1
        aux_import_files = {};
        for i = 1:length(importFiles)
            subject = [];
            for j = 1:minEp
                subject = [subject, importFiles{i}(j)];
            end
            aux_import_files = [aux_import_files, subject];
        end
        importFiles = aux_import_files;
    end

end

