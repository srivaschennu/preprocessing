function EEG = computeic(filename,icatype,pcacheck)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 

% Computes and savesICA decomposition. Optionally runs PCA beforehand if there are
% insufficient for a stable ICA decomposition. For more, see here:
% 
% https://sccn.ucsd.edu/wiki/Chapter_09:_Decomposing_Data_Using_ICA
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

if ~exist('icatype','var') || isempty(icatype)
    icatype = 'runica';
end

if (strcmp(icatype,'runica') || strcmp(icatype,'binica') || strcmp(icatype,'mybinica')) && ...
    (~exist('pcacheck','var') || isempty(pcacheck))
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

if strcmp(icatype,'runica') || strcmp(icatype,'binica') || strcmp(icatype,'mybinica')
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
else
    icaopts = {};
end

if strcmp(icatype,'mybinica')
    EEG = mybinica(EEG);
else
    EEG = pop_runica(EEG, 'icatype',icatype,'dataset',1,'chanind',1:EEG.nbchan,'options',icaopts);
end

if ischar(filename) && ~isempty(EEG.icaweights)
    EEG.saved = 'no';
    fprintf('Saving %s%s\n',EEG.filepath,EEG.filename);
    pop_saveset(EEG, 'savemode', 'resave');
end