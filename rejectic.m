function rejectic(basename,varargin)

loadpaths

param = finputcheck(varargin, { ...
    'prompt' , 'string' , {'on','off'}, 'on'; ...
    'skip' , 'string' , {'on','off'}, 'off'; ...
    'sortorder', 'integer', [], []; ...
    });


destfile = [basename '.set'];
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
    
    if strcmp(param.prompt,'on')
        
        if isempty(param.sortorder)
            param.sortorder = 1:size(EEG.icaweights,1);
        end
        
        EEG = VisEd(EEG,2,['[' num2str(param.sortorder) ']'],{});
        comptimefig = gcf;
        set(comptimefig,'Name',basename);
        g = get(comptimefig, 'UserData');
        badchan_old = cell2mat({g.eloc_file.badchan});
        
        for comp = 0:35:length(param.sortorder);
            choice = questdlg(sprintf('Plot component maps %d-%d?',comp+1,min(comp+35,length(param.sortorder))),...
                mfilename,'Yes','No','Yes');
            if ~strcmp(choice,'Yes')
                break;
            end
            pop_selectcomps(EEG, param.sortorder(comp+1:min(comp+35,length(param.sortorder))));
            uiwait;
            EEG = evalin('base','EEG');
            
            if ishandle(comptimefig)
                g = get(comptimefig, 'UserData');
                badchan_new = cell2mat({g.eloc_file.badchan});
                
                plotcomp = param.sortorder;
                for c = plotcomp
                    if badchan_old(c) == 0 && (badchan_new(c) == 1 || EEG.reject.gcompreject(c) == 1)
                        g.eloc_file(c).badchan = 1;
                    elseif badchan_old(c) == 1 && (badchan_new(c) == 0 || EEG.reject.gcompreject(c) == 0)
                        g.eloc_file(c).badchan = 0;
                    end
                end
                set(comptimefig, 'UserData', g);
                eegplot('drawp',0,[],comptimefig);
            end
        end
        
        if ishandle(comptimefig)
            uiwait(comptimefig);
        end
        
        EEG = evalin('base','EEG');
        
        EEG.saved = 'no';
        
        choice = questdlg(sprintf('Overwrite %s?',EEG.filename),...
            mfilename,'Yes','No','Yes');
        
        if ~strcmp(choice,'Yes')
            return;
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

EEG.setname = basename;
EEG.filename = destfile;
fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG, 'filepath', EEG.filepath, 'filename', EEG.filename);

fprintf('\n');

evalin('base','eeglab');
assignin('base','EEG',EEG);
evalin('base','[ALLEEG EEG index] = eeg_store(ALLEEG,EEG,0);');
evalin('base','eeglab redraw');