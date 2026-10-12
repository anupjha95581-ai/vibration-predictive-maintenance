function f = extract_features_cwru(x, fs, bpfo, bpfi, bsf)
% EXTRACT_FEATURES_CWRU  15 features from one vibration window
%   4 time-domain, 5 band powers (log10), 6 envelope-spectrum peaks

    f = nan(1, 15);                                  % always defined, even if something fails

    x = x(:);
    x = x - mean(x);
    N = numel(x);

    % ---- Time domain ----
    r     = rms(x);
    k     = kurtosis(x);
    crest = max(abs(x)) / r;
    p2p   = peak2peak(x);

    % ---- Band powers (log scale) ----
    edges = [0 500; 500 1500; 1500 2500; 2500 4000; 4000 5500];
    bp = zeros(1, 5);
    for i = 1:5
        bp(i) = log10(bandpower(x, fs, edges(i,:)) + eps);
    end

    % ---- Envelope spectrum ----
    Wn = [2000 5000] / (fs/2);
    [b, a] = butter(4, Wn, 'bandpass');
    xe  = filtfilt(b, a, x);
    env = abs(hilbert(xe));
    env = env - mean(env);
    E   = abs(fft(env .* hann(N))) / N * 2;
    df  = fs / N;
    fax = (0:N-1)' * df;

    inRef = (fax >= 20) & (fax <= 500);
    ref   = median(E(inRef));

    envf = zeros(1, 6);
    targets = [bpfo, 2*bpfo, bpfi, 2*bpfi, bsf, 2*bsf];
    for i = 1:6
        sel = (fax >= targets(i) - 3) & (fax <= targets(i) + 3);
        if any(sel)
            envf(i) = max(E(sel)) / (ref + eps);
        else
            envf(i) = 0;
        end
    end

    % ---- Output ----
    f = [r, k, crest, p2p, bp, envf];
end