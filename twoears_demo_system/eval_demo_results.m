function eval_demo_results( resultsmatfile )

if nargin < 1, resultsmatfile = 'results_1.mat'; end

rmf = load( resultsmatfile );

% NIGENS classes
classes = {{'alarm'},{'baby'},{'femaleSpeech'},{'fire'},{'crash'},{'dog'},...
           {'engine'},{'footsteps'},{'knock'},{'phone'},{'piano'},...
           {'maleSpeech'},{'femaleScream','maleScream'}};
classes = cellfun( @(c)(strcat( c{:} )), classes, 'UniformOutput', false );

% FS id
for cc = 1 : 13
    % class-wise model pos on- and offset times
    iddpos_cc = rmf.modelData.fs_d(:,cc) > 0;
    iddOnOffs = rmf.modelData.fs_onOffs(iddpos_cc,:);
    iddOnOffs = sortrows( iddOnOffs );
    kk = 1;
    while kk < size( iddOnOffs, 1 )
        if iddOnOffs(kk,2) >= iddOnOffs(kk+1,1)
            iddOnOffs(kk,2) = iddOnOffs(kk+1,2);
            iddOnOffs(kk+1,:) = [];
        else
            kk = kk + 1;
        end
    end

    % class-wise ground truth pos on- and offset times
    gt_ccActive = cellfun( @(c)(strcmp(c,classes{cc})), rmf.labels, 'UniformOutput', false );
    gt_ccOnoffs = cellfun( @(gc,mc)(gc(mc,:)), rmf.onOffsets, gt_ccActive, 'UniformOutput', false );
    gt_ccOnoffs = cat( 1, gt_ccOnoffs{:} );
    gt_ccOnoffs = sortrows( gt_ccOnoffs );
    kk = 1;
    while kk < size( gt_ccOnoffs, 1 )
        if gt_ccOnoffs(kk,2) >= gt_ccOnoffs(kk+1,1)
            gt_ccOnoffs(kk,2) = gt_ccOnoffs(kk+1,2);
            gt_ccOnoffs(kk+1,:) = [];
        else
            kk = kk + 1;
        end
    end

    ide(cc).time.testpos = sum( iddOnOffs(:,2) - iddOnOffs(:,1) );
    ide(cc).time.testneg = max( cellfun( @length, rmf.activity) )/44100 - ide(cc).time.testpos;
    ide(cc).time.condpos = sum( gt_ccOnoffs(:,2) - gt_ccOnoffs(:,1) );
    ide(cc).time.condneg = max( cellfun( @length, rmf.activity) )/44100 - ide(cc).time.condpos;
    ide(cc).time.truepos = 0;
    for kk = 1:size(iddOnOffs,1)
        intersectOffs = min( iddOnOffs(kk,2), gt_ccOnoffs(:,2) );
        intersectOns = max( iddOnOffs(kk,1), gt_ccOnoffs(:,1) );
        overlaps = max( 0, intersectOffs - intersectOns );
        ide(cc).time.truepos = ide(cc).time.truepos + sum( overlaps );
    end
    ide(cc).time.trueneg = ide(cc).time.condneg - ide(cc).time.testpos + ide(cc).time.truepos;
    ide(cc).time = IdEvalFrame.meanErrors( ide(cc).time );
end
ide_ccAvg.time.bac = nanMean( arrayfun( @(a)(a.time.bac), ide ) );
fprintf( 'FS class-average BAC: %.2f\n', ide_ccAvg.time.bac );

end
