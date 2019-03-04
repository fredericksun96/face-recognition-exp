% face recognition experiment
% study a series of faces; some upside down, some right side up (half-half)
% tested on old faces
% ASSUMING THIS IS DONE FROM THE SAME FOLDER THAT THE FACES ARE IN. !!!!1
% !!!!!! SEE ABOVE!!!!!!1
% !!!!!!!!!!!!!!!!!!!!!!!!1
% !!!!!!!!!!!!!!!!!!!!!!!!
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

savename = ['faceRecog' subjInfo.ID '.mat'];

%% load in faces
% this is assuming that we are in the faces directory that has the faces

faces = dir('*.jpg');
nFaces = length(faces);


% randomize order of faces for study
randOrder1 = randperm(nFaces);
faces_rand = faces(randOrder1);
faces1 = faces_rand(1:10); % make a set of faces that will be shown in the first condition only
isStudied = randOrder1(1:10); % this matrix has the indicies of the pictures that were shown from faces.
% will be used later in recognition trials

facecells2 = cell(1,20);
randOrder2 = randperm(nFaces);   %RANDOMIZE AGAIN! This will be the order shown in the recognition part.
faces_rand2 = faces(randOrder2);


for ii = 1:length(faces_rand)
  facecells2{ii} = imread(faces_rand2(ii).name);
end



% as of this moment, the faces that will be displayed during the actual recognition task will just be 
% in the order that the faces structure will be in. 

% make a cell array of faces1
facecells = cell(1,10);
for ii = 1:length(faces1)
  facecells{ii} = imread(faces1(ii).name);
end


% either flipepd or no
flips = [1 ; 2];
nFlips = length(flips);
% a new condition because it's just one variable changed--either flipped or not 
% I'M ASSUMING WE DON'T NEED TO RANDOMIZE SPEEDS LIKE THE ORIGINAL ASSIGNMENT. 
conds = repmat(flips, length(faces1)/nFlips,1);
conds = conds(randperm(length(faces1)),:);

%conds = fullfact([2 ,nFlips]);
%nConds = length(conds);
%conds = repmat(conds,nFaces/nConds,1);

% create arrays for storing experiment data
nRecogTrials = length(faces);
resp = nan(1,nRecogTrials);
acc = nan(1,nRecogTrials);
RT = zeros(1,nRecogTrials);

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
    if conds(ii)== 2 % if conds is 2, then we'll flip the image.
      Screen('PutImage', win, flipud(facecells{ii}), [cx-100 cy-100 cx+100 cy+100]);
      Screen('Flip', win);
      WaitSecs(2);
    else 
      Screen('PutImage', win, facecells{ii}, [cx-100 cy-100 cx+100 cy+100]);
      Screen('Flip', win);
      WaitSecs(2);
      
    end  
   
end

%% distractor task
% I guess I'll just leave this here. 
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
% show instructions. Too lazy to import the whole thing. 
% for some reason, PTB doesn't display this correctly. Dunno why might just be my computer 
 DrawFormattedText(win,['You are now going to see the words that you just'...
     ' studied as well as some new words. Your goal is to say whether you'...
     ' saw the word before or not. Press Y if you recognize the word; press' ...
     ' N if you do not. Press any key to start when you are ready.'],...
     'center','center',white);
Screen('Flip',win);
KbStrokeWait; 


% show the words
for ii = 1:length(facecells2)%nRecogTrials
    % draw the words
    Screen('PutImage', win, facecells2{ii}, [cx-100 cy-100 cx+100 cy+100]);
    Screen('Flip',win);  
    
    validKey = false;
    trialStartTime = GetSecs;
    while ~validKey 
        % get keypress
        [secs, keyCode, deltaSecs] = KbStrokeWait;
        keyPressed = KbName(keyCode);
    
        % record what key was pressed
        if strcmpi(keyPressed,'y')
            resp(ii) = 1;
            validKey = true;
        elseif strcmpi(keyPressed,'n')
            resp(ii) = 0;
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
    

     if resp(ii) == 1 && ismember(randOrder2(ii), isStudied) 
       % if the answer was yes, we studied before, and the index
       % of randOrder2, which was the order that the recognition trials were done in,
       % is part of isStudied, then we give acc(ii) = 1, for is accurate. vice versa below 
         acc(ii) = 1;
     elseif resp(ii) == 0 && ~ismember(randOrder2(ii),isStudied)
       acc(ii) = 1;
     else
       acc(ii) = 0;
     end
    
    % RESPONSE TIME 
    RT(ii) = secs - trialStartTime;
    save(savename,'subjInfo','faces1','isStudied','faces_rand','resp','acc','RT', 'randOrder2')
    % The reason I chose to do these variables is because:
%    subjInfo - yeah
%    faces1 - this is the structure that has the 10 first studied words.
%    isStudied - this is the array that has the indices of the studied words FROM faces_rand!
%    faces_rand - this is the randomized order of cell array of all the faces.
%    resp - The responses of participant 
%    acc - accuracy of said responses
%    RT - response time
%    randOrder2 - so the way I checked to make sure my code was working correctly was these three lines:
%    ismember(randOrder2, isStudied);
%    resp;
%    acc; 
%    At the indices where ismember(randOrder2, isStudied) is equal to resp, acc should be 1. 
    

end % over words / trials

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





