%% CHECK_CWRU_ROBUST  Does the classifier survive a sensor-gain change?
clear; clc; close all; rng(1);

T = readtable('features_cwru.csv');
y = categorical(T.Label);
X = table2array(T(:, 1:15));        % cols: 1 RMS, 2 Kurt, 3 Crest, 4 P2P,
%       5-9 log band powers, 10-15 envelope peaks
loads = unique(T.Load)';
gains = [1 0.5 2];

sets = {'Raw 15 features', @(Z) Z;
    'Scale-invariant', @makeInvariant};

fprintf('Leave-one-load-out accuracy, with the test signals scaled by a sensor gain\n');
fprintf('%-18s', 'Feature set');
for g = 1:numel(gains), fprintf('   gain=%-5g', gains(g)); end
fprintf('\n');

predInv = y;                         % will hold gain=1 predictions of the invariant model
for s = 1:size(sets,1)
    fh   = sets{s,2};
    accs = zeros(numel(loads), numel(gains));
    for i = 1:numel(loads)
        tr = T.Load ~= loads(i);
        te = T.Load == loads(i);
        m  = fitcensemble(fh(X(tr,:)), y(tr), 'Method','Bag', ...
            'NumLearningCycles',100, 'Learners','tree');
        for g = 1:numel(gains)
            Xt = applyGain(X(te,:), gains(g));
            p  = predict(m, fh(Xt));
            accs(i,g) = mean(p == y(te));
            if s == 2 && gains(g) == 1
                predInv(te) = p;
            end
        end
    end
    fprintf('%-18s', sets{s,1});
    fprintf('   %7.1f%%  ', 100*mean(accs,1));
    fprintf('\n');
end

%% Confusion matrix and per-class recall for the scale-invariant model (gain = 1)
cls = categories(y);
C   = confusionmat(y, predInv, 'Order', cls);
fprintf('\nScale-invariant model, leave-one-load-out, all loads pooled:\n');
disp(array2table(C, 'VariableNames', cls, 'RowNames', cls));
for i = 1:numel(cls)
    fprintf('  %-8s recall %5.1f %%  (%d of %d windows)\n', cls{i}, ...
        100*C(i,i)/sum(C(i,:)), C(i,i), sum(C(i,:)));
end

figure(1); confusionchart(y, predInv); drawnow;
title('Scale-invariant features, leave-one-load-out');

%% ---------- local functions ----------
function Xg = applyGain(X, g)
% Simulate a sensor with gain g: amplitude features scale, log power shifts
Xg = X;
Xg(:, [1 4]) = X(:, [1 4]) * g;           % RMS and peak-to-peak
Xg(:, 5:9)   = X(:, 5:9) + 2*log10(g);    % log10 band power scales with g^2
end

function Z = makeInvariant(X)
% Features that do not change when the signal is multiplied by a constant
BP     = X(:, 5:9);
ratios = [BP(:,1)-BP(:,3), BP(:,2)-BP(:,3), BP(:,4)-BP(:,3), BP(:,5)-BP(:,3)];
Z      = [X(:,2), X(:,3), X(:,10:15), ratios];   % Kurt, Crest, 6 envelope peaks, 4 ratios
end