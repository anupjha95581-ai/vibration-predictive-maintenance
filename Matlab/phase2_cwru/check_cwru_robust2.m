%% CHECK_CWRU_ROBUST2  Which scale-invariant features carry the result?
clear; clc; close all; rng(1);

T = readtable('features_cwru.csv');
y = categorical(T.Label);
X = table2array(T(:, 1:15));        % 1 RMS, 2 Kurt, 3 Crest, 4 P2P,
% 5-9 log band powers, 10-15 envelope peaks
loads = unique(T.Load)';
cls   = categories(y);

% Band ratios are log band powers minus the 1.5-2.5 kHz band (index 3).
% Band indices: 1 = 0-0.5k, 2 = 0.5-1.5k, 4 = 2.5-4k, 5 = 4-5.5k
sets = {'Kurt + Crest + Envelope',       @(Z) [Z(:,2) Z(:,3) Z(:,10:15)];
    'Invariant, no 4-5.5k ratio',    @(Z) [Z(:,2) Z(:,3) Z(:,10:15) bandRatios(Z,[1 2 4])];
    'Invariant, all ratios',         @(Z) [Z(:,2) Z(:,3) Z(:,10:15) bandRatios(Z,[1 2 4 5])];
    'Ratios only (no envelope)',     @(Z) [Z(:,2) Z(:,3) bandRatios(Z,[1 2 4 5])];
    'Ratios without 4-5.5k only',    @(Z) [Z(:,2) Z(:,3) bandRatios(Z,[1 2 4])]};

fprintf('Leave-one-load-out, all loads pooled\n');
fprintf('%-30s %9s   %s\n', 'Feature set', 'accuracy', strjoin(cls', '   '));

for s = 1:size(sets,1)
    fh   = sets{s,2};
    pred = y;                                   % will be overwritten fold by fold
    for i = 1:numel(loads)
        tr = T.Load ~= loads(i);
        te = T.Load == loads(i);
        m  = fitcensemble(fh(X(tr,:)), y(tr), 'Method','Bag', ...
            'NumLearningCycles',100, 'Learners','tree');
        pred(te) = predict(m, fh(X(te,:)));
    end
    C = confusionmat(y, pred, 'Order', cls);
    fprintf('%-30s %8.1f%%', sets{s,1}, 100*mean(pred == y));
    for i = 1:numel(cls)
        fprintf('   %5.1f%%', 100*C(i,i)/sum(C(i,:)));
    end
    fprintf('\n');
end

%% ---------- local function ----------
function R = bandRatios(Z, idx)
% Log band power of the chosen bands minus the 1.5-2.5 kHz band
BP = Z(:, 5:9);
R  = BP(:, idx) - BP(:, 3);
end