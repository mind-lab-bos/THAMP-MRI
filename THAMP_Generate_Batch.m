%% Load Data Files
cwd=pwd;
cd ./RAW_BIDS
FUNCTIONAL_FILE={cellstr(conn_dir('sub-*_task-rest_bold.nii.gz')); cellstr(conn_dir('sub-*_task-musbid*_bold.nii.gz')); cellstr(conn_dir('sub-*_task-facename_run-01_bold.nii.gz')); cellstr(conn_dir('sub-*_task-facename_run-02_bold.nii.gz'))};
for ses = 1:length(FUNCTIONAL_FILE)
    for sub = 1:length(FUNCTIONAL_FILE{ses})
        temp{sub,ses} = char(FUNCTIONAL_FILE{ses}(sub));
    end
end
clear FUNCTIONAL_FILE
FUNCTIONAL_FILE = temp;
STRUCTURAL_FILE=cellstr(conn_dir('sub-*_run-02_T1w.nii.gz'));
cd ../
NSUBJECTS= length(STRUCTURAL_FILE);
nsessions=size(FUNCTIONAL_FILE,2);
FUNCTIONAL_FILE=reshape(FUNCTIONAL_FILE,[NSUBJECTS,nsessions]);
STRUCTURAL_FILE={STRUCTURAL_FILE{1:NSUBJECTS}};
disp([num2str(size(FUNCTIONAL_FILE,1)),' subjects']);
disp([num2str(size(FUNCTIONAL_FILE,2)),' sessions']);
TR=0.475; % Repetition time

%% CONN-SPECIFIC SECTION: RUNS PREPROCESSING/SETUP/DENOISING/ANALYSIS STEPS
%% Prepares batch structure
clear batch;
batch.filename=fullfile(cwd,'MBI_Gamma_Conn.mat');            % New conn_*.mat experiment name

%% SETUP & PREPROCESSING step (using default values for most parameters, see help conn_batch to define non-default values)
% CONN Setup                                            % Default options (uses all ROIs in conn/rois/ directory); see conn_batch for additional options
% CONN Setup.preprocessing                               (realignment/coregistration/segmentation/normalization/smoothing)
batch.Setup.isnew= 0;
batch.Setup.add = 1;
batch.Setup.nsubjects=NSUBJECTS;
batch.Setup.RT=TR;                                        % TR (seconds)
batch.Setup.functionals=repmat({{}},[NSUBJECTS,1]);       % Point to functional volumes for each subject/session
for nsub=1:NSUBJECTS,for nses=1:nsessions,batch.Setup.functionals{nsub}{nses}{1}=FUNCTIONAL_FILE{nsub,nses}; end; end %note: each subject's data is defined by three sessions and one single (4d) file per session
batch.Setup.structurals=STRUCTURAL_FILE;                  % Point to anatomical volumes for each subject
nconditions=nsessions;                                  % treats each session as a different condition (comment the following three lines and lines 84-86 below if you do not wish to analyze between-session differences)
if nconditions==1
    batch.Setup.conditions.names={'rest'};
    for ncond=1,for nsub=1:NSUBJECTS,for nses=1:nsessions,              batch.Setup.conditions.onsets{ncond}{nsub}{nses}=0; batch.Setup.conditions.durations{ncond}{nsub}{nses}=inf;end;end;end     % rest condition (all sessions)
else
    batch.Setup.conditions.names=[{'rest'}, {'sart'}, {'nback'}]; %assign one condition per session
    for ncond=1:nconditions
        for nsub=1:NSUBJECTS
            for nses=1:nsessions
                if ncond == nses
                    batch.Setup.conditions.onsets{ncond}{nsub}{nses}=0; 
                    batch.Setup.conditions.durations{ncond}{nsub}{nses}=inf;
                else
                batch.Setup.conditions.onsets{ncond}{nsub}{nses}=[];batch.Setup.conditions.durations{ncond}{nsub}{nses}=[];
                end
            end
        end
    end
end
batch.Setup.preprocessing.steps='default_mni';
batch.Setup.preprocessing.sliceorder='interleaved (Siemens)';
batch.Setup.preprocessing.voxelsize_func = 3
batch.Setup.done=1;
batch.Setup.overwrite='No';

%% DENOISING step
% CONN Denoising                                    % Default options (uses White Matter+CSF+realignment+scrubbing+conditions as confound regressors); see conn_batch for additional options
batch.Denoising.filter=[0.008, 0.09];                 % frequency filter (band-pass values, in Hz)
batch.Denoising.done=1;
batch.Denoising.overwrite='No';
