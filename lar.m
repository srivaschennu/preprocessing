function Data = lar(Data,chanlocs,badchannels)
%Data assumed in format: epochs X frames X channels

if size(chanlocs,1) ~= size(Data,3)
    error('Number of channels and channel locations do not match.');
end

numneighbours = 6;

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