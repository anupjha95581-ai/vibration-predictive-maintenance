%% MAKE_DATASET_CWRU  Build a multi-load feature table from CWRU files
clear; clc;

% ---- EDIT ONLY THIS TABLE: file | label | load (hp) | original sampling rate ----
cfg = {
 'cwru/normal.mat',  'healthy', 0, 48000;
 'cwru/inner.mat',   'inner',   0, 12000;
 'cwru/ball.mat',    'ball',    0, 12000;
 'cwru/outer.mat',   'outer',   0, 12000;
 'cwru/98.mat',      'healthy', 1, 48000;
 'cwru/106.mat',     'inner',   1, 12000;
 'cwru/119.mat',     'ball',    1, 12000;
 'cwru/131.mat',     'outer',   1, 12000;
 'cwru/99.mat',      'healthy', 2, 48000;
 'cwru/107.mat',     'inner',   2, 12000;
 'cwru/120.mat',     'ball',    2, 12000;
 'cwru/132.mat',     'outer',   2, 12000;
 'cwru/100.mat',     'healthy', 3, 48000;
 'cwru/108.mat',     'inner',   3, 12000;
 'cwru/121.mat',     'ball',    3, 12000;
 'cwru/133.mat',     'outer',   3, 12000;
};
% -----------------------------------------------------------------------------

fs     = 12000;          % common sampling rate after resampling
winLen = 6000;           % 0.5 s windows
hop    = 3000;           % 50% overlap
nFeat  = 15;

varNames = {'RMS','Kurt','Crest','P2P','BP0_500','BP500_1500','BP1500_2500', ...
            'BP2500_4000','BP4000_5500','E_BPFO','E_2BPFO','E_BPFI','E_2BPFI', ...
            'E_BSF','E_2BSF'};

fprintf('Current folder: %s\n\n', pwd);

rows   = zeros(0, nFeat);
lab    = strings(0,1);
ld     = zeros(0,1);
fid    = zeros(0,1);
rpmAll = zeros(0,1);

for c = 1:size(cfg,1)
    fname = cfg{c,1};
    if ~isfile(fname)
        fprintf('MISSING, skipped: %s\n', fname);
        continue
    end

    S   = load(fname);
    fn  = fieldnames(S);
    iDE = find(endsWith(fn,'_DE_time'), 1);
    iRP = find(endsWith(fn,'RPM'), 1);
    if isempty(iDE)
        fprintf('No drive-end signal in %s, skipped\n', fname);
        continue
    end

    x    = S.(fn{iDE})(:);
    nRaw = numel(x);
    if cfg{c,4} ~= fs
        x = resample(x, fs, cfg{c,4});          % bring everything to 12 kHz
    end

    if ~isempty(iRP), rpm = double(S.(fn{iRP})); else, rpm = 1797; end
    fr   = rpm/60;                               % this file's own shaft frequency
    bpfo = 3.5848*fr;
    bpfi = 5.4152*fr;
    bsf  = 4.7135*fr;

    fprintf('%-18s %-8s load %d  raw samples %7d  rate %5d  rpm %4.0f  duration %.1f s\n', ...
            fname, cfg{c,2}, cfg{c,3}, nRaw, cfg{c,4}, rpm, numel(x)/fs);

    starts = 1:hop:(numel(x) - winLen + 1);
    for j = 1:numel(starts)
        w = x(starts(j):starts(j)+winLen-1);
        f = extract_features_cwru(w, fs, bpfo, bpfi, bsf);

        if numel(f) ~= nFeat
            error(['extract_features_cwru returned %d values, expected %d. ' ...
                   'Replace extract_features_cwru.m with the 15-feature version.'], ...
                   numel(f), nFeat);
        end

        rows(end+1,:)   = f;             %#ok<SAGROW>
        lab(end+1,1)    = cfg{c,2};      %#ok<SAGROW>
        ld(end+1,1)     = cfg{c,3};      %#ok<SAGROW>
        fid(end+1,1)    = c;             %#ok<SAGROW>
        rpmAll(end+1,1) = rpm;           %#ok<SAGROW>
    end
end

if isempty(rows)
    error(['No windows were created, so no file was loaded. ' ...
           'Check the paths in cfg against the folder listing: run  ls cwru']);
end

T = array2table(rows, 'VariableNames', varNames);
T.Label = lab;
T.Load  = ld;
T.File  = fid;
T.RPM   = rpmAll;
writetable(T, 'features_cwru.csv');

fprintf('\nSaved %d windows to features_cwru.csv\n', height(T));
disp(groupsummary(T, {'Label','Load'}));