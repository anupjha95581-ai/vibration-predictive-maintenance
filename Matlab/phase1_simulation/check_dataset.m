%% CHECK DATASET
clear; clc; close all; rng(7);

% Load dataset
T = readtable('features_sim.csv');
T.Label = categorical(T.Label);

% 1) Feature scatter plots
figure('Name', 'Feature Scatter Plots', 'Position', [100 100 1000 450]);
subplot(1,2,1); 
gscatter(T.RMS, T.PHigh, T.Label);
xlabel('RMS (g)'); ylabel('PHigh (500-700 Hz)'); 
title('RMS vs High-Band Power'); grid on;

subplot(1,2,2); 
gscatter(T.P1x, T.Ratio, T.Label);
xlabel('P1x'); ylabel('Harmonic Ratio'); 
title('1x Power vs Harmonic Ratio'); grid on;

% 2) Kurtosis histograms per class
figure('Name', 'Kurtosis Distribution', 'Position', [150 150 700 450]); 
hold on;
cls = categories(T.Label);
for i = 1:numel(cls)
    histogram(T.Kurt(T.Label == cls{i}), 20, ...
        'DisplayName', cls{i}, 'FaceAlpha', 0.5);
end
hold off;
legend('Location', 'northeast'); 
xlabel('Kurtosis'); ylabel('Count'); 
title('Kurtosis Distribution by Class'); grid on;

% 3) Decision-tree classifier (70/30 split)
cv        = cvpartition(T.Label, 'HoldOut', 0.3);
trainData = T(training(cv), :);
testData  = T(test(cv), :);

% Train Decision Tree (passing response column name directly)
mdl   = fitctree(trainData, 'Label');
pred  = predict(mdl, testData);
truth = testData.Label;

% Evaluate and display results
acc = mean(pred == truth);
fprintf('Test accuracy: %.1f%%\n', 100*acc);

figure('Name', 'Confusion Matrix', 'Position', [200 200 600 500]); 
confusionchart(truth, pred);
title(sprintf('Decision Tree Confusion Matrix (Accuracy: %.1f%%)', 100*acc));