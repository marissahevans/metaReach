function [displayInfo] = screenVisuals(displayInfo)
%Updating the displayInfo structure with trial specific visual info for the
%experiment. 

%Target dot appearance
dotColor = [0 1 0];             %green
dotSizePix = 10;                %Dot size in pixels

displayInfo.dotColor = dotColor;
displayInfo.dotSizePix = dotSizePix;

%Set the color of the confidence oval to yellow
rectColor = [1 1 0];            %yellow

displayInfo.rectColor = rectColor;

%fixation circle
fixation = [displayInfo.xCenter,displayInfo.screenYpixels-175];%fixation location
baseRect = abs([0 0 20 20]);    %fixation circle size
centeredRect = CenterRectOnPointd(baseRect, displayInfo.xCenter, displayInfo.screenYpixels-175); %fixation circle centered coordinates

displayInfo.fixation = fixation;
displayInfo.baseRect = baseRect;
displayInfo.centeredRect = centeredRect;

%Number of testable target locations
numTargets = 6;

displayInfo.numTargets = numTargets;

end

