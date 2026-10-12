%% Verify file number, load (from RPM) and sampling rate (from length)
clear; clc;
nums = [97 98 99 100 105 106 107 108 118 119 120 121 130 131 132 133];
% 0 hp files may still be named normal/inner/ball/outer; the loop skips missing files
fprintf('%-10s %-14s %8s %10s\n', 'file', 'DE variable', 'rpm', 'samples');
for n = nums
    fname = sprintf('cwru/%d.mat', n);
    if ~isfile(fname), fprintf('%-10d MISSING\n', n); continue; end
    S  = load(fname);  fn = fieldnames(S);
    iDE = find(endsWith(fn,'_DE_time'),1);
    iRP = find(endsWith(fn,'RPM'),1);
    fprintf('%-10d %-14s %8.0f %10d\n', n, fn{iDE}, S.(fn{iRP}), numel(S.(fn{iDE})));
end