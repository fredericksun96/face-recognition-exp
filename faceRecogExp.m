% face recognition experiment
% study a series of faces; some upside down, some right side up (half-half)
% tested on old faces

%% setup
clear; close all;
AssertOpenGL;
KbName('UnifyKeyNames');
rand('seed',sum(clock*100)); % for octave
Screen('Preference', 'SkipSyncTests', 1);
exitNow = false;

%% define some colors
% colors
black = [0 0 0];
white = [255 255 255];
red = [255 0 0];
green = [0 255 0];
blue = [0 0 255];
gray = [128 128 128];

%% get subject information
x = inputdlg({'Participant ID:','Gender:','Age:','Hours of Sleep:','Alterness:'});
subjInfo.ID = x{1};
subjInfo.Gender = x{2};
subjInfo.Age = str2double(x{3});
subjInfo.Sleep = str2double(x{4});
subjInfo.Alert = str2double(x{5});

savename = ['wordRecog_' subjInfo.ID '.mat'];

%% load in faces
% this is assuming that we are in the faces directory that has the faces

faces = dir('*.jpg');
nFaces = length(faces);


% randomize order of faces for study
randOrder = randperm(nFaces);
faces_rand = faces(randOrder);
faces1 = faces(1:10); % make a set of faces that will be shown in the first condition only
% as of this moment, the faces that will be displayed during the actual recognition task will just be 
% in the order that the faces structure will be in. 

% make a cell array of faces1
facecells = cell(1,10);
for ii = 1:length(faces1)
  facecells{ii} = imread(faces1(ii).name);
end


% load in the lure list
% lureWords = importdata('lureList.txt');
% nLureWords = length(lureWords);

% combine with the word lists
% allWords = [words ; lureWords];

% get total number of words
% nAllWords = numel(allWords);

% randomize the order of the words
%randOrder = randperm(nAllWords);
%allWords_rand = allWords(randOrder);

% add some conditions! different colors:
% 1 - white
% 2 - red
% 3 - blue
%colors = {white, red, blue};
%nColors = length(colors);

% either flipepd or no
flips = [1 ; 2];
nFlips = length(flips);
% a new condition because it's just one variable changed--either flipped or not 
conds = repmat(flips, length(faces1)/nFlips,1);
conds = conds(randperm(length(faces1)),:);

%conds = fullfact([2 ,nFlips]);
%nConds = length(conds);
%conds = repmat(conds,nFaces/nConds,1);

% create arrays for storing experiment data
nRecogTrials = length(faces);
resp = nan(1,nRecogTrials);
acc = nan(1,nRecogTrials);
RT = nan(1,nRecogTrials);

%% load in instructions
%recogInst = importdata('recogInst.txt');

%% experiment
try
%% open a window
%scrNum = max(Screen('Screens'));
[win, screenRect] = Screen('OpenWindow',0,black);
[width, height] = RectSize(screenRect);
[cx, cy] = RectCenter(screenRect);
Screen('TextSize',win,36);
HideCursor;
ListenChar(2);
Priority(MaxPriority(win));
Screen('Flip',win);

% show some instructions

%% display the words
for ii = 1:length(faces1)
    % from conditions matrix: read out color of word:
    
    
    % draw the words
    Screen('PutImage', win, facecells{ii}, [cx-100 cy-100 cx+100 cy+100]);
    Screen('Flip',win);  
    WaitSecs(2);
end

%% distractor task
#{
answer = 0;
num1 = randi(20);
num2 = randi(20);
correct_answer = num1+num2;
while answer ~= correct_answer
    answer = GetEchoNumber(win,...
        [num2str(num1) ' + ' num2str(num2) ' = '],...
        cx,cy,white,black);
    Screen('Flip',win);
end


%% recognition task
% show instructions 
% DrawFormattedText(win,['You are now going to see the words that you just'...
%     ' studied as well as some new words. Your goal is to say whether you'...
%     ' saw the word before or not. Press Y if you recognize the word; press' ...
%     ' N if you do not. Press any key to start when you are ready.'],...
%     'center','center',white);
DrawFormattedText(win,recogInst{1},'center','center',white,50);
Screen('Flip',win);
KbStrokeWait; 
% KbWait; KbReleaseWait;

% show the words
for w = 1:1%nRecogTrials
    % draw the words
    DrawFormattedText(win,upper(allWords_rand{w}),'center','center',white);
    Screen('Flip',win);  
    
    validKey = false;
    %noGoodKey = true;
    trialStartTime = GetSecs;
    while ~validKey % noGoodKey
        % get keypress
        [secs, keyCode, deltaSecs] = KbStrokeWait;
        keyPressed = KbName(keyCode);
    
        % record what key was pressed
        if strcmpi(keyPressed,'y')
            resp(w) = 1;
            %noGoodKey = false;
            validKey = true;
        elseif strcmpi(keyPressed,'n')
            resp(w) = 0;
            validKey = true;
        elseif strcmpi(keyPressed,'escape')
            validKey = true;
            exitNow = true;
        end
    end

    % if exit key pressed, stop the trials
    if exitNow 
        break;
    end
    
    % compute accuracy:
    % was the test word a studied word?
    isStudied = any(strcmpi(words,allWords_rand{w}));
    acc(w) = isStudied == resp(w);
    % compute response time
    RT(w) = secs - trialStartTime;
    
    save(savename,'subjInfo','words','lureWords','allWords_rand','resp','acc','RT')
    

end % over words / trials
#}
% close a window
ListenChar(0);
Priority(0);
ShowCursor;
sca; % Screen('CloseAll');
catch
    ListenChar(0);
    Priority(0);
    ShowCursor;
    sca;
    psychrethrow(psychlasterror);
end





