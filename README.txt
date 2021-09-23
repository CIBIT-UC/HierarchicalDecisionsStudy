to run the experiment code you'll need:

matlab, Psychtoolbox-3 and Eyelink Development Kit from the SR Research

https://www.sr-support.com/forum/downloads/eyelink-display-software/48-eyelink-matlab-toolbox


1. Install the Eyelink Development Kit from the SR Research support site

EyeLink Developers Kit for Windows (Windows Display Software)
https://www.sr-support.com/forum/downloads/eyelink-display-software/39-eyelink-developers-kit-for-windows-windows-display-software?6-Windows-Display-Software=


How do I install PTB
2. Install Matlab or GNU/Octave. The latest compatible version of Matlab or GNU/Octave are recommended by Psychtoolbox. 
Linux: Matlab 7.4 or later, 32 or 64 Bit. 32 Bit or 64 Bit Octave 3.2.x.
Windows:32 Bit or 64 Bit Matlab 7.4 or later. You may need to install some Microsoft Visual C runtime libraries to make it work.
OSX:64bit Matlab, or 64bit Octave version3.6.
more detail information can be found at http://psychtoolbox.org/requirements/

3. Download Psychtoolbox-3 by following the steps at http://psychtoolbox.org/download/ alternatively, update to the latest version by running Updatepsychtoolbox in the MATLAB command window

4. It is necessary that you reboot your computer now.

5. To test, run the demo EyelinkBubbleDemo located in Applications>Psychtoolbox>PsychHardware>EyelinkToo lbox>EyelinkDemos>GazeContingentDemos

6. If you have any issues during installation, please make sure you have all the system requirements listed in http://psychtoolbox.org/requirements/



%% Running the experiment
1 - Create stimuli sequences for each participant
\HierarchicalDecisionsStudy\create_task_stim_sequences\task_sequences_hierarchical_decisions.m

2 - Run training sequence to train participant
\HierarchicalDecisionsStudy\training\hierarchical_decisions_task_training.m

3 - Run experiment
\HierarchicalDecisionsStudy\hierarchical_decisions_task.m
