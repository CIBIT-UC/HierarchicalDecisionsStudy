function [seq, es] = make_glaze_block_training(trials, sigma, threshold, question_trials, single_side)
% duration = [2, 8];
duration_glaze = .4;
hazard_rate = 1/70;
Q_rate = 1/35;
% sigma = 0.5;
% threshold = 0.5; % position of mean of gaussians in relation to fixation cross

[seq, es] = make_glaze_sequence(hazard_rate, block_length, threshold, sigma, Q_rate, [duration_glaze, duration_glaze]);

 function [seq, es] = make_glaze_sequence(hazard_rate, block_length, threshold, sigma, Q_rate, duration)
        rng('shuffle');% Maria
        %% Makes a sequence of rules that change with a specific hazard rate.        
        seq.sample = [];
        seq.generating_side = [];
        seq.type = [];
        %seq.isi = [];
        seq.stimulus_onset = [0];
        seq.stim = [];
        es = [];
        mean_inter_change_length = 1/hazard_rate;
        sides = [1, -1];
        side = randsample(sides, 1);
        cnt = 0;
        last_choice = false;

            % first show 50 stimuli generated from right distribution
            side = 1;
            for i = 1:50               
                samples = (randn(1, 1)*sigma + side*threshold);
                seq.sample = [seq.sample,samples];
                seq.generating_side = [seq.generating_side, side*threshold];
                % Sample spacing is between 200 and 300ms.
                isi =  duration(1) + (duration(2)-duration(1)).*rand;
                seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end)+isi];
                seq.type = [seq.type, 0];
                seq.stim = [seq.stim nan];
                cnt = cnt+1;
            end
            % then show 50 stimuli generated from left distribution            
            side = side*-1;
            for i = 1:50               
                samples = (randn(1, 1)*sigma + side*threshold);
                seq.sample = [seq.sample,samples];
                seq.generating_side = [seq.generating_side, side*threshold];
                % Sample spacing is between 200 and 300ms.
                isi =  duration(1) + (duration(2)-duration(1)).*rand;
                %seq.isi = [seq.isi, isi]; 
                %if last_choice
                %    seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end) + 2 + isi + (3-2)*rand];
                %    last_choice = false;
                %else
                    seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end)+isi];
                %end
                seq.type = [seq.type, 0];
                seq.stim = [seq.stim nan];
                cnt = cnt+1;
            end
            
         while length(seq.stim)<301

            side = side*-1;
            e = exprndtrunc(mean_inter_change_length, 5, 2*mean_inter_change_length);
            for i = 1:e                
                samples = (randn(1, 1)*sigma + side*threshold);
                seq.sample = [seq.sample,samples];
                seq.generating_side = [seq.generating_side, side*threshold];
                % Sample spacing is between 200 and 300ms.
                isi =  duration(1) + (duration(2)-duration(1)).*rand;
                %seq.isi = [seq.isi, isi]; 
                %if last_choice
                %    seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end) + 2 + isi + (3-2)*rand];
                %    last_choice = false;
                %else
                    seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end)+isi];
                %end
                seq.type = [seq.type, 0];
                seq.stim = [seq.stim nan];
                cnt = cnt+1;
            end
            es = [es e]; %#ok<AGROW>                        
        end
            
            
        while length(seq.stim)<800

            side = side*-1;
            e = exprndtrunc(mean_inter_change_length, 5, 2*mean_inter_change_length);
            for i = 1:e                
                samples = (randn(1, 1)*sigma + side*threshold);
                seq.sample = [seq.sample,samples];
                seq.generating_side = [seq.generating_side, side*threshold];
                % Sample spacing is between 200 and 300ms.
                isi =  duration(1) + (duration(2)-duration(1)).*rand;
                %seq.isi = [seq.isi, isi]; 
                %if last_choice
                %    seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end) + 2 + isi + (3-2)*rand];
                %    last_choice = false;
                %else
                    seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end)+isi];
                %end
                seq.type = [seq.type, 0];
                seq.stim = [seq.stim nan];
                cnt = cnt+1;
                
                  if ((binornd(1, Q_rate) > 0.5) && (cnt > 10)) || (cnt > 20/.4)                    
                    seq.sample = [seq.sample, nan];
                    seq.generating_side = [seq.generating_side, side*threshold];
                    seq.type = [seq.type, 1];
                    %seq.isi = [seq.isi, isi];
                    seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end) + 2 + isi + (3-2)*rand];
                    seq.stim = [seq.stim randi(2, 1)-1];
                    cnt = 0;
                    last_choice = true;
                 end
            end
            es = [es e]; %#ok<AGROW>                        
        end
        
        idx = seq.stimulus_onset < block_length;
%         fields = fieldnames(seq);
%         for field = 1:length(fieldnames(seq))
%             k = seq.(fields{field});
%             seq.(fields{field}) = k(idx);
%         end
        seq.sigma = sigma;
        seq.block_type = 'GL';
    end

end