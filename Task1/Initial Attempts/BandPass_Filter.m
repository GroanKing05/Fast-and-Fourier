function Hd = BandPass_Filter
%BANDPASS_FILTER Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 24.1 and DSP System Toolbox 24.1.
% Generated on: 20-Nov-2024 14:58:14

% FIR Window Bandpass filter designed using the FIR1 function.

% All frequency values are in Hz.
Fs = 22050;  % Sampling Frequency

N    = 1000;      % Order
Fc1  = 1500;      % First Cutoff Frequency
Fc2  = 8000;     % Second Cutoff Frequency
flag = 'scale';  % Sampling Flag
% Create the window vector for the design algorithm.
win = hamming(N+1);

% Calculate the coefficients using the FIR1 function.
b  = fir1(N, [Fc1 Fc2]/(Fs/2), 'bandpass', win, flag);
Hd = dfilt.dffir(b);

% [EOF]
end