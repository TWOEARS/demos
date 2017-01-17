function binaural = spatializeAudio(audio,fsHz,azimuth,room)

% Check for proper input arguments
if nargin ~= 4
    help(mfilename);
    error('Wrong number of input arguments!')
end

% Number of audio files
[nSamplesRef,nSources] = size(audio);

% Number of different azimuths
nAzim = numel(azimuth);

% Check for proper dimensionality
if nSources ~= nAzim
    error('The number of sources must match the number of azimuths.')
end

% Get BRIRs
[brir,fsHzBRIR] = getBRIRs(room,azimuth);
    
% Check if fsHzRef are consistent
if any(fsHzBRIR(1)~= fsHzBRIR)
    error('BRIR catalog sampling frequency mismatch across azimuths.')
else
    fsHzBRIR = fsHzBRIR(1);
end

% Resample audio, if required
if fsHz > fsHzBRIR
    % Upsample BRIR catalog
    brir = resampleData(brir, fsHzBRIR, fsHz);
    
    bDownSample = false;
elseif ~isequal(fsHz,fsHzBRIR)
    % Resample audio
    audio = resample(audio, fsHzBRIR, fsHz);
    
    bDownSample = true;
else
    bDownSample = false;
end

% Allocate memory
binaural = zeros(size(audio,1),2);

% Loop over number of audio files
for ii = 1 : nSources
    
    % Filter input signal with HRTFs
    for cc = 1 : size(brir,2)
        binaural(:,cc) = binaural(:,cc) + fftfilt(brir(:,cc,ii),audio(:,ii));
    end
end

if bDownSample
    % Down-sample audio to original fsHz
    binaural = resample(binaural,fsHz,fsHzBRIR);
    
    % Trim signal
    binaural = binaural(1:nSamplesRef,:,:);
end