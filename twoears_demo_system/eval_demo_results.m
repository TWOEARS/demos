function eval_demo_results( resultsmatfile )

if nargin < 1, resultsmatfile = 'results_1.mat'; end

rmf = load( resultsmatfile );

% NIGENS classes
classes = {{'alarm'},{'baby'},{'femaleSpeech'},{'fire'},{'crash'},{'dog'},...
           {'engine'},{'footsteps'},{'knock'},{'phone'},{'piano'},...
           {'maleSpeech'},{'femaleScream','maleScream'}};
classes = cellfun( @(c)(strcat( c{:} )), classes, 'UniformOutput', false );

% FS id
time_uncovered = [rmf.modelData.fs_onOffs(1:end-1,2) rmf.modelData.fs_onOffs(2:end,1)];
for cc = 1 : 13
    % class-wise model pos on- and offset times
    iddpos_cc = rmf.modelData.fs_d(:,cc) > 0;
    iddOnOffs = rmf.modelData.fs_onOffs(iddpos_cc,:);
    iddOnOffs = sortAndMergeOnOffs( iddOnOffs );

    % class-wise ground truth pos on- and offset times
    gt_ccActive = cellfun( @(c)(strcmp(c,classes{cc})), rmf.labels, 'UniformOutput', false );
    gt_ccOnoffs = cellfun( @(gc,mc)(gc(mc,:)), rmf.onOffsets, gt_ccActive, 'UniformOutput', false );
    gt_ccOnoffs = cat( 1, gt_ccOnoffs{:} );
    gt_ccOnoffs(gt_ccOnoffs(:,1) > rmf.modelData.finishTime,:) = [];
    gt_ccOnoffs(gt_ccOnoffs(:,2) > rmf.modelData.finishTime,2) = rmf.modelData.finishTime;
    gt_ccOnoffs = sortAndMergeOnOffs( gt_ccOnoffs );

    tu = sum( time_uncovered(:,2) - time_uncovered(:,1) );
    % subtract time_uncovered from gt_ccOnoffs
    jj = size( gt_ccOnoffs, 1 );
    while jj >= 1
        for kk = 1 : size( time_uncovered, 1 )
            if time_uncovered(kk,2) <= gt_ccOnoffs(jj,1) || time_uncovered(kk,1) >= gt_ccOnoffs(jj,2)
                continue;
            end
            if time_uncovered(kk,1) <= gt_ccOnoffs(jj,1) && time_uncovered(kk,2) >= gt_ccOnoffs(jj,2)
                gt_ccOnoffs(jj,:) = [];
            elseif time_uncovered(kk,1) <= gt_ccOnoffs(jj,1) && time_uncovered(kk,2) < gt_ccOnoffs(jj,2)
                gt_ccOnoffs(jj,1) = time_uncovered(kk,2);
            elseif time_uncovered(kk,1) > gt_ccOnoffs(jj,1) && time_uncovered(kk,2) >= gt_ccOnoffs(jj,2)
                gt_ccOnoffs(jj,2) = time_uncovered(kk,1);
            elseif time_uncovered(kk,1) > gt_ccOnoffs(jj,1) && time_uncovered(kk,2) < gt_ccOnoffs(jj,2)
                gt_ccOnoffs = cat( 1, gt_ccOnoffs(1:jj,:), gt_ccOnoffs(jj:end,:) );
                gt_ccOnoffs(jj+1,1) = time_uncovered(kk,2);
                gt_ccOnoffs(jj,2) = time_uncovered(kk,1);
                jj = jj + 2;
                break;
            end
        end
        jj = jj - 1;
    end
    
    ide(cc).time.testpos = sum( iddOnOffs(:,2) - iddOnOffs(:,1) );
    ide(cc).time.testneg = rmf.modelData.finishTime - ide(cc).time.testpos - tu;
    ide(cc).time.condpos = sum( gt_ccOnoffs(:,2) - gt_ccOnoffs(:,1) );
    ide(cc).time.condneg = rmf.modelData.finishTime - ide(cc).time.condpos - tu;
    ide(cc).time.truepos = 0;
    for kk = 1:size(iddOnOffs,1)
        intersectOffs = min( iddOnOffs(kk,2), gt_ccOnoffs(:,2) );
        intersectOns = max( iddOnOffs(kk,1), gt_ccOnoffs(:,1) );
        overlaps = max( 0, intersectOffs - intersectOns );
        ide(cc).time.truepos = ide(cc).time.truepos + sum( overlaps );
    end
    ide(cc).time.trueneg = ide(cc).time.condneg - ide(cc).time.testpos + ide(cc).time.truepos;
    ide(cc).time = IdEvalFrame.meanErrors( ide(cc).time );
    
    ide(cc).blocks.condpos = 0;
    ide(cc).blocks.condneg = 0;
    ide(cc).blocks.testpos = 0;
    ide(cc).blocks.truepos = 0;
    ide(cc).blocks.testneg = 0;
    ide(cc).blocks.trueneg = 0;
    for oo = 1 : size( rmf.modelData.fs_onOffs, 1 )
        startBlockTime = rmf.modelData.fs_onOffs(oo,1);
        endBlockTime = rmf.modelData.fs_onOffs(oo,2);
        blockInclEvent = ...
            ( sum( (gt_ccOnoffs(:,1) <= endBlockTime) ...
            == (gt_ccOnoffs(:,2) >= endBlockTime) ) ...
            + sum( (gt_ccOnoffs(:,1) <= startBlockTime) ...
            == (gt_ccOnoffs(:,2) >= startBlockTime) ) ...
            + sum( (gt_ccOnoffs(:,1) >= startBlockTime) ...
            == (gt_ccOnoffs(:,2) <= endBlockTime) ) )...
            >= 1;
        ide(cc).blocks.condpos = ide(cc).blocks.condpos + blockInclEvent;
        ide(cc).blocks.condneg = ide(cc).blocks.condneg + ~blockInclEvent;
        if rmf.modelData.fs_d(oo,cc) > 0
            ide(cc).blocks.testpos = ide(cc).blocks.testpos + 1;
            ide(cc).blocks.truepos = ide(cc).blocks.truepos + blockInclEvent;
        else
            ide(cc).blocks.testneg = ide(cc).blocks.testneg + 1;
            ide(cc).blocks.trueneg = ide(cc).blocks.trueneg + ~blockInclEvent;
        end
    end
    ide(cc).blocks = IdEvalFrame.meanErrors( ide(cc).blocks );
end
ide_ccAvg.time.bac = nanMean( arrayfun( @(a)(a.time.bac), ide ) );
ide_ccAvg.time.sens = nanMean( arrayfun( @(a)(a.time.sensitivity), ide ) );
ide_ccAvg.time.spec = nanMean( arrayfun( @(a)(a.time.specificity), ide ) );
ide_ccAvg.time.prec = nanMean( arrayfun( @(a)(a.time.prec), ide ) );
fprintf( 'FS class-average time-calc BAC (SENS,SPEC;PREC): %.2f (%.2f,%.2f;%.2f)\n', ide_ccAvg.time.bac, ide_ccAvg.time.sens, ide_ccAvg.time.spec, ide_ccAvg.time.prec );
ide_ccAvg.blocks.bac = nanMean( arrayfun( @(a)(a.blocks.bac), ide ) );
ide_ccAvg.blocks.sens = nanMean( arrayfun( @(a)(a.blocks.sensitivity), ide ) );
ide_ccAvg.blocks.spec = nanMean( arrayfun( @(a)(a.blocks.specificity), ide ) );
ide_ccAvg.blocks.prec = nanMean( arrayfun( @(a)(a.blocks.prec), ide ) );
fprintf( 'FS class-average block-calc BAC (SENS,SPEC;PREC): %.2f (%.2f,%.2f;%.2f)\n', ide_ccAvg.blocks.bac, ide_ccAvg.blocks.sens, ide_ccAvg.blocks.spec, ide_ccAvg.blocks.prec );

end
