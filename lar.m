function Data = lar(Data,chanlocs,badchannels)
%Data - assumed in format: epochs X frames X channels
%chanlocs - N x 3 array of X Y Z locations of channels
%badchannels - index of bad channels if any. Else, specify []

%%% PARAMETERS for laplacian averaging

% number of surrounding neighbours of each channel to use for laplacian
% derivation
numneighbours = 6;

%%%

if size(chanlocs,1) ~= size(Data,3)
    error('Number of channels and channel locations do not match.');
end



OrigData = Data;
goodchannels = setdiff(1:size(Data,3),badchannels);

[THETA PHI] = cart2sph(chanlocs(:,1),chanlocs(:,2),chanlocs(:,3));
chanlocs = radtodeg([PHI THETA]);

[neighbours,neighweight] = getneighbours(chanlocs);

for chan = goodchannels
    thisneighbours = neighbours(chan,:);
    thisneighweight = neighweight(chan,:);
    
    goodchanidx = find(~ismember(thisneighbours,badchannels));
    
    thisneighbours = thisneighbours(goodchanidx(1:numneighbours));
    thisneighweight = thisneighweight(goodchanidx(1:numneighbours));
    
    for n = 1:length(thisneighbours)
        Data(:,:,chan) = Data(:,:,chan) - (thisneighweight(n) .* OrigData(:,:,thisneighbours(n)));
    end
end