function rejectic(basename,varargin)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
% 
% Visualise ICs using EEGLAB in groups of 35, and enable user to mark noisy ones.
% Delete marked ICs and project them back into data space.
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

param = finputcheck(varargin, { ...
    'showcomp' , 'string' , {'on','off'}, 'on'; ...
    'skip' , 'string' , {'on','off'}, 'off'; ...
    'sortorder', 'integer', [], []; ...
    'prompt' , 'string' , {'on','off'}, 'on'; ...
    });


destname = [basename '_clean'];
destfile = [basename '_clean.set'];
filename = [basename '_epochs.set'];
EEG = pop_loadset('filename', filename, 'filepath', filepath);


if strcmp(param.skip,'off')
    if isempty(EEG.icaweights)
        EEG = computeic(EEG);
        if ~isfield(EEG.reject,'gcompreject') || isempty(EEG.reject.gcompreject)
            EEG.reject.gcompreject = zeros(1,size(EEG.icaweights,1));
        end
        EEG.saved = 'no';
        pop_saveset(EEG, 'savemode', 'resave');
    end
    
    evalin('base','eeglab');
    assignin('base','EEG',EEG);
    evalin('base','[ALLEEG EEG index] = eeg_store(ALLEEG,EEG,0);');
    
    if strcmp(param.showcomp,'on')
        
        if isempty(param.sortorder)
            param.sortorder = 1:size(EEG.icaweights,1);
        end
        
        EEG = VisEd(EEG,2,['[' num2str(param.sortorder) ']'],{},'spacing',15);
        comptimefig = gcf;
        set(comptimefig,'Name',basename);
        g = get(comptimefig, 'UserData');
        badchan_old = cell2mat({g.eloc_file.badchan});
        
        curcmap = get(0,'DefaultFigureColormap');
        set(0,'DefaultFigureColormap',feval('jet'));
        for comp = 1:35:length(param.sortorder);
            if strcmp(param.prompt,'on')
                choice = questdlg(sprintf('Plot component maps %d-%d?',comp,min(comp+34,length(param.sortorder))),...
                    mfilename,'Yes','No','Yes');
                if ~strcmp(choice,'Yes')
                    break;
                end
            elseif comp > 35
                break;
            end
            pop_selectcomps(EEG, param.sortorder(comp:min(comp+34,length(param.sortorder))));
            uiwait;
            EEG = evalin('base','EEG');
            
            if ishandle(comptimefig)
                g = get(comptimefig, 'UserData');
                badchan_new = cell2mat({g.eloc_file.badchan});
                
                for c = 1:length(badchan_old)
                    if badchan_old(c) == 0 && (badchan_new(c) == 1 || EEG.reject.gcompreject(param.sortorder(c)) == 1)
                        g.eloc_file(c).badchan = 1;
                    elseif badchan_old(c) == 1 && (badchan_new(c) == 0 || EEG.reject.gcompreject(param.sortorder(c)) == 0)
                        g.eloc_file(c).badchan = 0;
                    end
                end
                set(comptimefig, 'UserData', g);
                eegplot('drawp',0,[],comptimefig);
            end
        end
        set(0,'DefaultFigureColormap',curcmap);
        
        if ishandle(comptimefig)
            uiwait(comptimefig);
        end
        
        EEG = evalin('base','EEG');
        
        EEG.saved = 'no';
        
        if strcmp(param.prompt,'on')
            choice = questdlg(sprintf('Overwrite %s?',EEG.filename),...
                mfilename,'Yes','No','Yes');
            
            if ~strcmp(choice,'Yes')
                return;
            end
        end
        
        fprintf('Resaving to %s%s.\n',EEG.filepath,EEG.filename);
        pop_saveset(EEG, 'savemode', 'resave');
    end
    
    rejectics = find(EEG.reject.gcompreject);
    fprintf('\n%d ICs marked for rejection: ', length(rejectics));
    
    fprintf('comp%d, ',rejectics(1:end));
    fprintf('\n');
    
    if strcmp(param.prompt,'on')
        choice = questdlg(sprintf('Reject marked ICs and overwrite %s?',destfile),...
            mfilename,'Yes','No','Yes');
        
        if ~strcmp(choice,'Yes')
            return;
        end
    end
    
    if ~isempty(rejectics)
        fprintf('Rejecting marked ICs\n');
        EEG = pop_subcomp( EEG, rejectics, 0);
        EEG = eeg_checkset(EEG);
    end
end

EEG.setname = destname;
EEG.filename = destfile;
fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG, 'filepath', EEG.filepath, 'filename', EEG.filename);

fprintf('\n');

evalin('base','eeglab');
assignin('base','EEG',EEG);
evalin('base','[ALLEEG EEG index] = eeg_store(ALLEEG,EEG,0);');
evalin('base','eeglab redraw');