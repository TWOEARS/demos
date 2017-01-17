function signals = readAudio(audioFiles,fsRef)

% Check for proper input arguments
if nargin ~= 2
    help(mfilename);
    error('Wrong number of input arguments!')
end

% Number of audio files
nFiles = numel(audioFiles);

% Allocate memory
nSamples = zeros(nFiles,1);
fsSig    = zeros(nFiles,1);
    
% Loop over number of audio files
for ii = 1 : nFiles
    nInfo = audioinfo(audioFiles{ii});
    nSamples(ii) = nInfo.TotalSamples;
    fsSig(ii) = nInfo.SampleRate;
end

% Overall duration
nSamplesMin = round(min(nSamples./fsSig.*fsRef));

% Allocate memory for signals
signals = zeros(nSamplesMin,nFiles);

% Loop over number of audio files
for ii = 1 : nFiles
    % Read ii-th signal
    [currSig] = audioread(audioFiles{ii});
    if fsSig(ii) ~= fsRef
        currSig = resample(currSig,fsRef,fsSig(ii));
    end
    currSig = currSig ./ rms(currSig);
    
    % Trim edges
    signals(:,ii) = currSig(1:nSamplesMin);
end

