function [bbs, locDecisionKS, segKS] = buildBlackboardSystem(robot, bFrontLocationOnly, bSolveConfusion, bIdentifySources, idSegModels, fsHz)

if ~exist('fsHz', 'var')
    fsHz = 16000;
end

%%
bbs = BlackboardSystem(1);
bbs.setRobotConnect(robot);

bbs.setDataConnect('AuditoryFrontEndKS', fsHz, 0.5);
segKS = bbs.createKS('TopdownSourceModelKS', {'JIDO-REC'});
if bFrontLocationOnly
    locKS = bbs.createKS('DnnLocationKS', {'MCT-DIFFUSE-FRONT'});
else
    locKS = bbs.createKS('DnnLocationKS', {'MCT-DIFFUSE'});
end
locDecisionKS = bbs.createKS('LocalisationDecisionKS', {bSolveConfusion, 0.5});
rotateKS = bbs.createKS('HeadRotationKS', {robot});
navKS = bbs.createKS('RobotNavigationKS', {robot});
%%
ppRemoveDc = false; 
%idLeakFactor = 0.5;
%idClassThresholds.fire = 0.8;
segIdClassThresholds.fire = 0.4;
segIdLeakFactor = 0.5;
segIdGaussWidth = 8;
segIdMaxObjects = 1;

%%
if bIdentifySources
    addPathsIfNotIncluded( {...
            cleanPathFromRelativeRefs( [pwd '/../../stream-segregation-training-pipeline/src'] ), ...
            cleanPathFromRelativeRefs( [pwd '/../../stream-segregation-training-pipeline/external/data-hash'] ), ...
            cleanPathFromRelativeRefs( [pwd '/../../stream-segregation-training-pipeline/external/yaml-matlab'] ) ...
            } );
    segmModelFileName = '70c4feac861e382413b4c4bfbf895695.mat';
    dirSegr = fullfile( db.tmp, 'learned_models', 'SegmentationKS' );
    if ~exist(dirSegr, 'dir')
        mkdir( dirSegr );
    end
    copyfile(  cleanPathFromRelativeRefs( [pwd '/../../AMLTTP/test/' segmModelFileName] ), ...
               fullfile( dirSegr, segmModelFileName ), ...
               'f' );
    fprintf( '.' );
    nsrcs = bbs.createKS( 'NumberOfSourcesKS', {'nSrcs_fc5','learned_models/NumberOfSourcesKS/mc3_models_dataset_1',ppRemoveDc} );
    fprintf( '.' );
    segment = bbs.createKS( 'StreamSegregationKS', ...
        {cleanPathFromRelativeRefs( [pwd '/../../AMLTTP/test/SegmentationTrainerParameters5.yaml'] )} );
    fprintf( '.' );
    for ii = 1 : numel( idSegModels )
        idSegKss{ii} = bbs.createKS('SegmentIdentityKS', {idSegModels(ii).name, idSegModels(ii).dir, ppRemoveDc});
        fprintf( '.' );
        idSegKss{ii}.setInvocationFrequency(10);
    end
    collectSegId = bbs.createKS('IntegrateSegregatedIdentitiesKS', {segIdLeakFactor,segIdGaussWidth,segIdMaxObjects,segIdClassThresholds});
end 
%%
bbs.blackboardMonitor.bind({bbs.scheduler}, {bbs.dataConnect}, 'replaceOld', 'AgendaEmpty');
bbs.blackboardMonitor.bind({bbs.dataConnect}, {segKS}, 'replaceOld');
bbs.blackboardMonitor.bind({segKS}, {locKS}, 'replaceOld' );
bbs.blackboardMonitor.bind({locKS}, {locDecisionKS}, 'replaceOld' );
bbs.blackboardMonitor.bind({locDecisionKS}, {rotateKS}, 'replaceOld', 'RotateHead');
if bIdentifySources
    bbs.blackboardMonitor.bind({locDecisionKS}, idSegKss, 'replaceOld', 'TopdownSegment' );
    bbs.blackboardMonitor.bind({locDecisionKS}, {nsrcs}, 'replaceOld');
    bbs.blackboardMonitor.bind({nsrcs}, {segment}, 'replaceOld' );
    bbs.blackboardMonitor.bind({segment}, idSegKss, 'replaceOld' );
    bbs.blackboardMonitor.bind(idSegKss(end), {collectSegId}, 'replaceOld' );
    bbs.blackboardMonitor.bind({collectSegId}, {navKS}, 'replaceOld' );
end

