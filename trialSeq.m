 function [resultsMat] = trialSeq(displayInfo,numBlocks, numIter, gamephase, trial,saveFile)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
%%
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

tarLocations = displayInfo.tarLocs';  %possible target locations

%Because tablet is smaller than projected area:
topBuff = [0 0 displayInfo.screenXpixels displayInfo.screenAdj/2]; %black bar at top of screen
bottomBuff = [0 displayInfo.screenYpixels-displayInfo.screenAdj/2 displayInfo.screenXpixels displayInfo.screenYpixels]; %black bar at bottom of screen
%% %%%%%%%%%%%%%%%%%%%%%%% Setting up PowerMate %%%%%%%%%%%%%%%%%%%%%%%%%%%


pm = PsychPowerMate('Open');            %will read a numeric value.

%%%%%%%%%%%%%%%%%%%%%%%%%% Initalizing WinTab %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
WinTabMex(0, displayInfo.window); %Initialize tablet driver, connect it to active window


%%
%%%%%%%%%%%%%%%%%%%%%%%% Experimental Code %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
blockScore =0;                                          %Score for each block
possibleScore = 0;                                      %possible score for each block given performance

resultsMat = struct();
tic                                                     %start block timer
jj = 1;                                                 %start counter for while loop
for bb = 1:numBlocks                                    %run for number of blocks in fucntion settings 
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Trial Permutations %%%%%%%%%%%%%%%%%%%%%%%%%%%
    tarOrder = cell2mat(arrayfun(@(tarLocations) randperm(displayInfo.numTargets), 1:numIter, 'UniformOutput',false)')'; %shuffle possible target locations
    timeFlag = 0;                                       %flag to reshuffle trial order of remaining permutations if trial was missed do to timing error
    
    for tt = 1:numIter                                  %run for set number of iterations within a block
        while jj < displayInfo.numTargets +1            %loop through each target location one time
            
            
%%%%%%%%%%%%%%%%%%%%%%% Setting up escape and timing %%%%%%%%%%%%%%%%%%%%%%
            % Define the ESC key 
            KbName('UnifyKeynames');                    %get key names
            esc = KbName('ESCAPE');                     %set escape key code                                      
            [keyIsDown, secs, keyCode] = KbCheck;       % Exits experiment when ESC key is pressed.
            if keyIsDown
                if keyCode(esc)
                    break
                end
            end

%%%%%%%%%%%%%%%%%%%%%%%%% Initalizing GetMouse %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [x, y, buttons] = GetMouse(displayInfo.window);
            
            while gamephase <= 5
%%%%%%%%%%%%%%%%%%%%%%%% Begin drawing to screen %%%%%%%%%%%%%%%%%%%%%%%%%%
                
                %Start Screen
                if gamephase == 0                       %starting screen
                    
                    startTimes(trial) = toc;            %capture start time
                    t = toc;                            %make relative time point 
                    temp = 1;                           %temp counting variable
                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Select Target Location %%%%%%%%%%%%%%%%%%%
                    
                    jitter = [randn*(displayInfo.xCenter/12),randn*(displayInfo.yCenter/12)]; %jitter applied (+/- randn) normally distributed noise
                    if timeFlag == 1                    %if time flag is 1, participant is restarting trial (due to taking too long to respond)
                        tarOrder(jj:end,tt) = Shuffle(tarOrder(jj:end,tt)); %shuffle remaining possible locations including location which was skipped
                        timeFlag = 0;                   %return time flag to zero for future trials 
                    end
                    tarPos = tarOrder(jj,tt);           %order in which target locations appear
                    resultsMat.tarOrder(trial,:) = tarOrder(jj,tt);
                    
                    dotXpos = tarLocations(tarPos,1) + jitter(1); %target X location after jitter is applied
                    dotYpos = tarLocations(tarPos,2) + jitter(2); %target Y location after jitter is applied.
                    targetLoc(trial,1) = dotXpos; targetLoc(trial,2) = dotYpos; %target position saved
                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Trial Visualizations Begin %%%%%%%%%%%%%%%
                    
                    while temp == 1
                        %Starting instruction screen
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Place pen inside white fixation circle';
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
                        Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.dotColor, [], 2); %target
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
                        respDist(trial,1) = sqrt( (targetLoc(trial,1)-endPointWac(trial,1))^2 + (targetLoc(trial,2)-endPointWac(trial,2))^2); %euclidian distance to target from true end point%if no timing mistakes were made
                        
                        if rem(trial,displayInfo.confTrial) == 0 %if it is a confidence judgement trial
                            gamephase = 3;                      %confidence test phase
                            pause(displayInfo.pauseTime)
                        else
                            gamephase = 4;                      %feedback phase
                            pause(displayInfo.pauseTime)
                        end
                        t = toc;                                %relative time point
                    end
                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Confidence Trial %%%%%%%%%%%%%%%%%
                elseif gamephase == 3
                    temp=1;
                    while temp == 1
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Place pen inside white circle to report confidence';
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
                    
                    [buttonPM, dialPos] = PsychPowerMate('Get',pm); %initalize powermate
                    startDial = dialPos;                        %get dial's starting position
                    circSize(trial) = randi([10,200],1);               %set a cirlce size to start (randomly)
                    
                    while ~buttonPM                             %until button on dial is pressed
                        
                        [buttonPM, dialPos] = PsychPowerMate('Get',pm); %get dial postion
                        
                        circStart(trial) = circSize(trial) + (dialPos-startDial)*2; %circle size adjusted for starting dial postion
                        baseRect2 = abs([0 0 circStart(trial) circStart(trial)]); %draw circle 
                        
                        centeredRect2 = CenterRectOnPointd(baseRect2, dotXpos, dotYpos); %Center the circle on the final pen location
                     
                        %points to circle size calculation
                        if baseRect2(4)/2 > 150                 %if the circle radius is greater than 150 pixels
                            pointsPos = 0;
                        elseif baseRect2(4)/2 < displayInfo.dotSizePix/2 %if the radius is smaller than the target size
                           pointsPos = 10;
                        else
                          pointsPos = 10-(10/(150-displayInfo.dotSizePix/2)*((baseRect2(4)/2)-displayInfo.dotSizePix/2)); %10 points are possible across a 150 pixel radius
                      
                        end
                        
                        Screen('FrameOval', displayInfo.window, displayInfo.rectColor, centeredRect2, 2,2); % Draw the circle to the screen
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Circle is centered on target, make circle just large enough to enclose end point - smaller circle = closer to goal';
                        [instructionsX] = centreText(displayInfo.window, instructions, 15);
                        instructions1 = 'Points only collected if final circle size would enclose the endpoint';
                        [instructions1X] = centreText(displayInfo.window, instructions1, 15);
                        points = ['Points possible: ' num2str(pointsPos)];
                        [pointsX, pointsY] = centreText(displayInfo.window, points, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, displayInfo.yCenter-280, displayInfo.whiteVal);
                        Screen('DrawText', displayInfo.window, instructions1, instructions1X, displayInfo.yCenter-240, displayInfo.whiteVal);
                        Screen('DrawText', displayInfo.window, points, pointsX, pointsY-160, displayInfo.whiteVal);
                        Screen('Flip', displayInfo.window);
                        
                    end
                    fbTime = toc - t;                           %elapsed time for rating to be set
                    confRad(trial,1) = baseRect2(4)/2;          %pixel radius of confidence circle recorded
                   
                    if respDist(trial,1) > 150                 %if radius is greater than 150 pixels
                        pointsPossible(trial,1) = 0;
                    elseif respDist(trial,1) < displayInfo.dotSizePix/2 %if radius is smaller than the target size
                        pointsPossible(trial,1) = 10;
                    else
                        pointsPossible(trial,1) = 10 -(10/ ((150-displayInfo.dotSizePix/2)*(respDist(trial,1)-displayInfo.dotSizePix/2)));   %points out of 10 across a 150 pixel radius
                   end
                    
                    if confRad(trial,1) >= respDist(trial,1)-4 %-4 to crop at edge of dot
                        pointsEarned(trial,1) = pointsPos;
                    else
                        pointsEarned(trial,1) = 0;
                    end
                    clear buttonPM
                    pause(displayInfo.pauseTime)
                    gamephase = 5;                              %move on to final trial phase
                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Feedback Trial %%%%%%%%%%%%%%%%%%%
                elseif gamephase == 4
                    temp = 1;
                    while temp == 1
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Place pen inside white circle to view feedback';
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
                    xPtb = endPointWac(trial,1)+displayInfo.ptb(trial);            %set X perturbation
                    yPtb = endPointWac(trial,2)+displayInfo.ptb(trial);            %set Y perturbation
                    
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
                    confRad(trial,1) = 0;                       %knob position saved as zero (no conf. rating)
                    endPointPtb(trial,1) = xPtb; endPointPtb(trial,2) = yPtb;
                    gamephase = 5;                              %move on to final trial phase
                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of Trial %%%%%%%%%%%%%%%%%%%
                elseif gamephase == 5
                    targetSector(trial,1) = tarPos;             %save target position since trial was fully completed
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
                    fd = fopen([saveFile,'_trial_',num2str(trial-1)],'w');
                    fprintf(fd,'trial=%f tarLocX=%f tarLocY=%f tarSec=%f wacEndPtX=%f wacEndPtY=%f confRad=%f',...
                        trialNum(trial-1), targetLoc(trial-1,:), targetSector(trial-1,:),wXwY(trial-1,:),confRad(trial-1,1));
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%% END OF BLOCK SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%
    blockScore(bb) = sum(pointsEarned) - sum(blockScore);       %score for this block
    runningScore(bb) = sum(pointsEarned);                       %running score across all blocks
    possibleScore(bb) = sum(pointsPossible) - sum(possibleScore); %possible score based on performance
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%% Save output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    resultsMat.trialNum = trialNum;
    resultsMat.targetLoc = targetLoc;
    resultsMat.targetSector = targetSector;
    resultsMat.startPos = startPos;
    resultsMat.wacEndPoint = wXwY;
    resultsMat.wacScreenEnd = endPointWac;
    resultsMat.feedbackLoc = endPointPtb;
    resultsMat.confCircStart = circSize;
    resultsMat.confRad = confRad;
    resultsMat.fixError = fixError;
    resultsMat.respDist = respDist;
    resultsMat.blockScore = blockScore;
    resultsMat.runningScore = runningScore;
    resultsMat.possibleScore = possibleScore;
    resultsMat.pointsEarned = pointsEarned;
    resultsMat.pointsPossible = pointsPossible;
    resultsMat.tarAppearTime = tarAppearTime;
    resultsMat.moveStart = moveStart;
    resultsMat.moveEnd = moveEnd;
    resultsMat.startTimes = startTimes;
    resultsMat.inTimes = inTimes;
    resultsMat.RTs = RTs;
    resultsMat.MTs = MTs;
    
    resultsMat.xPos = tabletData(:,1);
    resultsMat.yPos = tabletData(:,2);
    resultsMat.zPos = tabletData(:,3);
    resultsMat.buttonState = tabletData(:,4);
    resultsMat.serialNumber = tabletData(:,5);
    resultsMat.tabletTimeStamp = tabletData(:,6);
    resultsMat.penStatus = uint32(tabletData(:,7));
    resultsMat.penChange = uint32(tabletData(:,8));
    resultsMat.normalPressure = tabletData(:,9);
    resultsMat.getsecTimeStamp = tabletData(:,10);
    
    resultsMat.tabletData = tabletData;
    save([displayInfo.fSaveFile,'_results.mat'],'resultsMat');
    
    %End of block screen
    KbName('UnifyKeyNames');
    spaceKeyID = KbName('space');
    ListenChar(2);
    
    instructions = 'End of block - Press space bar to begin next block';
    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
    
    block = ['Your score so far: ' num2str(runningScore(bb))]';
    [blockX blockY] = centreText(displayInfo.window, block, 20);
    Screen('DrawText', displayInfo.window, block, blockX, blockY-100, displayInfo.whiteVal);
    
    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
    Screen('Flip', displayInfo.window);
   
    %Waits for space bar
    [keyIsDown, secs, keyCode] = KbCheck;
    while keyCode(spaceKeyID)~=1
        [keyIsDown, secs, keyCode] = KbCheck;
    end
    ListenChar(1);

end 

%% %%%%%%%%%%%%%%%%%%%%%%%%% FINAL LEADERBORAD %%%%%%%%%%%%%%%%%%%%%%%%%%%
[names,points] = addToLeaderboard(['metaReach_final'],displayInfo.subj,runningScore(end));

KbName('UnifyKeyNames');
spaceKeyID = KbName('space');
ListenChar(2);

instructions = 'End of Experiment - Thank you for participating!';
[instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);

leader = ('------ Final Leader Board ------');
[leaderX leaderY] = centreText(displayInfo.window, leader, 20);
Screen('DrawText', displayInfo.window, leader, leaderX, leaderY-50, displayInfo.whiteVal);

line1 = [names{1} ':   ' num2str(points(1))];
[line1X line1Y] = centreText(displayInfo.window, line1, 15);
Screen('DrawText', displayInfo.window, line1, line1X, line1Y, displayInfo.whiteVal);

line2 = [names{2} ':   ' num2str(points(2))];
[line2X line2Y] = centreText(displayInfo.window, line2, 15);
Screen('DrawText', displayInfo.window, line2, line2X, line2Y+20, displayInfo.whiteVal);

line3 = [names{3} ':   ' num2str(points(3))];
[line3X line3Y] = centreText(displayInfo.window, line3, 15);
Screen('DrawText', displayInfo.window, line3, line3X, line3Y+40, displayInfo.whiteVal);

line4 = [names{4} ':   ' num2str(points(4))];
[line4X line4Y] = centreText(displayInfo.window, line4, 15);
Screen('DrawText', displayInfo.window, line4, line4X, line4Y+60, displayInfo.whiteVal);

line5 = [names{5} ':   ' num2str(points(5))];
[line5X line5Y] = centreText(displayInfo.window, line5, 15);
Screen('DrawText', displayInfo.window, line5, line5X, line5Y+80, displayInfo.whiteVal);

Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
Screen('Flip', displayInfo.window);

pause(1);
%Waits for space bar
[keyIsDown, secs, keyCode] = KbCheck;
while keyCode(spaceKeyID)~=1
    [keyIsDown, secs, keyCode] = KbCheck;
end
ListenChar(1);
end
