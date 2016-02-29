function varargout = rejartifacts(basename,pbadchan,refmode,prompt,varsort,chanvarthresh,trialvarthresh)

% pbadchan 1 - delete bad channels; 2 - interpolate bad channels; 3 - do nothing
% refmode 1 = common average 2 = laplacian average 3 = linked mastoid 4 = none
% prompt 1 = manual mode 0 = automatic
% varsort 1 = display channel and trial variance 0 = off
% chanvarthresh default = 500
% trialvarthresh default = 250

if ~exist('chanvarthresh','var') || isempty(chanvarthresh)
    chanvarthresh = 500;
end

if ~exist('trialvarthresh','var') || isempty(trialvarthresh)
    trialvarthresh = 250;
end

if ~exist('prompt','var') || isempty(prompt)
    prompt = 1;
end

if ~exist('varsort','var') || isempty(varsort)
    varsort = 1;
end

if ~exist('refmode','var')
    refmode = [];
end

loadpaths

EEG = pop_loadset('filename',[basename '.set'],'filepath',filepath);

%% ARTIFACT REJECTION

if varsort
    assignin('base','EEG',EEG);
    uiwait(markartifacts(EEG,chanvarthresh,trialvarthresh));
    EEG = evalin('base','EEG');
end

if prompt
    evalin('base','eeglab');
    assignin('base','EEG',EEG);
    evalin('base','[ALLEEG EEG index] = eeg_store(ALLEEG,EEG,0);');
    VisEd(EEG,1,['[' num2str(1:EEG.nbchan) ']'],{});
    set(gcf,'Name',basename);
    uiwait
    EEG = evalin('base','EEG');
end

%% DEAL WITH BAD CHANNELS AND TRIALS

badchannels = find(cell2mat({EEG.chanlocs.badchan}));
badtrials = find(EEG.reject.rejmanual);

if prompt && (~exist('pbadchan','var') || isempty(pbadchan))
    pbadchanmodes = {'Delete','Interpolate','Do Nothing'};
    [pbadchan,ok] = listdlg('ListString',pbadchanmodes,'SelectionMode','single','Name','Bad Channels',...
        'PromptString','Process bad channels?');
    
    if ~ok
        return;
    end
end

if pbadchan == 1 || pbadchan == 2
    if isfield(EEG,'rejchan')
        for c = 1:length(EEG.rejchan)
            EEG.rejchan(c).badchan = 1;
        end
    else
        EEG.rejchan = [];
    end
    
    if ~isempty(badchannels)
        fprintf('\nDeleting bad channels...\n');
        EEG.rejchan = [EEG.rejchan EEG.chanlocs(badchannels)];
        EEG = pop_select(EEG,'nochannel',badchannels);
    end
    
    for c = 1:length(EEG.rejchan)
        EEG.rejchan(c).badchan = 0;
    end
    
    if pbadchan == 2
        fprintf('\nInterpolating bad channels...\n');
        EEG = eeg_interp(EEG, EEG.rejchan);
    end
else
    EEG.rejchan = [];
    fprintf('No channels deleted.\n');
end


if ~isempty(badtrials)
    fprintf('\nDeleting bad trials...\n');
    EEG = pop_select(EEG, 'notrial', badtrials);
    if isfield(EEG,'rejepoch')
        EEG.rejepoch = [EEG.rejepoch badtrials];
    else
        EEG.rejepoch = badtrials;
    end
else
    EEG.rejepoch = [];
    fprintf('\nNo trials deleted.\n');
end

%% RE-REFERENCING
EEG = rereference(EEG,refmode);

if prompt && exist([EEG.filepath EEG.filename],'file')
    choice = questdlg(sprintf('Overwrite %s?',EEG.filename),...
        mfilename,'Yes','No','Yes');
    
    if ~strcmp(choice,'Yes')
        return;
    end
end

fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);

evalin('base','eeglab');
assignin('base','EEG',EEG);
evalin('base','[ALLEEG EEG index] = eeg_store(ALLEEG,EEG,0);');
evalin('base','eeglab redraw');
