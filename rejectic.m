function rejectic(basename,prompt,skip)

loadpaths

if ~exist('prompt','var') || isempty(prompt)
    prompt = true;
end

if ~exist('skip','var') || isempty(skip)
    skip = false;
end

destfile = [basename '.set'];
filename = [basename '_epochs.set'];
EEG = pop_loadset('filename', filename, 'filepath', filepath);

if ~skip
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
    
    if prompt
        EEG = VisEd(EEG,2,['[' num2str(1:size(EEG.icaweights,1)) ']'],{});
        comptimefig = gcf;
        
        for comp = 0:35:size(EEG.icaweights,1)
            choice = questdlg(sprintf('Plot component maps %d-%d?',comp+1,min(comp+35,size(EEG.icaweights,1))),...
                mfilename,'Yes','No','Yes');
            if ~strcmp(choice,'Yes')
                break;
            end
            pop_selectcomps(EEG, comp+1:min(comp+35,size(EEG.icaweights,1)));
            uiwait;
            EEG = evalin('base','EEG');
            
            g = get(comptimefig, 'UserData');
            for c = 1:length(EEG.reject.gcompreject)
                g.eloc_file(c).badchan = EEG.reject.gcompreject(c);
            end
            set(comptimefig, 'UserData', g);
            eegplot('drawp',0,[],comptimefig);
            
        end
        
        if ishandle(comptimefig)
            uiwait(comptimefig);
        end
        
        EEG = evalin('base','EEG');
        
        EEG.saved = 'no';
        
        if prompt
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
    
    if prompt
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