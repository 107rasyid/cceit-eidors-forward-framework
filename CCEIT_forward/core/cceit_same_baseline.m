function [ok, mismatched] = cceit_same_baseline(A, B)
% CCEIT_SAME_BASELINE Compare model inputs independently of output paths.
% Purpose: decide whether saved numerical results match current physical and
% mesh parameters after the project folder has been reorganized.
% Inputs: A and B parameter structures.
% Outputs: scalar logical result and names of missing or mismatched fields.
% Manuscript ref: Section IV, reproducibility and saved-result reuse.

% Ring resolutions are supplied explicitly to each B scan and validated
% against its saved h_ring value. They are run-selection settings, not
% physical baseline parameters, and older MAT files may not contain them.
keys = {'nElec','R','w_el','width_mode','depth','h_int','h_el', ...
    'Vtx','f','sigma','epsr','eps0', ...
    'd','sigma_d','epsr_d','z_el'};
ok = isstruct(A) && isstruct(B);
mismatched = {};
if ~ok
    mismatched = {'not_struct'};
    return;
end
for ii = 1:numel(keys)
    key = keys{ii};
    if ~isfield(A, key) || ~isfield(B, key) || ...
            ~isequaln(A.(key), B.(key))
        ok = false;
        mismatched{end+1} = key; %#ok<AGROW>
    end
end
end
