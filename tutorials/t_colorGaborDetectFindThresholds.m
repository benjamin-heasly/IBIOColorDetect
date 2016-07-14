%% t_colorGaborDetectFindThresholds
%
% Classify data generated by
%   t_colorGaborConeCurrentEyeMovementsResponseInstances.
% That tutorial generates multiple noisy instances of responses for color
% gabors and saves them out in a .mat file.  Here we read that file and use
% SVM to build a computational observer that gives us percent correct, and
% then do this for multiple contrasts so that we find the predicted
% detection threshold.
%
% The intput comes from and the output goes into a place determined by
%   colorGaborDetectOutputDir
% which itself checks for a preference set by
%   ISETColorDetectPreferencesTemplate
% which you may want to edit before running this and other scripts that
% produce substantial output.  The output within the main output directory
% is sorted by directories whose names are computed from parameters.  This
% naming is done in routine
%   paramsToDirName.
%
% 7/11/16  npc Wrote it.

%% Initialize
ieInit; clear; close all;

% Add project toolbox to Matlab path
AddToMatlabPathDynamically(fullfile(fileparts(which(mfilename)),'../toolbox')); 

%% Define parameters of analysis
%
% Condition directory that has the response instances
conditionDir = 'cpd2_sfv1.00_fw0.350_tau0.165_dur0.33_em0_use50_off35_b0_l1_LMS1.00_0.00_0.00_mfv1.00';

% Signal source: select between 'photocurrents' and 'isomerizations'
signalSource = 'photocurrents';

% Number of SVM cross validations to use
kFold = 5;

% PCA components.  Set to zero for no PCA
PCAComponents = 200;

%% Get data saved by t_colorGaborConeCurrentEyeMovementsResponseInstances
%
% The file ending in _0 gives us the no stimulus data 
dataDir = colorGaborDetectOutputDir(conditionDir,'output');
responseFile = 'responseInstances_0';
responsesFullFile = fullfile(dataDir, sprintf('%s.mat',responseFile));
classificationPerformanceFile = fullfile(dataDir, sprintf('ClassificationPerformance_%s_kFold%0.0f_pca%0.0f.mat',signalSource,kFold,PCAComponents));
fprintf('\nLoading data from %s ...', responsesFullFile); 
theBlankData = load(responsesFullFile);
fprintf('done\n');
fprintf('\nWill save classification performance to %s\n', classificationPerformanceFile);
nTrials = numel(theBlankData.theNoStimData.responseInstanceArray);
testConeContrasts = theBlankData.testConeContrasts;
testContrasts = theBlankData.testContrasts;
gaborParams = theBlankData.gaborParams; 
temporalParams = theBlankData.temporalParams;
oiParams = theBlankData.oiParams; 
mosaicParams = theBlankData.mosaicParams;

%% Put zero contrast response instances into data that we will pass to the SVM
responseSize = numel(theBlankData.theNoStimData.responseInstanceArray(1).theMosaicPhotoCurrents(:));
fprintf('\nInsterting null stimulus data from %d trials into design matrix ...\n', nTrials);
for iTrial = 1:nTrials
    if (iTrial == 1)
        data = zeros(2*nTrials, responseSize);
        classes = zeros(2*nTrials, 1);
    end
    if (strcmp(signalSource,'photocurrents'))
        data(iTrial,:) = theBlankData.theNoStimData.responseInstanceArray(iTrial).theMosaicPhotoCurrents(:);
    else
        data(iTrial,:) = theBlankData.theNoStimData.responseInstanceArray(iTrial).theMosaicIsomerizations(:);
    end
    
    % Set up classes variable
    classes(iTrial,1) = 0;
    classes(nTrials+iTrial,1) = 1;
end
fprintf('done\n');

%% Do SVM for each test contrast and color direction.
%
% The work is done inside routine ClassifyForOneDirection.  We needed to
% encapsulate it there to make parfor happy.
%
% If you don't have a computer configured to work with parfor, you may need
% to change the parfor just to plain for.
tic
usePercentCorrect = cell(size(testConeContrasts,2),1);
useStdErr = cell(size(testConeContrasts,2),1);
parfor ii = 1:size(testConeContrasts,2)
    thisResponseFile = sprintf('responseInstances_%d',ii);
    thisResponseFullFile = fullfile(dataDir, sprintf('%s.mat',thisResponseFile));
    theData = load(thisResponseFullFile);
    [usePercentCorrect{ii},useStdErr{ii}] = ClassifyForOneDirection(ii,data,theData.theStimData,classes,nTrials,testContrasts,signalSource,PCAComponents,kFold);  
end
fprintf('SVM classification took %2.2f minutes\n', toc/60);
clearvars('theData','useData','data');

% Take the cell array form of the performance data and put it back into the
% matrix form we expect below and elsewhere.
for ii = 1:size(testConeContrasts,2)
    for jj = 1:numel(testContrasts)
        percentCorrect(ii,jj) = usePercentCorrect{ii}(jj);
        stdErr(ii,jj) = useStdErr{ii}(jj);
    end
end
clearvars('usePercentCorrect','useStdErr');

%% Save classification performance data and a copy of this script
save(classificationPerformanceFile, 'percentCorrect', 'stdErr', 'testConeContrasts','testContrasts', 'nTrials', ...
    'gaborParams', 'temporalParams', 'oiParams', 'mosaicParams');
scriptDir = colorGaborDetectOutputDir(conditionDir,'scripts');
    unix(['cp ' mfilename('fullpath') '.m ' scriptDir]);

%% Plot performances obtained.
hFig = figure(1); clf;
set(hFig, 'Position', [10 10 680 590], 'Color', [1 1 1]);
for ii = 1:size(testConeContrasts,2)
    subplot(size(testConeContrasts,2), 1, ii)
    errorbar(testContrasts, squeeze(percentCorrect(ii,:)), squeeze(stdErr(ii, :)), ...
        'ro-', 'LineWidth', 2.0, 'MarkerSize', 12, 'MarkerFaceColor', [1.0 0.5 0.50]);
    axis 'square'
    set(gca, 'YLim', [0 1.0],'XLim', [testContrasts(1) testContrasts(end)], 'FontSize', 14);
    xlabel('contrast', 'FontSize' ,16, 'FontWeight', 'bold');
    ylabel('percent correct', 'FontSize' ,16, 'FontWeight', 'bold');
    box off; grid on
    title(sprintf('LMS = [%2.2f %2.2f %2.2f]', testConeContrasts(1,ii), testConeContrasts(2,ii), testConeContrasts(3,ii)));
end

