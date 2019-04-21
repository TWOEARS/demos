function plot_test_signals()

classes = {{'alarm'},{'baby'},{'femaleSpeech'},{'fire'},{'crash'},{'dog'},...
           {'engine'},{'footsteps'},{'knock'},{'phone'},{'piano'},...
           {'maleSpeech'},{'femaleScream','maleScream'}};
classesIdxs = struct;
for ii = 1 : numel( classes )
    for jj = 1 : numel( classes{ii} )
        classesIdxs.(classes{ii}{jj}) = ii;
    end
end
classes = cellfun( @(c)(strcat( c{:} )), classes, 'UniformOutput', false );

f7 = load( 'signal_f7.mat', 'onOffsets', 'labels', 'activity' );
f8 = load( 'signal_f8.mat', 'onOffsets', 'labels', 'activity' );
f7v2 = load( 'signal_f7_v2.mat', 'onOffsets', 'labels', 'activity' );
f8v2 = load( 'signal_f8_v2.mat', 'onOffsets', 'labels', 'activity' );

maxLen = max( [numel( f7.activity ), numel( f8.activity ), numel( f7v2.activity ), numel( f8v2.activity )] );
f7.activity(maxLen) = false;
f8.activity(maxLen) = false;
f7v2.activity(maxLen) = false;
f8v2.activity(maxLen) = false;

t = (1:maxLen) / 100;
actMap = cat( 1, f7.activity, f8.activity, f7v2.activity, f8v2.activity );

figure; imagesc( t, 0.5:3.5, ~actMap );
colormap( 'Bone' );
xlabel( 't / s' );
ylabel( 'src idx' );
set( gca, 'FontSize',11, 'Layer','top', 'YTick', 1:4, 'YGrid', 'on' );

classMap = zeros( 13, maxLen );
for ff = [f7,f8,f7v2,f8v2]
    for ii = 1 : numel( ff.labels )
        cidx = classesIdxs.(ff.labels{ii});
        onSample = ceil( ff.onOffsets(ii,1) * 100 );
        offSample = ceil( ff.onOffsets(ii,2) * 100 );
        classMap(cidx,onSample:offSample) = cidx;
    end
end

figure; 
imAlpha = ones( size( classMap ) );
imAlpha(classMap==0) = 0;
imagesc( t, 0.5:12.5, classMap, 'AlphaData',imAlpha );
set( gca, 'color', [1 1 1] );
set( gca, 'FontSize',11, 'Layer','top', 'YTick', 1:13, 'YGrid', 'on' );
colormap( 'hsv' );
xlabel( 't / s' );
ylabel( 'class idx' );

end
