function [exp,fSaveFile,tSaveFile,restart] = expDataSetup(expName,subject,session,condLabel,restartYN)
% EXPDATASETUP keeps all experiment data stored in a fixed format by
% creating the necessary folders and subfolders, creating standardised
% filenames, and saving important data about the current run of the
% experiment.
%
% [EXP,FSAVEFILE,TSAVEFILE] = expDataSetup(EXPNAME,SUBJECT,SESSION,RESTARTYN)
%
% -- INPUTS --
% EXNAME: String identifier of particular experiment.
% SUBJECT: Initials of subject. If empty, user will be prompted to enter initials.
% SESSION: Session number. If empty, user will be prompted to enter session number.
% CONDLABEL: Condition label, if not defined by session number or is different from session number.
% RESTARTYN: If restarting exp, 1, otherwise 0.
%
% -- OUTPUTS --
% EXP: Structure storing important data about the exp.
% FSAVEFILE: Final save file name.
% TSAVEFILE: Temporary save file name.
% RESTART: Contains the file name to be loaded and the trial number for the experiment restart.
%
% Created by SML Nov 2014. Edited Jan 2015.


% Folder for storing data:
dataPath = ['data_', expName];
if ~isdir(dataPath)
    mkdir(dataPath);
end
disp(['Experiment data will be saved to: ' dataPath])

kSpaceBar = KbName('space');

% New session or starting from crash?:
if restartYN == false
    
    % --- Create new session --- %
    
    disp('Existing subject data directories: ')
    ls(dataPath)
    
    % Input subject initals:
    if isempty(subject)
        subject = upper(input('Please enter initials of subject: ','s'));
        if isempty(subject)
            subject = 'Test';
            disp('No subject entered. Data will be saved under Test.')
        end
    end
    
    % Find/create folder for subject and entry in subject log:
    dataSavePath = [dataPath filesep subject];
    if ~isdir(dataSavePath)
        mkdir(dataSavePath)
    end
    
    % Show the previous save files:
    disp('Previously saved files for selected subject: ')
    ls(dataSavePath)
    
    % Input session number:
    if isempty(session)
        session = upper(input('Please enter the session number: '));
        if isempty(session)
            session = 0;
            disp('No session number entered. Session number will be set to 0.')
        end
    end
    
    % Dummy restart variable:
    restart = [];
    
elseif restartYN == true
    
    % --- Select and load restart file ---- %
    
    filePickYN = 0;
    while filePickYN == 0
        [restartFile, restartPath] = uigetfile('*.mat', 'Pick the temp file to restart from');
        disp(['You have selected: ' restartFile])
%         disp('Press SPACE BAR to accept, or press any other key to select another file.')
%         [~,kPress] = KbWait([],2);
%         if kPress == kSpaceBar
%             filePickYN = 1;
%         end
        filePickYN = 1;
    end
    
    restart.filename = [restartPath restartFile];
    load(restart.filename)
    restart.nextTrial = nn+1;
    dataSavePath = [dataPath filesep subject];
    
else
    error('Incorrect input for restartYN. Enter 0 or 1.')
end

% --- Generate file names --- %

cSes = ['S' num2str(session)]; % Session identifier
tStamp = getTimeStamp; % Time and date info

% Final file name:
fSaveFile = [subject '_' expName '_' condLabel '_' cSes '_' tStamp]; % File name
fSaveFile = [dataSavePath filesep fSaveFile]; % with directory

% Temp file name
tSaveFile = ['Temp_' subject '_' expName '_' condLabel '_' cSes '_' tStamp]; % File name
tSaveFile = [dataSavePath filesep tSaveFile]; % with directory

% Store experiment details to be saved alongside data:
exp.info.name = expName;
exp.info.subject = subject;
exp.info.session = session;
if restartYN == false;
    exp.info.startTime = tStamp;
    exp.info.restart = 0;
else
%     exp.info.time = [exp.startTime; tStamp];
%     exp.info.restart = exp.restart + 1;
end

end