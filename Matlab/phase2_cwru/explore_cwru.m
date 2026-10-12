%% EXPLORE CWRU DATA (no features, no ML yet)
clear; clc; close all;

files    = {'cwru/normal.mat','cwru/inner.mat','cwru/ball.mat','cwru/outer.mat'};
names    = {'Normal'; 'Inner race'; 'Ball'; 'Outer race'}; % Column cell array
fsFile   = [48000 12000 12000 12000];   % EDIT normal to 12000 if needed
fsTarget = 12000;

sig = cell(4,1);
for k = 1:4
    S  = load(files{k});
    fn = fieldnames(S);
    iDE = find(endsWith(fn,'_DE_time'), 1);      % drive-end accelerometer
    iRP = find(endsWith(fn,'RPM'), 1);           % shaft speed, if present
    
    x  = S.(fn{iDE})(:);
    if fsFile(k) ~= fsTarget
        x = resample(x, fsTarget, fsFile(k));   % bring all to 12 kHz
    end
    sig{k} = x;
    
    if ~isempty(iRP), rpm = S.(fn{iRP}); else, rpm = NaN; end
    fprintf('%-11s samples: %7d  duration: %5.1f s  rpm: %g\n', ...
        names{k}, numel(x), numel(x)/fsTarget, rpm);
end
fs = fsTarget;

%% Expected bearing fault frequencies at ~1797 rpm (SKF 6205 drive-end bearing)
fr   = 1797/60;                  % shaft frequency (Hz)
BPFI = 5.4152*fr;                % inner race
BPFO = 3.5848*fr;                % outer race
BSF  = 4.7135*fr;                % ball spin
fprintf('\nfr=%.1f Hz  BPFI=%.1f  BPFO=%.1f  BSF=%.1f\n', fr, BPFI, BPFO, BSF);

%% Figure 1: raw waveforms (0.2 s)
figure('Name','Waveforms','Position',[100 100 900 650]);
n = round(0.2*fs);
for k = 1:4
    subplot(4,1,k); 
    plot((0:n-1)/fs, sig{k}(1:min(n, numel(sig{k}))));
    ylabel('g'); 
    title(names{k});
end
xlabel('Time (s)');

%% Figure 2: spectra
figure('Name','Spectra','Position',[150 150 900 650]);
for k = 1:4
    % Safe slicing: ensure we don't exceed available samples
    nSamples = min(10*fs, numel(sig{k}));
    x = sig{k}(1:nSamples) - mean(sig{k}(1:nSamples));    
    
    N = numel(x);
    X = abs(fft(x.*hann(N)))/N*2;
    f = (0:N-1)*fs/N;
    
    subplot(4,1,k); 
    plot(f(1:floor(N/2)), X(1:floor(N/2))); 
    xlim([0 1000]);
    hold on; 
    xline(fr,'--g','Shaft (fr)'); 
    xline(BPFO,'--r','BPFO'); 
    xline(BPFI,'--m','BPFI');
    ylabel('Amp'); 
    title(names{k});
end
xlabel('Frequency (Hz)');

%% Table: simple numbers per recording
rmsV  = cellfun(@rms, sig);
kurV  = cellfun(@kurtosis, sig);
crest = cellfun(@(x) max(abs(x))/rms(x), sig);

disp(table(names, rmsV, kurV, crest, ...
    'VariableNames', {'Condition','RMS','Kurtosis','Crest'})); 