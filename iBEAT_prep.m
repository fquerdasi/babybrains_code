function [] = iBEAT_prep(sub, ageMo)
% this function prepares files for iBEAT segmentation of babybrains participant
% specifically, it finds the nifti file for the correct anatomical scan based on age, makes a directory in
% ibeatfiles folder for sub, and converts the nifti to .img and .hdr files to be
% inputs for IBEAT. 
%
% INPUTS:
%  sub = babybrains study ID, e.g., 'bb08'
%  ageMo = age of timepoint in months that we are preparing
%  example input: iBEAT_prep('bb08', 3)
%
% written by FQ June 2019, edited by FQ November 2019

%% initialization
sess = strcat('mri', num2str(ageMo));
dataDir = ['/biac2/kgs/projects/babybrains/mri/' sub '/' sess '/anat/'];

%% make sure inputs are valid
% first, make sure sub input is a 4 character string and follows babybrains
% study conventions
if (length(sub) ~= 4 || sum(~isstrprop(sub(3:4), 'digit')) || sum(sub(1:2) ~= 'bb'))
    error('sub input is not valid -- must have the form "bb<2 digit number>", e.g., bb08');
end

%make sure age input is valid
if ~isinteger(int8(ageMo))
    ageMo = round(ageMo);
    warning('ageMo input was not an integer -- rounding to nearest integer')
end

if ageMo > 12 
    error('age input is not valid -- must be between 0 and 12 because those are the ages in months of subs in the babybrains project');
end

%% housekeeping
cd(dataDir)

% determine if we need to copy T1 or T2 (<= 8 month take T2, otherwise T1)
month = ageMo;

if month <= 8
    toCopy = 'T2';
elseif month > 8 && month <= 12
    toCopy = 'T1'; 
else
    error('the timepoint you specified is not a valid input - please check age variable');
end
    
anatDir = dir;

% % find toCopy folder in anatDir 
runs = struct2cell(anatDir);
runs = runs(1,:);
run = strfind(runs,toCopy);
tf = cellfun('isempty',run);
run = find(not(tf));

 if(length(run)>1) 
     % get a gui to select folder
     anatDir = uigetdir(dataDir,'Select directory of anatomy we want to use for iBEAT...');
 elseif(isempty(tf))
     error('the run you want is not there!');
 else
        anatDir = anatDir(run).name;
 end
 
cd(anatDir)

rawAnat = uigetfile('*1mm.nii.gz', 'select the 1mm anat you want to be processed for iBEAT',anatDir);
%rawAnat = rawAnat.name;
disp([rawAnat ' for ' sub ' ' sess '    --     will be prepared for iBEAT. If this is incorrect, please fix!']);


%% make file to be analyzed by ibeat, save in anatDir
% reslice to 1 mm isotropic (we should try once with up sampling!) and
% convert to .img file

outname = [toCopy 'w.img'];
cmd = ['mri_convert ' rawAnat ' -vs 1 1 1 -rt nearest ' outname];
display(cmd)
system(cmd)

%% put files to be analyzed by ibeat in appropriate ibeatFiles directory

% check if target folder exists, if not make it

% i_age is age for ibeat -- ibeat automatically uses T1 for babies age 6
% months or older, but contrast is too poor for decent segmentation so we
% make i_age = 5 for ibeat so T2 is used
if ageMo <= 5
    i_age = ageMo;
else
    i_age = 5;
end

ibeatDir = ['/biac2/kgs/projects/babybrains/mri/' sub '/ibeatfiles/' sub ]; 

ibeatsubDir = [ibeatDir '/' sub '-' num2str(i_age)]; 

if ~exist(ibeatsubDir, 'dir')
    mkdir(ibeatsubDir);
else
    warning('folder already exists for this subject, check why you wanted to run that subject again!');
end


%% copy files to ibeatFiles directory  
% copy files with their new name so that no non-useable names are in the
% ibeat folder

cmd = ['mv' ' ' toCopy 'w.hdr' ' ' ibeatsubDir '/' sub '-' i_age '-' toCopy '.hdr' ];
display(cmd)
re = system(cmd)
cmd = ['mv' ' ' toCopy 'w.img' ' ' ibeatsubDir '/' sub '-' i_age '-' toCopy '.img' ];
display(cmd)
re = system(cmd)

if re==0
    disp('done copying');
elseif re==1
    disp('files did not copy');
else
    disp(['problem trying to copy ibeat files for ' sub ]);
end
