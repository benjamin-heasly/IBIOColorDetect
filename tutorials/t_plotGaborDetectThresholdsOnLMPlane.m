function validationData = t_plotGaborDetectThresholdsOnLMPlane(rParams,LMPlaneInstanceParams,thresholdParams)
% validationData = t_plotGaborDetectThresholdsOnLMPlane(rParams,LMPlaneInstanceParams,thresholdParams)
%
% Read classification performance data generated by
%   t_colorGaborDetectFindPerformance
% 
% A) Plot the psychometric functions with a fit Weibull, which is used to find the threshold in each color direction.
% B) Plot the thresholds in the LM contrast plane.
% C) Fit an ellipse to the thresholds.
%
% This routine is specialized on the assumption that the test directions
% lie in the LM plane.
%
% The fit ellipse may be compared with actual psychophysical data.
% 
% 7/11/16  npc Wrote it.
% 7/13/16  dhb More.

%% Clear
if (nargin == 0)
    ieInit; close all;
end

%% Fix random number generator so we can validate output exactly
rng(1);

%% Get the parameters we need
%
% t_colorGaborResponseGenerationParams returns a hierarchical struct of
% parameters used by a number of tutorials and functions in this project.
if (nargin < 1 | isempty(rParams))
    rParams = colorGaborResponseParamsGenerate;
    
    % Override some defult parameters
    %
    % Set duration equal to sampling interval to do just one frame.
    rParams.temporalParams.simulationTimeStepSecs = 200/1000;
    rParams.temporalParams.stimulusDurationInSeconds = rParams.temporalParams.simulationTimeStepSecs;
    rParams.temporalParams.stimulusSamplingIntervalInSeconds = rParams.temporalParams.simulationTimeStepSecs;
    rParams.temporalParams.secondsToInclude = rParams.temporalParams.simulationTimeStepSecs;
    rParams.temporalParams.eyesDoNotMove = true;
    
    rParams.mosaicParams.timeStepInSeconds = rParams.temporalParams.simulationTimeStepSecs;
    rParams.mosaicParams.integrationTimeInSeconds = rParams.mosaicParams.timeStepInSeconds;
    rParams.mosaicParams.isomerizationNoise = true;
    rParams.mosaicParams.osNoise = true;
    rParams.mosaicParams.osModel = 'Linear';
end

%% Parameters that define the LM instances we'll generate here
%
% Make these numbers small (trialNum = 2, deltaAngle = 180,
% nContrastsPerDirection = 2) to run through a test quickly.
if (nargin < 2 | isempty(LMPlaneInstanceParams))
    LMPlaneInstanceParams = LMPlaneInstanceParamsGenerate;
end

%% Parameters related to how we find thresholds from responses
if (nargin < 3 | isempty(thresholdParams))
    thresholdParams = thresholdParamsGenerate;
end

%% Set up the rw object for this program
rwObject = IBIOColorDetectReadWriteBasic;
readProgram = 't_colorGaborDetectFindPerformance';
writeProgram = mfilename;

%% Read performance data
paramsList = {rParams.gaborParams, rParams.temporalParams, rParams.oiParams, rParams.mosaicParams, rParams.backgroundParams, LMPlaneInstanceParams, thresholdParams};
performanceData = rwObject.read('performanceData',paramsList,readProgram);

% If everything is working right, these check parameter structures will
% match what we used to specify the file we read in.
%
% SHOULD ACTUALLY CHECK FOR EQUALITY HERE.
rParamsCheck = performanceData.rParams;
LMPlaneInstanceParamsCheck = performanceData.LMPlaneInstanceParams;
thresholdParamsCheck = performanceData.thresholdParams;

% Extract data from loaded struct into convenient form
testContrasts = performanceData.testContrasts;
testConeContrasts = performanceData.testConeContrasts;
fitContrasts = logspace(log10(min(testContrasts)),log10(max(testContrasts)),100)';
nTrials = LMPlaneInstanceParams.trialsNum;

% Make sure S cone component of test contrasts is 0, because in this
% routine we are assuming that we are just looking in the LM plane.
if (any(testConeContrasts(3,:) ~= 0))
    error('This tutorial only knows about the LM plane');
end

%% Fit psychometric functions
%
% And make a plot of each along with its fit
for ii = 1:size(performanceData.testConeContrasts,2)
    % Get the performance data for this test direction, as a function of
    % contrast.
    thePerformance = squeeze(performanceData.percentCorrect(ii,:));
    theStandardError = squeeze(performanceData.stdErr(ii, :));
    
    % Fit psychometric function and find threshold.
    %
    % The work is done by singleThresholdExtraction, which itself calls the
    % Palemedes toolbox.  The Palemedes toolbox is included in the external
    % subfolder of the Isetbio distribution.
    [tempThreshold,fitFractionCorrect(:,ii),psychometricParams{ii}] = ...
       singleThresholdExtraction(testContrasts,thePerformance,thresholdParams.criterionFraction,nTrials,fitContrasts);
    thresholdContrasts(ii) = tempThreshold;
    
    % Make the plot for this test direction
    hFig = figure; hold on
    set(gca,'FontSize',rParams.plotParams.axisFontSize);
    errorbar(log10(testContrasts), thePerformance, theStandardError, 'ro', 'MarkerSize', rParams.plotParams.markerSize, 'MarkerFaceColor', [1.0 0.5 0.50]);
    plot(log10(fitContrasts),fitFractionCorrect(:,ii),'r','LineWidth', 2.0);
    plot(log10(thresholdContrasts(ii))*[1 1],[0 thresholdParams.criterionFraction],'b', 'LineWidth', 2.0);
    axis 'square'
    set(gca, 'YLim', [0 1.0],'XLim', log10([testContrasts(1) testContrasts(end)]), 'FontSize', 14);
    xlabel('contrast', 'FontSize' ,rParams.plotParams.labelFontSize, 'FontWeight', 'bold');
    ylabel('percent correct', 'FontSize' ,rParams.plotParams.labelFontSize, 'FontWeight', 'bold');
    box off; grid on
    title({sprintf('LMangle = %2.1f deg, LMthreshold (%0.4f%%,%0.4f%%)', atan2(testConeContrasts(2,ii), testConeContrasts(1,ii))/pi*180, ...
        100*thresholdContrasts(ii)*testConeContrasts(1,ii), 100*thresholdContrasts(ii)*testConeContrasts(2,ii)) ; ''}, ...
        'FontSize',rParams.plotParams.titleFontSize);
    rwObject.write(sprintf('LMPsychoFunctions_%d',ii),hFig,paramsList,writeProgram,'Type','figure');
    
    % Convert threshold contrast to threshold cone contrasts
    thresholdConeContrasts(:,ii) = testConeContrasts(:,ii)*thresholdContrasts(ii);
end

%% Thresholds are generally symmetric around the contrast origin
%
% We'll pad with this assumption, which makes both visualization and
% fitting easier.
thresholdConeContrasts = [thresholdConeContrasts -thresholdConeContrasts];

% Remove any NaN thresholds lurking around, as these will mess up attempts
% to fit.
thresholdConeContrastsForFitting0 = [];
for ii = 1:size(thresholdConeContrasts,2)
    if (~any(isnan(thresholdConeContrasts(:,ii))))
        thresholdConeContrastsForFitting0 = [thresholdConeContrastsForFitting0 thresholdConeContrasts(:,ii)];
    end
end

%% Fit ellipse
%
% This method fits a 3D ellipsoid and extracts the LM plane of
% the fit.
%
% The fit will be very bad off the LM plane, since there are no data there.
% But we don't care, because we are only going to look at the fit in the LM
% plane.  To make the fit stable, we generate data for fitting that are off
% the LM plane by simply producing shrunken and shifted copies of the in
% plane data.  A little klugy.
thresholdConeContrastsForFitting1 = 0.5*thresholdConeContrastsForFitting0;
thresholdConeContrastsForFitting1(3,:) = 0.5;
thresholdConeContrastsForFitting2 = 0.5*thresholdConeContrastsForFitting0;
thresholdConeContrastsForFitting2(3,:) = -0.5;
thresholdContrastsForFitting = [thresholdConeContrastsForFitting0 thresholdConeContrastsForFitting1 thresholdConeContrastsForFitting2];
[fitA,fitAinv,fitQ,fitEllParams] = EllipsoidFit(thresholdContrastsForFitting);

% Get the LM plane ellipse from the fit
nThetaEllipse = 200;
circleIn2D = UnitCircleGenerate(nThetaEllipse);
circleInLMPlane = [circleIn2D(1,:) ; circleIn2D(2,:) ; zeros(size(circleIn2D(1,:)))];
ellipsoidInLMPlane = PointsOnEllipsoidFind(fitQ,circleInLMPlane);

%% Plot the thresholds in the LM contrast plane
contrastLim = 0.02;
hFig = figure; clf; hold on; set(gca,'FontSize',rParams.plotParams.axisFontSize);
plot(thresholdConeContrasts(1,:),thresholdConeContrasts(2,:),'ro','MarkerFaceColor','r','MarkerSize',rParams.plotParams.markerSize);
plot(ellipsoidInLMPlane(1,:),ellipsoidInLMPlane(2,:),'r','LineWidth',2);
plot([-contrastLim contrastLim],[0 0],'k:','LineWidth',2);
plot([0 0],[-contrastLim contrastLim],'k:','LineWidth',2);
xlabel('L contrast','FontSize',rParams.plotParams.labelFontSize); ylabel('M contrast','FontSize',rParams.plotParams.labelFontSize);
title('M versus L','FontSize',rParams.plotParams.titleFontSize);
xlim([-contrastLim contrastLim]); ylim([-contrastLim contrastLim]);
axis('square');
rwObject.write('LMThresholdContour',hFig,paramsList,writeProgram,'Type','figure');

%% Validation data
if (nargin > 0)
    validationData.testContrasts = testContrasts;
    validationData.testConeContrasts = testConeContrasts;
    validationData.thresholdContrasts = thresholdContrasts;
end
    

