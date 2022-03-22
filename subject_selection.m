%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Separates an aimed subjects from a set of subjects
% • Returns the set of files related to the selected subjects and another
%   set related to other subjects of the input set
%
% INPUT:
% • rawFiles is the array containing the structures of the input files
% • srcSubjects is the subject (or the cell array of subjects) which have
%   to be separated from the whole set
%
% OUTPUT:
% • srcFiles is the array containing the structures of the input files
%   related the the selected subjects
% • noSrcFiles is the array containing the structures of the input files
%   related the the selected subjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [srcFiles, noSrcFiles] = subject_selection(rawFiles, srcSubjects)
    srcFiles = [];
    noSrcFiles = [];
    if not(iscell(srcSubjects))
        srcSubjects = {srcSubjects};
    end
    N = length(rawFiles);
    for i = 1:length(srcSubjects)
        for j = 1:N
            if strcmpi(string(srcSubjects{i}), string(rawFiles(j).SubjectName))
                srcFiles = [srcFiles, rawFiles(j)];
            else
                noSrcFiles = [noSrcFiles, rawFiles(j)];
            end
        end
    end
end
