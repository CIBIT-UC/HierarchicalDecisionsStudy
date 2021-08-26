function [p]=hierarchical_decisions_task_training_scanner(subject, rule_hierarchical_decision, fmri, feedback, language)
% subject = string with subject ID
% rule_hierarchical_decision = 0 or 1 - rule counterbalanced across
% feedback = 0 (no feedback); = 1 (feedback after each choice trial)
% language = 'PT'; = 'EN'
% participants
% press 'q' at time of response to quit
rng('shuffle'); % to be really random!
% NoEyelink = 1; %is Eyelink wanted?
debug   = 0; % debug mode => 1: transparent window enabling viewing the background.
small_window = 0; % Open a small window only

% close ports - scanner
IOPort('CloseAll');

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
% distance between means = 0.5 (threshold = 0.25); sd = 0.4; SNR = 1.25

if fmri == 0
    KbQueueStop(p.ptb.device);
    KbQueueRelease(p.ptb.device);
else
    p.LuminaHandle = IOPort('OpenSerialPort','COM4'); 
    IOPort('Flush',p.LuminaHandle); 
    KbName('UnifyKeyNames')
end

while 1
    p.location_of_mean = [0.5, 0.25]; p.sd = [0.4, 0.4];
    coloured_task = 0;

    %% hierarchical decisions training phase
    block = 2;
    number_of_trials = 400;
    p = hierarchical_decisions_training_phase(p, block, number_of_trials);

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

   function [p, RT, keycodes, response_times, abort] = choice_trial(p, ChoiceStimOnset, theImageLocation)
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
%         start_rt_counter  = TimeStimOnset;
        % record responses
        keycodes = []; RT = []; response_times = [];
        if fmri == 1
            while GetSecs<TimeStimOnset+ 0.2-p.ptb.slack
                % listen to button presses      
                [key,timestamp,~] = IOPort('Read',p.LuminaHandle);
                if ~isempty(key)
                    IOPort('Flush',p.LuminaHandle);
                    % Save responses 
                    keycodes = [keycodes, key];
                    reaction_time = timestamp - TimeStimOnset;
                    RT = [RT; reaction_time];
                    response_times = [response_times; timestamp];
                end
            end
        end
        
        TimeStimOffset  = Screen('Flip', p.ptb.w, TimeStimOnset+.2 -p.ptb.slack, 0);  %<----- FLIP             
        if fmri == 1
            while GetSecs<TimeStimOffset+1.8
                % listen to button presses      
                [key,timestamp,~] = IOPort('Read',p.LuminaHandle);
                if ~isempty(key)
                    IOPort('Flush',p.LuminaHandle);
                    % Save responses 
                    keycodes = [keycodes, key];
                    reaction_time = timestamp - TimeStimOnset;
                    RT = [RT; reaction_time];
                    response_times = [response_times; timestamp];
                end
            end 
        else
            WaitSecs(1.8);
            % Now record response
            [keycodes, response_times] = KbQueueDump(p);
            RT = response_times - TimeStimOnset;
            key_pressed = KbName(keycodes); if strcmp(key_pressed, 'q'), abort = 1; end
        end
   end


    function [TimeSampleOffset, p] = show_one_sample(p, SampleOnset, location, gener_side, coloured_task)
        % Show one sample, such that black and white parts cancel.
        r_inner = p.stim.r_inner;
        o = p.stim.lumdiff;
        p.sample_duration=p.stim.sample_duration;
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
        ActSampleOnset  = Screen('Flip',p.ptb.w, SampleOnset, 0);      %<----- FLIP
        draw_fix(p);
        TimeSampleOffset = Screen('Flip',p.ptb.w,ActSampleOnset+p.sample_duration, 0);     %<----- FLIP
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

        colorOval = p.stim.fix_target; % color of the two circles [R G B]
        colorCross = p.stim.bg; % color of the Cross [R G B]

        d1 = 0.6; % diameter of outer circle (degrees)
        d2 = 0.14; %0.2; % diameter of inner circle (degrees)

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
            p.stim.lumdiff = 12;%50; % luminance difference within sample fill and outline
        elseif strcmp(p.hostname, 'DESKTOP-MKKOQUF') % Coimbra lab 94  = ['DESKTOP-MKKOQUF']
%             p.display.resolution = [1600 900]; % CHECK
            p.display.dimension = [34.5 19.5]; % CHECK
            p.display.distance = [52, 50];% CHECK
            p.stim.bg = [48 48 48];%[128, 128, 128];
            p.stim.fix_target = [64 64 64]; 
            p.stim.lumdiff = 12;%50; % luminance difference within sample fill and outline
        elseif strcmp(p.hostname, 'cnd0151937') % Coimbra laptop
%             p.display.resolution = [1600 900]; 
            p.display.dimension = [34.5 19.5];
            p.display.distance = [52, 50];
            p.stim.bg = [128, 128, 128];
            p.stim.fix_target = [144 144 144]; 
            p.stim.lumdiff = 12;%50; % luminance difference within sample fill and outline
       elseif  strcmp(p.hostname, 'DESKTOP-TKTCOK0') % MRI SCANNER - CHECK CODE
            p.display.dimension = [87.8 48.5];
            p.display.distance = [175, 182.5];
%             p.path.baselocation = [pwd '\exp_data\' subject filesep 'session' num2str(session) filesep 'run' num2str(run)];
            p.stim.bg  = [92 92 92];
            p.stim.fix_target = [105 105 105];
            p.stim.lumdiff = 10;%50; % luminance difference within sample fill and outline
            % dir with car and house image files
%             p.images_dir = [pwd '\Stanford Vision & Perception Neuroscience Lab']; 
        else
            p.display.dimension = [34.5 19.5];
            p.display.distance = [52, 50];
            p.stim.bg = [128, 128, 128];
            p.stim.fix_target = [144 144 144];
            p.stim.lumdiff = 12;%50; % luminance difference within sample fill and outline
        end
        % find folder with face/house images
        mydir  = pwd; idcs   = strfind(mydir,filesep); newdir = mydir(1:idcs(end)-1);
        p.images_dir = [newdir '\Stanford Vision & Perception Neuroscience Lab'];
%         p.stim.bar_width = 400;
%         p.stim.bar_separation = 50; % check what is this!
        p.stim.r_inner = .1;
        p.stim.sample_duration = .1;
        p.subject                       = subject; %subject id
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
%                 p.LuminaHandle = IOPort('OpenSerialPort','COM4');
%                 IOPort('Flush',p.LuminaHandle);     
        end
        
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
% %         p.keys.confirm                 = '4$';%
% %         p.keys.answer_a                = {'1!', '2@', '3#', '4$'};
%         p.keys.answer_a_train          = 'z'; % left
% %         p.keys.answer_b                = {'6^', '7&', '8*', '9('};
%         p.keys.answer_b_train          = 'm'; % right
% %         p.keys.pulse                   = '5%';
%         p.keys.up_arrow                = 'UpArrow';
% %         p.keys.down_arrow              = 'DownArrow';
%         p.keys.down_arrow              = 'LeftArrow';
%         p.keys.repeat_training         = 'i';
%         p.keys.move_on                 = 'p';        
%         p.keys.el_calib                = 'v';
%         p.keys.el_valid                = 'c';
%         p.keys.escape                  = 'ESCAPE';
%         p.keys.enter                   = 'return';
%         p.keys.quit                    = 'q';
%         p.keylist = {p.keys.answer_a_train,...
%             p.keys.answer_b_train, p.keys.up_arrow, p.keys.down_arrow,...
%             p.keys.repeat_training, p.keys.move_on, ...
%             p.keys.el_calib, p.keys.el_valid, p.keys.enter};
        %% %%%%%%%%%%%%%%%%%%%%%%%%%

        %%
%         p.var.current_bg              = p.stim.bg;%current background to be used.
    end


    function SetPTB
        %Sets the parameters related to the PTB toolbox. Including
        %fontsizes, font names.
        %Default parameters
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        Screen('Preference', 'TextAntiAliasing',2);%enable textantialiasing high quality
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
%         p.ptb.keysOfInterest = [];
%         for i = fields(p.keys)'
%             p.ptb.keysOfInterest = [p.ptb.keysOfInterest KbName(p.keys.(i{1}))];
%         end
%         RestrictKeysForKbCheck(p.ptb.keysOfInterest);
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
        theImageLocation = [p.images_dir, '\car-27.jpg'];
        theImage_car = imread(theImageLocation);
        % Make the image into a texture
        imageTexture_car = Screen('MakeTexture', p.ptb.w, theImage_car);

        % House Image
        theImageLocation = [p.images_dir, '\house-38.jpg'];
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
            Screen('DrawTexture', p.ptb.w, imageTexture_car, [], NewImage_Left_Top, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_car, [], NewImage_Right_Bottom, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_house, [], NewImage_Right_Top, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_house, [], NewImage_Left_Bottom, 0);
            if strcmp(language, 'PT')
                text3 = ['Se, na altura da resposta,\n', ...
                'a nuvem de cima estiver ativa e aparecer.\n', ...
                'uma casa, responda � direita,\n', ...
                'se aparecer\n', ... 
                'um carro, responda � esquerda.'];
                text4 = ['Se, na altura da resposta,\n', ...
                'a nuvem de baixo estiver ativa e aparecer.\n', ...
                'um carro, responda � direita,\n', ...
                'se aparecer\n', ... 
                'uma casa, responda � esquerda.'];
            else
                text3 = ['If just before the decision cue,\n', ...
                    'the top cloud is active\n', ...
                    'and the decision cue is\n', ...
                    'a house, press the right button,\n', ...
                    'if the decision cue is\n', ...
                    'a car, press the left button.'];
                text4 = ['If just before the decision cue,\n', ...
                    'the bottom cloud is active\n', ...
                    'and the decision cue is\n', ...
                    'a car, press the right button,\n', ...
                    'if the decision cue is\n', ...
                    'a house, press the left button.'];
            end
        else
            Screen('DrawTexture', p.ptb.w, imageTexture_house, [], NewImage_Left_Top, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_house, [], NewImage_Right_Bottom, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_car, [], NewImage_Right_Top, 0);
            Screen('DrawTexture', p.ptb.w, imageTexture_car, [], NewImage_Left_Bottom, 0);
            if strcmp(language, 'PT')
                text3 = ['Se, na altura da resposta,\n', ...
                'a nuvem de cima estiver ativa e aparecer.\n', ...
                    'um carro, responda � direita,\n', ...
                    'se aparecer\n', ... 
                    'uma casa, responda � esquerda.'];
                text4 = ['Se, na altura da resposta,\n', ...
                'a nuvem de baixo estiver ativa e aparecer.\n', ...
                    'uma casa, responda � direita,\n', ...
                    'se aparecer\n', ... 
                    'um carro, responda � esquerda.'];
            else
                text3 = ['If just before the decision cue,\n', ...
                    'the top cloud is active\n', ...
                    'and the decision cue is\n', .....
                    'a car, press the right button,\n', ...
                    'if the decision cue is\n', ...
                    'a house, press the left button.'];
                text4 = ['If just before the decision cue,\n', ...
                    'the bottom cloud is active\n', ...
                    'and the decision cue is\n', ...
                    'a house, press the right button,\n', ...
                    'if the decision cue is\n', ...
                    'a car, press the left button.'];
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
            text1 = 'Quando tiver a regra bem memorizada, carregue numa tecla para avan�ar.';
            DrawFormattedText(p.ptb.w, text1, 'center', 9*p.ptb.height/10, p.stim.white,[],[],[],2,[]);
            text2 = 'Preste aten��o e memorize esta regra.';
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
    
    function [correct_trial, text] = hierarchical_decision_accuracy(keycodes,gener_side, stim_id, rule)
     if strcmp(language, 'PT')
        text = 'Carregue numa tecla para avan�ar.';
     else 
         text = 'Press any key to continue.';
     end
     text_bottom_PT = 'Era a nuvem de baixo que estava ativa.\n\n Carregue numa tecla para avan�ar.';  
     text_top_PT = 'Era a nuvem de cima que estava ativa.\n\n Carregue numa tecla para avan�ar.';  
     text_bottom_EN = 'It was the bottom cloud that was active. \n\n Press any key to continue.';  
     text_top_EN = 'It was the top cloud that was active.\n\n Press any key to continue.';  
     correct_trial = 0;
        if ~isnan(keycodes)
            for iii = 1:length(keycodes)
                if fmri == 0
                    keys = KbName(keycodes(iii));
                else
                    keys = num2str(keycodes(iii));
                end
                if iii == length(keycodes) % what counts for accuracy is last response
                    if strcmp(language, 'PT')
                        if rule == 0
                            if gener_side > 0 && stim_id == 0 % bottom and faces
                                if strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   correct_trial = 1;
                                   text = ['Correto! \n', text_bottom_PT];
                                elseif strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   text = ['Errado! \n', text_bottom_PT];
                                end
                            elseif gener_side >0 && stim_id ==1 % bottom and houses 
                                if strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   correct_trial = 1;
                                   text = ['Correto! \n', text_bottom_PT];  
                                elseif strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   text = ['Errado! \n', text_bottom_PT]; 
                                end
                            elseif gener_side <0 && stim_id ==0 % top and faces
                                if strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   correct_trial = 1;
                                   text = ['Correto! \n', text_top_PT'];  
                                elseif strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   text = ['Errado! \n', text_top_PT];  
                                end
                            elseif gener_side < 0 && stim_id == 1 % top and houses
                                if strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   correct_trial = 1;
                                   text = ['Correto! \n', text_top_PT]; 
                                elseif strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   text = ['Errado! \n', text_top_PT];
                                end
                            end
                        elseif rule == 1    
                             if gener_side > 0 && stim_id == 0 % bottom and faces
                                if strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   correct_trial = 1;
                                   text = ['Correto! \n', text_bottom_PT]; 
                                elseif strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   text = ['Errado! \n', text_bottom_PT];  
                                end
                            elseif gener_side >0 && stim_id ==1 % bottom and houses 
                                if strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   correct_trial = 1;
                                  text = ['Correto! \n', text_bottom_PT];  
                                elseif strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   text = ['Errado! \n', text_bottom_PT];  
                                end
                            elseif gener_side <0 && stim_id ==0 % top and faces
                                if strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   correct_trial = 1;
                                   text = ['Correto! \n',  text_top_PT]; 
                                elseif strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   text = ['Errado! \n', text_top_PT];
                                end
                            elseif gener_side < 0 && stim_id == 1 % top and houses
                                if strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   correct_trial = 1;
                                   text = ['Correto! \n',  text_top_PT];  
                                elseif strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   text = ['Errado! \n',  text_top_PT];
                                end
                             end 
                        end
                    else
                        if rule == 0
                            if gener_side > 0 && stim_id == 0 % bottom and faces
                                if strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   correct_trial = 1;
                                   text = ['Correct! \n', text_bottom_EN];
                                elseif strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   text = ['Wrong! \n', text_bottom_EN];
                                end
                            elseif gener_side >0 && stim_id ==1 % bottom and houses 
                                if strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   correct_trial = 1;
                                   text = ['Correct! \n', text_bottom_EN];
                                elseif strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   text = ['Wrong! \n', text_bottom_EN]; 
                                end
                            elseif gener_side <0 && stim_id ==0 % top and faces
                                if strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   correct_trial = 1;
                                   text = ['Correct! \n', text_top_EN];  
                                elseif strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   text = ['Wrong! \n', text_top_EN];  
                                end
                            elseif gener_side < 0 && stim_id == 1 % top and houses
                                if strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   correct_trial = 1;
                                   text = ['Correct! \n', text_top_EN]; 
                                elseif strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   text = ['Wrong! \n', text_top_EN];  
                                end
                            end
                        elseif rule == 1    
                             if gener_side > 0 && stim_id == 0 % bottom and faces
                                if strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   correct_trial = 1;
                                   text = ['Correct! \n', text_bottom_EN]; 
                                elseif strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   text = ['Wrong! \n', text_bottom_EN];   
                                end
                            elseif gener_side >0 && stim_id ==1 % bottom and houses 
                                if strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   correct_trial = 1;
                                  text = ['Correct! \n', text_bottom_EN];  
                                elseif strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   text = ['Wrong! \n', text_bottom_EN];  
                                end
                            elseif gener_side <0 && stim_id ==0 % top and faces
                                if strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   correct_trial = 1;
                                   text = ['Correct! \n', text_top_EN]; 
                                elseif strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   text = ['Wrong! \n', text_top_EN];
                                end
                            elseif gener_side < 0 && stim_id == 1 % top and houses
                                if strcmp(keys, 'z') || strcmp(keys, '49') || strcmp(keys, '50')
                                   correct_trial = 1;
                                   text = ['Correct! \n', text_top_EN];  
                                elseif strcmp(keys, 'm') || strcmp(keys, '51') || strcmp(keys, '52')
                                   text = ['Wrong! \n', text_top_EN];
                                end
                            end 
                       end
                   end
                end
            end
        else
            if strcmp(language, 'PT')
                text = ['N�o respondeu ou resposta lenta de mais.\n\n', ...
                   'Carregue numa tecla para avan�ar.'];
            else
                text = ['No response or response too slow. \n\n', ...
                   'Press any key to continue.'];
            end
        end
    end

    %% Hierarchical decisions training
    function p = hierarchical_decisions_training_phase(p, block, number_of_trials)
        if strcmp(language, 'PT')
            text = ['Nesta sess�o, as respostas ter�o em conta n�o s� qual a nuvem ativa,\n'...
                        'mas tamb�m qual a imagem que aparece a indicar que tem de tomar uma decis�o.\n\n'...
                        'Essa imagem pode ser um carro ou uma casa.\n\n'...
                        'Ter� de responder de acordo com a regra que ser� mostrada a seguir.\n\n'...
                        'Use o bot�o da esquerda para resposta � esquerda com o indicador esquerdo.\n'...
                        'Use o bot�o da direita para resposta � direita com o indicador direito.\n\n'...
                        'Carregue numa tecla para avan�ar.\n'];
        else     
            text = ['In this session, responses will take into account not only which cloud is active,\n '...
                        'but also which image appears indicating that you have to make a decision.\n\n' ...
                        'This image can be a car or a house.\n\n' ...
                        'You will have to answer according to the rule that will be shown next.\n\n' ...
                        'Use the left button with your left index finger for left answers.\n' ...
                        'Use the right button with your right index finger for right answers. \n\n' ...
                        'Press any button to continue. \n'];
        end

        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        Screen('Flip', p.ptb.w);
        if fmri == 0
            [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
            key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), return, end
        else
            IOPort('Read',p.LuminaHandle, 1, 1); %IOPort(�Read�, handle [, blocking=0] [, amount]);
            pr = 1;
            while pr
                key = IOPort('Read',p.LuminaHandle);
                if ~isempty(key) %&& (length(key) == 1)
                    pr = 0;
                end
                IOPort('Flush',p.LuminaHandle);
            end
        end

        rule_explained(p, rule_hierarchical_decision);
        if fmri == 0
            [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
            key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), return, end
        else
            IOPort('Read',p.LuminaHandle, 1, 1); %IOPort(�Read�, handle [, blocking=0] [, amount]);
            pr = 1;
            while pr
                key = IOPort('Read',p.LuminaHandle);
                if ~isempty(key) %&& (length(key) == 1)
                    pr = 0;
                end
                IOPort('Flush',p.LuminaHandle);
            end
        end
        
       if fmri == 0
            KbQueueStop(p.ptb.device);
            KbQueueRelease(p.ptb.device);
            KbQueueCreate(p.ptb.device);
            KbQueueStart(p.ptb.device);
            KbQueueFlush(p.ptb.device);
        else
            IOPort('Flush',p.LuminaHandle);
        end

        % [seq, es] = make_glaze_block_training_sequences(trials, sigma, threshold, question_trials, set_side)
        [seq,~] = make_glaze_block_training_sequences(number_of_trials, p.sd(block), p.location_of_mean(block), 1, 0);

        %% image files to load
        % dir with car or house images files
        car_dir = [p.images_dir, '\selected_cars_similar_lum'];
        house_dir = [p.images_dir, '\selected_houses_similar_lum2cars'];
        % check how many choice stimulus of each type for this run
        number_car_stim = length(find(seq.stim == 0));
        number_house_stim = length(find(seq.stim == 1));
        Files = dir(fullfile(car_dir,'*.jpg'));
        file_order_cars = randperm(size(Files, 1)); 
        p.choice_trials.file_order_cars = file_order_cars(1:number_car_stim);
        for numb_files=1:number_car_stim
            p.choice_trials.file_names_cars{numb_files, 1} = fullfile(Files(file_order_cars(numb_files)).folder, Files(file_order_cars(numb_files)).name);
        end
        Files = dir(fullfile(house_dir,'*.jpg'));
        file_order_houses = randperm(size(Files, 1));
        p.choice_trials.file_order_houses = file_order_houses(1:number_house_stim);
        for numb_files=1:number_house_stim
            p.choice_trials.file_names_houses{numb_files, 1} = fullfile(Files(file_order_houses(numb_files)).folder, Files(file_order_houses(numb_files)).name);
        end

        draw_fix(p);
        correct = 0; trial_number = 0;
        count_cars = 0; count_houses = 0; % to determine which image to show
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
                    count_cars = count_cars+1;
                    theImageLocation = p.choice_trials.file_names_cars{count_cars};
                elseif stim_id == 1
                    count_houses = count_houses+1;
                    theImageLocation = p.choice_trials.file_names_houses{count_houses};
                end
%                             fprintf('\nCHOICE TRIAL; stim_id:%i, gener_side:%02.2f ', stim_id, gener_side>0);
                [p, RT, keycodes, ~, abort] = choice_trial(p, OnsetTime, theImageLocation);
                if abort ==1, return, end
                % analysis accuracy of responses
                [correct_trial, text] = hierarchical_decision_accuracy(keycodes, gener_side, stim_id, rule_hierarchical_decision);
                correct = correct + correct_trial;
                if feedback == 1
                    DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
                    Screen('Flip', p.ptb.w);  
                    if fmri == 0
                        [~, keyCode, ~] = KbStrokeWait(p.ptb.device);
                        key_pressed = KbName(keyCode); if strcmp(key_pressed, 'q'), break, end %return?
                    else
                        IOPort('Read',p.LuminaHandle, 1, 1); %IOPort(�Read�, handle [, blocking=0] [, amount]);
                        pr = 1;
                        while pr
                            key = IOPort('Read',p.LuminaHandle);
                            if ~isempty(key) %&& (length(key) == 1)
                                pr = 0;
                            end
                            IOPort('Flush',p.LuminaHandle);
                        end
                    end
                end
                ActSampleOnset = GetSecs;
                p = dump_keys(p);
            end
        end
        Screen('Flip', p.ptb.w); % clear fixation cross
        % record accuracy
        p.accuracy.training_scanner = correct/trial_number;
        % feedback
        if strcmp(language, 'PT')
            text = [sprintf('Neste bloco acertou %2.0f%% das respostas.\n\n', 100*correct/trial_number)];
        else
            text = [sprintf('In this session, your answers were %2.0f%% correct.\n\n', 100*correct/trial_number)];
        end
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*0.5), p.stim.white,[],[],[],2,[]);
        Screen('Flip', p.ptb.w);
        KbWait(p.ptb.device, 2, GetSecs()+15);
    end
end

