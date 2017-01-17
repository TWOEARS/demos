function azEst = estAzimuth_GMM(prob,gridAz,intMethod,nSources,bPlot)

if nargin < 3 || isempty(intMethod); intMethod = 'HIST'; end
if nargin < 4 || isempty(nSources);  nSources  = inf;    end
if nargin < 5 || isempty(bPlot);     bPlot     = false;  end

% Determine size of probability map
[nFrames,nAz,nFilter] = size(prob);
 
% Ensure column vector 
gridAz = gridAz(:);

% Check for consistency
if nAz ~= length(gridAz)
    error('Dimensionality mismatch between the 3D probability map and the azimuth grid.')
end

% Determine azimuth step size
deltaAz = abs(diff(gridAz(1:2)));

% Allocate memory, if less peaks than nSources are identified, they will be
% replaced by NANs
if isfinite(nSources); azEst = nan(nSources,1); end;

% Select method for integrating localiztaion information across time
switch(upper(intMethod))    
    case 'AVG'        
        % Integrate probabilities across all filters
        prob_AF = exp(squeeze(nansum(log(prob),3)));
        
        % Normalize such that probabilities sum up to one for each frame
        prob_AFN = transpose(prob_AF ./ repmat(sum(prob_AF,2),[1 nAz]));

        % Integrate across all frames 
        prob_AFN_F = nanmean(prob_AFN,2);
       
    case 'HIST'
        % Integrate probabilities across all filters
        prob_AF = exp(squeeze(nansum(log(prob),3)));
        
        % Normalize such that probabilities sum up to one for each frame
        prob_AFN = transpose(prob_AF ./ repmat(sum(prob_AF,2),[1 nAz]));
        
        % Find maximum lag per frame
        maxInt = argmax(prob_AFN,1);
        
        % Histogram
        prob_AFN_F = hist(gridAz(maxInt),gridAz);
end

% Find peaks, also consider endpoints as peak candidates
pIdx = findpeaks([0; prob_AFN_F(:); 0]);
pIdx = pIdx - 1;

% Rank peaks
[temp,idx] = sort(prob_AFN_F(pIdx),'descend'); %#ok

% Number of azimuth estimates
nEst = min(numel(idx),nSources);

% Apply exponential interpolation to refine peak position
delta = interpolateParabolic(prob_AFN_F,pIdx(idx(1:nEst)));
        
% Azimuth estimate: Take most significant peaks
azEst(1:nEst) = gridAz(pIdx(idx(1:nEst))) + deltaAz * delta;

% Plot results
if bPlot || nargout == 0
    
    nTicksY = 5;
    nTicksX = 7;
    
    xTickIdx = 1:round(nAz/nTicksX):nAz;
    yTickIdx = 1:round(nFrames/nTicksY):nFrames;
    
    azimIdx  = 1:nAz;
    frameIdx = 1:nFrames;
    
    mIdxPlot = argmax(prob_AFN,1);
    mDelta   = interpolateParabolic(prob_AFN,mIdxPlot); 
    
    figure(gcf);clf;
    hSP1 = subplot(7,1,1:5);
    hpos = [0.1300    0.3690    0.7750    0.5560];
    set(hSP1,'position',hpos);
   
    imagesc(azimIdx,frameIdx,prob_AFN.');
    if isequal(upper(intMethod),'HIST')
        hold on;
        h = plot(azimIdx(mIdxPlot)+(5*mDelta),frameIdx,'k.','MarkerSize',18,'linewidth',2);
        set(h,'color',[0.8 0.8 0.8])
        hold off;
    end
    ylabel('Frame index')
    set(gca,'XTickLabel',[])
    hcb = colorbar;
    hpos = [0.9060    0.3690    0.0250    0.5560];

    set(hcb,'position',hpos);
    
    set(gca,'ytick',yTickIdx);    
    set(gca,'yticklabel',num2str(yTickIdx.'))
       
    ht = title('GMM pattern');
    htpos = get(ht,'position');
    htpos(2) = htpos(2) * 0.25;
    set(ht,'position',htpos);
       
    set(gca,'xtick',xTickIdx,'xticklabel',num2str(gridAz(xTickIdx)))

    xlim([0.5  nAz+0.5])
        
    hSP2 = subplot(7,1,6:7);
    hposS = get(hSP2,'position');
    hposS(2) = hposS(2) * 0.85;
    set(hSP2,'position',hposS);

    if isequal(upper(intMethod),'HIST')
        h = bar(azimIdx,prob_AFN_F,1);hold on;
        set(h,'FaceColor',[0.45 0.45 0.45])
    else
        h = plot(azimIdx,prob_AFN_F,'-');hold on;
        set(h,'color',[0.25 0.25 0.25],'linewidth',1.5)
    end
    plot(pIdx(idx(1:nEst))+delta,prob_AFN_F(pIdx(idx(1:nEst))),'kx','MarkerSize',18,'LineWidth',2.5)
    hold off;
    xlim([0.5  nAz+0.5])
    ylim([0 1.35*max(prob_AFN_F)])
    
    xlabel('Azimuth (deg)')
    ylabel('Activity')
    set(gca,'YTick',[],'YTickLabel',[])
    
    set(gca,'xtick',xTickIdx,'xticklabel',num2str(gridAz(xTickIdx)))
    box on;
        
    colormap(1-fireprint);
end