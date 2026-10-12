%% DEMO: four machine conditions
clear; clc; close all; rng(1);

fs = 2000; T = 1; N = round(fs*T);
faults = {'healthy', 'imbalance', 'misalign', 'bearing'};

h1 = figure('Name', 'Time domain', 'Position', [100 100 900 600]);
h2 = figure('Name', 'Spectra', 'Position', [150 150 900 600]);

t = (0:N-1)/fs;
f = (0:N-1)*(fs/N);
w = hann(N); % Window for FFT

for k = 1:4
    % 1. Generate vibration signal and pass through sensor model
    x_raw = gen_window(faults{k}, 0.8, fs, T);
    x     = sensor_model(x_raw);

    % 2. Plot Time-Domain Signal
    figure(h1); 
    subplot(2, 2, k);
    plot(t, x); 
    xlim([0 0.3]); % Show first 300 ms
    title(upper(faults{k})); 
    xlabel('Time (s)'); 
    ylabel('Acceleration (g)');
    grid on;

    % 3. Plot Frequency-Domain Spectrum (FFT)
    x_detrend = x - mean(x);
    X = abs(fft(x_detrend .* w)) / (N * mean(w)) * 2; % Amplitude corrected FFT

    figure(h2); 
    subplot(2, 2, k);
    plot(f(1:floor(N/2)), X(1:floor(N/2))); 
    xlim([0 800]); 
    title(upper(faults{k})); 
    xlabel('Frequency (Hz)'); 
    ylabel('Amplitude (g)');
    grid on;
end
