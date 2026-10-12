function y = sensor_model(x)
% SENSOR_MODEL  Mimic a MEMS accelerometer + 12-bit ADC
%   x : Input vibration signal (column vector or array, units: g)
%   y : Quantized and noise-corrupted output signal (units: g)

% Handle execution when called without inputs (e.g., clicking Run)
if nargin < 1
    x = sin(2*pi*30*(0:0.0001:0.1)'); % 30 Hz sine wave default signal
end

fsr = 4;                           % full-scale range (+/- g)
y = (1 + 0.05*randn) * x + 0.02*randn;   % gain error + DC offset
y   = max(min(y, fsr), -fsr);      % clipping to [-fsr, +fsr]
lsb = 2*fsr / 2^12;                % 12-bit step size (8 / 4096 = 0.00195 g)
y   = round(y/lsb) * lsb;          % quantization to nearest LSB step
end