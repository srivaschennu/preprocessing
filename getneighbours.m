function [neighbours,neighweight] = getneighbours(chanlocs,n_neighbours)

if ~exist('n_neighbours','var') || isempty(n_neighbours)
    n_neighbours = length(chanlocs)-1;
end

% Return n_neighbours geodesic neighbours for each channel in chanlocs
% chanlocs assumed to be spherical coordinates

neighbours = zeros(length(chanlocs),n_neighbours);
neighdist = zeros(length(chanlocs),n_neighbours);
neighweight = zeros(length(chanlocs),n_neighbours);

for chan = 1:length(chanlocs)
    dist = distance(chanlocs(chan,:),chanlocs);
    [~, sortidx] = sort(dist);
    neighbours(chan,:) = sortidx(2:n_neighbours+1);
    neighdist(chan,:) = dist(neighbours(chan,:));
    neighweight(chan,:) = (1./neighdist(chan,:)) / sum(1./neighdist(chan,:));
end
