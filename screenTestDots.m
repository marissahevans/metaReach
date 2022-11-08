screens = Screen('Screens');        % Get the screen numbers
screenNumber = max(screens);
white = WhiteIndex(screenNumber);   % Define white color spaces
black = BlackIndex(screenNumber);   % Define black color spaces
grey = white/2;                     % Define grey color spaces
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey); % Open a grey on screen window
[xCenter, yCenter] = RectCenter(windowRect);

tarLocs = [xCenter yCenter; xCenter - 200 yCenter; xCenter yCenter - 200; xCenter yCenter + 200; xCenter + 200 yCenter]';

Screen('DrawDots', window, tarLocs, 10, [.75 .75 .75], [], 2);
Screen('Flip', window);

sampDots = tarLocs;
dotSizePix = 10;
dotColor = [0 1 0];  
[~, ~, buttons] = GetMouse(window);

wacData = [];
%% Wacom
WinTabMex(0, window);   %Initialize tablet driver, connect it to active window
trialLength = .3;                   %record buffer at the end of response time
samplingRate = 60;                  %displayInfo.tabSamplingRate;
deltaT = 1/samplingRate;
testphase = 0;                      %denotes input phase waiting for press or not

a = 1:length(sampDots);             %number of dots to be tested
vecInt = [a];                     %test all points twice
xyPair = vecInt; %randomize points order

%Start sampling loop
for ii = 1:length(xyPair)
    j = xyPair(ii);                 %which dot is being selected
    xy = sampDots(:,j);             %coordinates of selected dot
    
    while testphase == 0    % waiting for pen to touch down
        [x, y, buttons] = GetMouse(window);
        xy2 = [x;y;];
        Screen('DrawDots', window, sampDots, dotSizePix, [.75 .75 .75], [], 2);
        Screen('DrawDots', window, xy, dotSizePix, dotColor, [], 2); %target
        Screen('Flip', window);
        if buttons(1) && sum(abs(xy - xy2))<21 %if pen is touching tablet and within a 21pt radius of target
            testphase = 1;
            clear buttons x y
            %WINTABMEX TABLET POSITION COLLECTION
            %Set up a variable to store data
            pktData = [];           %will hold data from each iteration
            WinTabMex(2);           %Empties the packet queue in preparation for collecting actual data
            
            %This loop runs for trialLength seconds.
            start = GetSecs;        %start time in seconds
            stop  = start + trialLength;
            
            while GetSecs < stop
                Screen('DrawDots', window, sampDots, dotSizePix, [.75 .75 .75], [], 2);
                Screen('DrawDots', window, xy, dotSizePix,[1 0 0], [], 2); %red target
                Screen('Flip', window);
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
                pkt = [pkt; (GetSecs - start)]; %add timing column
                pktData = [pktData pkt];        %collect location data over time
                
                %Waits to end of deltaT if need be
                if GetSecs<(loopStart+deltaT)
                    WaitSecs('UntilTime', loopStart+deltaT);
                end
                
            end
            pktData2 = pktData';  %Assemble the data and then transpose to arrange data in columns because of Matlab memory preferences
            pktData2 = [pktData2 j*ones(length(pktData2),1)]; %add dot location
            
            %Error if tablet is not recording data. Restart matlab and
            %clear all prior to restart
            if sum(pktData2(:,1)) == 0
                instructions = 'Wacom not recording data! Restart Matlab!';
                [instructionsX, instructionsY] = centreText(window, instructions, 15);
                Screen('DrawText', window, instructions, instructionsX, instructionsY, white);
                Screen('Flip', window);
                testphase = 0;
                pause(.5)
                
                ShowCursor;
                error('Wacom not recording data! Restart Matlab!');
                break
            else
                wacData = [wacData; pktData2;]; %save location data for each point
            end
        else
            testphase = 0;  %continue to wait for accepted pen touch
        end
    end
    
    WinTabMex(3);                               % Stop/Pause data acquisition.
    
    %all grey dots on screen between targets
    Screen('DrawDots', window, sampDots, dotSizePix, [.75 .75 .75], [], 2);
    Screen('Flip', window);
    pause(.5)
    testphase = 0;
end
WinTabMex(1);
pause(1)