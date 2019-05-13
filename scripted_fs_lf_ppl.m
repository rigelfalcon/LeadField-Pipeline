% Scripted leadfield pipeline for Freesurfer anatomy files
% Brainstorm (24-Feb-2019)
% Andy Hu, Feb. 24, 2019 

% clc; clear; close all;
% addpath('./brainstorm3');
% if ~brainstorm('status')
%     brainstorm nogui
% end

ProtocolName = 'Leadfield_Pipeline';
% Delete existing protocol
gui_brainstorm('DeleteProtocol', ProtocolName);
% Create new protocol
gui_brainstorm('CreateProtocol', ProtocolName, 0, 0);

% Input files
sFiles = [];
SubjectNames = {...
    'MC0000010'};
RawFiles = {...
    'F:\MEEGfMRI\Data\andy\MC0000010_EEG_anatomy_t13d_anatVOL_20060115002658_2.nii_out', ...
    'F:\MEEGfMRI\Data\andy\MC0000010_EEG_data.mat', ...
    ''};

% Start a new report
bst_report('Start', sFiles);

% Process: Import anatomy folder
sFiles = bst_process('CallProcess', 'process_import_anatomy', sFiles, [], ...
    'subjectname', SubjectNames{1}, ...
    'mrifile',     {RawFiles{1}, 'FreeSurfer'}, ...
    'nvertices',   6000, ...
    'nas',         [0, 0, 0], ...
    'lpa',         [0, 0, 0], ...
    'rpa',         [0, 0, 0], ...
    'ac',          [0, 0, 0], ...
    'pc',          [0, 0, 0], ...
    'ih',          [0, 0, 0], ...
    'aseg',        1);

% Process: Compute MNI transformation
sFiles = bst_process('CallProcess', 'process_mni_affine', sFiles, [], ...
    'subjectname', SubjectNames{1});

% Process: Generate BEM surfaces
sFiles = bst_process('CallProcess', 'process_generate_bem', sFiles, [], ...
    'subjectname', SubjectNames{1}, ...
    'nscalp',      1922, ...
    'nouter',      1922, ...
    'ninner',      1922, ...
    'thickness',   4);

% Process: Create link to raw file
sFiles = bst_process('CallProcess', 'process_import_data_raw', sFiles, [], ...
    'subjectname',    SubjectNames{1}, ...
    'datafile',       {RawFiles{2}, 'EEG-MAT'}, ...
    'channelreplace', 1, ...
    'channelalign',   1, ...
    'evtmode',        'value');

% Process: Set channel file
sFiles = bst_process('CallProcess', 'process_import_channel', sFiles, [], ...
    'channelfile',  {RawFiles{3}, RawFiles{3}}, ...
    'usedefault',   47, ...  % ICBM152: BioSemi 128 A1
    'channelalign', 1, ...
    'fixunits',     1, ...
    'vox2ras',      1);

% Process: Refine registration
sFiles = bst_process('CallProcess', 'process_headpoints_refine', sFiles, []);

% Process: Project electrodes on scalp
sFiles = bst_process('CallProcess', 'process_channel_project', sFiles, []);

% Process: Compute head model
sFiles = bst_process('CallProcess', 'process_headmodel', sFiles, [], ...
    'Comment',     '', ...
    'sourcespace', 1, ...  % Cortex surface
    'volumegrid',  struct(...
         'Method',        'isotropic', ...
         'nLayers',       17, ...
         'Reduction',     3, ...
         'nVerticesInit', 4000, ...
         'Resolution',    0.005, ...
         'FileName',      ''), ...
    'meg',         1, ...  % 
    'eeg',         3, ...  % OpenMEEG BEM
    'ecog',        1, ...  % 
    'seeg',        1, ...  % 
    'openmeeg',    struct(...
         'BemSelect',    [1, 1, 1], ...
         'BemCond',      [1, 0.0125, 1], ...
         'BemNames',     {{'Scalp', 'Skull', 'Brain'}}, ...
         'BemFiles',     {{}}, ...
         'isAdjoint',    0, ...
         'isAdaptative', 1, ...
         'isSplit',      0, ...
         'SplitLength',  4000));

% Save lead field
load('F:\MEEGfMRI\Brainstorm_DB\Leadfield_Pipeline\data\MC0000010\@rawMC0000010_EEG_data\headmodel_surf_openmeeg.mat');
Gain3d=Gain; Gain = bst_gain_orient(Gain3d, GridOrient);
save Gain Gain Gain3d;

% Save patch
load('F:\MEEGfMRI\Brainstorm_DB\Leadfield_Pipeline\anat\MC0000010\tess_cortex_pial_low.mat');
save patch Vertices Faces;

% Save and display report
ReportFile = bst_report('Save', sFiles);
bst_report('Open', ReportFile);
% bst_report('Export', ReportFile, ExportDir);

