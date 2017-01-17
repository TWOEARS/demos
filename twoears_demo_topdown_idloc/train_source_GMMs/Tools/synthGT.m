function [s] = synthGT(x, fs, mask, lowcf, highcf, framerate)
% SYNTHGT   Synthesise target signal using the gammatone filterbank
%  [s] = synthGT(x, fs, mask, lowcf, highcf, frameshift)
%
%  x          - mixture signal
%  fs         - sampling frequency in Hz
%  mask       - missing data mask for the target signal
%  lowcf      - lowest centre frequency in Hz (default = 50)
%  highcf     - highest centre frequency in Hz (default = 8000)
%  framerate  - frame rate in ms (default = 10)
%
%  s          - synthesised target signal (column vector)
%

if nargin < 6
  framerate = 10;
end
if nargin < 5
  highcf = 8000;
end
if nargin < 4
  lowcf = 50;
end
if nargin < 3
  error('Not enough input');
end

x = x(:)';

[numChans,numFrames] = size(mask);
cf = makeErbCFs(lowcf, highcf, numChans);
winsize = round(2*fs*framerate/1000);  % in samples
win = hammingWin(winsize);
win4 = round(winsize/4);
s = zeros(size(x));
lenx = length(x);

for c = 1:numChans
  
  bm = gammatone_c(x, fs, cf(c));
  
  % time reverse and do it again
  bm = fliplr(bm);
  bm = gammatone_c(bm, fs, cf(c));
  bm = fliplr(bm);
  
  % overlap add in frames
  mrow = mask(c,:);
  for frame = 1:numFrames
    idx1 = max(1, frames2Samples(frame,framerate,fs)-win4);
    idx2 = min(lenx, idx1+winsize-1);
    len = idx2 - idx1 + 1;
    s(idx1:idx2) = s(idx1:idx2) + mrow(frame) .* bm(idx1:idx2) .* win(1:len);
  end
  
end

%s = s(:) ./ 2;

%---- end

%------------------------------------------
function cf = makeErbCFs(lfhz,hfhz,n)
% make ERB CFs

cf= erbRateToHz(linspace(hzToErbRate(lfhz),hzToErbRate(hfhz),n));


%------------------------------------------
function y = erbRateToHz(x)
% erb to hz conversion

y = (10.^(x/21.4)-1)/4.37e-3;


%------------------------------------------
function y=hzToErbRate(x)
% hz to erb conversion

y = (21.4*log10(4.37e-3*x+1));


%------------------------------------------
function samples = frames2Samples(n, fr, fs)
% convert from frame n at frame rate fr ms to samples at fs Hz

samples = round((fs*fr*(n-1))/1000)+1;


%------------------------------------------
function w = hammingWin(L)
% returns an L-point symmetric Hamming window in the column vector w.

w = 0.54 - 0.46 * cos(2*pi/(L-1).*[0:L-1]);

