function eval_demo_results( resultsmatfile )

if nargin < 1, resultsmatfile = 'results_1_mini_headMoving_nsGt.mat'; end

rmf = load( resultsmatfile );

% NIGENS classes
classes = {{'alarm'},{'baby'},{'femaleSpeech'},{'fire'},{'crash'},{'dog'},...
           {'engine'},{'footsteps'},{'knock'},{'phone'},{'piano'},...
           {'maleSpeech'},{'femaleScream','maleScream'}};
classes = cellfun( @(c)(strcat( c{:} )), classes, 'UniformOutput', false );

% ground truth
time_uncovered_FS = [rmf.modelData.fs_onOffs(1:end-1,2) rmf.modelData.fs_onOffs(2:end,1)];
tu_FS = sum( time_uncovered_FS(:,2) - time_uncovered_FS(:,1) );
gt_ccOnoffs_FS = extractGtCcOnoffs( rmf, 1:numel( rmf.labels ), time_uncovered_FS, classes );
time_uncovered_SI = [rmf.modelData.si_dects.onOffs(1:end-1,2) rmf.modelData.si_dects.onOffs(2:end,1)];
maxSrcLen = max( cellfun( @numel, rmf.activity ) );
for srcidx = 1 : numel( rmf.labels )
    rmf.activity{srcidx}(maxSrcLen) = 0;
    gt_ccOnoffs_SI{srcidx} = extractGtCcOnoffs( rmf, srcidx, time_uncovered_SI, classes );
end
activity = cat( 1, rmf.activity{:} )';

% Fullstream id
for cc = 1 : 13
    % model pos on- and offset times
    iddpos_cc = rmf.modelData.fs_d(:,cc) > 0;
    iddOnOffs = rmf.modelData.fs_onOffs(iddpos_cc,:);
    iddOnOffs = sortAndMergeOnOffs( iddOnOffs );

    ide(cc).time.testpos = sum( iddOnOffs(:,2) - iddOnOffs(:,1) );
    ide(cc).time.testneg = rmf.modelData.finishTime - ide(cc).time.testpos - tu_FS;
    ide(cc).time.condpos = sum( gt_ccOnoffs_FS{cc}(:,2) - gt_ccOnoffs_FS{cc}(:,1) );
    ide(cc).time.condneg = rmf.modelData.finishTime - ide(cc).time.condpos - tu_FS;
    ide(cc).time.truepos = 0;
    for kk = 1:size(iddOnOffs,1)
        intersectOffs = min( iddOnOffs(kk,2), gt_ccOnoffs_FS{cc}(:,2) );
        intersectOns = max( iddOnOffs(kk,1), gt_ccOnoffs_FS{cc}(:,1) );
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
            ( sum( (gt_ccOnoffs_FS{cc}(:,1) <= endBlockTime) ...
            == (gt_ccOnoffs_FS{cc}(:,2) >= endBlockTime) ) ...
            + sum( (gt_ccOnoffs_FS{cc}(:,1) <= startBlockTime) ...
            == (gt_ccOnoffs_FS{cc}(:,2) >= startBlockTime) ) ...
            + sum( (gt_ccOnoffs_FS{cc}(:,1) >= startBlockTime) ...
            == (gt_ccOnoffs_FS{cc}(:,2) <= endBlockTime) ) )...
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

% Segregated id
[segid_results,scp] = convertToSegIdResultsFormat( rmf, gt_ccOnoffs_SI, activity );
[sens_b,spec_b] = getPerformanceDecorrMaximumSubset( segid_results.resc_b, ...
                                                     [segid_results.resc_b.id.posPresent], ...
                                                     {}, {}, ...
                                                     [segid_results.resc_b.id.classIdx,segid_results.resc_b.id.scpId] );
sens_b = sens_b(2);
spec_b_npp = spec_b(1);
spec_b_pp = spec_b(2);
fprintf( 'SI class-average block-calc Sensitivity/stream-wise: %.2f\n', sens_b );
fprintf( 'SI class-average block-calc Specificity/stream-wise/positive present: %.2f\n', spec_b_pp );
fprintf( 'SI class-average block-calc Specificity/stream-wise/no positive present: %.2f\n', spec_b_npp );
[sens_t,spec_t] = getPerformanceDecorrMaximumSubset( segid_results.resc_t, [], ...
                                                     {}, {}, ...
                                                     [segid_results.resc_t.id.classIdx,segid_results.resc_t.id.scpId] );
bac_t = 0.5*sens_t+0.5*spec_t;
fprintf( 'SI class-average block-calc BAC/time-wise (SENS,SPEC): %.2f (%.2f,%.2f)\n', bac_t,sens_t,spec_t );
rs_t_pp = segid_results.resc_t.filter( segid_results.resc_t.id.posPresent, @(x)(x==1) );
rs_t_ppd = rs_t_pp.filter( rs_t_pp.id.nYp, @(x)(x==1) );
azmErr_ppd = getAttributeDecorrMaximumSubset( rs_t_ppd, rs_t_ppd.id.azmErr, ...
                                              [], {}, {},...
                                              [rs_t_ppd.id.classIdx,rs_t_ppd.id.scpId] );
azmErr_ppd = (azmErr_ppd-1)*5;
fprintf( 'SI class-average block-calc AzmErr/positive present and detected: %.1f°\n', azmErr_ppd );
nyp_ppd = getAttributeDecorrMaximumSubset( rs_t_ppd, rs_t_ppd.id.nYp, ...
                                           [], {}, {},...
                                           [rs_t_ppd.id.classIdx,rs_t_ppd.id.scpId] );
nyp_ppd = nyp_ppd - 1;
fprintf( 'SI class-average block-calc NEP/positive present and detected: %.2f\n', nyp_ppd - 1 );
rs_t_npp = segid_results.resc_t.filter( segid_results.resc_t.id.posPresent, @(x)(x==2) );
nyp_npp = getAttributeDecorrMaximumSubset( rs_t_npp, rs_t_npp.id.nYp, ...
                                           [], {}, {},...
                                           [rs_t_npp.id.classIdx,rs_t_npp.id.scpId] );
nyp_npp = nyp_npp - 1;
fprintf( 'SI class-average block-calc NP/no positive present: %.2f\n', nyp_npp );
rs_b_pp = segid_results.resc_b.filter( segid_results.resc_b.id.posPresent, @(x)(x==1) );
rs_b_ppd = rs_b_pp.filter( rs_b_pp.id.nYp, @(x)(x==1) );
[placementLlh_scp_azms_ppd, ~, ~, bapr_scp_ppd] = getAzmPlacement( rs_b_ppd, rs_t_ppd, 'estAzm', 0, false );
[llhTPplacem_stats_avgNsp,azmsInterp] = computeInterpPlacementLlh( placementLlh_scp_azms_ppd, ...
                                                                   scp, 5, true, [], [], [], false );

fprintf( 'SI class-average block-calc BAPR: %.2f\n', mean( bapr_scp_ppd ) );

figure;
hold on;
azmsInterp(any( isnan( llhTPplacem_stats_avgNsp ), 1 )) = [];
llhTPplacem_stats_avgNsp(:,any( isnan( llhTPplacem_stats_avgNsp ), 1 )) = [];
patch( [azmsInterp, flip( azmsInterp )], [llhTPplacem_stats_avgNsp(2,:), flip( llhTPplacem_stats_avgNsp(3,:))], 1, 'facealpha', 0.1, 'edgecolor', 'none', 'facecolor', [0,0,0.8] );
plot( azmsInterp, llhTPplacem_stats_avgNsp(6,:), 'DisplayName', 'median', 'LineWidth', 2, 'color', [0,0,0.8] );
ylabel( 'Placement likelihood' );
ylim( [0 1] );
xlim( [0 180] );
xlabel( 'Distance to correct azimuth (°)' );
set( gca, 'XTick', [0,20,45,90,135,180] );
title( 'Interpolated Placement Likelihood' );

end

%% ---------------------------------------------------------------------------------------------- %%

function gt_ccOnoffs = extractGtCcOnoffs( rmf, srcIdxs, time_uncovered, classes )
    for cc = 1 : 13
        % class-wise ground truth pos on- and offset times
        gt_ccActive{cc} = cellfun( @(c)(strcmp(c,classes{cc})), rmf.labels(srcIdxs), 'UniformOutput', false );
        gt_ccOnoffs{cc} = cellfun( @(gc,mc)(gc(mc,:)), rmf.onOffsets(srcIdxs), gt_ccActive{cc}, 'UniformOutput', false );
        gt_ccOnoffs{cc} = cat( 1, gt_ccOnoffs{cc}{:} );
        gt_ccOnoffs{cc}(gt_ccOnoffs{cc}(:,1) > rmf.modelData.finishTime,:) = [];
        gt_ccOnoffs{cc}(gt_ccOnoffs{cc}(:,2) > rmf.modelData.finishTime,2) = rmf.modelData.finishTime;
        gt_ccOnoffs{cc} = sortAndMergeOnOffs( gt_ccOnoffs{cc} );

        % subtract time_uncovered from gt_ccOnoffs{cc}
        jj = size( gt_ccOnoffs{cc}, 1 );
        while jj >= 1
            for kk = 1 : size( time_uncovered, 1 )
                if time_uncovered(kk,2) <= gt_ccOnoffs{cc}(jj,1) || time_uncovered(kk,1) >= gt_ccOnoffs{cc}(jj,2)
                    continue;
                end
                if time_uncovered(kk,1) <= gt_ccOnoffs{cc}(jj,1) && time_uncovered(kk,2) >= gt_ccOnoffs{cc}(jj,2)
                    gt_ccOnoffs{cc}(jj,:) = [];
                elseif time_uncovered(kk,1) <= gt_ccOnoffs{cc}(jj,1) && time_uncovered(kk,2) < gt_ccOnoffs{cc}(jj,2)
                    gt_ccOnoffs{cc}(jj,1) = time_uncovered(kk,2);
                elseif time_uncovered(kk,1) > gt_ccOnoffs{cc}(jj,1) && time_uncovered(kk,2) >= gt_ccOnoffs{cc}(jj,2)
                    gt_ccOnoffs{cc}(jj,2) = time_uncovered(kk,1);
                elseif time_uncovered(kk,1) > gt_ccOnoffs{cc}(jj,1) && time_uncovered(kk,2) < gt_ccOnoffs{cc}(jj,2)
                    gt_ccOnoffs{cc} = cat( 1, gt_ccOnoffs{cc}(1:jj,:), gt_ccOnoffs{cc}(jj:end,:) );
                    gt_ccOnoffs{cc}(jj+1,1) = time_uncovered(kk,2);
                    gt_ccOnoffs{cc}(jj,2) = time_uncovered(kk,1);
                    jj = jj + 2;
                    break;
                end
            end
            jj = jj - 1;
        end
    end
end

function [sid_res, scp] = convertToSegIdResultsFormat( bb_results, gt_ccOnoffs_SI, activity )
    sid_res.resc_b = RescSparse( 'uint32', 'uint8' );
    sid_res.resc_t = RescSparse( 'uint32', 'uint8' );
    for ss = 1 : numel( bb_results.refAzimuths )
        scp(ss).azms = [bb_results.refAzimuths(ss) setdiff( bb_results.refAzimuths, bb_results.refAzimuths(ss) )'];
    end
    for cc = 1 : size( bb_results.modelData.si_dects.locs, 2 )
        scpid = 1;
        for ii = 1 : size( bb_results.modelData.si_dects.locs, 1 )
            startBlockTime = bb_results.modelData.si_dects.onOffs(ii,1);
            endBlockTime = bb_results.modelData.si_dects.onOffs(ii,2);
            blockInclEvent_gt_ss = false( 1, numel( bb_results.refAzimuths ) );
            for ss = 1 : numel( bb_results.refAzimuths )
                blockInclEvent_gt_ss(ss) = ...
                    ( sum( (gt_ccOnoffs_SI{ss}{cc}(:,1) <= endBlockTime) ...
                    == (gt_ccOnoffs_SI{ss}{cc}(:,2) >= endBlockTime) ) ...
                    + sum( (gt_ccOnoffs_SI{ss}{cc}(:,1) <= startBlockTime) ...
                    == (gt_ccOnoffs_SI{ss}{cc}(:,2) >= startBlockTime) ) ...
                    + sum( (gt_ccOnoffs_SI{ss}{cc}(:,1) >= startBlockTime) ...
                    == (gt_ccOnoffs_SI{ss}{cc}(:,2) <= endBlockTime) ) )...
                    >= 1;
            end
            eventActiveOnSrcs = find( blockInclEvent_gt_ss );
            if numel( eventActiveOnSrcs ) > 1
                continue; % skip blocks with target sound on more than one source (difficult to evaluate)
            elseif numel( eventActiveOnSrcs ) == 1
                scpid = eventActiveOnSrcs;
            end
            blockAct = activity(floor(startBlockTime*100):min(end,ceil(endBlockTime*100)),:);
            nsGt = sum( max( blockAct, [], 1 ), 2 );
            streamAzms_cc_ii = [bb_results.modelData.si_dects.locs{ii,cc,:}];
            nStreams = numel( streamAzms_cc_ii );
            streamAzms = repmat( wrapTo180( streamAzms_cc_ii' ), 1, nsGt );
            srcAzms = repmat( wrapTo180( bb_results.refAzimuths(logical( max( blockAct, [], 1 )))' ), nStreams, 1 );
            streamSrcAzmDists = abs( wrapTo180( srcAzms - streamAzms ) );
            [~,streamSrcAssignment] = min( streamSrcAzmDists, [], 1 );
            streamSrcAssignment = streamAzms_cc_ii(streamSrcAssignment);
            newBlocks = [];
            newYt = [];
            newYp = [];
            for dd = 1 : size( bb_results.modelData.si_dects.locs, 3 )
                siPred = bb_results.modelData.si_dects.locs{ii,cc,dd};
                for pp = 1 : numel( siPred )
                    newBlock = PerformanceMeasures.BAC_BAextended.nanRescStruct();
                    newBlock.scpId = scpid;
                    newBlock.classIdx = cc;
                    newBlock.nAct = nsGt;
                    newBlock.nYp = numel( bb_results.modelData.si_dects.locs{ii,cc,2} );
                    newBlock.estAzm = siPred(pp);
                    srcidx = find( streamSrcAssignment == newBlock.estAzm );
                    blockInclEvent_gt = any( blockInclEvent_gt_ss(srcidx) );
                    newBlock.posPresent = blockInclEvent_gt;
                    if ~isempty( srcidx )
                        if blockInclEvent_gt
                            newBlock.gtAzm = bb_results.refAzimuths(eventActiveOnSrcs);
                        else
                            newBlock.gtAzm = bb_results.refAzimuths(srcidx);
                        end
                        newBlock.azmErr = mean( abs( wrapTo180( newBlock.gtAzm - newBlock.estAzm ) ) );
                        if numel( newBlock.gtAzm ) > 1
                            newBlock.gtAzm = newBlock.gtAzm(randi( numel( newBlock.gtAzm ) ));
                        end
                    end
                    if dd == 1 && ~blockInclEvent_gt
                        newYt(end+1) = -1;
                        newYp(end+1) = -1;
                    elseif dd == 1 && blockInclEvent_gt
                        newYt(end+1) = 1;
                        newYp(end+1) = -1;
                    elseif dd == 2 && blockInclEvent_gt
                        newYt(end+1) = 1;
                        newYp(end+1) = 1;
                    elseif dd == 2 && ~blockInclEvent_gt
                        newYt(end+1) = -1;
                        newYp(end+1) = 1;
                    else
                        error( 'this should not happen' );
                    end
                    if isempty( newBlocks ), newBlocks = newBlock;
                    else newBlocks(end+1) = newBlock; 
                    end
                end
            end
            [newBlocks.posPresent] = deal( any( [newBlocks.posPresent] ) );
            [bap, asg, azmErrs] = PerformanceMeasures.BAC_BAextended.aggregateBlockAnnotations3( newBlocks, newYp, newYt );
            pis = PerformanceMeasures.BAC_BAextended.baParams2bapIdxs( bap );
            [agBap, agAsg] = PerformanceMeasures.BAC_BAextended.aggregateBlockAnnotations( newBlocks, newYp, newYt, azmErrs );
            agPis = PerformanceMeasures.BAC_BAextended.baParams2bapIdxs( agBap );
            sid_res.resc_b = PerformanceMeasures.BAC_BAextended.addDpiToResc( sid_res.resc_b, asg, pis );
            if any( ~cellfun( @isempty, agAsg ) )
                sid_res.resc_t = PerformanceMeasures.BAC_BAextended.addDpiToResc( sid_res.resc_t, agAsg, agPis );
            end
        end
        fprintf( ':' );
    end
    fprintf( '\n' );
end






