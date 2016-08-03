function dirname = paramsToMosaicDirName(obj,mosaicParams)
% pdirname = paramsToMosaicDirName(obj,mosaicParams)
% 
% Generate a directory names that captures the mosaic parameters.

if (~strcmp(mosaicParams.type,'Mosaic'))
    error('Incorrect parameter type passed');
end

dirname = sprintf('LMS%0.2f_%0.2f_%0.2f_mfv%0.1f_ecc%0.1f',...
    mosaicParams.LMSRatio(1),mosaicParams.LMSRatio(2),mosaicParams.LMSRatio(3), ...
    mosaicParams.fieldOfViewDegs, mosaicParams.eccentricityDegs);