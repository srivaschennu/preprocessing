function EEG = rmlinenoisemt(EEG,freq)

if ~exist('freq','var') || isempty(freq)
    freq = 50;
end

% for c = 1:EEG.nbchan
%     for e = 1:EEG.trials
%         EEG.data(c,:,e) = cca_multitaper(EEG.data(c,:,e),EEG.srate,freq,EEG.srate);
%     end
% end

EEG = pop_cleanline(EEG,'LineFrequencies',[freq freq*2],'Bandwidth',2,'SignalType','Channels');
 