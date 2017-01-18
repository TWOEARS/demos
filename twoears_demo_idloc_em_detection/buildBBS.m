function bbs = buildBBS(sim, bFrontLocationOnly, bSolveConfusion, bFullBodyRotation, ...
                        idModels, idSegModels, ppRemoveDc, fs, runningMode)

% runningMode:
% 'locOnly'     - localisation only
% 'segStream'   - segregated streams
% 'fullStream'  - full streams
% 'jointCNN'    - joint CNN
bbs = BlackboardSystem(1);
bbs.setRobotConnect(sim);
%% Create knowledge sources
bbs.setDataConnect('AuditoryFrontEndKS', fs, 0.5);
if bFrontLocationOnly
    dnnloc = bbs.createKS('DnnLocationKS', {'MCT-DIFFUSE-FRONT'});
else
    dnnloc = bbs.createKS('DnnLocationKS', {'MCT-DIFFUSE'});
end
locDec = bbs.createKS( 'LocalisationDecisionKS', {bSolveConfusion,0.5} );
if bFullBodyRotation
    rot = bbs.createKS('FullBodyRotationKS', {sim});
else
    rot = bbs.createKS('HeadRotationKS', {sim});
end
emDet = bbs.createKS('EmergencyDetectionKS');

%%
idClassThresholds.fire = 0.8;
segIdClassThresholds.fire = 0.8;
segIdLeakFactor = 0.25;
segIdGaussWidth = 10;
segIdMaxObjects = 2;
idLeakFactor = 0.5;
%%
if strcmp(runningMode, 'segStream')
    %% Identifcation on segregated streams
    addPathsIfNotIncluded( {...
        cleanPathFromRelativeRefs( [pwd '/../../segmentation-training-pipeline/src'] ), ...
        cleanPathFromRelativeRefs( [pwd '/../../segmentation-training-pipeline/external/data-hash'] ), ...
        cleanPathFromRelativeRefs( [pwd '/../../segmentation-training-pipeline/external/yaml-matlab'] ) ...
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
elseif strcmp(runningMode, 'jointCNN')
    %% Joint identification and localisation without segregation
    cnn_model_dir = 'learned_models/IdentityLocationKS/xJ_brir_c_03_3';
    cnn_model_name = 'deploy_c_03_3_thr.prototxt';
    cnn = bbs.createKS('IdentityLocationKS', {cnn_model_name, cnn_model_dir});
    do_idLocDec_idMasksLoc = true;
    do_idLocDec_visualise = false;
    idLocDec = bbs.createKS('IdentityLocationDecisionKS', ...
        {do_idLocDec_idMasksLoc, do_idLocDec_visualise});
    collectSegId = bbs.createKS('IntegrateSegregatedIdentitiesKS', {0.3,10,3});
elseif strcmp(runningMode, 'fullStream')
    %% Sound type identification on full streams
    for ii = 1 : numel( idModels )
        idKss{ii} = bbs.createKS('IdentityKS', {idModels(ii).name, idModels(ii).dir, ppRemoveDc});
        idKss{ii}.setInvocationFrequency(10);
    end  
    collectId = bbs.createKS('IntegrateFullstreamIdentitiesKS', {idLeakFactor,inf,idClassThresholds});
elseif strcmp(runningMode, 'fullAndSegStream')
    %% Sound type identification on full streams
    addPathsIfNotIncluded( {...
        cleanPathFromRelativeRefs( [pwd '/../../segmentation-training-pipeline/src'] ), ...
        cleanPathFromRelativeRefs( [pwd '/../../segmentation-training-pipeline/external/data-hash'] ), ...
        cleanPathFromRelativeRefs( [pwd '/../../segmentation-training-pipeline/external/yaml-matlab'] ) ...
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
    nsrcs = bbs.createKS( 'NumberOfSourcesKS', {'nSrcs','learned_models/NumberOfSourcesKS/mc3_models_dataset_1',ppRemoveDc} );
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
    for ii = 1 : numel( idModels )
        idKss{ii} = bbs.createKS('IdentityKS', {idModels(ii).name, idModels(ii).dir, ppRemoveDc});
        idKss{ii}.setInvocationFrequency(10);
    end  
    collectId = bbs.createKS('IntegrateFullstreamIdentitiesKS', {idLeakFactor,inf,idClassThresholds});
elseif strcmp(runningMode, 'emDet')
    %% Identifcation on segregated streams
    addPathsIfNotIncluded( {...
        cleanPathFromRelativeRefs( [pwd '/../../segmentation-training-pipeline/src'] ), ...
        cleanPathFromRelativeRefs( [pwd '/../../segmentation-training-pipeline/external/data-hash'] ), ...
        cleanPathFromRelativeRefs( [pwd '/../../segmentation-training-pipeline/external/yaml-matlab'] ) ...
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
%% knowledge source binding
bbs.blackboardMonitor.bind({bbs.scheduler}, {bbs.dataConnect}, 'replaceOld', 'AgendaEmpty' );
bbs.blackboardMonitor.bind({bbs.dataConnect}, {dnnloc}, 'replaceOld' );
bbs.blackboardMonitor.bind({dnnloc}, {locDec}, 'add' );
bbs.blackboardMonitor.bind({locDec}, {rot}, 'replaceOld', 'RotateHead' );
if strcmp(runningMode, 'segStream')
    bbs.blackboardMonitor.bind({locDec}, {nsrcs}, 'replaceOld' );
    bbs.blackboardMonitor.bind({nsrcs}, {segment}, 'replaceOld' );
    bbs.blackboardMonitor.bind({segment}, idSegKss, 'replaceOld' );
    bbs.blackboardMonitor.bind({idSegKss{end}}, {collectSegId}, 'replaceOld' );
elseif strcmp(runningMode, 'jointCNN')
    bbs.blackboardMonitor.bind({bbs.dataConnect}, {cnn}, 'replaceOld' );
    bbs.blackboardMonitor.bind({cnn}, {idLocDec}, 'replaceOld' );
     bbs.blackboardMonitor.bind({idLocDec}, {collectSegId}, 'replaceOld' );
elseif strcmp(runningMode, 'fullAndSegStream')
    bbs.blackboardMonitor.bind({locDec}, {nsrcs}, 'replaceOld' );
    bbs.blackboardMonitor.bind({nsrcs}, {segment}, 'replaceOld' );
    bbs.blackboardMonitor.bind({segment}, idSegKss, 'replaceOld' );
    bbs.blackboardMonitor.bind({idSegKss{end}}, {collectSegId}, 'replaceOld' );
    bbs.blackboardMonitor.bind({bbs.dataConnect}, idKss, 'replaceOld' );
    bbs.blackboardMonitor.bind({idKss{end}}, {collectId}, 'replaceOld' );    
elseif strcmp(runningMode, 'fullStream')
    bbs.blackboardMonitor.bind({bbs.dataConnect}, idKss, 'replaceOld' );
    bbs.blackboardMonitor.bind({idKss{end}}, {collectId}, 'replaceOld' );
elseif strcmp(runningMode, 'emDet')
    bbs.blackboardMonitor.bind({locDec}, {nsrcs}, 'replaceOld' );
    bbs.blackboardMonitor.bind({nsrcs}, {segment}, 'replaceOld' );
    bbs.blackboardMonitor.bind({segment}, idSegKss, 'replaceOld' );
    bbs.blackboardMonitor.bind({idSegKss{end}}, {collectSegId}, 'replaceOld' );
    bbs.blackboardMonitor.bind({collectSegId}, {emDet}, 'replaceOld' );
end
