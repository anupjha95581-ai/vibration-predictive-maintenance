function f = extract_features(x, fs)
% EXTRACT_FEATURES  Returns [RMS Kurt Crest P2P P1x P2x P3x PHigh Ratio]
%   x  : Vibration signal vector
%   fs : Sampling frequency (Hz)

% Default inputs for quick testing or clicking "Run"
if nargin < 2, fs = 10000; end
if nargin < 1, x = sin(2*pi*30*(0:1/fs:1)'); end

x = x - mean(x);                   % remove DC offset

r      = rms(x);
k      = kurtosis(x);
crest  = max(abs(x)) / (r + eps);  % protect against division by zero
p2p    = peak2peak(x);

% Calculate band powers (x, fs, [f_min f_max])
p1x    = bandpower(x, fs, [24 36]);    % around 1x (30 Hz)
p2x    = bandpower(x, fs, [50 70]);    % around 2x (60 Hz)
p3x    = bandpower(x, fs, [78 102]);   % around 3x (90 Hz)
phigh  = bandpower(x, fs, [500 700]);  % resonance band

ratio  = (p2x + p3x) / (p1x + eps);    % harmonic-to-fundamental ratio

f = [r, k, crest, p2p, p1x, p2x, p3x, phigh, ratio];
end


