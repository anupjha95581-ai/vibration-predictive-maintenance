%% CHECK_CWRU  Cross-load evaluation on real CWRU data
clear; clc; close all; rng(1);

T = readtable('features_cwru.csv');
T.Label = categorical(T.Label);
F = T(:, 1:15);                       % the 15 feature columns
loads = unique(T.Load)';

% Column map: 1-4 time domain | 5-9 band powers | 10-15 envelope peaks
sets = {'All 15',                 1:15;
        'No 4-5.5 kHz band',      [1:8 10:15];
        'No band powers',         [1:4 10:15];
        'Envelope peaks only',    10:15;
        'Time-domain only',       1:4};

%% 1) Leave-one-load-out: train on three loads, test on the fourth
fprintf('Accuracy when each load is held out (trained on the other three)\n');
fprintf('%-22s', 'Feature set');
for i = 1:numel(loads), fprintf('  test=%dhp', loads(i)); end
fprintf('     mean\n');

for s = 1:size(sets,1)
    cols = sets{s,2};
    accs = zeros(1, numel(loads));
    for i = 1:numel(loads)
        tr = T.Load ~= loads(i);
        te = T.Load == loads(i);
        m  = fitcensemble(F(tr,cols), T.Label(tr), 'Method','Bag', ...
                          'NumLearningCycles',100, 'Learners','tree');
        accs(i) = mean(predict(m, F(te,cols)) == T.Label(te));
    end
    fprintf('%-22s', sets{s,1});
    fprintf('   %5.1f%%', 100*accs);
    fprintf('   %5.1f%%\n', 100*mean(accs));
end

%% 2) Detail: train on 0-2 hp, test on 3 hp, all features
tr = T.Load <= 2;
te = T.Load == 3;
m  = fitcensemble(F(tr,:), T.Label(tr), 'Method','Bag', ...
                  'NumLearningCycles',100, 'Learners','tree');
pred  = predict(m, F(te,:));
truth = T.Label(te);

fprintf('\nTrain 0-2 hp, test 3 hp: %.1f %%\n', 100*mean(pred == truth));
cls = categories(truth);
C   = confusionmat(truth, pred, 'Order', cls);
disp(array2table(C, 'VariableNames', cls, 'RowNames', cls));

fprintf('Per-class detection rate (recall) at 3 hp:\n');
for i = 1:numel(cls)
    fprintf('  %-8s %5.1f %%  (%d of %d windows)\n', cls{i}, ...
            100*C(i,i)/sum(C(i,:)), C(i,i), sum(C(i,:)));
end

%% 3) Which features does the forest rely on?
imp = predictorImportance_forest(m);
[~, order] = sort(imp, 'descend');
fprintf('\nTop features by importance:\n');
for i = 1:6
    fprintf('  %-12s %.3f\n', F.Properties.VariableNames{order(i)}, imp(order(i)));
end

%% 4) Figures
figure(1); confusionchart(truth, pred); drawnow;
title('Random forest: trained on 0-2 hp, tested on 3 hp');

figure(2); gscatter(T.Kurt, T.E_BPFO, T.Label);
xlabel('Kurtosis'); ylabel('Envelope peak at BPFO / background');
title('Real data'); drawnow;

figure(3); gscatter(T.E_BPFI, T.E_BPFO, T.Label);
xlabel('Envelope peak at BPFI'); ylabel('Envelope peak at BPFO');
title('Real data'); drawnow;

figure(4); gscatter(T.BP4000_5500, T.BP500_1500, T.Label);
xlabel('log10 power 4-5.5 kHz'); ylabel('log10 power 0.5-1.5 kHz');
title('Possible recording-session artifact check'); drawnow;

%% Helper: average feature importance across the trees of the bagged forest
function imp = predictorImportance_forest(model)
    imp = predictorImportance(model);
end