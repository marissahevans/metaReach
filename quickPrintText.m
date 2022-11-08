function [] = quickPrintText(win,txt,loc,FS,colTxt,colBG,pauseYN,dispDur)
% QUICKPRINTTEXT a shorthand for getting text to display on a screen. Uses
% the psychtoolbox commands. The default is pauseYN=1, dispDur=0.
%
% [] = quickPrintText(WIN,TXT,LOC,FS,COLTXT,COLBG,PAUSEYN,DISPDUR)
%
% WIN: screen ID.
% TXT: The string of text to be printed.
% LOC: location of text as a string (e.g. 'center')
% FS: Font size of text.
% COLTXT: colour of text. Either single value for greyscale, or RGB for
%         colour.
% COLBG: Colour of the background. Either single value for greyscale, or
%        RGB for colour.
% PAUSEYN: Wait for key press to continue before clear screen of text.
% DISPDUR: Wait for a specified amount of time (in seconds) before clearing
%          screen of text. Note that you can use both PAUSEYN and DISPDUR in
%          combination to wait for keypress and then wait for a specified 
%          amount of time. If the dispDur input is an empty vector, the
%          text will not be cleared from the screen by this script.
%
% Created by SML July 2015
% Updated by SML Feb 2017: added option to leave text on the screen.

% Defaults
if nargin < 8
    dispDur = 0;
    if nargin < 7
        pauseYN = 1;
        if nargin < 6;
            colBG = [127 127 127]; % midgrey
            if nargin < 5
                colTxt = [255 255 255];
                if nargin < 4
                    FS = 18;
                    if nargin < 3
                        loc = 'center';
                    end
                end
            end
        end
    end
end

% Completion if empty:
if isempty(loc); loc = 'center'; end
if isempty(FS); FS = 18; end
if isempty(colTxt); colTxt = [255 255 255]; end
if isempty(colBG); colBG = [127 127 127]; end

% Check inputs:
assert((length(colBG)==1)||(length(colBG)==3),'Check that the colBG input is 1 or 3 valued.')
if length(colBG) == 1
    colBG = repmat(colBG,1,3);
end

% Print text to screen:
Screen('TextSize',win, FS);
Screen('FillRect', win, colBG);
DrawFormattedText(win, txt, loc, loc, colTxt);
Screen('Flip', win);

% Pause until keypress or for specified time:
if pauseYN == 1
    pause;
end
if dispDur ~= 0
    WaitSecs(dispDur);
end

% Clear screen:
if ~isempty(dispDur)
    Screen('FillRect', win, colBG); % Clear Screen
    Screen('Flip', win);
end

end