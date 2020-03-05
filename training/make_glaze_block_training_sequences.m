function [seq, es] = make_glaze_block_training_sequences(trials, sigma, threshold, question_trials, set_side)

duration_glaze = .4;
hazard_rate = 1/70;
Q_rate = 1/35;

[seq, es] = make_glaze_sequence(hazard_rate, trials, threshold, sigma, Q_rate, duration_glaze);

 function [seq, es] = make_glaze_sequence(hazard_rate, trials, threshold, sigma, Q_rate, duration)
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
        if set_side==0
            side = randsample(sides, 1);
        else
            side = set_side;
        end
        cnt = 0;
        last_choice = false;
        while length(seq.stimulus_onset)<=trials

            if set_side ~= 0 % distribution side always the same
                e = trials;
            else
                e = exprndtrunc(mean_inter_change_length, 5, 2*mean_inter_change_length);
            end
            for i = 1:e                
                samples = (randn(1, 1)*sigma + side*threshold);
                seq.sample = [seq.sample,samples];
                seq.generating_side = [seq.generating_side, side*threshold];
                % Sample spacing is 400 ms.
                isi =  duration;
                seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end)+isi];
                seq.type = [seq.type, 0];
                seq.stim = [seq.stim nan];
                cnt = cnt +1;
                if question_trials == 0 % no choice trials
                elseif question_trials == 1 && (((binornd(1, Q_rate) > 0.5) && (cnt > 10)) || (cnt > 20/.4))                    
                    seq.sample = [seq.sample, nan];
                    seq.generating_side = [seq.generating_side, side*threshold];
                    seq.type = [seq.type, 1];
                    %seq.isi = [seq.isi, isi];
                    seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end) + 2 + isi + (3-2)*rand];
                    seq.stim = [seq.stim randi(2, 1)-1];
                    cnt = 0;
%                     last_choice = true;
                end
            end
            side = side*-1;
            es = [es e]; %#ok<AGROW>                        
        end
%         idx = seq.stimulus_onset < block_length;
%         fields = fieldnames(seq);
%         for field = 1:length(fieldnames(seq))
%             k = seq.(fields{field});
%             seq.(fields{field}) = k(idx);
%         end
        seq.sigma = sigma;
%         seq.block_type = 'GL';
    end

end

