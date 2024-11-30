% Final Super Ultimate Promax Spectacular Code for Task 3a
% Task 3a Completed!
clear all; close all;

function stereoToMono(audio, Fs)
    % Convert stereo to mono if necessary
    if size(audio, 2) > 1
        audio = mean(audio, 2);
    end
end

function plotspec(audio, Fs)
    % Parameters for chunking
    chunkSeconds = 0.05;  % Specify chunk length in seconds (modify this value)
    windowLength = round(chunkSeconds * Fs);  % Convert seconds to samples
    overlap = round(windowLength/2);  % Overlap between chunks (50% overlap)
    nfft = windowLength;  % Number of FFT points

    % Create spectrogram using built-in function
    figure;
    subplot(3, 1, 1);
    spectrogram(audio, hamming(windowLength), overlap, nfft, Fs, 'yaxis');
    colormap('jet');
    colorbar;

    % ploting the audio signal
    subplot(3, 1, 2);
    t = (0:length(audio)-1) / Fs;  % Time vector
    plot(t, audio);
    title('Audio Signal');
    xlabel('Time (s)');
    ylabel('Amplitude');
    grid on;

    % Play the filtered audio signal
    sound(filteredAudio, Fs);
    % Plot the filtered audio signal
    subplot(3, 1, 3);   
    t = (0:length(filteredAudio)-1) / Fs;  % Time vector
    plot(t, filteredAudio);
    title('Filtered Audio Signal');
    xlabel('Time (s)');
    ylabel('Amplitude');
    grid on;
end

function plotfft(audio,fs)
    % Take the FFT of the audio signal
    n = length(audio);  % Number of samples
    f = (0:n-1)*(fs/n);  % Frequency range
    y = fft(audio);  % Compute the FFT

    % Plot the magnitude of the FFT
    % figure;
    plot(f, abs(y));
    title('Magnitude of FFT of Audio Signal');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    xlim([0 fs/2]);  % Plot up to the Nyquist frequency
    grid on;
end

function plotsig(audio, fs)
    % Plot the audio signal
    t = (0:length(audio)-1) / fs;  % Time vector
    plot(t, audio);
    % title('Audio Signal');
    xlabel('Time (s)');
    ylabel('Amplitude');
    grid on;
end

function filteredAudio = filter(audio,fs)
    % Plays the audio signal
    sound(audio, fs);

    % Perform FFT on the audio signal
    Y = fft(audio);

    % Get the length of the audio and calculate frequency vector
    N = length(audio);
    freq = (0:N-1) * (fs / N);

    % Create a mask for the desired frequency range
    mask = (freq <= 7000) & (freq >= 100);
    % For negative frequencies (second half of the FFT)
    mask = mask | (freq >= fs - 7000 & freq <= fs - 100);

    figure;
    % Plot the frequency domain of the original audio
    subplot(2,1,1);
    plot(freq, abs(Y));
    title('Frequency Domain of Original Audio');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    xlim([0 fs/2]);  % Plot up to the Nyquist frequency
    grid on;

    % Zero out frequencies outside the desired range
    Y(~mask) = 0;

    % Plot the frequency domain of Y
    subplot(2,1,2);
    plot(freq, abs(fft(filteredAudio)));
    title('Frequency Domain of Filtered Audio');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    xlim([0 fs/2]);  % Plot up to the Nyquist frequency
    grid on;

    % Inverse FFT to get back to time domain
    filteredAudio = real(ifft(Y));

    % Normalize the audio to prevent clipping
    filteredAudio = filteredAudio / max(abs(filteredAudio));

    % Play the filtered audio
    sound(filteredAudio, fs);
end

[audio, fs] = audioread('9.mp3'); 
[words, startTimes, endTimes, isLouder] = readTimeFile('9.txt');

stereoToMono(audio, fs);

% Apply filters
filteredAudio = noisefilter(audio,fs);

% % Plot the original audio signal
% figure;
% subplot(2, 1, 1);
% plotsig(audio, fs);
% title('Original Audio Signal');

% % Plot the filtered audio signal
% subplot(2, 1, 2);
% plotsig(filteredAudio, fs);
% title('Filtered Audio Signal');

% figure;
% subplot(2, 1, 1);
% plotfft(audio, fs);
% subplot(2, 1, 2);
% plotfft(filteredAudio, fs);

audio = filteredAudio;

% Process each word
for i = 1:length(words)
    % Convert time to samples
    startSample = round(startTimes(i) * fs);
    endSample = round(endTimes(i) * fs);
    
    % Extract word segment    
    wordSegment = audio(startSample:endSample);
    duration = endTimes(i) - startTimes(i);
    
    % Calculate RMS energy
    energy = sum(wordSegment.^2);
    peakAmplitude = max(abs(wordSegment));
    normalizedEnergy = energy / duration;
    % Perform STFT
    [S, F, T] = stft(wordSegment, fs, 'Window', hamming(256), 'OverlapLength', 128, 'FFTLength', 512);

    % Calculate energy in the frequency band of interest (500 Hz to 4 kHz)
    freqBand = (F >= 100 & F <= 7000);
    bandEnergy = sum(abs(S(freqBand, :)).^2, 'all');

    % want to hear the audio after removing the frequencies above 5k frequency
    % remove the frequencies above 5k frequency

    normalizedBandEnergy = bandEnergy / duration;
    % NOTE: 'bandEnergy' is the energy in the frequency domain but the 'energy' is in time domain.

    % Determine if loud (you may need to adjust threshold)
    threshold = 0.12;  % Adjust based on your audio
    if(peakAmplitude > 0.6)
        isLoud = 1;
    else
        isLoud = energy > threshold;
    end
    
    % Print result
    fprintf('Word: %s \t Peak Amplitude: %.4f \t Energy: %.4f \t normalisedEnergy: %.4f \t Band_Energy: %.4f \t normalisedBand_Energy: %.4f \t Is Loud: x\n', words{i}, peakAmplitude, energy, normalizedEnergy, bandEnergy, normalizedBandEnergy);
end

% The above code gives the audio characteristics like peak amplitude, energy, normalized energy, band energy, normalized band energy to determine if the word is loud or not.
% Assumption: The threshold value is set to 0.12 currently (can adjust it later)
% the band for human voice is taken to be from 40 to 500 Hz (got this idea by plotting by FFT of the audio signal)
% Observation: if amplitude > 0.6, sure shot 100% loud word (based on the data given)
% Check the word told in the 6th txt, parameters shows that it shows be loud