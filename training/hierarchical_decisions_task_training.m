function [p]=hierarchical_decisions_task_training(subject, rule_hierarchical_decision, start_phase, language)
% subject = string with subject ID
% rule_hierarchical_decision = 0 or 1 - rule counterbalanced across
% participants
% start_phase = 1 - to run the whole training schedule
% start_phase = 2 - to run only the second part with hierarchical decisions
% language = 'PT or 'EN'
% press 'q' at time of response to quit
rng('shuffle'); % to be really random!
% NoEyelink = 1; %is Eyelink wanted?
debug   = 0; % debug mode => 1: transparent window enabling viewing the background.
small_window = 0; % Open a small window only

%% >>>>> Set up a lot of stuff
abort = false; % 
start_time = GetSecs;
commandwindow; % focus on the command window, so that output is not written on the editor

p         = [];% parameter structure that contains all info about the experiment.
p.subject = subject; p.rule_hierarchical_decision = rule_hierarchical_decision;
SetParams;% set parameters of the experiment
SetPTB;% set visualization parameters.

% % text properties
Screen('TextSize', p.ptb.w,  20);
Screen('TextFont', p.ptb.w, 'Courier');
Screen('TextStyle', p.ptb.w, 1);

%% >>>>>>> Experiment starts.

% use two different sequences of stimuli:
% easy - distance between means = 1 (threshold = 0.5) ; sd = 0.4; SNR = 2.5
% difficult - distance between means = 0.5 (threshold = 0.25); sd = 0.4;
% SNR = 1.25

while 1
    p.location_of_mean = [0.5, 0.25]; p.sd = [0.4, 0.4];
    if strcmp(language, 'PT')
        text = ['Por favor, desligue ou tire o som ao telemóvel. \n'...
            'Obrigada!\n\n', ...
            'Carregue numa tecla para começar.'];
    else
        text = ['Please turn off or mute your phone.\n'...
            'Thank you!\n\n', ...
            'Press any key to start.'];
    end
    DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
    Screen('Flip', p.ptb.w);
    [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
    key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end

    if start_phase == 1
    
        show_probability_distributions(p); % explain data distributions

        WaitSecs(1);
        Screen('Flip', p.ptb.w);

        % PHASE 2 - show samples from alternating
        % distributions with choice trials - coloured samples
        if strcmp(language, 'PT')
            text = ['A seguir vamos observar uma sequência de pontos gerados pelas duas nuvens.\n', ... 
                'As cores indicam quando as alternâncias ocorrem. \n'...
                'Verde = nuvem superior. Azul = nuvem inferior.\n'...
                'Preste atenção à posição dos pontos. \n\n'...
                'Carregue numa tecla para avançar.'];
        else
            text = ['Next, we will observe a sequence of dots drawn from the two clouds. \n', ...
            'The colours indicate when the alternations occur. \n '...
            'Green = upper cloud. Blue = lower cloud. \n '...
            'Pay attention to the position of the dots. \n\n '...
            'Press any key to continue.'];   
        end
        
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        Screen('Flip', p.ptb.w);
        [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
        key_pressed = KbName(keyCode);
        if strcmp(language, 'PT')
            text = ['Nos momentos assinalados pelo círculo amarelo, terá de indicar que nuvem \n', ... 
                'estava ativa imediatamente antes, usando o teclado.\n\n'...
                'Responda com a mão direita usando as setas esquerda e cima.\n\n'...
                'Mantenha o olhar fixo no alvo de fixação e observe os pontos com a visão periférica. \n\n', ...
                'Carregue numa tecla para avançar.'];
        else
            text = ['At the moments marked by the yellow circle, you will have to indicate which cloud\n', ...
                'was active immediately before, using the keyboard.\n\n' ...
                'Answer with your right hand using the left arrow and up arrow keys.\n\n' ...
                'Keep your eyes fixed on the fixation target and observe the dots with your peripheral vision.\n\n', ...
                'Press any key to continue.'];            
        end
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        Screen('Flip', p.ptb.w);
        [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
        key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end
        draw_fix(p); 
        coloured_task = 1; block = 1; number_of_trials = 100;%200;
        p = inference_task(p, coloured_task, block, number_of_trials); % PHASE 2 - coloured task with choice trials

        coloured_task = 0; number_of_trials = 400;
        for block = 1:2 % first easy then difficult condition - PHASE 3 and phase 4
            draw_fix(p); 
            Screen('Flip', p.ptb.w);
            % show samples from alternating distributions with choice trials
            if block ==1 % PHASE 3
                if strcmp(language, 'PT')
                    text = ['A seguir vamos apresentar uma sequência de pontos gerados alternadamente \n', ... 
                    'pelas duas nuvens. Desta vez os pontos têm todos a mesma cor. \n\n', ...
                    'Terá de inferir quando houve mudança da nuvem ativa\n'... 
                    'através da análise das posições dos pontos. \n\n'...
                    'Carregue numa tecla para avançar.'];
                else
                   text = ['Next, we will show a sequence of dots alternately generated \n', ...
                    'by the two clouds. This time the dots are all the same color. \n\n ', ...
                    'You will have to infer when the active cloud has changed\n' ...
                    'through the analysis of the positions of the dots.\n\n '...
                    'Press any key to continue.'];
                end
                DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
                Screen('Flip', p.ptb.w);
                [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
                key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end
            elseif block ==2 % two distribution closer together - more difficult version of task - PHASE 4
                if strcmp(language, 'PT')
                    text = ['Agora vamos tornar o teste mais difícil.\n'...
                    'A partir de agora as nuvens que geram os pontos\n'... 
                    'vão estar mais sobrepostas.\n\n', ...
                    'Carregue numa tecla para avançar.'];
                else
                     text = ['Now, we will make the test more difficult. \n' ...
                    'From now on the clouds that generate the dots \n' ...
                    'will be more overlapping. \n\n', ...
                    'Press any key to continue.'];                   
                end
                DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
                Screen('Flip', p.ptb.w);
                [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
                key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end

                % show image with example of samples from both distributions
                text = 'Duas nuvens geradoras de pontos.';
                DrawFormattedText(p.ptb.w, text, 'center', p.ptb.CrossPosition_y-400, p.stim.white,[],[],[],2,[]);
                text = 'Carregue numa tecla para avançar.';
                DrawFormattedText(p.ptb.w, text, 'center', p.ptb.CrossPosition_y+400, p.stim.white,[],[],[],2,[]);
                % Here we load an image from file.
                if strcmp(p.hostname, 'czc0211hsd') %gab72
                    theImageLocation = [pwd, '\generative_processes_difficult_SNR_1_25_gab92.jpg'];
                elseif strcmp(p.hostname, 'DESKTOP-MKKOQUF') % Coimbra lab 94 
                    theImageLocation = [pwd, '\generative_processes_difficult_SNR_1_25_lab94.jpg'];
                else
                    theImageLocation = [pwd, '\generative_processes_difficult_SNR_1_25.jpg'];
                end
                
                theImage_example = imread(theImageLocation);
                % Make the image into a texture
                imageTexture_example = Screen('MakeTexture', p.ptb.w, theImage_example);
                Screen('DrawTexture', p.ptb.w, imageTexture_example);
                Screen('Flip', p.ptb.w);
                [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
                key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end
            end  

            if strcmp(language, 'PT')
                text = ['Nos momentos assinalados pelo círculo amarelo terá de indicar que nuvem\n', ... 
                'estava ativa imediatamente antes usando o teclado.\n\n'...
                'Responda com a mão direita usando as setas esquerda e cima,\n'... 
                'para indicar que nuvem estava ativa.\n\n'...
                'Mantenha o olhar fixo no alvo de fixação e observe os pontos com a visão periferica. \n\n', ...
                'Carregue numa tecla para avançar.'];
            else
                text = ['At the moments marked by the yellow circle you will have to indicate which cloud \ n', ...
                'was active immediately before using the keyboard. \ n \ n' ...
                'Answer with your right hand using the left and up arrows, \ n' ...
                'to indicate which cloud was active. \ n \ n' ...
                'Keep your eyes fixed on the target and observe the points with peripheral vision. \ n \ n ', ...
                'Press a key to advance.'];
            end
            DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
            Screen('Flip', p.ptb.w);
            [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
            key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end          

            draw_fix(p);
            p = inference_task(p, coloured_task, block, number_of_trials); 
        end 
        %% hierarchical decisions training phase
        block = 2; % use lower SNR - distributions closer together
        number_of_trials = 400;
        p = hierarchical_decisions_training_phase(p, block, number_of_trials);
    
    else
        %% hierarchical decisions training phase
        block = 2; % use lower SNR - distributions closer together
        number_of_trials = 400;
        p = hierarchical_decisions_training_phase(p, block, number_of_trials);
    end

    break
end
        end_time = GetSecs; p.training_time=(end_time-start_time)/60;
        fprintf('Esta sessao demorou %d minutes.\n',(end_time-start_time)/60);
        % save data
        mkdir([pwd, '/training_data']);
        save([pwd, '/training_data/', subject, '_training.mat'], 'p');
        %stop the queue and close screen etc
        cleanup;
        
    %% -----------------------------------
    %  Trial functions
    %  -----------------------------------
    % show visual stimulus as cue for responses - on top of fixation cross
    % in yellow
    function [p, response] = visual_cue_trial(p)
        response= nan;
        % Show one sample, such that black and white parts cancel.
        r_inner = p.stim.r_inner;
%         o = p.stim.lumdiff;
        p.sample_duration=p.stim.sample_duration;
        x_outer = r_inner*(2^.5 -1);
        r_outer = (r_inner + x_outer)*p.display.ppd;
        r_inner = r_inner*p.display.ppd;
        cx = p.ptb.CrossPosition_x;
        cy = p.ptb.CrossPosition_y;
        
        % on top of fixation cross in red
        draw_fix(p);
        % Make a base Rect - outer circle
        baseRect = [0 0 0.5*p.display.ppd 0.5*p.display.ppd];
        % Center the rectangle on the centre of the screen
        centeredRect = CenterRectOnPointd(baseRect, cx, cy);
        Screen('FillOval', p.ptb.w, [200, 200, 0], centeredRect);

        ActSampleOnset  = Screen('Flip',p.ptb.w);      %<----- FLIP

        % record responses - circle on until response
        [secs, keyStateVec] = KbWait((p.ptb.device), 2);
        start_rt_counter  = ActSampleOnset;response = nan; RT = nan;
%         [keycodes, secs] = KbQueueDump(p);    
        keycodes=find(keyStateVec==1);
        if numel(keycodes)
            keys = KbName(keycodes(end)); % consider only last response in case it was corrected
            if strcmp(keys, p.keys.up_arrow) %{p.keys.answer_a, p.keys.answer_a_train}
                    % Answer a = Left - top
                    response = 0;
            elseif strcmp(keys, p.keys.down_arrow) %{p.keys.answer_b, p.keys.answer_b_train}
                    % Answer b = Right - bottom
                    response = 1;
            end
        end
        
        % yellow circle disappears
        draw_fix(p);
        TimeSampleOffset = Screen('Flip',p.ptb.w,ActSampleOnset+1, 0);     %<----- FLIP
%         draw_fix(p);
    end

   function [p, RT, keycodes, response_times, abort] = choice_trial(p, ChoiceStimOnset, theImageLocation)
%         rule = nan;
        response = nan;
        RT = nan; %#ok<NASGU>
        abort = false;
        
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

        % Flip to the screen
        % STIMULUS ONSET
        TimeStimOnset  = Screen('Flip', p.ptb.w, ChoiceStimOnset - p.ptb.slack, 0);    
        start_rt_counter  = TimeStimOnset;
        
        % Check for key events
        p = dump_keys(p);
        KbQueueFlush(p.ptb.device);
        % Now wait for response!
        response = nan;
        RT = nan;
        draw_fix(p);
        TimeStimOffset  = Screen('Flip', p.ptb.w, TimeStimOnset+ 0.5 - p.ptb.slack, 0);  %<----- FLIP                    
        WaitSecs(1.5);
        response = nan;
        keycodes = nan; response_times = nan;
        [keycodes, response_times] = KbQueueDump(p);  
   end


    function [ActSampleOnset, p] = show_one_sample(p, SampleOnset, location, gener_side, coloured_task)
        % Show one sample, such that black and white parts cancel.
        r_inner = p.stim.r_inner;
        o = p.stim.lumdiff;
        p.sample_duration = p.stim.sample_duration;
        x_outer = r_inner*(2^.5 -1);
        r_outer = (r_inner + x_outer)*p.display.ppd;
        r_inner = r_inner*p.display.ppd;
        cx = p.ptb.CrossPosition_x; % screen mid point
        cy = p.ptb.CrossPosition_y; % screen mid point

        % left, top, right, bottom -  rect(1)=left border, rect(2)=top, rect(3)=right, rect(4)=bottom.
        location = location*p.display.ppd;% location negative = up; location positive = down
        % vertical positioning of dots % left, top, right, bottom
        rin = [cx-r_inner, location-r_inner+cy, cx+r_inner, location+r_inner+cy];
        rout = [cx-r_outer, location-r_outer+cy, cx+r_outer, location+r_outer+cy];
  
        draw_fix(p);            
            
        if coloured_task == 1
            % sample generated by TOP source coloured blue
            % sample generated by BOTTOM cource coloured orange
            if gener_side<0
                colour=[0 70 0];
            else
                colour=[0 37 255];
            end
        else
            colour = p.stim.bg;
        end
        Screen('FillOval', p.ptb.w, colour-o, rout);
        Screen('FillOval', p.ptb.w, colour+o, rin);

        ActSampleOnset  = Screen('Flip',p.ptb.w, SampleOnset - p.ptb.slack, 0);      %<----- FLIP
        draw_fix(p);
        TimeSampleOffset = Screen('Flip', p.ptb.w, ActSampleOnset + p.sample_duration - p.ptb.slack, 0);     %<----- FLIP
        draw_fix(p); 
    end


    %% -----------------------------------
    %  Helper functions
    %  -----------------------------------

    function p = dump_keys(p)
        %dump the final events
        [keycode, secs] = KbQueueDump(p);%this contains both the pulses and keypresses.
        %log everything but "pulse keys" as pulses, not as keypresses.
%         pulses          = (keycode == KbName(p.keys.pulse));
    end


    function draw_fix(p)
% fixation target as suggested in Vision Research. Volume 76, 14 January 2013, Pages 31-42
% What is the best fixation target? The effect of target shape on stability of fixational eye movements. 
% L.Thalerab, A.C.SchützcM.A.GoodalebdK.R.Gegenfurtnerc
        colorOval = p.stim.fix_target; % color of the two circles [R G B]
        colorCross = p.stim.bg; % color of the Cross [R G B]

        d1 = 0.6; % diameter of outer circle (degrees)
        d2 = 0.14; % diameter of inner circle (degrees)

        Screen('FillOval', p.ptb.w, colorOval, [p.ptb.CrossPosition_x-d1/2 * p.display.ppd, p.ptb.CrossPosition_y-d1/2 * p.display.ppd, p.ptb.CrossPosition_x+d1/2 * p.display.ppd, p.ptb.CrossPosition_y+d1/2 * p.display.ppd], d1 * p.display.ppd);
        Screen('DrawLine', p.ptb.w, colorCross, p.ptb.CrossPosition_x-d1/2 * p.display.ppd, p.ptb.CrossPosition_y, p.ptb.CrossPosition_x+d1/2 * p.display.ppd, p.ptb.CrossPosition_y, d2 * p.display.ppd);
        Screen('DrawLine', p.ptb.w, colorCross, p.ptb.CrossPosition_x, p.ptb.CrossPosition_y-d1/2 * p.display.ppd, p.ptb.CrossPosition_x, p.ptb.CrossPosition_y+d1/2 * p.display.ppd, d2 * p.display.ppd);
        Screen('FillOval', p.ptb.w, colorOval, [p.ptb.CrossPosition_x-d2/2 * p.display.ppd, p.ptb.CrossPosition_y-d2/2 * p.display.ppd, p.ptb.CrossPosition_x+d2/2 * p.display.ppd, p.ptb.CrossPosition_y+d2/2 * p.display.ppd], d2 * p.display.ppd);
%         Screen(p.ptb.w, 'Flip'); 
    end

    function SetParams
        %% relative path to stim and experiments
        %Path Business.
        [~, hostname]                 = system('hostname');
        p.hostname                    = deblank(hostname);

        if strcmp(p.hostname, 'czc0211hsd') % gab72
%             p.display.resolution = [1680 1050]; 
            p.display.dimension = [47.5, 29.5];
            p.display.distance = [62, 59];
            p.stim.bg = [128, 128, 128]; % screen darkers than in the lab - only for script writing and testing
            p.stim.fix_target = [144 144 144]; 
        elseif strcmp(p.hostname, 'DESKTOP-MKKOQUF') % Coimbra lab 94  = ['DESKTOP-MKKOQUF']
%             p.display.resolution = [1600 900]; % CHECK
            p.display.dimension = [52.5, 39.5];
            p.display.distance = [88, 88];
            p.stim.bg = [48 48 48];%[128, 128, 128];
            p.stim.fix_target = [64 64 64]; 
        elseif strcmp(p.hostname, 'cnd0151937') % Coimbra laptop
%             p.display.resolution = [1600 900]; 
            p.display.dimension = [34.5 19.5];
            p.display.distance = [52, 50];
            p.stim.bg = [128, 128, 128];
            p.stim.fix_target = [144 144 144]; 
        else
            p.display.dimension = [34.5 19.5];
            p.display.distance = [52, 50];
            p.stim.bg = [128, 128, 128];
            p.stim.fix_target = [144 144 144]; 
        end
        % find folder with face/house images
        mydir  = pwd; idcs   = strfind(mydir,filesep); newdir = mydir(1:idcs(end)-1);
        p.images_dir = [newdir '\Stanford Vision & Perception Neuroscience Lab'];
%         p.stim.bar_width = 400;
%         p.stim.bar_separation = 50; % check what is this!
        p.stim.r_inner = .1;
        p.stim.lumdiff = 12;%50; % luminance difference within sample fill and outline
        p.stim.sample_duration = .1; % NOT SURE THIS IS RIGHT!!!
        p.subject                       = subject; %subject id
        p.timestamp                     = datestr(now, 30); %the time_stamp of the current experiment.

        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        p.stim.white                = get_color('white');
        p.text.fontname                = 'Courier';
        p.text.fontsize                = 20;
        p.text.fixsize                 = 60;

        %% keys to be used during the experiment:
        % This part is highly specific for your system and recording setup,
        % please enter the correct key identifiers. You can get this information calling the
        % KbName function and replacing the code below for the key below.
        %1, 6 ==> Right
        %2, 7 ==> Left
        %3, 8 ==> Down
        %4, 9 ==> Up (confirm)
        %5    ==> Pulse from the scanner

        KbName('UnifyKeyNames');
%         p.keys.confirm                 = '4$';%
%         p.keys.answer_a                = {'1!', '2@', '3#', '4$'};
        p.keys.answer_a_train          = 'z'; % left
%         p.keys.answer_b                = {'6^', '7&', '8*', '9('};
        p.keys.answer_b_train          = 'm'; % right
%         p.keys.pulse                   = '5%';
        p.keys.up_arrow                = 'UpArrow';
%         p.keys.down_arrow              = 'DownArrow';
        p.keys.down_arrow              = 'LeftArrow';
        p.keys.repeat_training         = 'i';
        p.keys.move_on                 = 'p';        
        p.keys.el_calib                = 'v';
        p.keys.el_valid                = 'c';
        p.keys.escape                  = 'ESCAPE';
        p.keys.enter                   = 'return';
        p.keys.quit                    = 'q';
        p.keylist = {p.keys.answer_a_train,...
            p.keys.answer_b_train, p.keys.up_arrow, p.keys.down_arrow,...
            p.keys.repeat_training, p.keys.move_on, ...
            p.keys.el_calib, p.keys.el_valid, p.keys.enter};
        %% %%%%%%%%%%%%%%%%%%%%%%%%%

        %%
        p.var.current_bg              = p.stim.bg;%current background to be used.
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
        if strcmp(p.hostname, 'czc0211hsd')
            p.ptb.screenNumber          =  max(screens);%the maximum is the second monitor
            [idx, names, ~] = GetKeyboardIndices;
            p.ptb.device = nan;
            for iii = 1:length(idx)
                if strcmp(names{iii}, '')
                    p.ptb.device = idx(iii);
                    break
                end
            end
            fprintf('Device name is: %s\n', names{iii})
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
        else
            p.ptb.screenNumber          = max(screens);%the maximum is the second monitor
            p.ptb.device        = -1;
%             gamma = load('nne_uke_scanner.mat');
%             gamma = [0 0 0; gamma.gammaTable];
%             p.ptb.gamma = gamma;
        end 
          p.ptb.device        = -1; % not sure why this is like this!
%         p.ptb.screenNumber
        %Make everything transparent for debugging purposes.
        if debug == 1
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

%         BackupCluts(); % Maria - something to do with screen gamma
%         tables!!
%         if numel(p.ptb.gamma, 2) > 0
%             [old_table] = Screen('LoadNormalizedGammaTable', p.ptb.w, p.ptb.gamma);
%             p.ptb.gamma_loaded = true;
%             p.ptb.old_gamma = old_table;
%             p.ptb.gamma_loaded = false;
%         else
            p.ptb.gamma_loaded=false;
%         end
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

%         fix  = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y];
% 
%         d = (p.ptb.fc_size(1)^2/2)^.5;
%         p.square = [fix(1)-d, fix(2)-d, fix(1)+d, fix(2)+d];
%         p.FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
%         p.FixCross_s   = [fix(1)-1,fix(2)-p.ptb.fc_size/2,fix(1)+1,fix(2)+p.ptb.fc_size/2;fix(1)-p.ptb.fc_size/2,fix(2)-1,fix(1)+p.ptb.fc_size/2,fix(2)+1];
% %         p = make_dist_textures(p);
%         l = p.ptb.rect(1); t = p.ptb.rect(2); r = p.ptb.rect(3); b = p.ptb.rect(4);
%         p.stim.left_rect = [l, (b-t)/2-5-20, r, (b-t)/2+5-20];
%         p.stim.right_rect = [l, 20+(b-t)/2-5, r, 20+(b-t)/2+5];
             
        
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


    function cleanup
        % Close window:
        RestoreCluts()
        %Screen('flip', p.ptb.w)
        sca;
        %show the cursor
        ShowCursor(p.ptb.screenNumber);
        commandwindow;
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
    end


    function [keycode, secs] = KbQueueDump(p)
        %[keycode, secs] = KbQueueDump
        %   Will dump all the events accumulated in the queue.
        keycode = [];
        secs    = [];
        pressed = [];
        while KbEventAvail(p.ptb.device)
            [evt, n]   = KbEventGet([]);%(p.ptb.device);
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
        theImageLocation = [p.images_dir, '\child-3.jpg'];
        theImage_face = imread(theImageLocation);
        % Make the image into a texture
        imageTexture_face = Screen('MakeTexture', p.ptb.w, theImage_face);

        % House Image
        theImageLocation = [p.images_dir, '\house-3.jpg'];
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
            if strcmp(language, 'PT')
                text3 = ['Se, na altura da resposta,\n', ...
                'a nuvem de cima estiver ativa e aparecer.\n', ...
                'uma casa, responda à direita,\n', ...
                'se aparecer\n', ... 
                'uma cara, responda à esquerda.'];
                text4 = ['Se, na altura da resposta,\n', ...
                'a nuvem de baixo estiver ativa e aparecer.\n', ...
                'uma cara, responda à direita,\n', ...
                'se aparecer\n', ... 
                'uma casa, responda à esquerda.'];
            else
                text3 = ['If just before the decision cue,\n', ...
                    'the top cloud is active\n', ...
                    'and the decision cue is\n', ...
                    'a house, press the right button,\n', ...
                    'if the decision cue is\n', ...
                    'a face, press the left button.'];
                text4 = ['If just before the decision cue,\n', ...
                    'the bottom cloud is active\n', ...
                    'and the decision cue is\n', ...
                    'a face, press the right button,\n', ...
                    'if the decision cue is\n', ...
                    'a house, press the left button.'];
            end
        else
            Screen('DrawTexture', p.ptb.w, imageTexture_house, [], NewImage_Left_Top, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_house, [], NewImage_Right_Bottom, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_face, [], NewImage_Right_Top, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_face, [], NewImage_Left_Bottom, 0);
            if strcmp(language, 'PT')
                text3 = ['Se, na altura da resposta,\n', ...
                'a nuvem de cima estiver ativa e aparecer.\n', ...
                    'uma cara, responda à direita,\n', ...
                    'se aparecer\n', ... 
                    'uma casa, responda à esquerda.'];
                text4 = ['Se, na altura da resposta,\n', ...
                'a nuvem de baixo estiver ativa e aparecer.\n', ...
                    'uma casa, responda à direita,\n', ...
                    'se aparecer\n', ... 
                    'uma cara, responda à esquerda.'];
            else
                text3 = ['If just before the decision cue,\n', ...
                    'the top cloud is active\n', ...
                    'and the decision cue is\n', .....
                    'a face, press the right button,\n', ...
                    'if the decision cue is\n', ...
                    'a house, press the left button.'];
                text4 = ['If just before the decision cue,\n', ...
                    'the bottom cloud is active\n', ...
                    'and the decision cue is\n', ...
                    'a house, press the right button,\n', ...
                    'if the decision cue is\n', ...
                    'a face, press the left button.'];
            end
        end
       
        Screen('DrawTexture', p.ptb.w, fullWindowMask);
        draw_fix(p);
        %DrawFormattedText(win, tstring [, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical][, vSpacing][, righttoleft][, winRect])

        Screen('TextSize', p.ptb.w, 16);
        DrawFormattedText(p.ptb.w, text3, .25*p.ptb.width/10, p.ptb.height/2-img_size*3/4, p.stim.white,[],[],[],2,[]);
        DrawFormattedText(p.ptb.w, text4, .25*p.ptb.width/10, p.ptb.height/2+img_size/4, p.stim.white,[],[],[],2,[]);
        
        Screen('TextSize', p.ptb.w,  20);
        if strcmp(language, 'PT')
            text1 = 'Quando tiver a regra bem memorizada, carregue numa tecla para avançar.';
            DrawFormattedText(p.ptb.w, text1, 'center', 9*p.ptb.height/10, p.stim.white,[],[],[],2,[]);
            text2 = 'Preste atenção e memorize esta regra.';
            DrawFormattedText(p.ptb.w, text2, 'center', 1*p.ptb.height/10, p.stim.white,[],[],[],2,[]);
        else
            text1 = 'Once you have learned the rule, press any key to continue.';
            DrawFormattedText(p.ptb.w, text1, 'center', 9*p.ptb.height/10, p.stim.white,[],[],[],2,[]);
            text2 = 'Pay attention and memorize this rule.';
            DrawFormattedText(p.ptb.w, text2, 'center', 1*p.ptb.height/10, p.stim.white,[],[],[],2,[]);
        end


        %% Flip to the screen
        Screen('Flip', p.ptb.w);

    end
    
    function [correct_trial, text] = hierarchical_decision_accuracy(keycodes, p, gener_side, stim_id, rule)
     text = 'Carregue numa tecla para avançar.';
     correct_trial = 0;
                if ~isnan(keycodes)
                    for iii = 1:length(keycodes)
                        keys = KbName(keycodes(iii));
                        if iii == length(keycodes) % what counts for accuracy is last response
                            if rule == 0
                                if gener_side > 0 && stim_id == 0 % bottom and faces
                                    if strcmp(keys, 'm')
                                       correct_trial = 1;
                                       text = ['Correto! \n', ...  
                                       'Era a nuvem de baixo que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.'];
                                    elseif strcmp(keys, 'z')
                                       text = ['Errado! \n', ...  
                                       'Era a nuvem de baixo que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.'];
                                    end
                                elseif gener_side >0 && stim_id ==1 % bottom and houses 
                                    if strcmp(keys, 'z')
                                       correct_trial = 1;
                                       text = ['Correto! \n', ...  
                                       'Era a nuvem de baixo que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.'];  
                                    elseif strcmp(keys, 'm')
                                       text = ['Errado! \n', ...  
                                       'Era a nuvem de baixo que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.']; 
                                    end
                                elseif gener_side <0 && stim_id ==0 % top and faces
                                    if strcmp(keys, 'z')
                                       correct_trial = 1;
                                       text = ['Correto! \n', ...  
                                       'Era a nuvem de cima que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.'];  
                                    elseif strcmp(keys, 'm')
                                       text = ['Errado! \n', ...  
                                       'Era a nuvem de cima que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.'];  
                                    end
                                elseif gener_side < 0 && stim_id == 1 % top and houses
                                    if strcmp(keys, 'm')
                                       correct_trial = 1;
                                       text = ['Correto! \n', ...  
                                       'Era a nuvem de cima que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.']; 
                                    elseif strcmp(keys, 'z')
                                       text = ['Errado! \n', ...  
                                       'Era a nuvem de cima que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.'];  
                                    end
                                end
                            elseif rule == 1    
                                 if gener_side > 0 && stim_id == 0 % bottom and faces
                                    if strcmp(keys, 'z')
                                       correct_trial = 1;
                                       text = ['Correto! \n', ...  
                                       'Era a nuvem de baixo que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.']; 
                                    elseif strcmp(keys, 'm')
                                       text = ['Errado! \n', ...  
                                       'Era a nuvem de baixo que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.'];  
                                    end
                                elseif gener_side >0 && stim_id ==1 % bottom and houses 
                                    if strcmp(keys, 'm')
                                       correct_trial = 1;
                                      text = ['Correto! \n', ...  
                                       'Era a nuvem de baixo que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.'];  
                                    elseif strcmp(keys, 'z')
                                       text = ['Errado! \n', ...  
                                       'Era a nuvem de baixo que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.'];  
                                    end
                                elseif gener_side <0 && stim_id ==0 % top and faces
                                    if strcmp(keys, 'm')
                                       correct_trial = 1;
                                       text = ['Correto! \n', ...  
                                       'Era a nuvem de cima que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.']; 
                                    elseif strcmp(keys, 'z')
                                       text = ['Errado! \n', ...  
                                       'Era a nuvem de cima que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.'];
                                    end
                                elseif gener_side < 0 && stim_id == 1 % top and houses
                                    if strcmp(keys, 'z')
                                       correct_trial = 1;
                                       text = ['Correto! \n', ...
                                       'Era a nuvem de cima que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.'];  
                                    elseif strcmp(keys, 'm')
                                       text = ['Errado! \n', ...
                                       'Era a nuvem de cima que estava ativa.\n\n', ...
                                       'Carregue numa tecla para avançar.'];
                                    end
                                 end 
                            end
                        end
                    end
                else
                   text = ['Não respondeu ou resposta lenta de mais.\n\n', ...
                           'Carregue numa tecla para avançar.'];
                end
    end

    function show_probability_distributions(p)
    % show image with example of samples from both distributions
    if strcmp(language, 'PT')
        text1 = 'Aqui estão representadas a azul e a verde duas nuvens geradoras de pontos.';
        text2 = ['Neste teste, vários pontos serão apresentados\n'...
            'sequencialmente, numa linha vertical.\n'...
            'O objetivo é conseguir estimar qual das\n'... 
            'nuvens gera os pontos apresentados.'];
        text3 = 'Carregue numa tecla para avançar.'; 
    else
        text1 = 'Below, two dots-generating clouds are represented in blue and green.';
        text2 = ['In this test, several dots will be presented\n' ...
            'sequentially, in a vertical line.\n' ...
            'The goal is to be able to estimate which\n' ...
            'cloud is generating the dots presented.'];
        text3 = 'Press any key to continue.';        
    end
    
     % Here we load an image from file.
    if strcmp(p.hostname, 'czc0211hsd') %gab72
        theImageLocation = [pwd, '\generative_processes_easy_SNR_2_5_gab92.jpg'];
    elseif strcmp(p.hostname, 'DESKTOP-MKKOQUF') % Coimbra lab 94 
        theImageLocation = [pwd, '\generative_processes_easy_SNR_2_5_lab94.jpg'];
    else
        theImageLocation = [pwd, '\generative_processes_easy_SNR_2_5.jpg'];
    end
    theImage_example = imread(theImageLocation);
    % Make the image into a texture
    imageTexture_example = Screen('MakeTexture', p.ptb.w, theImage_example);
    Screen('DrawTexture', p.ptb.w, imageTexture_example);
    %load text
    DrawFormattedText(p.ptb.w, text1, 'center',  p.ptb.CrossPosition_y-400, p.stim.white,[],[],[],2,[]);
    Screen('TextSize', p.ptb.w, 18);
    DrawFormattedText(p.ptb.w, text2, .25*p.ptb.width/10, 'center', p.stim.white,[],[],[],2,[]);
    Screen('TextSize', p.ptb.w, 20);
    DrawFormattedText(p.ptb.w, text3, 'center', p.ptb.CrossPosition_y+400, p.stim.white,[],[],[],2,[]);
   
    Screen('Flip', p.ptb.w);
    [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
    key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), return, end
    % Screen('Flip', p.ptb.w);
    block = 1;% easy version
        % PHASE 1 - example of bottom distribution
        if strcmp(language, 'PT')
            text = ['Agora, vamos mostrar uma sequência de pontos com origem na nuvem inferior.\n\n'...
                'Carregue numa tecla para avançar.'];
        else
            text = ['Now, we are going to show a sequence of dots drawn from the lower cloud.\n\n'...
                'Press any key to advance.'];
        end
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        Screen('Flip', p.ptb.w);
        [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
        key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), return, end
        draw_fix(p); coloured_task = 1;
%         [seq, es] = make_glaze_block_training_sequences(trials, sigma, threshold, question_trials, set_side)
        [seq,~] = make_glaze_block_training_sequences(25, p.sd(block), p.location_of_mean(block), 0, 1);
        ActSampleOnset = GetSecs; p.seq.phase1 = seq;
         for trial  = 1:25
            %Get the variables that Trial function needs.
            stim_id       = seq.stim(trial);
            type          = seq.type(trial);
            location      = seq.sample(trial);
            gener_side    = seq.generating_side(trial);
            OnsetTime     = ActSampleOnset + 0.4; % ISI = 400 ms
            % Show a single sample
            [ActSampleOnset, p] = show_one_sample(p, OnsetTime, location, gener_side, coloured_task);
         end

         WaitSecs(1);
         Screen('Flip', p.ptb.w);
        % notice that and second phase - example of top distribution
        if strcmp(language, 'PT')
            text = ['Note que na sequência anterior apesar da maioria dos pontos se encontrarem \n'...
                'a baixo do alvo de fixação, alguns apareceram acima do alvo de fixação.\n\n', ...
                'Carregue numa tecla para avançar.'];
        else
            text = ['Note that in the previous sequence despite the fact that most dots were\n' ...
                'below the fixation target, some appeared above the fixation target.\n\n', ...
                'Press any key to continue.'];            
        end
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        Screen('Flip', p.ptb.w);
        [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
        key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), return, end
        % PHASE 2
        if strcmp(language, 'PT')
            text = ['A seguir, vamos apresentar uma sequência de pontos com origem na nuvem superior.\n\n', ...
                'Carregue numa tecla para avançar.'];
        else
            text = ['Next, we will present a sequence of dots originating from the upper cloud.\n\n', ...
                'Press any key to continue.'];          
        end
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        Screen('Flip', p.ptb.w);
        [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
        key_pressed = KbName(keyCode);
        draw_fix(p); coloured_task = 1;
%       [seq, es] = make_glaze_block_training_sequences(trials, sigma, threshold, question_trials, set_side)
        [seq,~] = make_glaze_block_training_sequences(25, p.sd(block), p.location_of_mean(block), 0, -1);
        ActSampleOnset = GetSecs; p.seq.phase2 = seq;
         for trial  = 1:25
            %Get the variables that Trial function needs.
            stim_id       = seq.stim(trial);
            type          = seq.type(trial);
            location      = seq.sample(trial);
            gener_side    = seq.generating_side(trial);
            OnsetTime     = ActSampleOnset + 0.4; % ISI = 400 ms
            % Show a single sample
            [ActSampleOnset, p] = show_one_sample(p, OnsetTime, location, gener_side, coloured_task);
         end
    end

    function p = inference_task(p, coloured_task, block, number_of_trials)              
            correct = 0; trial_number = 0;
            keys_repeat_training = {'i'}; run = 0;
         while strcmp(keys_repeat_training, 'i')
                run = run+1;
            %         [seq, es] = make_glaze_block_training_sequences(trials, sigma, threshold, question_trials, set_side)
            [seq,~] = make_glaze_block_training_sequences(number_of_trials, p.sd(block), p.location_of_mean(block), 1, 0);
            ActSampleOnset = GetSecs; 
            % save sequences used
            if coloured_task == 1, p.seq.phase3{run} = seq; elseif coloured_task == 0 && block == 1, p.seq.phase4{run} = seq;
            elseif coloured_task == 0 && block == 2, p.seq.phase5{run} = seq; end
            
             for trial  = 1:number_of_trials
                %Get the variables that Trial function needs.
                stim_id       = seq.stim(trial);
                type          = seq.type(trial);
                location      = seq.sample(trial);
                gener_side    = seq.generating_side(trial);
                OnsetTime     = ActSampleOnset + 0.4; % ISI = 400 ms

                if type == 0 % Show a single sample
                    [ActSampleOnset, p] = show_one_sample(p, OnsetTime, location, gener_side, coloured_task);
                elseif type == 1 % Choice trial.
                    trial_number = trial_number+1;
                    [p, response] = visual_cue_trial(p);
                    if strcmp(language, 'PT')
                        text_correct = 'Correto!\n';
                        text_wrong = 'Errado!\n';
                        text_lower = ['Era a nuvem de baixo que estava ativa.\n\n', ...
                               'Carregue numa tecla para avançar.'];
                        text_upper = ['Era a nuvem de cima que estava ativa.\n\n', ...
                               'Carregue numa tecla para avançar.'];
                        text_wrong_key = ['Carregou na tecla errada.\n\n', ...
                           'Carregue numa tecla para avançar.'];
                    else
                        text_correct = 'Correct!\n';
                        text_wrong = 'Wrong!\n';
                        text_lower = ['It was the lower cloud that was active. \n\n', ...
                               'Press any key to continue.'];
                        text_upper = ['It was the upper cloud that was active. \n\n', ...
                               'Press any key to continue.'];
                        text_wrong_key = ['You pressed the wrong key. \n\n', ...
                           'Press any key to continue.'];
                    end

                    if gener_side>0 && response == 1
                       correct = correct+1;
                       text = [text_correct, text_lower];
                    elseif gener_side<0 && response == 0
                        correct = correct+1;
                        text = [text_correct, text_upper];
                    elseif gener_side>0 && response == 0
                       text = [text_wrong, text_lower];
                    elseif gener_side<0 && response == 1
                       text = [text_wrong, text_upper];
                    else
                       text = text_wrong_key;
                    end
                    DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
                    Screen('Flip', p.ptb.w);
                    [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
                    key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end
                    ActSampleOnset = GetSecs;
                end
                p = dump_keys(p);

                if abort
                    break
                end

             end

            % feedback
            Screen('Flip', p.ptb.w); % clear fixation cross
            % save accuracy on p variable
            if coloured_task == 1, p.accuracy.phase3_easy_coloured{run} = correct/trial_number; elseif coloured_task == 0 && block == 1, p.accuracy.phase4_easy{run} = correct/trial_number;
            elseif coloured_task == 0 && block == 2, p.accuracy.phase5_difficult{run} = correct/trial_number; end
            if strcmp(language, 'PT')
                text = [sprintf('Nesta sessão acertou %2.0f%% das respostas.\n\n', 100*correct/trial_number),...
                    'Para repetir a sessão pressione a tecla I. Para avançar pressione a tecla P.'];
            else
                 text = [sprintf('In this session, you got %2.0f%% correct answers.\n\n', 100*correct/trial_number),...
                    'If you want to repeat the block, press the I key, otherwise press the P key to proceed.'];               
            end
            DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
            Screen('Flip', p.ptb.w);

            % record responses
            while 1
                [~, keyStateVec] = KbWait((p.ptb.device), 2);
                keycodes=find(keyStateVec==1);
                keys_repeat_training = KbName(keycodes(1));
                if strcmp(keys_repeat_training, 'q') || strcmp(keys_repeat_training, 'p') || strcmp(keys_repeat_training, 'i')
                    break
                end
            end
         end
         p = dump_keys(p);
    end


    %% Hierarchical decisions training phase
    % PHASE 5 and 6
    function p = hierarchical_decisions_training_phase(p, block, number_of_trials)
        if strcmp(language, 'PT')
            text = ['Nesta parte do treino, as respostas terão em conta não só qual a nuvem ativa,\n'...
                        'mas também qual a imagem que aparece a indicar que tem de tomar uma decisão.\n\n'...
                        'Essa imagem pode ser uma cara ou uma casa.\n\n'...
                        'Terá de responder de acordo com a regra que será mostrada a seguir.\n\n'...
                        'Use a tecla Z para resposta à esquerda com o indicador esquerdo.\n'...
                        'Use a tecla M para resposta à direita com o indicador direito.\n\n'...
                        'Carregue numa tecla para avançar.\n'];
        else
            text = ['In this part of the training, the answers will take into account not only which cloud is active,\n' ...
                        'but also which image appears indicating that you have to make a decision.\n\n' ...
                        'This image can be a face or a house.\n\n' ...
                        'You will have to answer according to the rule that will be shown next.\n\n' ...
                        'Use the Z key to answer on the left with the left index finger.\n'...
                        'Use the M key to answer on the right with the right index finger.\n\n' ...
                        'Press any key to continue.\n'];
        end
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        Screen('Flip', p.ptb.w);
        [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
        key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), return, end     

        rule_explained(p, rule_hierarchical_decision); KbStrokeWait(p.ptb.device);

        % for rule_hierarchical_decision = [0, 1]
        run_colour = 0; run_no_colour = 0;
        for coloured_task = [1 0] % first run with colours then without colours

            if coloured_task == 1 % PHASE 5
                if strcmp(language, 'PT')
                    text = ['Numa primeira fase, poderá usar as cores para inferir qual a nuvem ativa.\n\n'...
                        'Verde = nuvem superior. Azul = nuvem inferior.\n\n'...
                        'Após o aparecimento da imagem, tem dois segundos para responder.\n\n'...
                        'Carregue numa tecla para avançar.\n'];
                else
                    text = ['In a first phase, you can use the colours to infer which cloud is active.\n\n' ...
                        'Green = upper cloud. Blue = lower cloud.\n\n'...
                        'After the image appears, you have two seconds to respond.\n\n' ...
                        'Press any key to continue.\n'];
                end
                DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
                Screen('Flip', p.ptb.w);
                [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
                key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end   
            else % PHASE 6
                if strcmp(language, 'PT')
                    text = ['Agora terá de inferir qual a nuvem ativa sem a ajuda das cores.\n\n'...    
                        'A representação visual da regra será mostrada a seguir.\n\n'...
                        'Carregue numa tecla para avançar.\n'];
                else
                    text = ['Now you will have to infer which cloud is active without the help of the colors.\n\n' ...
                        'The visual representation of the rule will be shown next.\n\n' ...
                        'Press any key to continue. \ N'];
                end
                DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
                Screen('Flip', p.ptb.w);
                [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
                key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end   
                % show rule
                rule_explained(p, rule_hierarchical_decision); KbStrokeWait(p.ptb.device);
            end 

            keys_repeat_training = {'i'};
            while strcmp(keys_repeat_training, 'i') % for repeating run if necessary

                % [seq, es] = make_glaze_block_training_sequences(trials, sigma, threshold, question_trials, set_side)
                [seq,~] = make_glaze_block_training_sequences(400, p.sd(block), p.location_of_mean(block), 1, 0);
                if coloured_task == 1
                    run_colour = run_colour+1; 
                    p.seq.phase6_color{run_colour} = seq;
                else
                    run_no_colour = run_no_colour+1;
                    p.seq.phase7_no_color{run_no_colour} = seq;
                end

                if (coloured_task == 1 && run_colour>1) ||  (coloured_task == 0 && run_no_colour>1)
                    % show rule to remind participant on second try
                    rule_explained(p, rule_hierarchical_decision); KbStrokeWait(p.ptb.device);
                end


                %% image files to load
                % dir with face or house images files
                face_dir = [p.images_dir, '\selected_faces_adults_similar_lum_centered'];
                house_dir = [p.images_dir, '\selected_houses_similar_lum_centered'];
                % check how many choice stimulus of each type for this run
                number_face_stim = length(find(seq.stim == 0));
                number_house_stim = length(find(seq.stim == 1));
                Files = dir(fullfile(face_dir,'*.jpg'));
                file_order_faces = randperm(size(Files, 1)); 
                p.choice_trials.file_order_faces = file_order_faces(1:number_face_stim);
                for numb_files=1:number_face_stim
                    p.choice_trials.file_names_faces{numb_files, 1} = fullfile(Files(file_order_faces(numb_files)).folder, Files(file_order_faces(numb_files)).name);
                end
                Files = dir(fullfile(house_dir,'*.jpg'));
                file_order_houses = randperm(size(Files, 1));
                p.choice_trials.file_order_houses = file_order_houses(1:number_house_stim);
                for numb_files=1:number_house_stim
                    p.choice_trials.file_names_houses{numb_files, 1} = fullfile(Files(file_order_houses(numb_files)).folder, Files(file_order_houses(numb_files)).name);
                end

                draw_fix(p);
                correct = 0; trial_number = 0;
                count_faces = 0; count_houses = 0; % to determine which image to show
                ActSampleOnset = GetSecs;
                for trial  = 1:number_of_trials%size(p.sequence.stim, 2)
                    %Get the variables that Trial function needs.
                    stim_id       = seq.stim(trial);
                    type          = seq.type(trial);
                    location      = seq.sample(trial);
                    gener_side    = seq.generating_side(trial);
                    OnsetTime     = ActSampleOnset + 0.4; % ISI = 400 ms

                    if type == 0
                        % Show a single sample
                        [ActSampleOnset, p] = show_one_sample(p, OnsetTime, location, gener_side, coloured_task);
                    elseif type == 1 % Choice trial.
                        trial_number = trial_number+1;
                        if stim_id == 0
                            count_faces = count_faces+1;
                            theImageLocation = p.choice_trials.file_names_faces{count_faces};
                        elseif stim_id == 1
                            count_houses = count_houses+1;
                            theImageLocation = p.choice_trials.file_names_houses{count_houses};
                        end
%                             fprintf('\nCHOICE TRIAL; stim_id:%i, gener_side:%02.2f ', stim_id, gener_side>0);
                        [p, ~, keycodes, ~, abort] = choice_trial(p, OnsetTime, theImageLocation);
                        % analysis accuracy of responses
                        [correct_trial, text] = hierarchical_decision_accuracy(keycodes, p, gener_side, stim_id, rule_hierarchical_decision);
                        correct = correct + correct_trial;
                        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
                        Screen('Flip', p.ptb.w);
                        [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
                        key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end     
                        ActSampleOnset = GetSecs;
                        p = dump_keys(p);
                    end
                end
                Screen('Flip', p.ptb.w); % clear fixation cross
                % record accuracy
                if coloured_task == 1
                    p.accuracy.phase6_color{run_colour} = correct/trial_number;
                else
                    p.accuracy.phase7_no_color{run_no_colour} = correct/trial_number;
                end
                % feedback
                if strcmp(language, 'PT')
                    text = [sprintf('Neste bloco acertou %2.0f%% das respostas.\n\n', 100*correct/trial_number),...
                    'Para repetir o bloco pressione a tecla I; para avançar pressione a tecla P.'];
                else
                    text = [sprintf('In this session, you got %2.0f%% correct responses.\n\n', 100*correct/trial_number),...
                    'If you want to repeat the session, press the I key, otherwise press the P key to proceed.']; 
                end
                DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*0.5), p.stim.white,[],[],[],2,[]);
                Screen('Flip', p.ptb.w);
                while 1
                    % record responses
                    [~, keyStateVec] = KbWait((p.ptb.device), 2);
                    keycodes=find(keyStateVec==1);
                    keys_repeat_training = KbName(keycodes(1));
                   if strcmp(keys_repeat_training , 'q') || strcmp(keys_repeat_training , 'p') || strcmp(keys_repeat_training , 'i')
                       break
                   end
                end
            end  
        end
    end

end
