function [p]=hierarchical_decisions_task(subject, session, run, rule_hierarchical_decision, coloured_task)
% subject = subject code (string)
% session = session number: 1 and 2 outside scanner; 3 and 4 inside scanner
% run = up to 5 runs per session - ~10min per run
% rule_hierarchical_decision = 0 or 1
% coloured_task = 0 (grey samples) or 1 (coloured samples according to source)
% press 'q' on choice trials to quit
NoEyelink = 1; %is Eyelink wanted?
debug   = 0; % debug mode => 1: transparent window enabling viewing the background.
small_window = 0; % Open a small window only

%% >>>>> Set up a lot of stuff
% Load stimulus sequence
load_dir = [pwd '\exp_data' filesep subject];
load([load_dir filesep 'task_sequences']);

if subject > 0
    sequence = task_sequences{session}{run};
    fmri = sequence.fmri; % if false skip waiting for pulses.
end

commandwindow; %focus on the command window, so that output is not written on the editor
% %clear everything
% clear mex global functions;%clear all before we start.

GetSecs;
WaitSecs(0.001);

el        = []; % eye-tracker variable
p         = []; % parameter structure that contains all info about the experiment.

SetParams;%set parameters of the experiment
SetPTB;%set visualization parameters.


% check how many choice stimulus of each type for this run
number_face_stim = length(find(sequence.stim == 0));
number_house_stim = length(find(sequence.stim == 1));
Files = dir(fullfile([p.images_dir '\selected_faces_adults_similar_lum'],'*.jpg'));
file_order_faces = randperm(size(Files, 1)); 
p.choice_trials.file_order_faces = file_order_faces(1:number_face_stim);
for numb_files=1:number_face_stim
    p.choice_trials.file_names_faces{numb_files, 1} = fullfile(Files(file_order_faces(numb_files)).folder, Files(file_order_faces(numb_files)).name);
end
Files = dir(fullfile([p.images_dir '\selected_houses_similar_lum'] ,'*.jpg'));
file_order_houses = randperm(size(Files, 1));
p.choice_trials.file_order_houses = file_order_houses(1:number_house_stim);
for numb_files=1:number_house_stim
    p.choice_trials.file_names_houses{numb_files, 1} = fullfile(Files(file_order_faces(numb_files)).folder, Files(file_order_houses(numb_files)).name);
end

p.rule_hierarchical_decision = rule_hierarchical_decision; % to counterbalance across participants which rule in first run, can be 0 or 1
p.session = session; p.run = run;
p.subject = subject;

% calibrated = false;

%% >>>>>>> Experiment starts.
%try

    for block = run
        fprintf(['Running SUB=' subject, ' Run=' num2str(block) '\n']);
        p.block = block;
        p.sequence = sequence;
        if fmri == 0
            KbQueueStop(p.ptb.device);
            KbQueueRelease(p.ptb.device);
        else
            IOPort('Flush',p.LuminaHandle); 
        end

        text = ['Durante a tarefa, mantenha o olhar fixo na figura central,\n'...
                'mantenha a cabeça fixa no apoio e não fale.\n\n'...
                'Carregue numa tecla para avançar.\n'];
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        Screen('Flip', p.ptb.w);
        if fmri == 0
            [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
            key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end
        else
            IOPort('Read',p.LuminaHandle, 1, 1); %IOPort(‘Read’, handle [, blocking=0] [, amount]);
            pr = 1;
            while pr
                key = IOPort('Read',response_box_handle);
                if ~isempty(key) %&& (length(key) == 1)
                    pr = 0;
                end
                IOPort('Flush',response_box_handle);
            end
        end
                        
        p = InitEyeLink(p);
        CalibrateEL;
        
        rule_explained(p, rule_hierarchical_decision) % show image with rule
        if fmri == 0
            [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
            key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end
        else
            pr = 1;
            while pr
                key = IOPort('Read',response_box_handle);
                if ~isempty(key) %&& (length(key) == 1)
                    pr = 0;
                end
                IOPort('Flush',response_box_handle);
            end
        end
        
         if p.syncboxEnabled %Catarina defined waiting MRI 
            Screen('FillRect', p.ptb.w, p.stim.bg );
            DrawFormattedText(p.ptb.w, 'Waiting MRI to start...', 'center', 'center', p.stim.white,[],[],[],2,[]);
            Screen('Flip',p.ptb.w);

            SynchBox = IOPort('OpenSerialPort', 'COM2', 'BaudRate=57600 DataBits=8 Parity=None StopBits=1 FlowControl=None');
            IOPort('Flush',SynchBox);
            [TriggerReceived, StartTime]=waitForTrigger(SynchBox,1,1000); %

            if ~ TriggerReceived
                disp('Did not receive trigger - aborting stim');
                sca; return
            end
         end
        
        draw_fix(p); %Screen('Flip',p.ptb.w);  
        %WaitSecs(12); % baseline?
        [p, outcomes] = GlazeBlock(p,coloured_task);
        
    end
    p = dump_keys(p);
    WaitSecs(10);
    fprintf('\n This block of trials lasted %3.2fs\n', GetSecs()-p.start_trials);

    % Need to show feedback here!
    p.sum_outcomes = sum(outcomes);
    p.accuracy_rate = p.sum_outcomes/length(outcomes);
    text = sprintf('No último bloco acertou %2.0f%% das respostas.\n', 100*p.accuracy_rate);
    Screen('FillRect', p.ptb.w, p.stim.bg);
    DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
    Screen('Flip',p.ptb.w);
    KbWait(p.ptb.device, 2, GetSecs()+15);
    p = save_data(p);
    %stop the queue
    if fmri == 0
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
    end

    cleanup(p);
    % lasterr

    %% -----------------------------------
    %  Experiment blocks
    %  -----------------------------------

    function [p, outcomes] = GlazeBlock(p, coloured_task)
        % 4.8 Check data save
%         abort=false;
        p.start_time = datestr(now, 'dd-mmm-yyTHHMM'); %p.start_time = datestr(now, 'dd-mmm-yy-HH:MM:SS');

        Screen('FillRect',p.ptb.w,p.stim.bg);
        Screen('Flip',p.ptb.w);
        
        if fmri == 0
            KbQueueStop(p.ptb.device);
            KbQueueRelease(p.ptb.device);
            KbQueueCreate(p.ptb.device);
            KbQueueStart(p.ptb.device);
            KbQueueFlush(p.ptb.device);
        else
            IOPort('Flush',p.LuminaHandle);
        end
        
        Screen('Flip', p.ptb.w);
        Eyelink('StartRecording');
        WaitSecs(.01);
        Eyelink('Message', ['SUBJECT ', p.subject]);
        p = Log(p, GetSecs, 'START_GLAZE', nan);
        p = Log(p, GetSecs, 'SUBJECT', p.subject);
        
        
        draw_fix(p);
        WaitSecs(1);

%         StartGlazeEyelinkRecording(p.block, p.phase_variable);
        outcomes = []; % response accuracy
        p.start_trials = GetSecs();
%         start = start_trials+0.4;
        ActSampleOnset = GetSecs;
        count_faces = 0; count_houses = 0; % to determine which image to show
        for trial  = 1:size(p.sequence.stim, 2)
            %Get the variables that Trial function needs.
            stim_id       = p.sequence.stim(trial);
            type          = p.sequence.type(trial);
            location      = p.sequence.sample(trial);
            gener_side    = p.sequence.generating_side(trial);
%             OnsetTime     = start+p.sequence.stimulus_onset(trial);
            OnsetTime     = ActSampleOnset + 0.4; % ISI = 400 ms
%             if location < 0
%                 fprintf('-');
%             else
%                 fprintf('+');
%             end
            Eyelink('Message', 'trial_id %i', trial);
            
            p = Log(p, GetSecs, 'GL_TRIAL_START', trial);
            if ~isnan(stim_id)
                p = Log(p, GetSecs, 'GL_TRIAL_STIM_ID', stim_id);
                Eyelink('Message', 'stim_id %i', stim_id);
            end
            if ~isnan(gener_side)
                p = Log(p, GetSecs, 'GL_TRIAL_GENSIDE', gener_side);
                Eyelink('Message', 'gener_side %i', round(100*gener_side)); 
            end
            if ~isnan(location)
                Eyelink('Message', 'location %d', round(1000*location)); 
                p = Log(p, GetSecs, 'GL_TRIAL_LOCATION', location);
            end
            p = Log(p, GetSecs, 'GL_TRIAL_TYPE', type);
            Eyelink('Message', 'type %i', type);

            if type == 0
                % Show a single sample
                [ActSampleOnset, p] = show_one_sample(p, OnsetTime, location, gener_side, coloured_task);
            elseif type == 1
                % Choice trial.
                if stim_id == 0
                    count_faces = count_faces+1;
                    theImageLocation = p.choice_trials.file_names_faces{count_faces};
                elseif stim_id == 1
                    count_houses = count_houses+1;
                    theImageLocation = p.choice_trials.file_names_houses{count_houses};
                end
                fprintf('\nCHOICE TRIAL; stim_id:%i, gener_side:%02.2f ', stim_id, gener_side>0);
                [p, ~, keycodes, response_times, abort] = choice_trial(p, OnsetTime, stim_id, theImageLocation);
                if abort==1, return, end
                % analysis accuracy of responses
                correct = 0;
                if ~isnan(keycodes)
                    for iii = 1:length(keycodes)
                        RT = response_times(iii);
                        keys = KbName(keycodes(iii));
                        p = Log(p, RT, 'BUTTON_PRESS', keys); % save info for all responses so we know if it was corrected
                        if iii == length(keycodes) % what counts for accuracy is last response
                            if gener_side > 0 && stim_id == 0 % bottom and faces
                                if p.rule_hierarchical_decision == 0 && strcmp(keys, 'm')
                                    correct = correct+1;
                                elseif p.rule_hierarchical_decision == 1 && strcmp(keys, 'z')
                                    correct = correct+1;
                                end
                            elseif gener_side >0 && stim_id ==1 % bottom and houses 
                                if p.rule_hierarchical_decision == 0 && strcmp(keys, 'z')
                                    correct = correct+1;
                                elseif p.rule_hierarchical_decision == 1 && strcmp(keys, 'm')
                                    correct = correct+1;
                                end
                            elseif gener_side <0 && stim_id ==0 % top and faces
                                if p.rule_hierarchical_decision == 0 && strcmp(keys, 'z')
                                    correct = correct+1;
                                elseif p.rule_hierarchical_decision == 1 && strcmp(keys, 'm')
                                    correct = correct+1;
                                end
                            elseif gener_side < 0 && stim_id == 1 % top and houses
                                if p.rule_hierarchical_decision == 0 && strcmp(keys, 'm')
                                    correct = correct+1;
                                elseif p.rule_hierarchical_decision == 1 && strcmp(keys, 'z')
                                    correct = correct+1;
                                end
                            end
                        end

                    end
                else
                    p = Log(p, stim_id, 'NO_RESPONSE', NaN);
                end
                p = Log(p, stim_id, 'CHOICE_TRIAL_ACCURACY', correct);
                fprintf('ACCURACY: %i, ', correct);  
                if correct == 1
                    outcomes = [outcomes 1]; %#ok<AGROW>
                    fprintf('REWARD!\n');
                else
                    outcomes = [outcomes 0]; %#ok<AGROW>
                    fprintf('NO REWARD!\n')
                end
                ActSampleOnset = GetSecs-0.4; % so that next sample starts on time!
            end

        end
    end


    %% -----------------------------------
    %  Trial functions
    %  -----------------------------------

    function [p, RT, keycodes, response_times, abort] = choice_trial(p, ChoiceStimOnset, stim_id, theImageLocation)
%         rule = nan;
        response = nan; %#ok<NASGU>
        RT = nan; %#ok<NASGU>
        abort = 0;
        
        % load image of face or house - face - stim_id = 0; house - stim_id = 1 
        % Here we load in an image from file.
        theImage = imread(theImageLocation);
        %    Make the image into a texture
        imageTexture = Screen('MakeTexture', p.ptb.w, theImage);
        % Draw the gaussian apertures  into our full screen aperture mask
        Screen('DrawTextures', p.gaussian_aperture.fullWindowMask, p.gaussian_aperture.masktex, [], p.gaussian_aperture.dstRects);

        % Draw the image to the screen
        % left, top, right, bottom - size of image in pixels [0,0] = top left
        % corner
        NewImageRect = [0 0 300 300];
        NewImageRect_centered = CenterRectOnPointd(NewImageRect, p.ptb.width / 2, p.ptb.height / 2);
        Screen('DrawTexture', p.ptb.w, imageTexture, [], NewImageRect_centered, 0);
        Screen('DrawTexture', p.ptb.w, p.gaussian_aperture.fullWindowMask);

        % Flush key events
        if fmri == 0
            p = dump_keys(p);
            KbQueueFlush(p.ptb.device);        
        elseif fmri == 1   
            IOPort('Flush',p.LuminaHandle); %cat% 
        end
        
        % Flip to the screen
        % STIMULUS ONSET
        TimeStimOnset  = Screen('Flip', p.ptb.w, ChoiceStimOnset, 0);    
        start_rt_counter  = TimeStimOnset;
        p = Log(p,TimeStimOnset, 'CHOICE_TRIAL_ONSET', stim_id);
        Eyelink('Message', sprintf('CHOICE_TRIAL_ONSET %i', stim_id));
        draw_fix(p);
        if fmri == 1
            while GetSecs<TimeStimOnset+ 0.2-p.ptb.slack
                % listen to button presses      
                [key,timestamp,~] = IOPort('Read',p.LuminaHandle);
                if ~isempty(key)
                    IOPort('Flush',p.LuminaHandle);
                    % Save responses 
                    keys_pressed = [keys_pressed; key];
                    times_pressed = [times_pressed; timestamp];
                end
            end
        end
        
        TimeStimOffset  = Screen('Flip', p.ptb.w, TimeStimOnset+ 0.2 -p.ptb.slack, 0);  %<----- FLIP                    
        p = Log(p,TimeStimOffset, 'CHOICE_TRIAL_STIMOFF', nan);
        Eyelink('Message', 'CHOICE_TRIAL_STIMOFF');
        if fmri == 1
            while GetSecs<TimeStimOffset+1.8
                % listen to button presses      
                [key,timestamp,~] = IOPort('Read',p.LuminaHandle);
                if ~isempty(key)
                    IOPort('Flush',p.LuminaHandle);
                    % record responses 
                    keys_pressed = [keys_pressed; key];
                    times_pressed = [times_pressed; timestamp];
                end
            end 
        else
            WaitSecs(1.8);
            % Now record response
            keycodes = nan; response_times = nan;
            [keycodes, response_times] = KbQueueDump(p);
            key_pressed = KbName(keycodes); if strcmp(key_pressed, 'q'), abort = 1; end
        end
    end


    function [ActSampleOnset, p] = show_one_sample(p, SampleOnset, location, gener_side, coloured_task)
        % Show one sample, such that black and white parts cancel.
        r_inner = p.stim.r_inner;
        o = p.stim.lumdiff;
        p.sample_duration=p.stim.sample_duration;
        x_outer = r_inner*(2^.5 -1);
        r_outer = (r_inner + x_outer)*p.display.ppd;
        r_inner = r_inner*p.display.ppd;
        cx = p.ptb.CrossPosition_x;
        cy = p.ptb.CrossPosition_y;

        % left, top, right, bottom
        location = location*p.display.ppd; % location negative = up; location positive = down
        rin = [cx-r_inner, location-r_inner+cy, cx+r_inner, location+r_inner+cy];
        rout = [cx-r_outer, location-r_outer+cy, cx+r_outer, location+r_outer+cy];
        draw_fix(p);            
            
        if coloured_task == 1
            % sample generated by left source coloured blue
            % sample generated by right cource coloured orange
            if gener_side<0
                colour=[0 70 0]; %green
            else
                colour=[0 37 255]; %blue
            end
        else
            colour = p.stim.bg;
        end
        Screen('FillOval', p.ptb.w, colour-o, rout);
        Screen('FillOval', p.ptb.w, colour+o, rin);

        ActSampleOnset  = Screen('Flip',p.ptb.w, SampleOnset, 0);      %<----- FLIP
        if gener_side<0 % Maria to make analyses easier
            Eyelink('message', sprintf('sample_neg %f', location));
            p = Log(p,ActSampleOnset, 'SAMPLE_ONSET_NEG', location);
            Eyelink('message', sprintf('sample_pos %f', location));
            p = Log(p,ActSampleOnset, 'SAMPLE_ONSET_POS', location);
        end
%         Eyelink('message', sprintf('sample %f', location)); 
%         p = Log(p,ActSampleOnset, 'SAMPLE_ONSET', location, p.phase_variable, p.block);
        %MarkCED( p.com.lpt.address, p.com.lpt.event);
        draw_fix(p);

        TimeSampleOffset = Screen('Flip',p.ptb.w,ActSampleOnset+p.sample_duration, 0);     %<----- FLIP
        draw_fix(p);
        %TimeSampleOffset = Screen('Flip',p.ptb.w,TimeSampleOffset+(.25), 0);
    end



    %% -----------------------------------
    %  Helper functions
    %  -----------------------------------

    function p = dump_keys(p)
        %dump the final events
        [keycode, secs] = KbQueueDump(p);%this contains both the pulses and keypresses.
    end


    function draw_fix(p)
% fixation target as suggested in Vision Research. Volume 76, 14 January 2013, Pages 31-42
% What is the best fixation target? The effect of target shape on stability of fixational eye movements. 
% L.Thalerab, A.C.SchützcM.A.GoodalebdK.R.Gegenfurtnerc

        colorOval = p.stim.fix_target; % color of the two circles [R G B]
        colorCross = p.stim.bg; % color of the Cross [R G B]

        d1 = 0.6; % diameter of outer circle (degrees)
        d2 = 0.2; % diameter of inner circle (degrees)

        Screen('FillOval', p.ptb.w, colorOval, [p.ptb.CrossPosition_x-d1/2 * p.display.ppd, p.ptb.CrossPosition_y-d1/2 * p.display.ppd, p.ptb.CrossPosition_x+d1/2 * p.display.ppd, p.ptb.CrossPosition_y+d1/2 * p.display.ppd], d1 * p.display.ppd);
        Screen('DrawLine', p.ptb.w, colorCross, p.ptb.CrossPosition_x-d1/2 * p.display.ppd, p.ptb.CrossPosition_y, p.ptb.CrossPosition_x+d1/2 * p.display.ppd, p.ptb.CrossPosition_y, d2 * p.display.ppd);
        Screen('DrawLine', p.ptb.w, colorCross, p.ptb.CrossPosition_x, p.ptb.CrossPosition_y-d1/2 * p.display.ppd, p.ptb.CrossPosition_x, p.ptb.CrossPosition_y+d1/2 * p.display.ppd, d2 * p.display.ppd);
        Screen('FillOval', p.ptb.w, colorOval, [p.ptb.CrossPosition_x-d2/2 * p.display.ppd, p.ptb.CrossPosition_y-d2/2 * p.display.ppd, p.ptb.CrossPosition_x+d2/2 * p.display.ppd, p.ptb.CrossPosition_y+d2/2 * p.display.ppd], d2 * p.display.ppd);
%         Screen(p.ptb.w, 'Flip'); 
    end



%     function text = RewardText(reward_rate)
%         text = [sprintf('No último bloco acertou %2.0f%% das respostas.\n', 100*reward_rate)];
%             %sprintf('Isso corresponde %1.2f EUR!\n', earned_money)...
%             %sprintf('No total, ganhou um bónus de %1.2f EUR!', total_money)];
%     end


    function ShowText(text, onset)

        Screen('FillRect',p.ptb.w,p.var.current_bg);
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        if nargin==1
            Screen('Flip',p.ptb.w);
        else
            Screen('Flip',p.ptb.w, onset);
        end
        %show the messages at the experimenter screen
    end


     function SetParams
%         %mrt business
%         p.mrt.dummy_scan              = 5; %this will wait until the 6th image is acquired.
%         p.mrt.LastScans               = 5; %number of scans after the offset of the last stimulus
%         p.mrt.tr                      = 2; %in seconds.

        %will count the number of events to be logged
        p.out.event_count             = 0;
        %% relative path to stim and experiments
        %Path Business.
        [~, hostname]                 = system('hostname');
        p.hostname                    = deblank(hostname);

        if strcmp(p.hostname, 'czc0211hsd') %gab 72
%             p.display.resolution = [1680 1050];
            p.display.dimension = [47 29.5];
            p.display.distance = [52, 64]; 
            p.path.baselocation = ['N:\ProjectBrainstemAgeing\exp_data\' subject filesep 'session' num2str(session) filesep 'run' num2str(run)];
            p.stim.bg  = [128, 128, 128];
            p.stim.fix_target = [144 144 144]; 
            % dir with face or house images files
%             face_dir = [pwd '\Stanford Vision & Perception Neuroscience Lab\selected_faces_adults_similar_lum'];
%             house_dir = [pwd '\Stanford Vision & Perception Neuroscience Lab\selected_houses_similar_lum'];
            p.images_dir = [pwd '\Stanford Vision & Perception Neuroscience Lab'];
        elseif strcmp(p.hostname, 'cnd0151937') % laptop hp elitebook
%             p.display.resolution = [1600 900];
            p.display.dimension = [34.5 19.5];
            p.display.distance = [52, 64]; 
            p.path.baselocation = [pwd '\exp_data\' subject filesep 'session' num2str(session) filesep 'run' num2str(run)];
            p.stim.bg  = [128, 128, 128];
            p.stim.fix_target = [144 144 144]; 
            p.images_dir = [pwd '\Stanford Vision & Perception Neuroscience Lab'];
        elseif strcmp(p.hostname, 'DESKTOP-MKKOQUF')        % Coimbra lab 94  = ['DESKTOP-MKKOQUF']
%             p.display.resolution = [1600 900]; %[1440 1080]; %[1920 1080]; Maria set to laptop 14Sep2019
            p.display.dimension = [34.5 19.5]; %[52, 39.5]; %[52, 29.5]; Maria set to laptop 14Sep2019
            p.display.distance = [52, 50]; %[62, 59]; % 
            p.path.baselocation           = 'C:\Users\admin\Desktop\MariaRibeiro\GlazeTask\faces_vs_houses_lab94\data';
            p.stim.bg = [48 48 48];%[128, 128, 128];
            p.stim.fix_target = [64 64 64]; 
            % dir with face or house images files
%             face_dir = 'C:\Users\admin\Desktop\MariaRibeiro\GlazeTask\Stanford Vision & Perception Neuroscience Lab\selected_faces_adults_similar_lum';
%             house_dir = 'C:\Users\admin\Desktop\MariaRibeiro\GlazeTask\Stanford Vision & Perception Neuroscience Lab\selected_houses_similar_lum';
            p.images_dir = 'C:\Users\admin\Desktop\MariaRibeiro\GlazeTask\Stanford Vision & Perception Neuroscience Lab';
        else % other displays
%             p.display.resolution = [1600 900]; %[1440 1080]; %[1920 1080]; Maria set to laptop 14Sep2019
            p.display.dimension = [34.5 19.5];
            p.display.distance = [52, 50]; 
            p.path.baselocation = [pwd '\exp_data\' subject filesep 'session' num2str(session) filesep 'run' num2str(run)];
            p.stim.bg  = [128, 128, 128];
            p.stim.fix_target = [144 144 144]; 
            % dir with face or house images files
%             face_dir = [pwd '\Stanford Vision & Perception Neuroscience Lab\selected_faces_adults_similar_lum'];
%             house_dir = [pwd '\Stanford Vision & Perception Neuroscience Lab\selected_houses_similar_lum'];
            p.images_dir = [pwd '\Stanford Vision & Perception Neuroscience Lab'];        
        end

        p.stim.r_inner = .1;
        p.stim.lumdiff = 12; % luminance difference within sample fill and outline
        p.stim.sample_duration = .1;
        %create the base folder if not yet there.
        if exist(p.path.baselocation) == 0 %#ok<EXIST>
            mkdir(p.path.baselocation);
        end
        p.timestamp                     = datestr(now, 30); %the time_stamp of the current experiment.

        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        
        p.stim.white                = get_color('white');
        p.text.fontname                = 'Courier';
        p.text.fontsize                = 20;
        p.text.fixsize                 = 60;
        
        % Set response device: 
        %if outside scanner = keyboard; 
        % inside scanner = lumina
        switch fmri
            case 0
                p.responseDevice = 'keyboard';
                p.syncboxEnabled = 0;
                KbName('UnifyKeyNames');
%                 Screen('FillRect', p.ptb.w, p.stim.bg);
%                 DrawFormattedText(p.ptb.w, 'Ready...', 'center', 'center', p.stim.white,[],[],[],2,[]);
%                 Screen('Flip',p.ptb.w);
%                 KbWait
            case 1
                p.responseDevice = 'lumina';
                p.syncboxEnabled=1;
                p.LuminaHandle = IOPort('OpenSerialPort','COM3', 'ReadTimeout', 30);
                IOPort('Flush',p.LuminaHandle);     
        end
        
        %% keys to be used during the experiment:
        %This part is highly specific for your system and recording setup,
        %please enter the correct key identifiers. You can get this information calling the
        %KbName function and replacing the code below for the key below.
        %1, 6 ==> Right
        %2, 7 ==> Left
        %3, 8 ==> Down
        %4, 9 ==> Up (confirm)
        %5    ==> Pulse from the scanner

%         KbName('UnifyKeyNames');
        p.keys.confirm                 = '4$';%
%         p.keys.answer_a                = {'1!', '2@', '3#', '4$'};
%         p.keys.answer_a_train          = 'z';
        p.keys.answer_left       = 'z';
%         p.keys.answer_b                = {'6^', '7&', '8*', '9('};
%         p.keys.answer_b_train          = 'm';
        p.keys.answer_right          = 'm';
%         p.keys.pulse                   = '5%';
        p.keys.el_calib                = 'v';
        p.keys.el_valid                = 'c';
        p.keys.escape                  = 'ESCAPE';
        p.keys.enter                   = 'return';
        p.keys.quit                    = 'q';
        p.keys.list = {p.keys.confirm,...
            p.keys.answer_left,...
            p.keys.answer_right,...
            p.keys.el_calib, p.keys.el_valid, p.keys.enter};
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
%         %Communication business
%         %parallel port
%         p.com.lpt.address = 888;%parallel port of the computer.
%         %codes for different events that are sent for logging in the
%         %physiological computer.
%         p.com.lpt.resp0     = 128;
%         p.com.lpt.resp1     = 64;
%         p.com.lpt.stim      = 32;
%         p.com.lpt.sample    = 16;
%         %Record which phase_variable are we going to run in this run.
%         p.stim.phase_variable                   = phase_variable;
        p.out.log                     = cell(1000000,1);%Experimental LOG.

        %%
%         p.var.current_bg              = p.stim.bg;%current background to be used.
        %save(p.path.path_param,'p');
    end


    function SetPTB    
        %Sets the parameters related to the PTB toolbox. Including
        %fontsizes, font names.
        %Default parameters
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        Screen('Preference', 'TextAntiAliasing',2);%enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'SuppressAllWarnings', 1);
        %%Find the number of the screen to be opened
        screens                     =  Screen('Screens');
%         if strcmp(p.hostname, 'larry.local')
%             p.ptb.screenNumber          =  min(screens);%the maximum is the second monitor
%             [idx, names, ~] = GetKeyboardIndices;
%             p.ptb.device = nan;
%             for iii = 1:length(idx)
%                 if strcmp(names{iii}, '')
%                     p.ptb.device = idx(iii);
%                     break
%                 elseif strcmp(names{iii}, 'Apple Internal Keyboard / Trackpad') && isnan(p.ptb.device)
%                     p.ptb.device = idx(iii);
%                     break
%                 end
%             end
%             fprintf('Device name is: %s\n', names{iii})
%             gamma = load('dell241i_calibration.mat');
%             p.ptb.gamma = gamma.gTmp;
%         elseif strcmp(p.hostname, 'donnerlab-Precision-T1700')
%             p.ptb.screenNumber          =  0;
%             [idx, names, ~] = GetKeyboardIndices;
%             p.ptb.device = nan;
%             for iii = 1:length(idx)
%                 if strcmp(names{iii}, 'DELL Dell USB Entry Keyboard')
%                     p.ptb.device = idx(iii);
%                     break
%                 end
%             end
%             p.ptb.device
%             gamma = load('vpixx_gamma_table.mat');
%             p.ptb.gamma = gamma.table;
%         else
        p.ptb.screenNumber   = max(screens);%the maximum is the second monitor
        [idx, names, ~] = GetKeyboardIndices;
        p.ptb.device = idx;
%             gamma = load('nne_uke_scanner.mat');
%             gamma = [0 0 0; gamma.gammaTable];
%             p.ptb.gamma = gamma;
%         end 

        %Make everything transparent for debugging purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end
        %set the resolution correctly
        res = Screen('resolution', p.ptb.screenNumber);
        p.display.resolution = [res.width res.height];
        p.display.ppd = ppd(mean(p.display.distance), p.display.resolution(1),...
            p.display.dimension(1));
        %spit out the resolution,
        fprintf('Resolution of the screen is %dx%d...\n',res.width,res.height);

        HideCursor(p.ptb.screenNumber);%make sure that the mouse is not
%         shown at the participant's monitor
        
        %Open a graphics window using PTB
        if ~small_window
            [p.ptb.w, p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, p.stim.bg);
        else
            [p.ptb.w, p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, p.stim.bg, [0, 0, 900, 700]);
        end

        % Set up alpha-blending for smooth (anti-aliased) lines
        Screen('BlendFunction', p.ptb.w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        
        p.ptb.gamma_loaded=false;
        Screen('Flip',p.ptb.w);%make the bg

        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);

        %find the mid position on the screen.
        x = p.ptb.rect(1) + (p.ptb.rect(3)/2);
        y = p.ptb.rect(2) + (p.ptb.rect(4)/2);

        p.ptb.midpoint              = [x, y]; % p.ptb.width./2 p.ptb.height./2];
        %NOTE about RECT:
        %RectLeft=1, RectTop=2, RectRight=3, RectBottom=4.
        p.ptb.CrossPosition_x       = p.ptb.midpoint(1);
        p.ptb.CrossPosition_y       = p.ptb.midpoint(2);
        %cross position for the eyetracker screen.
        p.ptb.fc_size               = 10;

        Priority(MaxPriority(p.ptb.w));


        if IsWindows
            LoadPsychHID;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%Prepare the keypress queue listening.

        %get all the required keys in a vector
        p.ptb.keysOfInterest = [];
        for i = fields(p.keys)'
            p.ptb.keysOfInterest = [p.ptb.keysOfInterest KbName(p.keys.(i{1}))];
        end
        RestrictKeysForKbCheck(p.ptb.keysOfInterest);
        KbQueueCreate(p.ptb.device);%, p.ptb.keysOfInterest);%default device.
     
        Screen('TextSize', p.ptb.w,  20);
        Screen('TextFont', p.ptb.w, 'Courier');
        Screen('TextStyle', p.ptb.w, 1);
        
        
        %% Make a gaussian aperture with the "alpha" channel
        % to show images of faces and houses
        gaussDim = 150;
        gaussSigma = gaussDim / 3;
        [xm, ym] = meshgrid(-gaussDim:gaussDim, -gaussDim:gaussDim);
        gauss = exp(-(((xm .^2) + (ym .^2)) ./ (2 * gaussSigma^2)));
        [s1, s2] = size(gauss);
        mask = ones(s1, s2, 2) * p.stim.bg(1);
        mask(:, :, 2) = 255 * (1 - gauss);
        p.gaussian_aperture.masktex = Screen('MakeTexture', p.ptb.w, mask);

        % Make a grey texture to cover the full window
        p.gaussian_aperture.fullWindowMask = Screen('MakeTexture', p.ptb.w,...
    ones(p.ptb.height, p.ptb.width) .* p.stim.bg(1)); %grey

        % Make coordinates in which to draw the apertures into our full screen mask
        % [xg, yg] = meshgrid(-3:1:3, -3:1:3);
        xg = 0; yg = 0; % centre of aperture = centre of screen
        spacing = gaussDim * 2;
        xg = xg .* spacing + p.ptb.width / 2;
        yg = yg .* spacing + p.ptb.height / 2;
        xg = reshape(xg, 1, numel(xg));
        yg = reshape(yg, 1, numel(yg));

        % Make the destination rectangles for the gaussian apertures
        p.gaussian_aperture.dstRects = nan(4, numel(xg));
        for i = 1:numel(xg)
            p.gaussian_aperture.dstRects(:, i) = CenterRectOnPointd([0 0 size(mask, 1), size(mask, 2)], xg(i), yg(i));
        end
        
    end


    function p=InitEyeLink(p)
        %
        if EyelinkInit(NoEyelink)%use 0 to init normaly
            fprintf('=================\nEyelink initialized correctly...\n')
        else
            fprintf('=================\nThere is problem in Eyelink initialization\n')
            keyboard;
        end
        %
        WaitSecs(0.5);
        [~, vs] = Eyelink('GetTrackerVersion');
        fprintf('=================\nRunning experiment on a ''%s'' tracker.\n', vs );

        %
        el                          = EyelinkInitDefaults(p.ptb.w);
        %update the defaults of the eyelink tracker
        el.backgroundcolour         = p.stim.bg;
        el.msgfontcolour            = WhiteIndex(el.window);
        el.imgtitlecolour           = WhiteIndex(el.window);
        el.targetbeep               = 0;
        el.calibrationtargetcolour  = WhiteIndex(el.window);
        el.calibrationtargetsize    = 1.5;
        el.calibrationtargetwidth   = 0.5;
        el.displayCalResults        = 1;
        el.eyeimgsize               = 50;
        el.waitformodereadytime     = 25;%ms
        el.msgfont                  = 'Times New Roman';
        el.cal_target_beep          =  [0 0 0];%[1250 0.6 0.05];
        %shut all sounds off
        el.drift_correction_targetp.ptb.wid_beep = [0 0 0];
        el.calibration_failed_beep      = [0 0 0];
        el.calibration_success_beep     = [0 0 0];
        el.drift_correction_failed_beep = [0 0 0];
        el.drift_correction_success_beep= [0 0 0];
        EyelinkUpdateDefaults(el);
        PsychEyelinkDispatchCallback(el);

        % open file.
%         if p.subject <= -100
%             p.edffile = 'samptest.edf';
%         else
%             p.edffile = sprintf('%d%d.edf', p.subject, p.block);
%         end
        % name of edf file to be created with eye tracking data - max
        % number of characters = 8
        p.edffile = [p.subject(3:end), 'S', num2str(p.session), 'R', num2str(p.run)]; %sprintf('S%d_B%d.edf', p.subject,  p.block); % Maria
        res = Eyelink('Openfile', p.edffile); %#ok<NASGU>

        Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);

        pw = p.display.dimension(1);
        ph = p.display.dimension(2);
        phys_coord = sprintf('screen_phys_coords = %ld, %ld, %ld, %ld'...
            , -floor(10*pw/2)... %half width
            ,  floor(10*ph/2)... %half height
            ,  floor(10*pw/2)... %half width
            , -floor(10*ph/2));   %half height %rv 2
        Eyelink('command', phys_coord);

        Eyelink('command', 'screen_distance = %ld %ld', ...
            10*p.display.distance(2), 10*p.display.distance(2)); %rv 3

        % set calibration type.
        Eyelink('command','auto_calibration_messages = YES');
        Eyelink('command', 'calibration_type = HV13');
        Eyelink('command', 'select_parser_configuration = 1');
        %what do we want to record
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET');
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'use_ellipse_fitter = no');
        % set sample rate in camera setup screen
        Eyelink('command', 'sample_rate = %d',1000);

    end


    function StopEyelink(filename, path_edf)
        if ~NoEyelink
            try
                fprintf('Trying to stop the Eyelink system with StopEyelink\n');
                Eyelink('StopRecording');
                WaitSecs(0.5);
                Eyelink('Closefile');
%                 display('receiving the EDF file...');
                Eyelink('ReceiveFile', filename, path_edf);
%                 display('...finished!')
                % Shutdown Eyelink:
                Eyelink('Shutdown');
            catch
                display('StopEyeLink routine didn''t really run well');
            end
        end
    end


    function cleanup(p)
        % Close window:
        RestoreCluts()
        %Screen('flip', p.ptb.w)
        sca;
        %set back the old resolution
        if strcmp(p.hostname,'triostim1')
            %            Screen('Resolution',p.ptb.screenNumber, p.ptb.oldres.width, p.ptb.oldres.height );
            %show the cursor
            ShowCursor(p.ptb.screenNumber);
        end
        %
        commandwindow;
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
    end


    function CalibrateEL
        fprintf('=================\n=================\nEntering Eyelink Calibration\n')
        p.var.Expphase_variable  = 0;
        EyelinkDoTrackerSetup(el);
        %Returns 'messageString' text associated with result of last calibration
        [~, messageString] = Eyelink('CalMessage');
        Eyelink('Message','%s', messageString);%
        WaitSecs(0.05);
        fprintf('=================\n=================\nNow we are done with the calibration\n')
%         if numel(p.ptb.gamma, 2) > 0
%             [old_table] = Screen('LoadNormalizedGammaTable', p.ptb.w, p.ptb.gamma);
%             p.ptb.gamma_loaded = true;
%             p.ptb.old_gamma = old_table;
%             p.ptb.gamma_loaded = false;
%         else
            p.ptb.gamma_loaded=false;
%         end
    end


    function p = Log(p, ptb_time, event_type, event_info)
        for iii = 1:length(ptb_time)
            p.out.event_count                = p.out.event_count + 1;
            p.out.log{p.out.event_count}   = {ptb_time(iii) event_type event_info(iii)};
            %fprintf('LOG: %2.2f, %i, %s, %s, %i \n', ptb_time, event_type, event_info, phase_variable, block)
        end

    end


    function [keycode, secs] = KbQueueDump(p)
        %[keycode, secs] = KbQueueDump
        %   Will dump all the events accumulated in the queue.
        keycode = [];
        secs    = [];
        pressed = [];
        while KbEventAvail(p.ptb.device)
            [evt, n]   = KbEventGet(p.ptb.device);
            n          = n + 1;
            keycode(n) = evt.Keycode; %#ok<AGROW>
            pressed(n) = evt.Pressed; %#ok<AGROW>
            secs(n)    = evt.Time; %#ok<AGROW>
        end
        i           = pressed == 1;
        keycode(~i) = [];
        secs(~i)    = [];

    end


    function [keyIsDown, firstPress] = check_kbqueues(devices) %#ok<DEFNU>
        firstPress = boolean(zeros(1, 256));
        keyIsDown = false;
        for device = devices
            [kD, fP] = PsychHID('KbQueueCheck', device);
            keyIsDown = keyIsDown | kD;
            firstPress = firstPress | boolean(fP);
        end
    end


    function p = save_data(p)
%         p.save_time = datestr(now, 'dd-mmm-yyyy HH:MM:SS');
        p.save_time = datestr(now, 'yyyymmddTHHMMSS');
        rst = randstr(5);
        p.random_string = rst;
        path_edf = fullfile(p.path.baselocation, sprintf(p.subject,  p.block));
        path_data = [p.path.baselocation, filesep p.subject, rst];
        %get the eyelink file back to this computer
        StopEyelink(p.edffile,   path_edf);
        %trim the log file and save
        p.out.log = p.out.log(1:p.out.event_count);

        %shift the time so that the first timestamp is equal to zero
        %p.out.log(:,1) = p.out.log(:,1) - p.out.log(1);
        %p.out.log      = p.out.log;%copy it to the output variable.
        save(path_data, 'p');
    end


    function r = randstr(n)
        symbols = ['a':'z' 'A':'Z' '0':'9'];
        stLength = randi(n);
        nums = randi(numel(symbols),[1 stLength]);
        r = symbols (nums);
    end

    function ppd = ppd(distance, x_px, width)
        o = tan(0.5*pi/180) * distance;
        ppd = 2 * o*x_px/width; %  number of points per degree
    end

        function rule_explained(p, rule)

        % 'center' = 0 - top: face-left, house-right; bottom house-left, face-right        
        % load image of face or house - face - stim_id = 0; house - stim_id = 1 

        %% load and  make images the images into a textureS 
        img_size = 300;
        % Here we load in an image from file.
        % face image
        theImageLocation = [p.images_dir '\child-3.jpg'];
        theImage_face = imread(theImageLocation);
        % Make the image into a texture
        imageTexture_face = Screen('MakeTexture', p.ptb.w, theImage_face);

        % House Image
        theImageLocation = [p.images_dir '\house-3.jpg'];
        theImage = imread(theImageLocation);
        % Make the image into a texture
        imageTexture_house = Screen('MakeTexture', p.ptb.w, theImage);

        %% create four gaussian appertures, one for each image (https://peterscarfe.com/bubblesdemo.html)
        % Make a gaussian aperture with the "alpha" channel
        gaussDim = 150;
        gaussSigma = gaussDim / 3;
        [xm, ym] = meshgrid(-gaussDim:gaussDim, -gaussDim:gaussDim);
        gauss = exp(-(((xm .^2) + (ym .^2)) ./ (2 * gaussSigma^2)));
        [s1, s2] = size(gauss);
        mask = ones(s1, s2, 2) * p.stim.bg(1) ;
        mask(:, :, 2) = 255 * (1 - gauss);
        % four_masks = cat(1, mask, mask);
        % four_masks = cat(2, four_masks, four_masks);
        masktex = Screen('MakeTexture', p.ptb.w, mask);

        % Make a grey texture to cover the full p.ptb.w
        fullWindowMask = Screen('MakeTexture', p.ptb.w,...
            ones(p.ptb.height, p.ptb.width) .* p.stim.bg(1));

        % Make coordinates in which to draw the apertures into our full screen mask
        % xg = 0; yg = 0; %centre of aperture = centre of screen
        xg = [p.ptb.width/2 - img_size/2, p.ptb.width/2 + img_size/2, p.ptb.width/2 - img_size/2, p.ptb.width/2 + img_size/2];
        yg = [p.ptb.height/2 - img_size/2, p.ptb.height/2 + img_size/2, p.ptb.height/2 + img_size/2, p.ptb.height/2 - img_size/2];

        % Make the destination rectangles for the gaussian apertures
        dstRects_1 = nan(4, numel(xg));
        for i = 1:numel(xg)
            dstRects_1(:, i) = CenterRectOnPointd([0 0 size(mask, 1), size(mask, 2)], xg(i), yg(i));
        end

        % Draw the gaussian apertures  into our full screen aperture mask
        Screen('DrawTextures', fullWindowMask, masktex, [], dstRects_1);

        %% draw mask
        % Draw the image to the screen
        % left, top, right, bottom - size of image in pixels [0,0] = top left
        % corner
%         NewImageRect = [0 0 img_size img_size];
        NewImage_Left_Top = [p.ptb.width/2-img_size, p.ptb.height/2-img_size, p.ptb.width/2, p.ptb.height/2];
        NewImage_Right_Bottom = [p.ptb.width/2, p.ptb.height/2, p.ptb.width/2+img_size, p.ptb.height/2+img_size];
        NewImage_Right_Top = [p.ptb.width/2, p.ptb.height/2-img_size, p.ptb.width/2+img_size, p.ptb.height/2];
        NewImage_Left_Bottom = [p.ptb.width/2-img_size, p.ptb.height/2, p.ptb.width/2, p.ptb.height/2+img_size];

        if rule == 0
            Screen('DrawTexture', p.ptb.w, imageTexture_face, [], NewImage_Left_Top, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_face, [], NewImage_Right_Bottom, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_house, [], NewImage_Right_Top, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_house, [], NewImage_Left_Bottom, 0);
        else
            Screen('DrawTexture', p.ptb.w, imageTexture_house, [], NewImage_Left_Top, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_house, [], NewImage_Right_Bottom, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_face, [], NewImage_Right_Top, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_face, [], NewImage_Left_Bottom, 0);
        end
       
        Screen('DrawTexture', p.ptb.w, fullWindowMask);
        draw_fix(p);
        text = 'Carregue numa tecla para avançar.';
        DrawFormattedText(p.ptb.w, text, 'center', 9*p.ptb.height/10, p.stim.white,[],[],[],2,[]);
        %% Flip to the screen
        Screen('Flip', p.ptb.w);
    end
end