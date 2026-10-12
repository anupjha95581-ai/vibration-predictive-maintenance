function x = gen_window(fault, severity, fs, T)
% GEN_WINDOW  Simulate one vibration window (units: g)
%   fault    : 'healthy' | 'imbalance' | 'misalign' | 'bearing'
%   severity : 0..1 (ignored for 'healthy')
%   fs, T    : sampling rate (Hz), window length (s)

% Provide default values if called without arguments
if nargin < 4, T = 1; end
if nargin < 3, fs = 10000; end
if nargin < 2, severity = 0.5; end
if nargin < 1, fault = 'healthy'; end

N  = round(fs*T);
t  = (0:N-1)'/fs;
fr = 30*(1 + 0.06*randn);            % was 0.03        % shaft speed varies slightly (Hz)
ph = 2*pi*rand;                    % random phase

A0 = 0.7 + 0.6*rand;                 % baseline amplitude varies 0.7..1.3
x  = A0*sin(2*pi*fr*t + ph);               % healthy 1x component

switch lower(fault)
    case 'healthy'
        % nothing extra

    case 'imbalance'               % stronger 1x
        x = (1 + 1.0*severity) * sin(2*pi*fr*t + ph);

    case 'misalign'                % extra 2x and 3x harmonics
        x = x + severity*( 1.2*sin(2*pi*2*fr*t + 2*pi*rand) ...
            + 0.6*sin(2*pi*3*fr*t + 2*pi*rand) );

    case 'bearing'                 % periodic impulses ringing a resonance
        fb  = 3.57*fr;             % outer-race fault frequency (Hz)
        imp = zeros(N,1);
        idx = floor((0:floor(T*fb)-1)*fs/fb) + 1;
        idx = idx(idx <= N);       % ensure indices stay within bounds
        imp(idx) = 1;
        n   = 100;
        tk  = (0:n-1)'/fs;
        h   = exp(-300*tk).*sin(2*pi*600*tk);   % 600 Hz resonance
        x   = x + severity*1.5*filter(h, 1, imp);

    otherwise
        error('Unknown fault type: %s', fault);
end

sigma = 0.05 + 0.10*rand;          % noise level varies per window
x = x + sigma*randn(N,1);
end