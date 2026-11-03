function pairs = cceit_pair_list(n_electrodes)
% CCEIT_PAIR_LIST Return unordered electrode pairs in acquisition order.
% Purpose: define one canonical pair index for scans, plots, and exports.
% Inputs: n_electrodes, number of electrodes.
% Outputs: pairs, [tx rx] rows ordered by tx then increasing rx.
% Manuscript ref: Section III, 120-pair voltage-driven acquisition.

if ~isscalar(n_electrodes) || n_electrodes < 2 || ...
        n_electrodes ~= floor(n_electrodes)
    error('cceit_pair_list: n_electrodes must be an integer >= 2');
end

n_pairs = n_electrodes*(n_electrodes-1)/2;
pairs = zeros(n_pairs, 2);
k = 0;
for tx = 1:n_electrodes-1
    for rx = tx+1:n_electrodes
        k = k+1;
        pairs(k,:) = [tx rx];
    end
end
end
