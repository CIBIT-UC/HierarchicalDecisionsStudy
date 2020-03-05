% save images with task examples
clear;
NoEyelink = 1; %is Eyelink wanted?
debug   = 0; %debug mode => 1: transparent window enabling viewing the background.
small_window = 0; % Open a small window only
% number_of_trials = 100; %size(seq.stim, 2)

%% >>>>> Set up a lot of stuff
abort = false; % 
start_time = GetSecs;
commandwindow; %focus on the command window, so that output is not written on the editor

p         = [];%parameter structure that contains all info about the experiment.

[p] = SetParams(p);%set parameters of the experiment
[p] = SetPTB(p, debug, small_window);%set visualization parameters.

location_of_mean = [0.5, 0.25]; sd = [0.5, 0.5];
for block = 1:2
    draw_fix(p); coloured_task = 1;
    %[seq, es] = make_glaze_block_training_sequences(trials, sigma, threshold, question_trials, set_side)
    [seq,~] = make_glaze_block_training_sequences(25, sd(block), location_of_mean(block), 0, 1);
    start = GetSecs; 

    for trial = 1:length(seq.sample)
     %Get the variables that Trial function needs.
        stim_id       = seq.stim(trial);
        type          = seq.type(trial);
        location      = seq.sample(trial);
        gener_side    = seq.generating_side(trial);
        OnsetTime     = GetSecs + 0.4; % ISI = 400 ms
            % Show a single sample
            arrow = 0;horz_pos = -100+rand(length(seq.sample), 1)*10;
            [p] = show_one_sample(p, horz_pos(trial), location, gener_side, coloured_task, arrow);
    end


    [seq,~] = make_glaze_block_training_sequences(25, sd(block), location_of_mean(block), 0, -1);
    start = GetSecs;
    for trial = 1:length(seq.sample)
     %Get the variables that Trial function needs.
        stim_id       = seq.stim(trial);
        type          = seq.type(trial);
        location      = seq.sample(trial);
        gener_side    = seq.generating_side(trial);
        OnsetTime     = GetSecs + 0.4; % ISI = 400 ms
            % Show a single sample
            arrow = 0;horz_pos = 100+rand(length(seq.sample), 1)*10;
            [p] = show_one_sample(p, horz_pos(trial), location, gener_side, coloured_task, arrow);
    end
    %      Screen('Flip', p.ptb.w);
    % 
    %     imageArray=Screen('GetImage', p.ptb.w, [p.ptb.CrossPosition_x-300, p.ptb.CrossPosition_y-300,p.ptb.CrossPosition_x+300, p.ptb.CrossPosition_y+300] );
    %     imwrite(imageArray, 'both_distributions_small.jpg');
    %     
    %         cx = p.ptb.CrossPosition_x+horz_pos; % screen mid point
    %         cy = p.ptb.CrossPosition_y; % screen mid point
    % 
    %         KbStrokeWait(p.ptb.device);


            %% make bar with points probability
            draw_fix(p); 
            t = -2*p.display.ppd:2*p.display.ppd; 
            % top distribution
            mean = location_of_mean(block); sigma = sd(block);
            mean_pixels = mean*p.display.ppd; sigma_pixels = sigma*p.display.ppd; 
            imgout = normpdf(t, mean_pixels, sigma_pixels);
            % p.display.ppd - change vector dimensions so that each point
            % corresponds to pixels and not degrees
    %         length_imgout_pixels = length(imgout)*p.display.ppd; 
    %         imgout_pixels = interp1(1:length(imgout),imgout,length(imgout)/784:length(imgout)/784:length(imgout), 'spline');

    %         clear bar
            for c=1:20
                for rgb = 1:3
                   bar_inf(:, c, rgb) = imgout'*255*20+p.stim.bg(1);
                end
            end

            bar_inferior = Screen('MakeTexture', p.ptb.w, bar_inf);  %
            % destinationRect = [left top right bottom]
            destinationRect = [p.ptb.CrossPosition_x-50, p.ptb.CrossPosition_y-size(bar_inf, 1)/2, ...
                p.ptb.CrossPosition_x-50+size(bar_inf, 2), p.ptb.CrossPosition_y+size(bar_inf, 1)/2];
            Screen('DrawTexture', p.ptb.w, bar_inferior, [], destinationRect); 
            %draw black line at mean position
            % Screen(‘DrawLine’, windowPtr [,color], fromH, fromV, toH, toV [,penWidth]);
            Screen('DrawLine', p.ptb.w, 0, p.ptb.CrossPosition_x-50, p.ptb.CrossPosition_y+mean_pixels, p.ptb.CrossPosition_x-50+size(bar_inf, 2), p.ptb.CrossPosition_y+mean_pixels, 2);


            % bottom distribution
            mean = -location_of_mean(block); sigma = sd(block);
            mean_pixels = mean*p.display.ppd; sigma_pixels = sigma*p.display.ppd; 
            imgout = normpdf(t, mean_pixels, sigma_pixels);
            % p.display.ppd - change vector dimensions so that each point
            % corresponds to pixels and not degrees
    %         length_imgout_pixels = length(imgout)*p.display.ppd; 
    %         imgout_pixels = interp1(1:length(imgout),imgout,length(imgout)/784:length(imgout)/784:length(imgout), 'spline');
    %         clear bar
            for c=1:20
                for rgb = 1:3
                   bar_sup(:, c, rgb) = imgout'*255*20+p.stim.bg(1);
                end
            end
            % p.display.ppd
            bar_superior = Screen('MakeTexture', p.ptb.w, bar_sup);  %
            % destinationRect = [left top right bottom]
            destinationRect = [p.ptb.CrossPosition_x+50-size(bar_sup, 2), p.ptb.CrossPosition_y-size(bar_sup, 1)/2, ...
                p.ptb.CrossPosition_x+50, p.ptb.CrossPosition_y+size(bar_sup, 1)/2];
            Screen('DrawTexture', p.ptb.w, bar_superior, [], destinationRect); 
            %draw black line at mean position
            Screen('DrawLine', p.ptb.w, 0, p.ptb.CrossPosition_x+50-size(bar_sup, 2), p.ptb.CrossPosition_y+mean_pixels, p.ptb.CrossPosition_x+50, p.ptb.CrossPosition_y+mean_pixels, 2);

            Screen('Flip', p.ptb.w);

            imageArray=Screen('GetImage', p.ptb.w, [p.ptb.CrossPosition_x-300, p.ptb.CrossPosition_y-300,p.ptb.CrossPosition_x+300, p.ptb.CrossPosition_y+300] );
            if block == 1
                imwrite(imageArray, 'generative_processes_easy_3.jpg');
            else
                imwrite(imageArray, 'generative_processes_difficult_3.jpg');
            end
            KbStrokeWait(p.ptb.device);
end
        RestoreCluts()
        % Screen('flip', p.ptb.w)
        sca;
        % show the cursor
        ShowCursor(p.ptb.screenNumber);
        commandwindow;
%% task functions

 function [p] = show_one_sample(p, horz_pos, location, gener_side, coloured_task, arrow)
        % Show one sample, such that black and white parts cancel.
        r_inner = p.stim.r_inner;
        o = p.stim.lumdiff;
        p.sample_duration=p.stim.sample_duration;
        x_outer = r_inner*(2^.5 -1);
        r_outer = (r_inner + x_outer)*p.display.ppd;
        r_inner = r_inner*p.display.ppd;
        cx = p.ptb.CrossPosition_x+horz_pos; % screen mid point
        cy = p.ptb.CrossPosition_y; % screen mid point

        % left, top, right, bottom -  rect(1)=left border, rect(2)=top, rect(3)=right, rect(4)=bottom.
        location = location*p.display.ppd;% location negative = up; location positive = down
        % vertical positioning of dots % left, top, right, bottom
        rin = [cx-r_inner, location-r_inner+cy, cx+r_inner, location+r_inner+cy];
        rout = [cx-r_outer, location-r_outer+cy, cx+r_outer, location+r_outer+cy];
%         draw_fix(p); 
        
        % create a triangle to signal position of generative
        % distribution
        head   = [ cx-100, gener_side*p.display.ppd+cy ]; % coordinates of head
        width  = 10;           % width of arrow head
        points = [ head-[width,0]         % left corner
                   head+[width,0]         % right corner
                   head+[0,width] ];      % vertex
       points = [ head;        % vertex pointing right
                   head-[width, width/2]         % top corner
                   head+[-width,width/2] ];      % vertex
  
        draw_fix(p);            
            
        if coloured_task == 1
            % sample generated by TOP source coloured blue
            % sample generated by BOTTOM cource coloured orange
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
        if arrow == 1
            Screen('FillPoly', p.ptb.w,[200,200,200], points); % arrow signaling which side the distribution comes from 
        end

%         ActSampleOnset  = Screen('Flip',p.ptb.w, SampleOnset, 0);      %<----- FLIP
% 
%         draw_fix(p);
%         if arrow == 1
%             Screen('FillPoly', p.ptb.w,[200,200,200], points); % arrow signaling which side the distribution comes from 
%         end
%         TimeSampleOffset = Screen('Flip',p.ptb.w,ActSampleOnset+p.sample_duration, 0);     %<----- FLIP
%         draw_fix(p); 
%         %TimeSampleOffset = Screen('Flip',p.ptb.w,TimeSampleOffset+(.25), 0);
    end

 function [p] = SetParams(p)
        %% relative path to stim and experiments
        %Path Business.
        [~, hostname]                 = system('hostname');
        p.hostname                    = deblank(hostname);

        if strcmp(p.hostname, 'czc0211hsd') % gab72
            p.display.resolution = [1680 1050]; 
            p.display.dimension = [47.5, 29.5];
            p.display.distance = [62, 59];
            p.stim.bg = [128, 128, 128]; % screen darkers than in the lab - only for script writing and testing
            p.stim.fix_target = [144 144 144]; 
        elseif strcmp(p.hostname, 'DESKTOP-MKKOQUF') % Coimbra lab 94  = ['DESKTOP-MKKOQUF']
            p.display.resolution = [1600 900]; % CHECK
            p.display.dimension = [34.5 19.5]; % CHECK
            p.display.distance = [52, 50];% CHECK
            p.stim.bg = [48 48 48];%[128, 128, 128];
        elseif strcmp(p.hostname, 'cnd0151937') % Coimbra laptop
            p.display.resolution = [1600 900]; 
            p.display.dimension = [34.5 19.5];
            p.display.distance = [52, 50];
            p.stim.bg = [128, 128, 128];
        end
        
        p.display.ppd = ppd(mean(p.display.distance), p.display.resolution(1),...
            p.display.dimension(1));
%         p.stim.bar_width = 400;
%         p.stim.bar_separation = 50;
        p.stim.r_inner = .1;
        p.stim.lumdiff = 12;%50; % luminance difference within sample fill and outline
        p.stim.sample_duration = .1; % NOT SURE THIS IS RIGHT!!!
%         p.stim.threshold = .5;
%         p.stim.sigma = .5;

        p.timestamp                     = datestr(now, 30); %the time_stamp of the current experiment.

        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        p.stim.white                = get_color('white');
        p.text.fontname                = 'Times New Roman';
        p.text.fontsize                = 28;
        p.text.fixsize                 = 60;


        %% keys to be used during the experiment:
        %This part is highly specific for your system and recording setup,
        %please enter the correct key identifiers. You can get this information calling the
        %KbName function and replacing the code below for the key below.
        %1, 6 ==> Right
        %2, 7 ==> Left
        %3, 8 ==> Down
        %4, 9 ==> Up (confirm)
        %5    ==> Pulse from the scanner

        KbName('UnifyKeyNames');
        p.keys.confirm                 = '4$';%
        p.keys.answer_a                = {'1!', '2@', '3#', '4$'};
        p.keys.answer_a_train          = 'x';
        p.keys.answer_b                = {'6^', '7&', '8*', '9('};
        p.keys.answer_b_train          = 'm';
        p.keys.pulse                   = '5%';
        p.keys.el_calib                = 'v';
        p.keys.el_valid                = 'c';
        p.keys.escape                  = 'ESCAPE';
        p.keys.enter                   = 'return';
        p.keys.quit                    = 'q';
        p.keylist = {p.keys.confirm,...
            p.keys.answer_a{1}, p.keys.answer_a{2},p.keys.answer_a{3},p.keys.answer_a{4},...
            p.keys.answer_b{1}, p.keys.answer_b{2},p.keys.answer_b{3},p.keys.answer_b{4},...
            p.keys.answer_a_train,...
            p.keys.answer_b_train, p.keys.pulse,...
            p.keys.el_calib, p.keys.el_valid, p.keys.enter};
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        p.out.log                     = cell(1000000,1);%Experimental LOG.

        %%
        p.var.current_bg              = p.stim.bg;%current background to be used.
        
        
    function ppd = ppd(distance, x_px, width)
        o = tan(0.5*pi/180) * distance;
        ppd = 2 * o*x_px/width; %  number of points per degree
    end
        
        
    end


    function [p] = SetPTB(p, debug, small_window)
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
        p.display.correct_resolution = res;
        HideCursor(p.ptb.screenNumber);%make sure that the mouse is not
%         shown at the participant's monitor
        %spit out the resolution,
        fprintf('Resolution of the screen is %dx%d...\n',res.width,res.height);

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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% Build a procedural gabor texture for a gabor with a support of tw x th
        % pixels, and a RGB color offset of 0.5 -- a 50% gray.
        p.stim.radius = p.ptb.rect(4)/2;
        p.stim.radius_deg = (p.ptb.rect(4)/2)/p.display.ppd;
        p.stim.sf = 1.2/p.display.ppd;
        fprintf('R and SF: %f %f', p.stim.radius, p.stim.sf)
        %p.ptb.gabortex = CreateProceduralGabor(p.ptb.w, p.ptb.width, p.ptb.height, 0, [0.5 0.5 0.5 0.0]);
        p.ptb.gabortex = CreateProceduralSineGrating(p.ptb.w, 2*p.stim.radius, 2*p.stim.radius,...
            [], p.stim.radius);

        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %Make final reminders to the experimenter to avoid false starts,
        %which are annoying. Here I specifically send test pulses to the
        %physio computer and check if everything OK.
        % k = 0;
        %         while ~(k == p.keys.el_calib);%press V to continue
        %             pause(0.1);
        %             outp(p.com.lpt.address,244);%244 means all but the UCS channel (so that we dont shock the subject during initialization).
        %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        %             fprintf('1/ Red cable has to be connected to the Cogent BOX\n');
        %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        %             fprintf('2/ D2 Connection not to forget on the LPT panel\n');
        %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        %             fprintf('3/ Switch the SCR cable\n');
        %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        %             fprintf('4/ Button box has to be on\n');
        %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        %             fprintf('5/ Did the trigger test work?\n!!!!!!You MUST observe 5 pulses on the PHYSIOCOMPUTER!!!!!\n\n\nPress V(alidate) to continue experiment or C to continue sending test pulses...\n')
        %             [~, k] = KbStrokeWait(p.ptb.device);
        %             k = find(k);
        %         end


        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y];

        d = (p.ptb.fc_size(1)^2/2)^.5;
        p.square = [fix(1)-d, fix(2)-d, fix(1)+d, fix(2)+d];
        p.FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        p.FixCross_s   = [fix(1)-1,fix(2)-p.ptb.fc_size/2,fix(1)+1,fix(2)+p.ptb.fc_size/2;fix(1)-p.ptb.fc_size/2,fix(2)-1,fix(1)+p.ptb.fc_size/2,fix(2)+1];
%         p = make_dist_textures(p);
        l = p.ptb.rect(1); t = p.ptb.rect(2); r = p.ptb.rect(3); b = p.ptb.rect(4);
        p.stim.left_rect = [l, (b-t)/2-5-20, r, (b-t)/2+5-20];
        p.stim.right_rect = [l, 20+(b-t)/2-5, r, 20+(b-t)/2+5];
        
        
        
                %% Make a gaussian aperture with the "alpha" channel
        % to show images of faces and houses
        gaussDim = 200;
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
    
    function draw_fix(p) % fixation target as ... paper
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
