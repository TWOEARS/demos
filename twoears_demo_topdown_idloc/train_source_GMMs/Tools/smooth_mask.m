function outMask= smooth_mask(inMask)

MEDIAN_FILTER_SIZE= [3 5];
GAUSS_FILTER_SIZE= [3 5];
GAUSS_FILTER_SIGMA= .5;

%Pad the input mask replicating the border pixels before filtering it
hmed2= fix(MEDIAN_FILTER_SIZE/2);
m= padarray(inMask, hmed2, 'replicate', 'both');
%Median filter
outMask= medfilt2(m, MEDIAN_FILTER_SIZE);
%Crop the fitered mask
[fils cols]= size(inMask);
outMask= outMask(hmed2(1)+1:hmed2(1)+fils, hmed2(2)+1:hmed2(2)+cols);

%Gaussian filter
hgauss= fspecial('gaussian', GAUSS_FILTER_SIZE, GAUSS_FILTER_SIGMA);
outMask= imfilter(outMask, hgauss, 'replicate', 'same');
