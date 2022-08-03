inDir = 'D:\Ricerca\FP_MOUS_res\FP_MOUS_res.tar\fp_Mous_results\MOUS_ver_3';
outDir = 'D:\Ricerca\FP_MOUS_res\AECFilt';
fun = @amplitude_envelope_correlation;

% Create output directory
if exist(outDir, "dir") == 0
    mkdir(outDir);
end

anatomies = dir(inDir);
nAnat = length(anatomies);
parfor anat = 1:nAnat
    if contains(anatomies(anat).name, "sub")
        [anatDir, outAnatDir] = directory_management(inDir, outDir, ...
            anatomies(anat).name);
        sources = dir(anatDir);
        nSrc = length(sources);
        progress = anat*100/nAnat;
        for src = 1:nSrc
            disp(progress+src/(nAnat*nSrc))
            if contains(sources(src).name, "sub")
                [srcDir, outSrcDir] = directory_management(anatDir, ...
                    outAnatDir, sources(src).name);
                epochs = dir(srcDir);
                nEp = length(epochs);
                for ep = 1:nEp
                    fname = epochs(ep).name;
                    outFile = strcat(outSrcDir, filesep, fname);
                    if contains(fname, ".mat") && ...
                            not(exist(outFile, "file"))
                        extraction(srcDir, fname, outFile, fun);
                    end
                end
            end
        end
    end
end


function [inSubDir, outSubDir] = directory_management(inDir, outDir, name)
    outSubDir = strcat(outDir, filesep, name);
    if exist(outSubDir, "dir") == 0
        mkdir(outSubDir);
    end
    inSubDir = strcat(inDir, filesep, name);
end

function extraction(srcDir, fname, outFile, fun)
  load(strcat(srcDir, filesep, fname));
  fs = 600;
  conn = fun(athena_filter(Value, fs, 13, 30)');
  save(outFile, "conn")
end