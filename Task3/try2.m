% Read the audio file
% [audio, fs] = audioread(fullfile('..','References and Tasks', 'Project_LouderWordsDetection', 'audios', '1.wav'));  % Replace with your wav filename

% % Read timestamp data from text file
% opts = detectImportOptions('1.txt', 'Delimiter', '\t');
% opts.VariableNames = {'Word', 'StartTime', 'EndTime', 'Expected'};
% opts = setvartype(opts, {'Word', 'StartTime', 'EndTime', 'Expected'}, {'char', 'double', 'double', 'double'});
% data = readtable('1.txt', opts);

% words = data.Word;
% startTimes = data.StartTime;
% endTimes = data.EndTime;
% expected = data.Expected;
clear all; close all;
function Hd = bandpass
    %BANDPASS Returns a discrete-time filter object.
    
    % MATLAB Code
    % Generated by MATLAB(R) 24.1 and Signal Processing Toolbox 24.1.
    % Generated on: 20-Nov-2024 10:23:43
    
    % FIR Window Bandpass filter designed using the FIR1 function.
    
    % All frequency values are in Hz.
    Fs = 44100;  % Sampling Frequency
    
    Fstop1 = 90;              % First Stopband Frequency
    Fpass1 = 100;             % First Passband Frequency
    Fpass2 = 2000;             % Second Passband Frequency
    Fstop2 = 2020;             % Second Stopband Frequency
    Dstop1 = 0.001;           % First Stopband Attenuation
    Dpass  = 0.057501127785;  % Passband Ripple
    Dstop2 = 0.0001;          % Second Stopband Attenuation
    flag   = 'scale';         % Sampling Flag
    
    % Calculate the order from the parameters using KAISERORD.
    [N,Wn,BETA,TYPE] = kaiserord([Fstop1 Fpass1 Fpass2 Fstop2]/(Fs/2), [0 ...
                                 1 0], [Dstop1 Dpass Dstop2]);
    
    % Calculate the coefficients using the FIR1 function.
    b  = fir1(N, Wn, TYPE, kaiser(N+1, BETA), flag);
    Hd = dfilt.dffir(b);
    
    % [EOF]
end

function filteredAudio = applyBandpassFilter(audio, fs)
    % Apply the bandpass filter to the audio signal
    Hd = bandpass();  % Get the filter object
    filteredAudio = filter(Hd, audio);  % Apply the filter
end

function stereoToMono(audio, Fs)
    % Convert stereo to mono if necessary
    if size(audio, 2) > 1
        audio = mean(audio, 2);
    end

    % Parameters for chunking
    chunkSeconds = 0.05;  % Specify chunk length in seconds (modify this value)
    windowLength = round(chunkSeconds * Fs);  % Convert seconds to samples
    overlap = round(windowLength/2);  % Overlap between chunks (50% overlap)
    nfft = windowLength;  % Number of FFT points

    % Error checking for window size
    % if windowLength > length(audio)
    %     error('Chunk length is too large for the signal');
    % end

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
    
    % filter audio using bandpass filter
    filteredAudio = applyBandpassFilter(audio, Fs);
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

[audio, fs] = audioread('5.wav'); 
stereoToMono(audio, fs);
[words, startTimes, endTimes, isLouder] = readTimeFile('5.txt');

    sound(audio, fs);

% filteredAudio = applyBandpassFilter(audio, fs);
    % Apply low-pass filter below 100 Hz
  % Low-pass filter with wider transition band
  Fn = fs/2;  % Nyquist frequency

  % Low-pass filter
  lpFilt = designfilt('lowpassiir', ...
      'FilterOrder', 8, ...
      'PassbandFrequency', 510/Fn, ...    % Normalize by dividing by Fn
      'PassbandRipple', 0.01);
  
  % High-pass filter
  hpFilt = designfilt('highpassiir', ...
      'FilterOrder', 8, ...
      'PassbandFrequency', 200 /Fn, ...   % Normalize by dividing by Fn
      'PassbandRipple', 0.01);
  
  % Apply filters
%   lowPassedAudio = filter(lpFilt, audio);
  highPassedAudio = filter(hpFilt, audio);
  
  % Play audio with proper pausing
%   sound(lowPassedAudio, fs);
%   pause(length(lowPassedAudio)/fs + 0.5);
%   sound(highPassedAudio, fs);
    % pause(length(highPassedAudio)/fs + 1);  % Wait for the audio to finish

    % Plot the low-passed audio signal
    figure;
    subplot(2, 1, 1);
    t = (0:length(audio)-1) / fs;  % Time vector
    plot(t, audio);
    title('original Audio Signal');
    xlabel('Time (s)');
    ylabel('Amplitude');
    grid on;

    % Plot the high-passed audio signal
    subplot(2, 1, 2);
    t = (0:length(highPassedAudio)-1) / fs;  % Time vector
    plot(t, highPassedAudio);
    title('High-Passed Audio Signal');
    xlabel('Time (s)');
    ylabel('Amplitude');
    grid on;
    % Play the filtered audio signal
    % sound(filteredAudio, fs);
    % Plot the filtered audio signal

% Take the FFT of the audio signal
n = length(audio);  % Number of samples
f = (0:n-1)*(fs/n);  % Frequency range
y = fft(audio);  % Compute the FFT

% Plot the magnitude of the FFT
% figure;
% plot(f, abs(y));
% title('Magnitude of FFT of Audio Signal');
% xlabel('Frequency (Hz)');
% ylabel('Magnitude');
% xlim([0 fs/2]);  % Plot up to the Nyquist frequency
% grid on;

% Print to verify the data
for i = 1:length(words)
    fprintf('%s\t\t%f\t%f\t%d\n', words{i}, startTimes(i), endTimes(i), isLouder(i));
end
fprintf('\n');

% Process each word
for i = 1:length(words)
    % Convert time to samples
    startSample = round(startTimes(i) * fs);
    endSample = round(endTimes(i) * fs);
    
    % Extract word segment    
    wordSegment = audio(startSample:endSample);
    duration = endTimes(i) - startTimes(i);
    
    % Calculate RMS energy
    energy = sqrt(mean(wordSegment.^2));
    peakAmplitude = max(abs(wordSegment));
    normalizedEnergy = energy / duration;
    % Perform STFT
    [S, F, T] = stft(wordSegment, fs, 'Window', hamming(256), 'OverlapLength', 128, 'FFTLength', 512);

    % Calculate energy in the frequency band of interest (500 Hz to 4 kHz)
    freqBand = (F >= 90 & F <=500);
    bandEnergy = sum(abs(S(freqBand, :)).^2, 'all');

    normalizedBandEnergy = bandEnergy / duration;
    % NOTE: 'bandEnergy' is the energy in the frequency domain but the 'energy' is in time domain.

    % Determine if loud (you may need to adjust threshold)
    threshold = 0.12;  % Adjust based on your audio
    isLoud = energy > threshold;
    
    % Print result
    % fprintf('Word: %s \t Peak Amplitude: %.4f \t Energy: %.4f \t normalisedEnergy: %.4f \t Band_Energy: %.4f \t normalisedBand_Energy: %.4f \t Is Loud: %d\n', words{i}, peakAmplitude, energy, normalizedEnergy, bandEnergy, normalizedBandEnergy, isLoud);
end

% The above code gives the audio characteristics like peak amplitude, energy, normalized energy, band energy, normalized band energy to determine if the word is loud or not.
% Assumption: The threshold value is set to 0.12 currently (can adjust it later)
% the band for human voice is taken to be from 40 to 500 Hz (got this idea by plotting by FFT of the audio signal)
% Observation: if amplitude > 0.6, sure shot 100% loud word (based on the data given)
% Check the word told in the 6th txt, parameters shows that it shows be loud