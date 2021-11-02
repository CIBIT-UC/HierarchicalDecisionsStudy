
p.display.dimension = [87.8 48.5];
p.display.distance = [175, 182.5];
p.stim.bg  = [92 92 92];
p.stim.fix_target = [105 105 105]; 
p.stim.lumdiff = 10; % luminance difference within sample fill and outline


%Sets the parameters related to the PTB toolbox. Including
%fontsizes, font names.
%Default parameters
Screen('Preference', 'SkipSyncTests', 1);
% Screen('Preference', 'DefaultFontSize', p.text.fontsize);
% Screen('Preference', 'DefaultFontName', p.text.fontname);
Screen('Preference', 'TextAntiAliasing',2);%enable textantialiasing high quality
Screen('Preference', 'VisualDebuglevel', 0);
Screen('Preference', 'SuppressAllWarnings', 1);


%%Find the number of the screen to be opened
screens                     =  Screen('Screens');
p.ptb.screenNumber   = max(screens);%the maximum is the second monitor
[idx, names, ~] = GetKeyboardIndices;
p.ptb.device = idx;

%set the resolution correctly
res = Screen('resolution', p.ptb.screenNumber);
p.display.resolution = [res.width res.height];
p.display.ppd = ppd(mean(p.display.distance), p.display.resolution(1),...
    p.display.dimension(1));

HideCursor(p.ptb.screenNumber);%make sure that the mouse is not
%         shown at the participant's monitor

[p.ptb.w, p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, p.stim.bg);
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
 
 
draw_fix(p); Screen('Flip',p.ptb.w);

KbStrokeWait(p.ptb.device);

% show 3 dot samples
r_inner = .1;
o = p.stim.lumdiff;
x_outer = r_inner*(2^.5 -1);
r_outer = (r_inner + x_outer)*p.display.ppd;
r_inner = r_inner*p.display.ppd;
cx = p.ptb.CrossPosition_x;
cy = p.ptb.CrossPosition_y;

location = 50;
rin_1 = [cx-r_inner, location-r_inner+cy, cx+r_inner, location+r_inner+cy];
rout_1 = [cx-r_outer, location-r_outer+cy, cx+r_outer, location+r_outer+cy];

location = 0;
rin_2 = [cx-r_inner, location-r_inner+cy, cx+r_inner, location+r_inner+cy];
rout_2 = [cx-r_outer, location-r_outer+cy, cx+r_outer, location+r_outer+cy];

location = -50;
rin_3 = [cx-r_inner, location-r_inner+cy, cx+r_inner, location+r_inner+cy];
rout_3 = [cx-r_outer, location-r_outer+cy, cx+r_outer, location+r_outer+cy];

colour = p.stim.bg;
Screen('FillOval', p.ptb.w, colour-o, rout_1);
Screen('FillOval', p.ptb.w, colour+o, rin_1);
Screen('FillOval', p.ptb.w, colour-o, rout_2);
Screen('FillOval', p.ptb.w, colour+o, rin_2);
Screen('FillOval', p.ptb.w, colour-o, rout_3);
Screen('FillOval', p.ptb.w, colour+o, rin_3);

Screen('Flip',p.ptb.w);   
KbStrokeWait(p.ptb.device);


% show 2 dots
location = 25;
rin_1 = [cx-r_inner, location-r_inner+cy, cx+r_inner, location+r_inner+cy];
rout_1 = [cx-r_outer, location-r_outer+cy, cx+r_outer, location+r_outer+cy];

location = -25;
rin_2 = [cx-r_inner, location-r_inner+cy, cx+r_inner, location+r_inner+cy];
rout_2 = [cx-r_outer, location-r_outer+cy, cx+r_outer, location+r_outer+cy];


colour = p.stim.bg;
Screen('FillOval', p.ptb.w, colour-o, rout_1);
Screen('FillOval', p.ptb.w, colour+o, rin_1);
Screen('FillOval', p.ptb.w, colour-o, rout_2);
Screen('FillOval', p.ptb.w, colour+o, rin_2);

Screen('Flip',p.ptb.w);   
KbStrokeWait(p.ptb.device);


% show 4 dots
location = 25;
rin_1 = [cx-r_inner, location-r_inner+cy, cx+r_inner, location+r_inner+cy];
rout_1 = [cx-r_outer, location-r_outer+cy, cx+r_outer, location+r_outer+cy];

location = -25;
rin_2 = [cx-r_inner, location-r_inner+cy, cx+r_inner, location+r_inner+cy];
rout_2 = [cx-r_outer, location-r_outer+cy, cx+r_outer, location+r_outer+cy];

location = 75;
rin_3 = [cx-r_inner, location-r_inner+cy, cx+r_inner, location+r_inner+cy];
rout_3 = [cx-r_outer, location-r_outer+cy, cx+r_outer, location+r_outer+cy];

location = -75;
rin_4 = [cx-r_inner, location-r_inner+cy, cx+r_inner, location+r_inner+cy];
rout_4 = [cx-r_outer, location-r_outer+cy, cx+r_outer, location+r_outer+cy];


colour = p.stim.bg;
Screen('FillOval', p.ptb.w, colour-o, rout_1);
Screen('FillOval', p.ptb.w, colour+o, rin_1);
Screen('FillOval', p.ptb.w, colour-o, rout_2);
Screen('FillOval', p.ptb.w, colour+o, rin_2);
Screen('FillOval', p.ptb.w, colour-o, rout_3);
Screen('FillOval', p.ptb.w, colour+o, rin_3);
Screen('FillOval', p.ptb.w, colour-o, rout_4);
Screen('FillOval', p.ptb.w, colour+o, rin_4);

Screen('Flip',p.ptb.w);   
KbStrokeWait(p.ptb.device);


% Close window:
RestoreCluts()
%Screen('flip', p.ptb.w)
sca;
ShowCursor(p.ptb.screenNumber);
commandwindow;

 function draw_fix(p)
    % fixation target as suggested in Vision Research. Volume 76, 14 January 2013, Pages 31-42
    % What is the best fixation target? The effect of target shape on stability of fixational eye movements. 
    % L.Thalerab, A.C.SchützcM.A.GoodalebdK.R.Gegenfurtnerc

    colorOval = p.stim.fix_target; % color of the two circles [R G B]
    colorCross = p.stim.bg; % color of the Cross [R G B]

    d1 = 0.6; % diameter of outer circle (degrees)
    d2 = 0.14; % 0.2; % diameter of inner circle (degrees)

    Screen('FillOval', p.ptb.w, colorOval, [p.ptb.CrossPosition_x-d1/2 * p.display.ppd, p.ptb.CrossPosition_y-d1/2 * p.display.ppd, p.ptb.CrossPosition_x+d1/2 * p.display.ppd, p.ptb.CrossPosition_y+d1/2 * p.display.ppd], d1 * p.display.ppd);
    Screen('DrawLine', p.ptb.w, colorCross, p.ptb.CrossPosition_x-d1/2 * p.display.ppd, p.ptb.CrossPosition_y, p.ptb.CrossPosition_x+d1/2 * p.display.ppd, p.ptb.CrossPosition_y, d2 * p.display.ppd);
    Screen('DrawLine', p.ptb.w, colorCross, p.ptb.CrossPosition_x, p.ptb.CrossPosition_y-d1/2 * p.display.ppd, p.ptb.CrossPosition_x, p.ptb.CrossPosition_y+d1/2 * p.display.ppd, d2 * p.display.ppd);
    Screen('FillOval', p.ptb.w, colorOval, [p.ptb.CrossPosition_x-d2/2 * p.display.ppd, p.ptb.CrossPosition_y-d2/2 * p.display.ppd, p.ptb.CrossPosition_x+d2/2 * p.display.ppd, p.ptb.CrossPosition_y+d2/2 * p.display.ppd], d2 * p.display.ppd);
    %         Screen(p.ptb.w, 'Flip'); 
 end

 
 function ppd_var = ppd(distance, x_px, width)
    o = tan(0.5*pi/180) * distance;
    ppd_var = 2 * o*x_px/width; %  number of points per degree
end