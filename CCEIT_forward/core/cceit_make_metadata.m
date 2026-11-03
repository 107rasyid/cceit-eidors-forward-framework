function meta = cceit_make_metadata(P)
% CCEIT_MAKE_METADATA  Create software and run metadata for saved results.
%
% Purpose: record interpreter, EIDORS, and NETGEN version provenance.
% Inputs:  P parameter structure containing netgen_bin when available.
% Outputs: meta structure with version strings and generation timestamp.
% Implements: Section IV, reproducibility and result provenance.

meta.version = version;
meta.date = datestr(now);
meta.eidors_version = 'unknown';
meta.netgen_version = 'unknown';

try
    if exist('eidors_obj', 'file') == 2
        meta.eidors_version = eidors_obj('eidors_version');
    end
catch
    meta.eidors_version = 'unknown';
end

% NETGEN does not expose a stable version command through the configured
% EIDORS wrapper, so preserve an explicit unknown instead of guessing.
if nargin > 0 && isstruct(P) && isfield(P, 'netgen_bin') && ...
        exist(fullfile(P.netgen_bin, 'netgen.exe'), 'file') ~= 2
    meta.netgen_version = 'unknown';
end
end
