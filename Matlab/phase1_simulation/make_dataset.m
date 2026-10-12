%% MAKE DATASET
clear; clc; rng(42);

fs = 2000; T = 1;
classes = {'healthy', 'imbalance', 'misalign', 'bearing'};
nPer    = 200;                         % windows per class
varNames = {'RMS', 'Kurt', 'Crest', 'P2P', 'P1x', 'P2x', 'P3x', 'PHigh', 'Ratio'};

numClasses = numel(classes);
totalRows  = nPer * numClasses;

F      = zeros(totalRows, numel(varNames));
labels = strings(totalRows, 1);

row = 0;
for c = 1:numClasses
    for i = 1:nPer
        row = row + 1;
       sev = 0.05 + 0.95*rand;              % was 0.1 + 0.9*rand      % random severity 0.1..1

        % 1. Simulate vibration window & pass through sensor model
        x_raw = gen_window(classes{c}, sev, fs, T);
        x     = sensor_model(x_raw);

        % 2. Extract feature vector
        F(row, :)   = extract_features(x, fs);
        labels(row) = classes{c};
    end
end

% Construct output table
T_out = array2table(F, 'VariableNames', varNames);
T_out.Label = categorical(labels);     % Convert labels to categorical

% Save to CSV
writetable(T_out, 'features_sim.csv');
fprintf('Saved %d rows to features_sim.csv\n', height(T_out));
disp(head(T_out));