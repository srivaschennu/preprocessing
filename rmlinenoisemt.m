function EEG = rmlinenoisemt(EEG,freq)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
% 
% Removes line noise around selected frequency and its double using notch
% filtering.
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


if ~exist('freq','var') || isempty(freq)
    freq = 50;
end

fprintf('Notch Filtering.\n');
EEG = pop_eegfiltnew(EEG,freq-2,freq+2,[],1);
EEG = pop_eegfiltnew(EEG,(freq*2)-2,(freq*2)+2,[],1);
