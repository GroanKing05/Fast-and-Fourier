% Bird Matcher

clc, clearvars;

ref_files = {'bird1.wav', 'bird2.wav', 'bird3.wav'};

task_file = 'F8.wav'; % Change the Test file

[task_audio, task_fs] = audioread(task_file);

% Initialize score arrays
dominant_freq_scores = zeros(1, length(ref_files));
spcc_scores = zeros(1, length(ref_files)); % Spectrogram Cross-Correlation
tdcc_scores = zeros(1, length(ref_files)); % Time Domain Cross-Correlation

% Dominant Frequency Matching + Spectrogram Cross-Correlation (SPCC)
for j = 1:length(ref_files)
    ref_file = ref_files{j};
    [ref_audio, ref_fs] = audioread(ref_file);
    
    % spectrograms using a Hamming Window of 256 samples, with 50% overlap
    [task_spectrogram, task_frequencies, ~] = spectrogram(task_audio, hamming(256), 128, 256, task_fs, 'yaxis');
    [ref_spectrogram, ref_frequencies, ~] = spectrogram(ref_audio, hamming(256), 128, 256, ref_fs, 'yaxis');
    
    % dominant frequencies and their order
    [task_dominant_freqs, task_dominant_order] = find_dominant_frequencies(task_spectrogram, task_frequencies, 4);
    [ref_dominant_freqs, ref_dominant_order] = find_dominant_frequencies(ref_spectrogram, ref_frequencies, 4);
    
    % Compute similarity score based on dominant frequencies
    dominant_freq_scores(j) = compute_similarity_score(ref_dominant_freqs, ref_dominant_order, task_dominant_freqs, task_dominant_order);
    
    % Compute spcc
    [spcc, ~] = xcorr(task_spectrogram(:), ref_spectrogram(:));
    spcc_scores(j) = max(spcc);
end

% Time-Domain Cross-Correlation (TDCC)
for j = 1:length(ref_files)
    ref_file = ref_files{j};
    [ref_audio, ~] = audioread(ref_file);
    
    % Compute TDCC
    [tdcc, ~] = xcorr(task_audio, ref_audio);
    tdcc_scores(j) = max(tdcc);
end

max_dominant_freq_score = 4; % The max score that a file can have is 4, when all 4 dominant frequencies match
normalized_dominant_freq_scores = dominant_freq_scores / max_dominant_freq_score;

% Normalize scores using self-match
normalized_spcc_scores = zeros(1, length(spcc_scores));
normalized_tdcc_scores = zeros(1, length(tdcc_scores));
max_spcc_score = zeros(1, length(normalized_tdcc_scores));
max_tdcc_score = zeros(1, length(normalized_tdcc_scores));

for ref_bird = 1 : length(ref_files)
    [audio_Data, audio_fs] = audioread(ref_files{ref_bird});
    bird_spect = spectrogram(audio_Data, hamming(256), 128, 256, audio_fs, 'yaxis'); 
    max_spcc_score(ref_bird) = max(xcorr(bird_spect(:) , bird_spect(:)));
    if max_spcc_score(ref_bird) > 0
        normalized_spcc_scores(ref_bird) = spcc_scores(ref_bird) / max_spcc_score(ref_bird);
    else
        normalized_spcc_scores(ref_bird) = spcc_scores(ref_bird); % No normalization if max score is 0
    end

    max_tdcc_score(ref_bird) = max(xcorr(audio_Data , audio_Data));
    if max_tdcc_score(ref_bird) > 0
        normalized_tdcc_scores(ref_bird) = tdcc_scores(ref_bird) / max_tdcc_score(ref_bird);
    else
        normalized_tdcc_scores(ref_bird) = tdcc_scores(ref_bird); % No normalization if max score is 0
    end
end

% Define weights for each stage
dominant_freq_weight = 0.25;  % Lower weight 
spcc_weight = 0.35;           % Lower weight 
tdcc_weight = 0.4;           % Higher weight

% Add weights to the scores
combined_scores = dominant_freq_weight * normalized_dominant_freq_scores ...
                  + spcc_weight * normalized_spcc_scores ...
                  + tdcc_weight * normalized_tdcc_scores;

% Max score choice
[best_score, best_idx] = max(combined_scores);
best_match = ref_files{best_idx};
[best_match_audio, best_match_fs] = audioread(best_match);

fprintf('\nBest match : %s ', best_match);

% spectrograms of the task file and best match
figure;

% best match spectrogram
subplot(2, 1, 2);
spectrogram(best_match_audio, hamming(256), 128, 256, best_match_fs, 'yaxis');
axis xy;
colormap('jet');
title(['Best Match Spectrogram (' best_match ')']);
xlabel('Time (s)');
ylabel('Frequency (kHz)');
colorbar;

% task audio spectrogram
subplot(2, 1, 1);
spectrogram(task_audio, hamming(256), 128, 256, task_fs, 'yaxis');
axis xy;
colormap('jet');
title(['Task Audio Spectrogram (' task_file ')']);
xlabel('Time (s)');
ylabel('Frequency (kHz)');
colorbar;

function [dominant_freqs, dominant_order] = find_dominant_frequencies(spectrogram, frequencies, n)
    % Returns the dominant frequencies and their indices in the frequencies array
    [~, idx] = sort(max(spectrogram, [], 2), 'descend'); % Gives us the indices of the max frequency components
    dominant_freqs = frequencies(idx(1:n));
    dominant_order = idx(1:n);
end

function similarity_score = compute_similarity_score(ref_dominant_freqs, ref_dominant_order, task_dominant_freqs, task_dominant_order)
    score = 0;
    for i = 1:length(ref_dominant_freqs)
        if abs(ref_dominant_freqs(i) - task_dominant_freqs(i)) < 100
            score = score + 1;
        end
    end
    similarity_score = score / length(ref_dominant_freqs);
end