% SUMMARY_SWEEPS  Summarize frequency, layer, and medium sweeps.
% Implements: Section IV.D, parameter-sweep results and frequency response.
clear; close all; clc;

P = cceit_params();
files = {'sweepA_results.mat', 'sweepA2_results.mat', 'sweepA3_results.mat'};
loaded = cell(size(files));
for k = 1:numel(files)
    result_path = fullfile(P.outdir, files{k});
    if exist(result_path, 'file') ~= 2
        error('summary_sweeps: missing %s in results; run the sweep scripts first', files{k});
    end
    loaded{k} = load(result_path);
end
FA = loaded{1}; A2 = loaded{2}; A3 = loaded{3};
if ~isfield(FA, 'freqs') || ~isfield(FA, 'Yf') || ...
        ~isfield(A2, 'res') || ~isfield(A3, 'R')
    error('summary_sweeps: one or more sweep result files have an unexpected format');
end
baseline_ok = isfield(FA, 'P0') && isfield(A2, 'P0') && isfield(A3, 'P0') && ...
    abs(FA.P0.sigma-P.sigma) < 1e-12 && abs(FA.P0.epsr-P.epsr) < 1e-12 && ...
    abs(A2.P0.sigma-P.sigma) < 1e-12 && abs(A2.P0.epsr-P.epsr) < 1e-12 && ...
    abs(A2.P0.d-P.d) < 1e-12 && abs(A2.P0.epsr_d-P.epsr_d) < 1e-12 && ...
    abs(A2.P0.sigma_d-P.sigma_d) < 1e-15 && ...
    abs(A3.P0.sigma-P.sigma) < 1e-12 && abs(A3.P0.epsr-P.epsr) < 1e-12 && ...
    abs(A3.P0.epsr_d-P.epsr_d) < 1e-12 && ...
    abs(A3.P0.sigma_d-P.sigma_d) < 1e-15;
if ~baseline_ok
    error('summary_sweeps: sweep baselines differ from cceit_params; rerun the relevant sweeps');
end

frequency_parameter = sprintf('f = %.3g to %.3g Hz', min(FA.freqs), max(FA.freqs));
freq_base_idx = find(abs(FA.freqs - P.f) == min(abs(FA.freqs - P.f)), 1);
y_base = FA.Yf(:, freq_base_idx);
frequency_delta = zeros(numel(FA.freqs), 1);
for k = 1:numel(FA.freqs)
    frequency_delta(k) = norm(FA.Yf(:,k) - y_base) / norm(y_base);
end
frequency_range = [min(frequency_delta) max(frequency_delta)];

layer_names = {'d', 'epsr_d', 'sigma_d'};
layer_delta = [];
layer_range_text = {};
for k = 1:numel(layer_names)
    ix = find(strcmp({A2.res.name}, layer_names{k}), 1);
    if isempty(ix), continue; end
    vals = A2.res(ix).vals(:);
    delt = A2.res(ix).delta(:);
    layer_delta = [layer_delta; delt];
    if strcmp(layer_names{k}, 'd')
        layer_range_text{end+1} = sprintf('d %.3g-%.3g mm', min(vals)*1e3, max(vals)*1e3);
    elseif strcmp(layer_names{k}, 'epsr_d')
        layer_range_text{end+1} = sprintf('epsr_d %.3g-%.3g', min(vals), max(vals));
    else
        layer_range_text{end+1} = sprintf('sigma_d %.3g-%.3g S/m', min(vals), max(vals));
    end
end
if isempty(layer_delta)
    error('summary_sweeps: layer sweep fields d, epsr_d, sigma_d were not found');
end
layer_parameter = strjoin(layer_range_text, '; ');
layer_delta_range = [min(layer_delta) max(layer_delta)];

medium_delta = [];
medium_range_text = {};
medium_names = {'sigma', 'epsr'};
for k = 1:numel(medium_names)
    ix = find(strcmp({A2.res.name}, medium_names{k}), 1);
    if isempty(ix), continue; end
    vals = A2.res(ix).vals(:);
    medium_delta = [medium_delta; A2.res(ix).delta(:)];
    if strcmp(medium_names{k}, 'sigma')
        medium_range_text{end+1} = sprintf('sigma %.3g-%.3g S/m', min(vals), max(vals));
    else
        medium_range_text{end+1} = sprintf('epsr %.3g-%.3g', min(vals), max(vals));
    end
end
for k = 1:numel(A3.R)
    medium_delta = [medium_delta; A3.R(k).Delta_p_sig(:); A3.R(k).Delta_p_eps(:)];
end
if ~isempty(A3.R)
    sig_values = [A3.R.sig_vals];
    eps_values = [A3.R.eps_vals];
    medium_range_text{end+1} = sprintf('A3 sigma %.3g-%.3g S/m', ...
        min(sig_values), max(sig_values));
    medium_range_text{end+1} = sprintf('A3 epsr %.3g-%.3g', ...
        min(eps_values), max(eps_values));
end
if isempty(medium_delta)
    error('summary_sweeps: medium sweep values are empty');
end
medium_parameter = strjoin(medium_range_text, '; ');
medium_delta_range = [min(medium_delta) max(medium_delta)];

study = {'frequency'; 'layer'; 'medium'};
parameter_range = {frequency_parameter; layer_parameter; medium_parameter};
delta_range = [frequency_range; layer_delta_range; medium_delta_range];
fprintf('%-12s | %-74s | %-12s | %-12s\n', ...
    'Study', 'Parameter range', 'Delta_p min', 'Delta_p max');
fprintf('%s\n', repmat('-',1,120));
for k = 1:numel(study)
    fprintf('%-12s | %-74s | %-12.4g | %-12.4g\n', ...
        study{k}, parameter_range{k}, delta_range(k,1), delta_range(k,2));
end

csv_path = fullfile(P.outdir, 'summary_sweeps.csv');
fid = fopen(csv_path, 'w');
if fid < 0
    error('summary_sweeps: cannot open %s for writing', csv_path);
end
fprintf(fid, 'Study,Parameter range,Delta_p min,Delta_p max\n');
for k = 1:numel(study)
    csv_parameter = strrep(parameter_range{k}, '"', '""');
    fprintf(fid, '%s,"%s",%.12g,%.12g\n', study{k}, csv_parameter, ...
        delta_range(k,1), delta_range(k,2));
end
fclose(fid);

meta = cceit_make_metadata(P);
result_path = fullfile(P.outdir, 'summary_sweeps.mat');
freq_Hz = FA.freqs(:).';
median_abs_Y = median(abs(FA.Yf), 1);
median_phase_deg = median(angle(FA.Yf), 1)*180/pi;
save(result_path, 'P', 'study', 'parameter_range', 'delta_range', ...
    'freq_Hz', 'median_abs_Y', 'median_phase_deg', 'meta');
fprintf('CSV: %s\nMAT: %s\n', csv_path, result_path);
