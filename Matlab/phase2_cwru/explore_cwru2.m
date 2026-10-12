%% Smoothed PSD and envelope spectrum (run explore_cwru.m first)

% 1) Smoothed PSD up to 6 kHz
figure('Name','PSD','Position',[100 100 900 650]);
for k = 1:4
    [p,f] = pwelch(sig{k}-mean(sig{k}), hann(4096), 2048, 4096, fs);
    subplot(4,1,k); semilogy(f, p); xlim([0 6000]);
    title(names{k}); ylabel('PSD');
end
xlabel('Frequency (Hz)');

% 2) Envelope spectrum
band = [2000 5000];                              % resonance band, tune later
[b,a] = butter(4, band/(fs/2), 'bandpass');
figure('Name','Envelope spectrum','Position',[150 150 900 650]);
for k = 1:4
    x   = filtfilt(b, a, sig{k}-mean(sig{k}));
    env = abs(hilbert(x));
    env = env - mean(env);
    N   = numel(env);
    E   = abs(fft(env.*hann(N)))/N*2;
    f   = (0:N-1)*fs/N;
    subplot(4,1,k); plot(f(1:N/2), E(1:N/2)); xlim([0 500]);
    title(names{k}); hold on;
    xline(fr,'--g'); xline(BPFO,'--r'); xline(BPFI,'--m'); xline(BSF,'--c');
end
xlabel('Frequency (Hz)');