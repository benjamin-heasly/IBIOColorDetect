%% IBIOColorDetectToolboxConfig
%
% Declare the toolboxes we need for the IBIOColorDetect project and
% write them into a JSON file.  This will let us use the ToolboxToolbox to
% deliver unto us the perfect runtime environment for this project.
%
% 2016 benjamin.heasly@gmail.com

% Clear
clear;

%% Declare some toolboxes we want.
config = [ ...

    tbToolboxRecord( ...
    'name', 'BrainardLabToolbox', ...
    'url', 'https://github.com:DavidBrainard/BrainardLabToolbox.git'), ...
    tbToolboxRecord( ...
    'name', 'UnitTestToolbox', ...
    'url', 'https://github.com:isetbio/UnitTestToolbox.git'), ...
    tbToolboxRecord( ...
    'name', 'RemoteDataToolbox', ...
    'url', 'https://github.com:isetbio/RemoteDataToolbox.git'), ...
    tbToolboxRecord( ...
    'name', 'isetbio', ...
    'url', 'https://github.com:isetbio/isetbio.git', ...
    'hook', 'run /Users/dhb/Desktop/ProjectPrefs/isetbio/ieSetPreferencesDB'), ...
    tbToolboxRecord( ...
    'name', 'IBIOColorDetectProjectToolbox', ...
    'type', 'local', ...
    'url', fullfile(pwd,'toolbox')) ...

    % tbToolboxRecord( ...
    % 'name', 'BrainardLabToolbox', ...
    % 'url', 'https://github.com:DavidBrainard/BrainardLabToolbox.git'), ...
    % tbToolboxRecord( ...
    % 'name', 'Psychtoolbox-3', ...
    % 'url', 'https://github.com/Psychtoolbox-3/Psychtoolbox-3.git', ...
    % 'subfolder','Psychtoolbox') ...
    ];

%% Write the config to a JSON file.
configPath = 'IBIOColorDetectToolboxConfig.json';
tbWriteConfig(config, 'configPath', configPath);
