% Scripted pipeline from Brainstorm (24-Feb-2019)
% Andy Hu, Feb. 24, 2019

clc; clear; close all;
addpath('./brainstorm3');
if ~brainstorm('status')
    brainstorm nogui
end

ProtocolName = 'Leadfield_Pipeline';
% Delete existing protocol
gui_brainstorm('DeleteProtocol', ProtocolName);
% Create new protocol
gui_brainstorm('CreateProtocol', ProtocolName, 0, 0);

% Input files
sFiles = [];
SubjectNames = {'HCP'};
RawFiles = {fullfile(pwd,'example data\113922_MEG_anatomy'), fullfile(pwd,'example data\113922_MEG_Restin_unproc\3-Restin\4D\c,rfDC')};

% Start a new report
bst_report('Start', sFiles);

% Process: Import anatomy folder
sFiles = bst_process('CallProcess', 'process_import_anatomy', sFiles, [],     'subjectname', SubjectNames{1},     'mrifile',     {RawFiles{1}, 'HCPv3'},     'nvertices',   6001,     'aseg',        0);

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
    'datafile',       {RawFiles{2}, '4D'}, ...
    'channelreplace', 1, ...
    'channelalign',   1, ...
    'evtmode',        'value');

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
    'meg',         4, ...  % 4 - OpenMEEG BEM  3 - overlapping spheres
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
load('brainstorm_db\Leadfield_Pipeline\data\HCP\@raw3-Restin_c_rfDC\headmodel_surf_openmeeg.mat');
Gain3d=Gain; Gain = bst_gain_orient(Gain3d, GridOrient);
save Gain Gain Gain3d;

% Save patch
load('brainstorm_db\Leadfield_Pipeline\anat\HCP\tess_cortex_mid.mat');
save patch Vertices Faces;

% Save and display report
ReportFile = bst_report('Save', sFiles);
bst_report('Open', ReportFile);
% bst_report('Export', ReportFile, ExportDir);

