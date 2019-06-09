function varargout = rejartifacts(basename,pbadchan,refmode,prompt,varsort,chanvarthresh,trialvarthresh)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
%
% Rejects noisy (bad) channels and epochs based on variance. Uses a quasi-automated approach
% in which a pre-specified rejection threshold can be adjusted if necessary.
% Eventually rereferences data as specified.
%
% Input arguments:
% pbadchan - how to process bad channels: 1 - delete bad channels; 2 - interpolate bad channels; 3 - do nothing
% refmode - re-referencng option: 1 = common average; 2 = laplacian average; 3 = linked mastoid; 4 = none
% prompt - prompt user before writing output?: 1 = manual mode; 0 = automatic
% varsort - display channel and trial variance?: 1 = on; 0 = off
% chanvarthresh - channel variance threshold: default = 500
% trialvarthresh - trial variance threshold: default = 250
%
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.

if ~exist('chanvarthresh','var')
    chanvarthresh = [];
end

if ~exist('trialvarthresh','var')
    trialvarthresh = [];
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
    VisEd(EEG,1,['[' num2str(1:EEG.nbchan) ']'],{},'spacing',50);
    set(gcf,'Name',basename);
    uiwait
    EEG = evalin('base','EEG');
end

%% DEAL WITH BAD CHANNELS AND TRIALS

badchannels = find(cell2mat({EEG.chanlocs.badchan}));
badtrials = find(EEG.reject.rejmanual);

if prompt && (~exist('pbadchan','var') || isempty(pbadchan))
    pbadchanmodes = {'Delete','Interpolate','Do Nothing'};
    [pbadchan,ok] = listdlg2('ListString',pbadchanmodes,'SelectionMode','single','Name','Bad Channels',...
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
