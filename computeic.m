function EEG = computeic(filename,runmybinica,pcacheck)

loadpaths

if ~exist('runmybinica','var') || isempty(runmybinica)
    runmybinica = false;
end

if ~exist('pcacheck','var') || isempty(pcacheck)
    pcacheck = true;
end

if ischar(filename)
    EEG = pop_loadset('filename', sprintf('%s.set', filename), 'filepath', filepath);
else
    EEG = filename;
end

% find and remove bad channels
if isfield(EEG.chanlocs,'badchan')
    badchannels = find(cell2mat({EEG.chanlocs.badchan}));
    if ~isempty(badchannels)
        fprintf('\nFound %d bad channels: ', length(badchannels));
        for ch=1:length(badchannels)-1
            fprintf('%s,',EEG.chanlocs(badchannels(ch)).labels);
        end
        fprintf('%s\n',EEG.chanlocs(badchannels(end)).labels);
        EEG = pop_select(EEG,'nochannel',badchannels);
    else
        fprintf('No bad channel info found.\n');
    end
end

if pcacheck
    kfactor = 60;
    pcadim = round(sqrt(EEG.pnts*EEG.trials/kfactor));
    if EEG.nbchan > pcadim
        fprintf('Too many channels for stable ICA. Data will be reduced to %d dimensions using PCA.\n',pcadim);
        icaopts = {'extended' 1 'pca' pcadim};
    else
        icaopts = {'extended' 1};
    end
else
    icaopts = {'extended' 1};
end

if runmybinica
    EEG = mybinica(EEG);
else
    EEG = pop_runica(EEG, 'icatype','runica','dataset',1,'chanind',1:EEG.nbchan,'options',icaopts);
end

if ischar(filename) && ~isempty(EEG.icaweights)
    EEG.saved = 'no';
    fprintf('Saving %s%s\n',EEG.filepath,EEG.filename);
    pop_saveset(EEG, 'savemode', 'resave');
end