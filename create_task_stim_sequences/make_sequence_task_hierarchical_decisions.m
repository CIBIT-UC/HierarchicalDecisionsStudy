function stimuli = make_sequence_task_hierarchical_decisions(block_length)
    %%
    % Generate sequences for the complete experiment per subject.
    stimuli = {};
    % Define sequence of blocks. max 5 runs for session
    % 2 sessions outside scanner + 2 sessions inside scanner
    block_types = {{'GL', 'GL', 'GL', 'GL', 'GL'}, ...
                   {'GL', 'GL', 'GL', 'GL', 'GL'}, ...
                   {'GL', 'GL', 'GL', 'GL', 'GL'}, ...
                   {'GL', 'GL', 'GL', 'GL', 'GL'}};

    stimuli = {};
    for p = 1:size(block_types, 2) % This iterates over sessions!  
        blocks = {};
        for block = 1:length(block_types{p})                
%             type = block_types{p}(block);

            [seq, es] = make_block_hierarchical_decisions(block_length);
            blocks{block} = seq; %#ok<*AGROW>  

            if p == 1 || p == 2
                blocks{block}.fmri = false;
            else
                blocks{block}.fmri = true;
            end
        end
        stimuli{p} = blocks;
    end      
end