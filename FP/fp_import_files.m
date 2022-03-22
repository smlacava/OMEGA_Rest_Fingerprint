function importFiles = fp_import_files(inDir, epTime)
    if not(contains(string(inDir), "data"))
        inDir = strcat(inDir, filesep, "data");
    end
    importFiles = {};
    dirs = dir(inDir);
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
                    for f = 1:length(files)
                        if contains(string(files(f).name), "data_block")
                            aux_subject = struct();
                            aux_subject.iStudy = 20;
                            aux_subject.item = item;
                            aux_subject.FileName = char(strcat(subDir, ...
                                filesep, files(f).name));
                            aux_subject.FileType = 'data';
                            aux_subject.Comment = char(strcat('Raw (', ...
                                string(epTime*(item-1)), ".00s,", ...
                                string(epTime*item),".00s)"));
                            aux_subject.Condition = sub_dirs(s).name;
                            aux_subject.SubjectFile = ...
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
                end
            end
            importFiles = [importFiles, subject];
        end
    end
end

