% create sequence files for experiment
% for each subject create before start experiment
rng shuffle;
subject = 'AB100';
cd ..
sbj_dir = [pwd '\exp_data' filesep subject];
if ~exist(sbj_dir, 'dir')
   mkdir(sbj_dir)
end

cd([pwd '\create_task_stim_sequences'])
block_length=600; % 10 minute blocks
task_sequences = make_sequence_task_hierarchical_decisions(block_length);

save([sbj_dir filesep 'task_sequences'], 'task_sequences');
