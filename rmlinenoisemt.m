function EEG = rmlinenoisemt(EEG,freq)

if ~exist('freq','var') || isempty(freq)
    freq = 50;
end

% %GCCA toolbox function
% for c = 1:EEG.nbchan
%     for e = 1:EEG.trials
%         EEG.data(c,:,e) = cca_multitaper(EEG.data(c,:,e),EEG.srate,freq,EEG.srate);
%     end
% end

% EEGLAB's cleanline function
% EEG = pop_cleanline(EEG,'LineFrequencies',[freq freq*2],'Bandwidth',2,'SignalType','Channels');

fprintf('Notch Filtering.\n');
EEG = pop_eegfiltnew(EEG,freq-2,freq+2,[],1);
EEG = pop_eegfiltnew(EEG,(freq*2)-2,(freq*2)+2,[],1);
