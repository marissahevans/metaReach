function [ contResultsMat] = controlExpSigmaP(displayInfo,numBlocks, numIter, gamephase, trial,saveFile)
%% Control experiment to test what participant's SigmaP and SigmaM are prior
% to running the main experiment. This experiment has 9 steps:

% 1. Instructions screen - verbal instructions for how to do the task
% 2. Wait for participant to move pen to fixation point
% 3. Turn cursor off 
% 4. Display a target
% 5. Reach is made to target location at the 'go' cue
% 6. Wait for participant to move pen to fixation again
% 7. Turn cursor on
% 8. Use mouse to move to percieved location of reach end point and click
% 9. Switch back to pen and repeat from step 1 (250-300 trials)

wacData = [];

xc = displayInfo.xCenter;
yc = displayInfo.yCenter;

sampDots = [xc yc]'; 

HideCursor;
%%%%%%%%%%%%%%%%%%%%%%%%%% Output Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%location information
trialNum =[];                   %trial number
targetLoc = [];                 %tar X and tar Y (after jitter applied)
targetSector = [];              %sector of target location (1-6, 1 is bottom left, 6 is bottom right)
wXwY = nan(displayInfo.totalTrials,2);      %wacom coordinates for end point
endPointWac = [];               %true end X and Y
endPointPtb = [];               %feedback X and Y after perturbation applied
confRad = [];                   %confidence rating circle radius
fixError =[];                   %error (in pixels) from fixation
respDist = [];                  %euclidian distance from true target location to end point
circStart = [];                 %size of circle at start of conf. trial

%timestamps
tarAppearTime = [];             %target appearance time
moveStart = [];                 %movement start time
moveEnd = [];                   %movement end time
startTimes = [];                %start time of trial

%duration measures
inTimes = [];                   %time it takes for participant to get inside fixation
RTs = [];                       %time it takes for participant to start response
MTs = [];                       %duration of movement
tabletData = [];

tarLocations = displayInfo.tarLocs;  %possible target locations

%Because tablet is smaller than projected area:
topBuff = [0 0 displayInfo.screenXpixels displayInfo.screenAdj/2]; %black bar at top of screen
bottomBuff = [0 displayInfo.screenYpixels-displayInfo.screenAdj/2 displayInfo.screenXpixels displayInfo.screenYpixels]; %black bar at bottom of screen

%%%%%%%%%%%%%%%%%%%%%%%%%% Initalizing WinTab %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
WinTabMex(0, displayInfo.window); %Initialize tablet driver, connect it to active window

%%%%%%%%%%%%%%%%%%%%%%% Setting up escape and timing %%%%%%%%%%%%%%%%%%%%%%
% Define the ESC key
KbName('UnifyKeynames');                    %get key names
esc = KbName('ESCAPE');                     %set escape key code
[keyIsDown, secs, keyCode] = KbCheck;       % Exits experiment when ESC key is pressed.
% if keyIsDown
%     if keyCode(esc)
%         break
%     end
% end
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSTRUCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%
%INSTRUCTIONS PAGE 1 - experiment instructions
instructions1 = ('In this control experiment you will be reaching to the same point on every trial with no feedback');
instructions2 = ('After each reach you will be asked to indicate your perceived reach end point using the mouse');
instructions3 = ('A dot will represent your mouse position, move it to the chosen location then click to confirm your input');
instructions4 = ('A set of practice reaches will occur before the experiment so you can practice your reach on the tablet');
instructions6 = ('Always pick the pen up after each reach and do not leave it positioned on the tablet');
instructions5 = ('Press SPACE to move to next screen');
[instructionsX1, instructionsY1] = centreText(displayInfo.window, instructions1, 15);
[instructionsX2, instructionsY2] = centreText(displayInfo.window, instructions2, 15);
[instructionsX3, instructionsY3] = centreText(displayInfo.window, instructions3, 15);
[instructionsX4, instructionsY4] = centreText(displayInfo.window, instructions4, 15);
[instructionsX5, instructionsY5] = centreText(displayInfo.window, instructions5, 15);
[instructionsX6, instructionsY6] = centreText(displayInfo.window, instructions6, 15);
Screen('DrawText', displayInfo.window, instructions6, instructionsX6, instructionsY6+120, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions1, instructionsX1, instructionsY1-40, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions2, instructionsX2, instructionsY2, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions3, instructionsX3, instructionsY3+40, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions4, instructionsX4, instructionsY4+80, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions5, instructionsX5, instructionsY5+160, displayInfo.whiteVal);
Screen('Flip', displayInfo.window);
pause(2);

KbName('UnifyKeyNames');
KeyID = KbName('space');
ListenChar(2);
%Waits for key press
[keyIsDown, secs, keyCode] = KbCheck;
while keyCode(KeyID)~=1
    [keyIsDown, secs, keyCode] = KbCheck;
end
ListenChar(1);

%INSTRUCTIONS PAGE 2 - exploring screen
instructions1 = ('Please take the next 15 seconds to explore the tablet with the pen');
instructions2 = ('Move your hand with the pen around on the tablet like you are drawing');
instructions3 = ('Practice trials will automatically begin after 15 seconds');
instructions5 = ('Press SPACE to start');
[instructionsX1, instructionsY1] = centreText(displayInfo.window, instructions1, 15);
[instructionsX2, instructionsY2] = centreText(displayInfo.window, instructions2, 15);
[instructionsX3, instructionsY3] = centreText(displayInfo.window, instructions3, 15);
[instructionsX5, instructionsY5] = centreText(displayInfo.window, instructions5, 15);
Screen('DrawText', displayInfo.window, instructions1, instructionsX1, instructionsY1-40, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions2, instructionsX2, instructionsY2, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions3, instructionsX3, instructionsY3+40, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions5, instructionsX5, instructionsY5+160, displayInfo.whiteVal);
Screen('Flip', displayInfo.window);
pause(2);

KbName('UnifyKeyNames');
KeyID = KbName('space');
ListenChar(2);
%Waits for key press
[keyIsDown, secs, keyCode] = KbCheck;
while keyCode(KeyID)~=1
    [keyIsDown, secs, keyCode] = KbCheck;
end
ListenChar(1);

%%
%%%%%%%%%%%%%%%%%%%%%%%%% EXPLORE SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This uses PROJECTOR COORDINATES to allow participant to explore the tablet
%and get used to the dimentions etc.
tic
tt = 0;
while tt <= 15          %run for 15 seconds
    
    % Get the current position of the mouse
    [x, y, buttons] = GetMouse(displayInfo.window);
    
    % Draw a white dot where the mouse cursor is
    Screen('DrawDots', displayInfo.window, [x y], 10, displayInfo.whiteVal, [], 2);
    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
    
    % Flip to the screen
    Screen('Flip', displayInfo.window);
     tt = toc;
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%% Practice Trials %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Just reaches,  no mouse input. 

 
%%
%%%%%%%%%%%%%%%%%%%%%%%% Experimental Code %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
contResultsMat = struct();
tic                                                     %start block timer
jj = 1;
for bb = 1:numBlocks                                    %run for number of blocks in fucntion settings
timeFlag = 0;                                       %flag to reshuffle trial order of remaining permutations if trial was missed do to timing error    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Trial Permutations %%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for tt = 1:numIter                                  %run for set number of iterations within a block
       while jj < displayInfo.numTargets +1  
           
        %%%%%%%%%%%%%%%%%%%%%%%%% Initalizing GetMouse %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [x, y, buttons] = GetMouse(displayInfo.window);
        
        while gamephase <= 5
            %%%%%%%%%%%%%%%%%%%%%%%% Begin drawing to screen %%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %Start Screen
            if gamephase == 0                       %starting screen
                
                startTimes(trial) = toc;            %capture start time
                t = toc;                            %make relative time point
                temp = 1;                           %temp counting variable
                if trial == 1
                       instructions = 'Begin Practice Trials';
                       [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                       Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                       Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                       Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                       Screen('Flip', displayInfo.window);
                        
                       pause(3)
                end
                if trial == numBlocks*numIter +1
                       instructions = 'Begin Control Experiment';
                       [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                       Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                       Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                       Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                       Screen('Flip', displayInfo.window);
                       
                       pause(3)
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Select Target Location %%%%%%%%%%%%%%%%%%%
                
                dotXpos = xc; %target X location
                dotYpos = yc-125; %target Y location
                targetLoc = [dotXpos dotYpos];
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Trial Visualizations Begin %%%%%%%%%%%%%%%
                
                while temp == 1
                    %Starting instruction screen
                    Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                    instructions = 'Place pen inside white fixation circle and hold until target turns green';
                    [instructionsX, instructionsY] = centreText(displayInfo.window, instructions, 15);
                    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                    
                    [x, y, buttons] = GetMouse(displayInfo.window); %get pen position
                    startPos = [displayInfo.xCenter displayInfo.screenYpixels-175];
                    fixError(trial,1) = x-displayInfo.xCenter; fixError(trial,2) = y-(displayInfo.screenYpixels-175); %fixation check (must be inside circle)
                    %Show cursor when near fixation to help center at
                    %start
                    if abs(fixError(trial,1)) <= 50 && abs(fixError(trial,2)) <= 50
                        Screen('DrawDots', displayInfo.window, [x y], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %pen location
                    end
                    if abs(fixError(trial,1)) <= displayInfo.baseRect(3)/2 && abs(fixError(trial,2)) <=displayInfo.baseRect(3)/2 && buttons(1) == 1 %if error is smaller than fixation radius and pen is touching surface
                        gamephase = 1;                      %move forward to next phase
                        inTimes(trial) = toc - t;           %save time it took to find fixation
                        pause(displayInfo.pauseTime);
                        t = toc;                            %relative time point
                        temp = 0;                           %conditions are met
                        
                    else
                        temp = 1;                           %repeat until conditions are met
                    end
                    Screen('Flip', displayInfo.window);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Target Appears %%%%%%%%%%%%%%%%%%%
            elseif gamephase == 1
                
                for frame = 1:displayInfo.numFrames         %display target for numFrames seconds
                    Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %target
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                    Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
                    Screen('Flip', displayInfo.window);
                    tarAppearTime(trial,1) = toc;
                    
                    [x, y, buttons] = GetMouse(displayInfo.window); %get pen position
                    if ~buttons(1)                          %if they lift the pen during target display
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Jumped the gun!';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                        Screen('Flip', displayInfo.window);
                        timeFlag = 1;                       %flag for reshuffling of locations when repeated
                        gamephase = 99;                     %restart trial phase
                        pause(displayInfo.iti+.3);
                        break
                    end
                end
                t = toc;                                    %relative time point
                if gamephase == 1
                    while buttons(1) && toc-t<displayInfo.respWindow %while fixation is held and less than .6 seconds has elapsed
                        
                        [x, y, buttons] = GetMouse(displayInfo.window); %get pen position
                        Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.dotColor, [], 2); %go cue target
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        Screen('Flip', displayInfo.window);
                    end
                    
                    if toc-t > displayInfo.respWindow       %if elapsed time is longer than the response window (.6 seconds)
                        instructions = 'too slow';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        Screen('Flip', displayInfo.window);
                        timeFlag = 1;                       %flag for reshuffling of locations when repeated
                        gamephase = 99;                     %restart trial phase
                        pause(displayInfo.iti+.3);
                    else
                        gamephase = 2;                      %if no mistakes are made move to next trial phase
                    end
                else
                end
                RTs(trial) = toc-t;                         %elapsed response time
                t = toc;                                    %relative time point
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Participant Response %%%%%%%%%%%%%%%
            elseif gamephase == 2
                
                %%%%%% WINTABMEX TABLET POSITION COLLECTION
                trialLength = displayInfo.respWindow +.2; %record buffer at the end of response time
                samplingRate = 100; %displayInfo.tabSamplingRate;
                deltaT = 1/samplingRate;
                
                %Set up a variable to store data
                pktData = [];
                WinTabMex(2);       %Empties the packet queue in preparation for collecting actual data
                %Call this immediately before beginning any slow loop
                
                %This loop runs for trialLength seconds.
                start = GetSecs;
                stop  = start + trialLength;
                
                while GetSecs < stop  %once movement has started and lasts under .6 seconds
                    moveStart(trial,1) = toc;               %movement start time
                    
                    loopStart = GetSecs;
                    
                    %This loop runs for deltaT or until it successfully retrieves some data from the queue
                    while 1  %Note this loop MUST be broken manually, as 'while 1' always returns TRUE
                        
                        pkt = WinTabMex(5);
                        
                        %This check breaks the loop if data is recovered from the queue before deltaT is up
                        if ~isempty(pkt)
                            break
                        end
                        
                        %This check breaks the loop after deltaT if pkt was always empty
                        if GetSecs>(loopStart+deltaT)
                            pkt = zeros(9,1); %Dummy data representing a missed data point
                            break;
                        end
                    end
                    pkt = [pkt; (GetSecs - start)];
                    pktData = [pktData pkt];
                    
                    %Waits to end of deltaT if need be
                    if GetSecs<(loopStart+deltaT)
                        WaitSecs('UntilTime', loopStart+deltaT);
                    end
                    
                end
                pktData2 = pktData';  %Assemble the data and then transpose to arrange data in columns because of Matlab memory preferences
                
                pktData2 = [pktData2 trial*ones(length(pktData2),1)];
                if sum(pktData2(:,1)) == 0
                    ShowCursor;
                    instructions = 'Wacom not recording data! Restart!';
                    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                    Screen('Flip', displayInfo.window);
                    error('Wacom not recording data! Restart!');
                    break
                end
                tabletData = [tabletData; pktData2;];
                
                WinTabMex(3); % Stop/Pause data acquisition.
                %%%%%%
                
                %no feedback during trial
                Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                Screen('Flip', displayInfo.window);
                
                if sum(pktData2(:,4)== 1)<1 | pktData2(min(find(pktData2(:,4) == 1)),10) > trialLength -.2         %if movement was longer than .8 seconds
                    instructions = 'too slow';
                    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                    Screen('Flip', displayInfo.window);
                    timeFlag = 1;                           %flagging for reshuffling of locations on repeat
                    gamephase = 99;                         %restart trial phase
                    pause(displayInfo.iti+.3);
                end
                if (sum(pktData2(:,8) == 0)) < 1            %if they slid their hand
                    
                    instructions = 'Pick up hand higher during reach!';
                    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                    Screen('Flip', displayInfo.window);
                    timeFlag = 1;                           %flagging for reshuffling of locations on repeat
                    gamephase = 99;                         %restart trial phase
                    pause(displayInfo.iti+.5);
                end
                MTs(trial) = toc - t;                       %elapsed movement time
                moveEnd(trial,1) = toc;                     %movement end timing saved
                
                if gamephase ~= 99
                    wX = pktData2(min(find(pktData2(:,4) == 1)),1); %find X location at first pen touch point
                    wY = pktData2(min(find(pktData2(:,4) == 1)),2); %find Y location at first pen touch point
                    wXwY(trial,1) = wX; wXwY(trial,2) = wY;
                    [endPointWac(trial,1) endPointWac(trial,2)] = transformPointsForward(displayInfo.tform,wX,wY); %transform into projector space
                    respDist(trial,1) = sqrt( (targetLoc(1,1)-endPointWac(trial,1))^2 + (targetLoc(1,2)-endPointWac(trial,2))^2); %euclidian distance to target from true end point%if no timing mistakes were made
                    
                    
                    gamephase  = 3;                         %use mouse to report
                    t = toc;                                %relative time point
                end
                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reporting End Point %%%%%%%%%%%%%%%%%  
            elseif gamephase == 3
                
                %%%%%% RETURNING TO FIXATION %%%%%%%
                temp = 1;
                while temp == 1
                    Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                    instructions = 'Touch pen inside white circle to continue';
                    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                    
                    [x, y, buttons] = GetMouse(displayInfo.window); %get pen position
                    fixError(trial,1) = x-displayInfo.xCenter; fixError(trial,2) = y-(displayInfo.screenYpixels-175); %fixation check (must be inside circle)
                    
                    if abs(fixError(trial,1)) <= 50 && abs(fixError(trial,2)) <= 50
                        Screen('DrawDots', displayInfo.window, [x y], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %pen location
                    end
                    
                    if abs(fixError(trial,1)) <= displayInfo.baseRect(3)/2 && abs(fixError(trial,2)) <=displayInfo.baseRect(3)/2 && buttons(1) == 1 %if error is smaller than fixation radius and pen is touching surface
                        gamephase = 1;                      %move forward to next phase
                        inTimes(trial) = toc - t;           %save time it took to find fixation
                        pause(displayInfo.pauseTime);
                        t = toc;                            %relative time point
                        temp = 0;                           %conditions are met
                        
                    else
                        temp = 1;                           %repeat until conditions are met
                    end
                    Screen('Flip', displayInfo.window);
                end
                
                    %%%%% %IF PRACTICE TRIAL %%%%%%%%
               if bb == 1 
                    xPtb = endPointWac(trial,1);                 %set X perturbation
                    yPtb = endPointWac(trial,2);                 %set Y perturbation
                    
                    for frame = 1:displayInfo.numFrames         %display feedback for 1 second
                        Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.rectColor, [], 2); %target location
                        Screen('DrawDots', displayInfo.window, [xPtb yPtb], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %perturbed endpoint location
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Feedback';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                        Screen('Flip', displayInfo.window);
                    end
                    endptChosen(trial,:) = [0 0];
                    endPointPtb(trial,1) = xPtb; endPointPtb(trial,2) = yPtb;
                    gamephase = 5;                              %move on to final trial phase
              
                    %%%%%% SWITCHING TO MOUSE %%%%%
               else
                   
                   %Check to make sure pen has been lifted
                   [x, y, buttons] = GetMouse(displayInfo.window);
                   while buttons(1)
                       Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                       Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                       instructions = 'Pick up the pen from the tablet and switch to the mouse';
                       [instructionsX] = centreText(displayInfo.window, instructions, 15);
                       Screen('DrawText', displayInfo.window, instructions, instructionsX, displayInfo.yCenter-250, displayInfo.whiteVal);
                       [x, y, buttons] = GetMouse(displayInfo.window)
                       Screen('DrawDots', displayInfo.window, [x y], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %mouse location
                       Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.dotColor, [], 2); %go cue target
                       Screen('Flip', displayInfo.window);
                   end
                   
                   SetMouse(displayInfo.fixation(1),displayInfo.fixation(2),displayInfo.window)
                   [x, y, buttons] = GetMouse(displayInfo.window);
                   
%                    while [x y] == displayInfo.fixation
%                        Screen('DrawDots', displayInfo.window, [x y], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %mouse location
%                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
%                        Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.dotColor, [], 2); %go cue target
%                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
%                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
%                        instructions = 'Switch to the mouse and indicate your percieved reach end point with a click';
%                        [instructionsX, instructionsY] = centreText(displayInfo.window, instructions, 15);
%                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
%                        Screen('Flip', displayInfo.window);
%                        [x, y, buttons] = GetMouse(displayInfo.window);
%                    end
%                    [x, y, buttons] = GetMouse(displayInfo.window);
                   
                while ~buttons(1)
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                    instructions = 'Use the mouse to click on the point where you think your reach endpoint was';
                    [instructionsX] = centreText(displayInfo.window, instructions, 15);
                    Screen('DrawText', displayInfo.window, instructions, instructionsX, displayInfo.yCenter-250, displayInfo.whiteVal);
                    [x, y, buttons] = GetMouse(displayInfo.window);
                    Screen('DrawDots', displayInfo.window, [x y], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %mouse location
                    Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.dotColor, [], 2); %go cue target
                    Screen('Flip', displayInfo.window);
                end
                endptChosen(trial,:) = [x y];
                fbTime = toc - t;                           %elapsed time for rating to be set
                
                pause(displayInfo.pauseTime)
                gamephase = 5;                              %move on to final trial phase
              end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of Trial %%%%%%%%%%%%%%%%%%%
            elseif gamephase == 5
                
                clear buttons;
                
                if jj == displayInfo.numTrials(bb)          %if this is last trial
                    instructions = 'End of Run';
                    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                    trialNum(trial) = trial;                %save trial number
                    trial = trial+1;                        %update trial counter
                    jj = jj+1;                              %update iteration counter
                    gamephase = 6;                          %signal end of trial
                else
                    instructions = 'Get ready for next trial';
                    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                    trialNum(trial) = trial;
                    jj = jj+1;
                    trial = trial+1;
                    gamephase = 6;
                end
                % Flip to the screen
                Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                Screen('Flip', displayInfo.window);
                pause(displayInfo.iti);
                
                %saving trial by trial output incase of a crash
                fd = fopen([saveFile,'_controltrial_',num2str(trial-1)],'w');
                fprintf(fd,'trial=%f tarLocX=%f tarLocY=%f endptChosenX=%f  endptChosenY=%f wacEndPtX=%f wacEndPtY=%f',...
                    trialNum(trial-1),targetLoc,endptChosen(trial-1,:),wXwY(trial-1,:));
                fclose(fd);
                
            elseif gamephase == 99                          %flagged as a repeat trial
                9999999                                     %visual output for testing
                gamephase = 0;                              %reset trial phase for restart
                instructions = 'Get ready for next trial';
                [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                Screen('Flip', displayInfo.window);
                pause(displayInfo.iti);
            end
        end
        gamephase = 0;                                      %reset trial phase at the end of trial
    end
    jj = 1;                                                 %reset location count at the end of iteration
end



%End of block screen
KbName('UnifyKeyNames');
spaceKeyID = KbName('space');
ListenChar(2);

instructions = 'End of block - Press space bar to begin next block';
[instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);

Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
Screen('Flip', displayInfo.window);

%Waits for space bar
[keyIsDown, secs, keyCode] = KbCheck;
while keyCode(spaceKeyID)~=1
    [keyIsDown, secs, keyCode] = KbCheck;
end
ListenChar(1);


%% %%%%%%%%%%%%%%%%%%%%%%%%% Save output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
contResultsMat.trialNum = trialNum;
contResultsMat.targetLoc = targetLoc;
contResultsMat.startPos = startPos;
contResultsMat.wacEndPoint = wXwY;
contResultsMat.wacScreenEnd = endPointWac;
contResultsMat.mouseEndPt = endptChosen;
contResultsMat.fixError = fixError;
contResultsMat.respDist = respDist;
contResultsMat.tarAppearTime = tarAppearTime;
contResultsMat.moveStart = moveStart;
contResultsMat.moveEnd = moveEnd;
contResultsMat.startTimes = startTimes;
contResultsMat.inTimes = inTimes;
contResultsMat.RTs = RTs;
contResultsMat.MTs = MTs;

contResultsMat.xPos = tabletData(:,1);
contResultsMat.yPos = tabletData(:,2);
contResultsMat.zPos = tabletData(:,3);
contResultsMat.buttonState = tabletData(:,4);
contResultsMat.serialNumber = tabletData(:,5);
contResultsMat.tabletTimeStamp = tabletData(:,6);
contResultsMat.penStatus = uint32(tabletData(:,7));
contResultsMat.penChange = uint32(tabletData(:,8));
contResultsMat.normalPressure = tabletData(:,9);
contResultsMat.getsecTimeStamp = tabletData(:,10);

contResultsMat.tabletData = tabletData;
save([displayInfo.fSaveFile,'_controlresults.mat'],'contResultsMat');
end
%% %%%%%%%%%%%%%%%%%%%%%%%%% FINAL SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%%

KbName('UnifyKeyNames');
spaceKeyID = KbName('space');
ListenChar(2);

instructions = 'End of Experiment - Thank you for participating!';
[instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);

Screen('Flip', displayInfo.window);

%Waits for space bar
[keyIsDown, secs, keyCode] = KbCheck;
while keyCode(spaceKeyID)~=1
    [keyIsDown, secs, keyCode] = KbCheck;
end
ListenChar(1);
end



