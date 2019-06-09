function EEG = rereference(basename,refmode,keepref,filesuffix)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
%
% Re-references data according to one of the following choices, specified
% by the refmode input.
% 
% refmode:
% 1 = common average
% 2 = laplacian average
% 3 = linked mastoid
% 4 = none
% 5 = current source density
%
% keepref: this parameter currently does nothing
% filesuffix: optional suffix to append to re-referenced file.
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

loadpaths

if ~exist('keepref','var') || isempty(keepref)
    keepref = 0;
end

if ~exist('filesuffix','var') || isempty(filesuffix)
    filesuffix = '';
end

if ischar(basename)
    EEG = pop_loadset('filepath',filepath,'filename',[basename '_clean.set']);
elseif isstruct(basename)
    EEG = basename;
end

if isfield(EEG.chanlocs,'badchan')
    badchannels = find(cell2mat({EEG.chanlocs.badchan}));
else
    badchannels = [];
end

if ~exist('refmode','var') || isempty(refmode)
    refmodes = {'Common','Laplacian','Linked Mastoid','None','Current Source Density'};
    [refmode,ok] = listdlg('ListString',refmodes,'SelectionMode','single','Name','Re-referencing',...
        'PromptString','Choose re-referencing type');
else
    ok = 1;
end

if refmode == 4
    fprintf('Data reference unchanged.\n');
    return;
end

if ok
    if isfield(EEG.chaninfo,'ndchanlocs') && isstruct(EEG.chaninfo.ndchanlocs)
        EEG.chaninfo.nodatchans = EEG.chaninfo.ndchanlocs;
        czidx = find(strcmp('Cz',{EEG.chaninfo.ndchanlocs.labels}));
    elseif isfield(EEG.chaninfo,'nodatchans') && isstruct(EEG.chaninfo.nodatchans)
        EEG.chaninfo.ndchanlocs = EEG.chaninfo.nodatchans;
        czidx = find(strcmp('Cz',{EEG.chaninfo.ndchanlocs.labels}));
    else
        czidx = [];
    end
    
    switch refmode
        case 1
            fprintf('Referencing to common average.\n');
            if isempty(czidx)
                EEG = pop_reref( EEG, [], 'exclude', badchannels);
            else
                fieldloc = fieldnames(EEG.chanlocs);
                for ind = 1:length(fieldloc)
                    if ~isfield(EEG.chaninfo.ndchanlocs(czidx),fieldloc{ind})
                        EEG.chaninfo.ndchanlocs(czidx).(fieldloc{ind}) = [];
                    end
                end
                EEG = pop_reref( EEG, [], 'exclude', badchannels,'refloc',EEG.chaninfo.ndchanlocs(czidx));
                EEG.chaninfo.ndchanlocs(strcmp('Cz',{EEG.chaninfo.ndchanlocs.labels})) = [];
            end
            EEG.ref = 'averef';
            
        case 2
            fprintf('Referencing to laplacian average.\n');
            if ~isempty(czidx)
                EEG.chanlocs(end+1).labels = EEG.chaninfo.ndchanlocs(czidx).labels;
                fieldloc = fieldnames(EEG.chaninfo.ndchanlocs(czidx));
                for ind = 1:length(fieldloc)
                    EEG.chanlocs(end).(fieldloc{ind}) = EEG.chaninfo.ndchanlocs(czidx).(fieldloc{ind});
                end
                EEG.chanlocs(end).type = '';
                EEG.chaninfo.ndchanlocs(czidx) = [];
                EEG.data(end+1,:,:) = 0;
                EEG.nbchan = EEG.nbchan + 1;
            end
            % EEGLAB has nose direction as X-axis and right ear direction
            % as Y-axis, whereas cart2sph expects the reverse. Hence swap X
            % and Y below
            chanlocs = cat(2,cell2mat({EEG.chanlocs.Y})',cell2mat({EEG.chanlocs.X})',cell2mat({EEG.chanlocs.Z})');
            EEG.data = permute(lar(permute(EEG.data,[3 2 1]),chanlocs,badchannels),[3 2 1]);
            EEG.ref = 'laplacian';
            
        case 3
            
            [refchan,ok] = listdlg2('ListString',{EEG.chanlocs.labels},'Name','Reference Channels',...
                'PromptString','Select channels for offline rereferencing:');
            if ~ok
                error('No valid reference channels selected.');
            end
            
            refchan = setdiff(refchan,badchannels);
            fprintf('Referencing to %s.\n',cell2mat({EEG.chanlocs(refchan).labels}));
            EEG.ref = cell2mat({EEG.chanlocs(refchan).labels});
            
            if isempty(czidx)
                EEG = pop_reref( EEG, refchan, 'exclude', badchannels);
            else
                fieldloc = fieldnames(EEG.chanlocs);
                for ind = 1:length(fieldloc)
                    if ~isfield(EEG.chaninfo.ndchanlocs(czidx),fieldloc{ind})
                        EEG.chaninfo.ndchanlocs(czidx).(fieldloc{ind}) = [];
                    end
                end
                EEG = pop_reref( EEG, refchan, 'exclude', badchannels,'refloc',EEG.chaninfo.ndchanlocs(czidx));
                EEG.chaninfo.ndchanlocs(strcmp('Cz',{EEG.chaninfo.ndchanlocs.labels})) = [];
            end
            
        case 4
            fprintf('Data reference unchanged.\n');
            return;
            
        case 5
            fprintf('Computing current source density.\n');
            if ~isempty(czidx)
                EEG.chanlocs(end+1).labels = EEG.chaninfo.ndchanlocs(czidx).labels;
                fieldloc = fieldnames(EEG.chaninfo.ndchanlocs(czidx));
                for ind = 1:length(fieldloc)
                    EEG.chanlocs(end).(fieldloc{ind}) = EEG.chaninfo.ndchanlocs(czidx).(fieldloc{ind});
                end
                EEG.chanlocs(end).type = '';
                EEG.chaninfo.ndchanlocs(czidx) = [];
                EEG.chaninfo.nodatchans(czidx) = [];
                EEG.data(end+1,:,:) = 0;
                EEG.nbchan = EEG.nbchan + 1;
            end
            % EEGLAB has nose direction as X-axis and right ear direction
            % as Y-axis, whereas cart2sph expects the reverse. Hence swap X
            % and Y below
            chanlocs = cat(2,cell2mat({EEG.chanlocs.Y})',cell2mat({EEG.chanlocs.X})',cell2mat({EEG.chanlocs.Z})');
            [sph.theta, sph.phi] = cart2sph(chanlocs(:,1),chanlocs(:,2),chanlocs(:,3));
            sph.theta = (180/pi) * sph.theta;
            sph.phi = (180/pi) * sph.phi;
            sph.lab = {EEG.chanlocs.labels}';
            [G,H] = GetGH(sph);
            EEG.data = double(CSD(single(EEG.data),G,H));
            EEG.ref = 'csd';
    end
    
    if ischar(basename)
        fprintf('Saving to %s%s.set.\n',basename,filesuffix);
        pop_saveset(EEG,'filepath',filepath,'filename',[basename filesuffix '.set']);
    end
end