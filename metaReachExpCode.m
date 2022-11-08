   %% Meta Reach Experiment main operational code
%This file is the main control script for the experiment. For each session
%edit the necessary information in the Participant Info section then run
%from thi s script. 

%This s  cript calls several functions, namely:
%screenVisuals.m - sets up colors and screens
%startExp.m - st  arts psychToolbox
%controlExpSigmaP.m - session 1 control experiment (+practice trials)
%pracTrialSeq.m - practice trial s  for main experiment
%t rialSeq.m - main experimental trials
 
%Output is save as results.mat and dispInfo.mat
 
%setting the file path 
cd('C:\Users\labadmin\Documents\metaReachExperiment');
%% Experiment start   
% Clear the workspace and the s creen
sca;  
close all;     
clearvars;
%%%%%%%%%%%%%%%%%%%%%%% % Participant Info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subj = 'TEST';                      %participant initials
session = 01;                    %session being run {01, 02, 03, or 04)
redoCalib = 0;                   %force re-calibration. Always 0 unless session calibration was inaccurate, then 1
prac = 1;                        %Always 1 unless particpant is doing back to back sessions, then 0
%% DO NOT EDIT BELOW THIS LINE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if session == 1
    sigmaPtest = 1;             %If running control experiment 1, otherwise 0
    numBlocks = 6;              %number of blocks
else
    sigmaPtest = 0;             %If running control experiment 1, otherwise 0
    numBlocks = 5;              %number of blocks
end
expName = 'metaReach';          %experiment title    
numIter = 10;                   %number of iterations across all 6x locations
confTrial = 3;                  %how often does a confidence trial appear
restart = 0;                    %Always 0
 
dateTime = clock;               %gets time for seed
rng(sum(100*dateTime));         %sets seed to be dependent on the clock

%%%%%%%%%%%%%%%%%%%%%%%%% File Save Path %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%using file save stucture function from Shannon

%create save structure for practice trials
if prac == 1
    [prac_exp,prac_fSaveFile,prac_tSaveFile,prac_restart] = expDataSetup(expName,subj,session,'practice',restart);
end

%create save structure for experimental trials
[exp,fSaveFile,tSaveFile,restart] = expDataSetup(expName,subj,session,'exp',restart);

%% %%%%%%%%%%%%%%%%%%%%%%% Setting up Psychtoolbox %%%%%%%%%%%%%%%%%%%%%%%%

%Standard settings for number of screens, screen size, screen selection,
%refresh rate, color space, and screen coordinates.
[displayInfo] = startExp(subj,datetime,rng);

%%
%%%%%%%%%%%%%%%%%%%%%%% Visual Trial Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Visual settings includng target color, size, location, quantity,
%confidence circle color and shape, fixation circle color and shape

[displayInfo] = screenVisuals(displayInfo);

%% %%%%%%%%%%%%%%%%%%%%% Screen Calibration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Check if calibration for TODAY already exists for a given participant, and
%no recalibration has been requested
if exist(['data_metaReach\' subj '\' subj '_' expName '_S' num2str(session) '_' date,'_tform.mat']) && redoCalib == 0
    load(['data_metaReach\' subj '\' subj '_' expName '_S' num2str(session) '_' date,'_tform.mat']) %load calibration incase of restart
    load(['data_metaReach\' subj '\' subj '_' expName '_S' num2str(session) '_' date,'_calibration.mat'])
else
    %9 point calibration for WACOM tablet and projector screen. Includes
    %calibration, affine transform, calibration test, and acceptance check.
    startPhase = 0;
    while startPhase == 0
        [tform, calibration,startPhase] = wacCalib(displayInfo); 
        if startPhase == 1
            save(['data_metaReach\' subj '\' subj '_' expName '_S' num2str(session) '_' date,'_tform.mat'],'tform')
            save(['data_metaReach\' subj '\' subj '_' expName '_S' num2str(session) '_' date,'_calibration.mat'],'calibration')
        end
        pause(1);
    end
    %% %%%%%%%% Pause in experiment to change to full siver mirror %%%%%%%%%%%%
    
    instructions = ('Please wait for experimenter to change mirror, then press T to continue to the experiment');
    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
    Screen('Flip', displayInfo.window);
    
    KbName('UnifyKeyNames');
    tKeyID = KbName('t');
    ListenChar(2);
    
    %Waits for T key to move forward with experiment
    [keyIsDown, secs, keyCode] = KbCheck;
    while keyCode(tKeyID)~=1
        [keyIsDown, secs, keyCode] = KbCheck;
    end
    ListenChar(1);
    
end

%%%%%%%%%%%%%%%%%%%% Target Sector Locations in Tablet Space %%%%%%%%%%%%%%
%target location base sectors
theta = (0:36:180).*pi/180;          %six sections for targets in radians
radius = 400;                       %chosen radius - this is how far all points are away from the hand
x = radius*cos(theta);
y = radius*sin(theta);

Xstrt = displayInfo.fixation(1);                %untransformed starting point
Ystrt = displayInfo.fixation(2);                %untransformed starting point

targets = [x+Xstrt; abs(y-Ystrt)]; %target locations in PIXEL space

displayInfo.tarLocs = targets; %target locations in PIXEL space

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% Trial Specifics %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%starting position for values within the trial loop
gamephase = 0;                  %trial phase start
trial = 1;                      %trial counter start

% Practice specifics if practice is happening
if prac == 1
    pracIter = 10;               %if practice how many iterations
    pracBlocks = 1;              %if practice how many blocks
    pracNumTrials = ones(pracBlocks,1)*(pracIter*displayInfo.numTargets); %total trial number per block must be a factor of 6
    pracTotalTrials = sum(pracNumTrials);   %total trials in all blocks
    
    %saving to file structure
    displayInfo.pracIterations = pracIter;
    displayInfo.pracBlocks = pracBlocks;
    displayInfo.pracNumTrials = pracNumTrials;
    displayInfo.pracTotalTrials = pracTotalTrials;
end

%settings specific to the trial set
numTrials = ones(numBlocks,1)*(numIter*displayInfo.numTargets); %total trial number per block must be a factor of 6
totalTrials = sum(numTrials);   %total trials in all blocks
numSecs = 1;                    %stimulus hold time
numFrames = round(numSecs/displayInfo.ifi); %stimulus hold time on screen adjusted for refresh
tarDispTime = round(.25/displayInfo.ifi);   %target display duration
ptb = 0*linspace(0,1,totalTrials); %30*sin(2*pi*numBlocks*linspace(0,1,totalTrials)); %perturbation function
pauseTime = .7;                  %pauses within trial
iti = .2;                        %inter-trial interval in seconds
respWindow = 1.2;                %time participant has to respond


%saving trial specifics to structure
displayInfo.numBlocks = numBlocks;
displayInfo.numIterations = numIter;
displayInfo.numTrials = numTrials;
displayInfo.totalTrials = totalTrials;
displayInfo.confTrial = confTrial;
displayInfo.numFrames = numFrames;
displayInfo.ptb = ptb;
displayInfo.pauseTime = pauseTime;
displayInfo.iti = iti;
displayInfo.tarDispTime = tarDispTime;
displayInfo.respWindow = respWindow;
displayInfo.tform = tform;
displayInfo.calibration = calibration;
displayInfo.fSaveFile = fSaveFile ;

%% Run control experiment if requested at top of code
%first block is practice trials
if sigmaPtest == 1
    save([fSaveFile,'_dispInfo.mat'],'displayInfo')
    [controlDat] = controlExpSigmaP(displayInfo, 6, 10, gamephase, trial, fSaveFile);
    %saving visual and system settings for experimental trials
else
%%
%%%%%%%%%%%%%%%%%%%%%%% Save Display Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%saving visual and system settings for practice trials
if prac == 1
    save([prac_fSaveFile,'_dispInfo.mat'],'displayInfo')
end

%saving visual and system settings for experimental trials
save([fSaveFile,'_dispInfo.mat'],'displayInfo')

%%
%%%%%%%%%%%%%%%%%%%%%%% Run Practice Trials %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if prac == 1
    HideCursor;
    [prac_resultsMat] = pracTrialSeq(displayInfo, pracBlocks, pracIter, gamephase, trial, prac_fSaveFile);
    
    save([prac_fSaveFile,'_pracResults.mat'],'prac_resultsMat'); %save data from practice
    
    %Wait screen before continuing to experiment
    instructions = ('To continue on to the experimental trials, please press the space bar');
    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
    Screen('Flip', displayInfo.window);
    pause(1);
    
    KbName('UnifyKeyNames');
    KeyID = KbName('space');
    ListenChar(2);
    
    %Waits for T key
    [keyIsDown, secs, keyCode] = KbCheck;
    while keyCode(KeyID)~=1
        [keyIsDown, secs, keyCode] = KbCheck;
    end
    ListenChar(1);
    ShowCursor;
    %clear tablet
    WinTabMex(3)
    WinTabMex(1); 
end
%%
%%%%%%%%%%%%%%%%%%%%%%%%%% Run Experiment Trials %%%%%%%%%%%%%%%%%%%%%%%%%%
HideCursor;
[resultsMat] = trialSeq(displayInfo, numBlocks, numIter, gamephase, trial, fSaveFile);

save([fSaveFile,'_results.mat'],'resultsMat'); %saves final expermimental data (also saved at the end of each run, and text files per trial)
ShowCursor;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%% Finish Experiment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%'end' page is displayed at the end of the experimental trials 
%clear tablet
WinTabMex(3)
WinTabMex(1);

end
% Clear the screen
sca;