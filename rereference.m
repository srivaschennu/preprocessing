function EEG = rereference(EEG,refmode)

%reference modes
%1 = common average
%2 = laplacian average
%3 = linked mastoid
%4 = none

if isfield(EEG.chanlocs,'badchan')
    badchannels = find(cell2mat({EEG.chanlocs.badchan}));
else
    badchannels = [];
end

if ~exist('refmode','var') || isempty(refmode)
    refmodes = {'Common','Laplacian','Linked Mastoid','None'};
    [refmode,ok] = listdlg('ListString',refmodes,'SelectionMode','single','Name','Re-referencing',...
        'PromptString','Choose re-referencing type');
else
    ok = 1;
end

if isfield(EEG.chaninfo,'ndchanlocs')
    EEG.chaninfo.nodatchans = EEG.chaninfo.ndchanlocs;
end

if isstruct(EEG.chaninfo.nodatchans)
    czidx = find(strcmp('Cz',{EEG.chaninfo.nodatchans.labels}));
else
    czidx = [];
end

refchan = {'E57' 'E100'};
for r = 1:length(refchan)
    refchan{r} = find(strcmp(refchan{r},{EEG.chanlocs.labels}));
end
refchan = cell2mat(refchan);

if ok
    switch refmode
        case 1
            fprintf('Referencing to common average.\n');
            EEG = pop_select(EEG,'nochannel',refchan);
            if isempty(czidx)
                EEG = pop_reref( EEG, [], 'exclude', badchannels);
            else
                EEG = pop_reref( EEG, [], 'exclude', badchannels,'refloc',EEG.chaninfo.nodatchans(czidx));
                EEG.chaninfo.nodatchans(strcmp('Cz',{EEG.chaninfo.nodatchans.labels})) = [];
            end
            EEG.ref = 'average';
            
        case 2
            fprintf('Referencing to laplacian average.\n');
            EEG = pop_select(EEG,'nochannel',refchan);
            if ~isempty(czidx)
                EEG.chanlocs(end+1).labels = EEG.chaninfo.nodatchans(czidx).labels;
                fieldloc = fieldnames(EEG.chaninfo.nodatchans(czidx));
                for ind = 1:length(fieldloc)
                    EEG.chanlocs(end).(fieldloc{ind}) = EEG.chaninfo.nodatchans(czidx).(fieldloc{ind});
                end
                EEG.chanlocs(end).type = '';
                EEG.chaninfo.nodatchans(czidx) = [];
                EEG.data(end+1,:,:) = 0;
                EEG.nbchan = EEG.nbchan + 1;
            end
            chanlocs = cat(2,cell2mat({EEG.chanlocs.X})',cell2mat({EEG.chanlocs.Y})',cell2mat({EEG.chanlocs.Z})');
            EEG.data = permute(lar(permute(EEG.data,[3 2 1]),chanlocs,badchannels),[3 2 1]);
            EEG.ref = 'laplacian';
            
        case 3
            refchan = setdiff(refchan,badchannels);
            fprintf('Referencing to %s.\n',cell2mat({EEG.chanlocs(refchan).labels}));
            if isempty(czidx)
                EEG = pop_reref( EEG, refchan, 'exclude', badchannels);
            else
                EEG = pop_reref( EEG, refchan, 'exclude', badchannels,'refloc',EEG.chaninfo.nodatchans(czidx));
                EEG.chaninfo.nodatchans(strcmp('Cz',{EEG.chaninfo.nodatchans.labels})) = [];
            end
            
        case 4
            fprintf('Data reference unchanged.\n');
            return;
    end
end