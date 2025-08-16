function VisualSearchTask()
% Treisman Visual Search Task - MATLAB/Psychtoolbox Implementation
% With: Subject ID prompt + Practice block (not saved)
% Requires Psychtoolbox 3.0.19.15 or compatible version
%
% Task: Find red triangle target among distractors
% Feature Search: Target differs by single feature (color or shape)
% Conjunction Search: Target requires combination of features
% Array sizes: 4, 8, 16, 32 items
% Responses: 'y' for present, 'n' for absent

try
    %% Setup and Configuration
    clc;
    fprintf('Initializing Visual Search Task...\n');

    % --- Ask for subject ID BEFORE opening a PTB window ---
    subID = '';
    while isempty(subID)
        subID = strtrim(input('Enter subject ID (e.g., ke1): ', 's'));
    end

    % Screen setup
    Screen('Preference', 'SkipSyncTests', 1); % Dev-only. Use 0 for real data.
    screens = Screen('Screens');
    screenNumber = max(screens);

    % Colors (RGB values 0-255)
    white = [255 255 255];
    black = [0 0 0];
    red   = [255 0   0];
    blue  = [0   0 255];
    gray  = [128 128 128];

    % Open window
    [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    [xCenter, yCenter] = RectCenter(windowRect);

    % Text setup
    Screen('TextFont', window, 'Arial');
    Screen('TextSize', window, 24);

    % Stimulus parameters
    stimSize = 40;              % Size of shapes in pixels
    minDistance = stimSize * 2; % Minimum distance between stimuli

    %% Trial Design (MAIN)
    presentAbsent = [1, 0];                       % 1 = present, 0 = absent
    searchTypes = {'feature', 'conjunction'};     % feature vs conjunction search
    arraySizes = [4, 8, 16, 32];                  % number of items in display
    nRepsPerCondition = 5;                        % repetitions per condition

    trials = [];
    trialNum = 1;
    for present = presentAbsent
        for searchIdx = 1:length(searchTypes)
            for arraySize = arraySizes
                for rep = 1:nRepsPerCondition
                    trials(trialNum).present   = present;
                    trials(trialNum).searchType= searchTypes{searchIdx};
                    trials(trialNum).arraySize = arraySize;
                    trials(trialNum).rep       = rep;
                    trialNum = trialNum + 1;
                end
            end
        end
    end

    % Randomize trial order
    trials = trials(randperm(length(trials)));
    nTrials = length(trials);

    fprintf('Total trials (main): %d\n', nTrials);

    %% Instructions
    ShowInstructions(window, xCenter, yCenter, white);

    %% Show Target Example
    ShowTargetExample(window, xCenter, yCenter, stimSize, red, white, black, true); % true => say 'Press SPACE to start PRACTICE'

    %% PRACTICE BLOCK (not saved)
    RunPracticeBlock(window, xCenter, yCenter, screenXpixels, screenYpixels, stimSize, minDistance, white, black, red, blue);

    % Transition to the real experiment
    Screen('FillRect', window, gray);
    DrawFormattedText(window, 'Practice complete!\n\nPress SPACE to start the real experiment', 'center', 'center', white);
    Screen('Flip', window); KbWait([], 2);

    %% MAIN EXPERIMENT LOOP
    results = struct();

    for trial = 1:nTrials
        targetStr = 'Absent';
        if trials(trial).present
            targetStr = 'Present';
        end
        fprintf('Trial %d/%d - %s search, Array size: %d, Target: %s\n', ...
            trial, nTrials, trials(trial).searchType, trials(trial).arraySize, targetStr);

        % Generate stimulus positions
        positions = GeneratePositions(trials(trial).arraySize, screenXpixels, screenYpixels, minDistance);

        % Generate stimuli for this trial
        stimuli = GenerateStimuli(trials(trial), positions);

        % Show fixation cross
        DrawFixation(window, xCenter, yCenter, white);
        Screen('Flip', window);
        WaitSecs(0.5);

        % Present search display and record response
        startTime = GetSecs;
        [response, RT] = PresentSearchDisplay(window, stimuli, stimSize, white, black, red, blue);

        % Record results
        results(trial).trial      = trial;
        results(trial).subID      = subID;
        results(trial).present    = trials(trial).present;
        results(trial).searchType = trials(trial).searchType;
        results(trial).arraySize  = trials(trial).arraySize;
        results(trial).response   = response;
        results(trial).RT         = RT;
        results(trial).correct    = (response == 'y' && trials(trial).present) || ...
                                    (response == 'n' && ~trials(trial).present);

        % Feedback        % (No feedback in main block)

        % ITI
        WaitSecs(0.5);

        % Break every 20 trials
        if mod(trial, 20) == 0 && trial < nTrials
            ShowBreak(window, xCenter, yCenter, white, trial, nTrials);
        end
    end

    %% Results Summary
    ShowResults(window, xCenter, yCenter, white, results);

    %% Save Results (with subID in file + column)
    SaveResults(results, subID);

    %% Cleanup
    Screen('CloseAll');
    fprintf('Experiment completed successfully!\n');

catch ME
    Screen('CloseAll');
    rethrow(ME);
end
end

function ShowInstructions(window, xCenter, yCenter, textColor)
    instructions = {
        'Visual Search Task'
        ''
        'You will see displays with shapes of different colors.'
        'Your task is to find the RED TRIANGLE target.'
        ''
        'Press Y if the red triangle is present'
        'Press N if the red triangle is absent'
        ''
        'Press ESC to quit at any time.'
        ''
        'Press SPACE to see the target example'
    };

    yOffset = -200;
    for i = 1:length(instructions)
        DrawFormattedText(window, instructions{i}, 'center', yCenter + yOffset + (i-1)*40, textColor);
    end
    Screen('Flip', window);

    KbWait([], 2); % Wait for key press
end

function ShowTargetExample(window, xCenter, yCenter, stimSize, red, white, black, forPractice)
    % If forPractice==true, show text to start PRACTICE; otherwise start experiment
    if nargin < 8 || isempty(forPractice), forPractice = false; end

    Screen('FillRect', window, [128 128 128]); % Gray background

    % Draw target example (red triangle)
    DrawTriangle(window, xCenter, yCenter, stimSize, red, black);

    DrawFormattedText(window, 'This is your TARGET: Red Triangle', 'center', yCenter - 100, white);
    if forPractice
        DrawFormattedText(window, 'Press SPACE to start PRACTICE', 'center', yCenter + 100, white);
    else
        DrawFormattedText(window, 'Press SPACE to start the experiment', 'center', yCenter + 100, white);
    end

    Screen('Flip', window);
    KbWait([], 2); % Wait for key press
end

function RunPracticeBlock(window, xCenter, yCenter, screenXpixels, screenYpixels, stimSize, minDistance, white, black, red, blue)
    % Define a smaller set of trials for practice (not saved)
    presentAbsent_prac = [1, 0];
    searchTypes_prac   = {'feature','conjunction'};
    arraySizes_prac    = [4, 8];
    reps_prac          = 2; % total practice trials = 2*2*2*2 = 16

    trialsP = [];
    t = 1;
    for present = presentAbsent_prac
        for s = 1:length(searchTypes_prac)
            for arr = arraySizes_prac
                for r = 1:reps_prac
                    trialsP(t).present    = present;
                    trialsP(t).searchType = searchTypes_prac{s};
                    trialsP(t).arraySize  = arr;
                    t = t + 1;
                end
            end
        end
    end
    trialsP = trialsP(randperm(length(trialsP)));

    % Intro message for practice
    Screen('FillRect', window, [128 128 128]);
    DrawFormattedText(window, ['Practice block:\n' ...
                               'Respond with Y (present) / N (absent).\n' ...
                               'Try to be fast and accurate.\n\n' ...
                               'Press SPACE to begin practice'], 'center', 'center', white);
    Screen('Flip', window); KbWait([],2);

    % Run practice trials (no saving)
    for i = 1:length(trialsP)
        % Positions
        positions = GeneratePositions(trialsP(i).arraySize, screenXpixels, screenYpixels, minDistance);
        % Stimuli
        stimuli   = GenerateStimuli(trialsP(i), positions);

        % Fixation
        DrawFixation(window, xCenter, yCenter, white);
        Screen('Flip', window); WaitSecs(0.5);

        % Present & respond
        [response, ~] = PresentSearchDisplay(window, stimuli, stimSize, white, black, red, blue);
        correct = (response == 'y' && trialsP(i).present) || (response == 'n' && ~trialsP(i).present);

        % Feedback
        ShowFeedback(window, xCenter, yCenter, correct, white, red);
        WaitSecs(0.4);
    end
end

function positions = GeneratePositions(arraySize, screenXpixels, screenYpixels, minDistance)
    % Generate random positions ensuring minimum distance between items
    margin = 100; % Margin from screen edges
    maxAttempts = 1000;

    positions = zeros(arraySize, 2);

    for i = 1:arraySize
        validPosition = false;
        attempts = 0;

        while ~validPosition && attempts < maxAttempts
            x = margin + rand() * (screenXpixels - 2*margin);
            y = margin + rand() * (screenYpixels - 2*margin);

            if i == 1
                validPosition = true;
            else
                % Check distance from all previous positions
                distances = sqrt(sum((positions(1:i-1, :) - [x, y]).^2, 2));
                if all(distances >= minDistance)
                    validPosition = true;
                end
            end

            attempts = attempts + 1;
        end

        if validPosition
            positions(i, :) = [x, y];
        else
            % Fallback: grid arrangement
            fprintf('Warning: Using grid fallback for position %d\n', i);
            gridSize = ceil(sqrt(arraySize));
            row = floor((i-1) / gridSize);
            col = mod(i-1, gridSize);
            if gridSize == 1
                x = screenXpixels/2; y = screenYpixels/2;
            else
                x = 100 + col * (screenXpixels - 200) / (gridSize - 1);
                y = 100 + row * (screenYpixels - 200) / (gridSize - 1);
            end
            positions(i, :) = [x, y];
        end
    end
end

function stimuli = GenerateStimuli(trial, positions)
    arraySize = trial.arraySize;
    present = trial.present;
    searchType = trial.searchType;

    stimuli = struct();

    if present
        % Target is present
        targetPos = randi(arraySize); % Random position for target
        stimuli(targetPos).shape = 'triangle';
        stimuli(targetPos).color = 'red';
        stimuli(targetPos).x = positions(targetPos, 1);
        stimuli(targetPos).y = positions(targetPos, 2);

        % Generate distractors
        for i = 1:arraySize
            if i ~= targetPos
                stimuli(i).x = positions(i, 1);
                stimuli(i).y = positions(i, 2);

                if strcmp(searchType, 'feature')
                    % Feature search: distractors differ by one feature
                    if rand() < 0.5
                        % Blue triangles
                        stimuli(i).shape = 'triangle';
                        stimuli(i).color = 'blue';
                    else
                        % Red squares
                        stimuli(i).shape = 'square';
                        stimuli(i).color = 'red';
                    end
                else
                    % Conjunction search: distractors share features with target
                    if rand() < 0.5
                        % Blue triangles (same shape, different color)
                        stimuli(i).shape = 'triangle';
                        stimuli(i).color = 'blue';
                    else
                        % Red squares (same color, different shape)
                        stimuli(i).shape = 'square';
                        stimuli(i).color = 'red';
                    end
                end
            end
        end
    else
        % Target is absent - generate all distractors
        for i = 1:arraySize
            stimuli(i).x = positions(i, 1);
            stimuli(i).y = positions(i, 2);

            if strcmp(searchType, 'feature')
                % Feature search: use distractors that differ by one feature
                if rand() < 0.5
                    stimuli(i).shape = 'triangle';
                    stimuli(i).color = 'blue';
                else
                    stimuli(i).shape = 'square';
                    stimuli(i).color = 'red';
                end
            else
                % Conjunction search: use blue triangles and red squares
                if rand() < 0.5
                    stimuli(i).shape = 'triangle';
                    stimuli(i).color = 'blue';
                else
                    stimuli(i).shape = 'square';
                    stimuli(i).color = 'red';
                end
            end
        end
    end
end

function [response, RT] = PresentSearchDisplay(window, stimuli, stimSize, white, black, red, blue)
    % Draw all stimuli
    Screen('FillRect', window, [128 128 128]); % Gray background

    for i = 1:length(stimuli)
        x = stimuli(i).x;
        y = stimuli(i).y;

        % Set color
        if strcmp(stimuli(i).color, 'red')
            fillColor = red;
        else
            fillColor = blue;
        end

        % Draw shape
        if strcmp(stimuli(i).shape, 'triangle')
            DrawTriangle(window, x, y, stimSize, fillColor, black);
        else
            DrawSquare(window, x, y, stimSize, fillColor, black);
        end
    end

    % Show display
    Screen('Flip', window);
    startTime = GetSecs;

    % Wait for response
    response = '';
    while isempty(response)
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(KbName('y'))
                response = 'y';
            elseif keyCode(KbName('n'))
                response = 'n';
            elseif keyCode(KbName('ESCAPE'))
                error('Experiment terminated by user');
            else
                % Ignore all other keys
            end
        end
    end

    RT = GetSecs - startTime;
end

function DrawTriangle(window, x, y, sz, fillColor, lineColor)
    % Draw filled triangle (equilateral, pointing up)
    halfSize = sz / 2;
    trianglePoints = [
        x,           y - halfSize;   % Top
        x - halfSize, y + halfSize;  % Bottom-left
        x + halfSize, y + halfSize   % Bottom-right
    ]; % n x 2

    Screen('FillPoly',  window, fillColor, trianglePoints, 1); % isConvex=1
    Screen('FramePoly', window, lineColor, trianglePoints, 2);
end

function DrawSquare(window, x, y, sz, fillColor, lineColor)
    % Draw filled square
    halfSize = sz / 2;
    rect = [x - halfSize, y - halfSize, x + halfSize, y + halfSize];

    Screen('FillRect',  window, fillColor, rect);
    Screen('FrameRect', window, lineColor, rect, 2);
end

function DrawFixation(window, x, y, color)
    fixSize = 20;
    fixLines = [-fixSize, fixSize, 0, 0; 0, 0, -fixSize, fixSize];
    Screen('DrawLines', window, fixLines, 2, color, [x, y]);
end

function ShowFeedback(window, xCenter, yCenter, correct, textColor, errorColor)
    Screen('FillRect', window, [128 128 128]);

    if correct
        DrawFormattedText(window, 'Correct!', 'center', yCenter, textColor);
    else
        DrawFormattedText(window, 'Incorrect', 'center', yCenter, errorColor);
    end

    Screen('Flip', window);
    WaitSecs(0.5);
end

function ShowBreak(window, xCenter, yCenter, textColor, currentTrial, totalTrials)
    Screen('FillRect', window, [128 128 128]);

    breakText = {
        sprintf('Break - Trial %d of %d completed', currentTrial, totalTrials)
        ''
        'Take a short rest'
        'Press SPACE to continue'
    };

    yOffset = -50;
    for i = 1:length(breakText)
        DrawFormattedText(window, breakText{i}, 'center', yCenter + yOffset + (i-1)*40, textColor);
    end

    Screen('Flip', window);
    KbWait([], 2);
end

function ShowResults(window, xCenter, yCenter, textColor, results)
    % Calculate summary statistics
    featureTrials = strcmp({results.searchType}, 'feature');
    conjunctionTrials = strcmp({results.searchType}, 'conjunction');

    featureAcc = mean([results(featureTrials).correct]) * 100;
    conjunctionAcc = mean([results(conjunctionTrials).correct]) * 100;

    featureRT = mean([results(featureTrials & [results.correct]).RT]) * 1000;
    conjunctionRT = mean([results(conjunctionTrials & [results.correct]).RT]) * 1000;

    Screen('FillRect', window, [128 128 128]);

    resultText = {
        'Experiment Complete!'
        ''
        sprintf('Feature Search: %.1f%% accurate, %.0f ms', featureAcc, featureRT)
        sprintf('Conjunction Search: %.1f%% accurate, %.0f ms', conjunctionAcc, conjunctionRT)
        ''
        'Results saved to file'
        'Press SPACE to exit'
    };

    yOffset = -100;
    for i = 1:length(resultText)
        DrawFormattedText(window, resultText{i}, 'center', yCenter + yOffset + (i-1)*40, textColor);
    end

    Screen('Flip', window);
    KbWait([], 2);
end

function SaveResults(results, subID)
    % Save results to CSV file, including subject ID in filename and as a column
    ts = datestr(now, 'yyyymmdd_HHMMSS');
    filename = sprintf('visual_search_results_%s_%s.csv', subID, ts);

    % Open file for writing
    fid = fopen(filename, 'w');

    % Write header
    fprintf(fid, 'trial,subID,present,searchType,arraySize,response,RT,correct\n');

    % Write data
    for i = 1:length(results)
        fprintf(fid, '%d,%s,%d,%s,%d,%s,%.3f,%d\n', ...
            results(i).trial, ...
            subID, ...
            results(i).present, ...
            results(i).searchType, ...
            results(i).arraySize, ...
            results(i).response, ...
            results(i).RT, ...
            results(i).correct);
    end

    fclose(fid);
    fprintf('Results saved to: %s\n', filename);
end
