classdef VisualiserLayout < handle
    
    properties(Constant)
    end
    
    properties (SetAccess = private)
        idColourMap = containers.Map; % identity colour map
        idRadiusMap = containers.Map; % identity radius map
        % todo fix color per class and sync with visualizer in bbs
        colourList = [0.4660    0.6740    0.1880
                      0.8500    0.3250    0.0980
                      0.0000    0.4470    0.7410
                      0.9290    0.6940    0.1250
                      0.3010    0.7450    0.9330
                      0.6350    0.0780    0.1840
                      0.4940    0.1840    0.5560];
        colourIndex = 1;
        drawHandle
        texthandles
        imgHandle
        tmIdx = -1
        speakerPos = [...
            335, 148; ...
            85, 160; ...
            103, 245; ...
            170, 310];
    end
    
    methods
        
        function obj = VisualiserLayout(drawHandle)
            if nargin>0
                obj.drawHandle = drawHandle;
            else
                figure('Color',[1 1 1]);
                obj.drawHandle = gca;
            end
            obj.reset();
        end
        
        function reset(obj)
            axes(obj.drawHandle);
            
            obj.idColourMap = containers.Map;
            cla;
            c = [0.9 0.9 0.9];
            hold on;
            
%             img_layout = imread('twoears_kemar_adream_pos.png');
            img_layout = imread('twoears_kemar_adream_pos_no_kemar.png');
            obj.imgHandle = imshow(img_layout);
            for spIdx = 1:size(obj.speakerPos,1)
                [spX, spY] = getSpeakerTextPos(obj, spIdx);
                obj.texthandles(spIdx) = text(spX, spY, ...
                    ['speaker', num2str(spIdx)], ...
                    'Color', [0,0,0]);
            end
        end
        
        function colourVector = getIdColor(obj, label)
            if obj.idColourMap.isKey(label)
                % If we've seen this sound type, try to use the same colour
                colourVector = obj.colourList(obj.idColourMap(label),:);
            else
                % Get a new colour
                obj.idColourMap(label) = obj.colourIndex;
                colourVector = obj.colourList(obj.colourIndex,:);
                obj.colourIndex = obj.colourIndex + 1;
                if obj.colourIndex > size(obj.colourList, 1)
                    obj.colourIndex = 1;
                end
            end
        end
        
        function clearSpeakerText(obj, speakerIdx)
            [x,y] = getSpeakerTextPos(obj, speakerIdx);
            set(obj.texthandles(speakerIdx), ...
                'Color', [1,1,1], ...
                'Position', [x, y], ...
                'String', '');
        end
        
        function setSpeakerText(obj, speakerIdx, label)
            color = obj.getIdColor(label);
            [x,y] = getSpeakerTextPos(obj, speakerIdx);
            set(obj.texthandles(speakerIdx), ...
                'Color', color, ...
                'Position', [x, y], ...
                'String', label);
        end
        
        function [x,y] = getSpeakerTextPos(obj, speakerIdx)
            pos = obj.speakerPos(speakerIdx, :);
            x = pos(1);
            y = pos(2);
        end
        
        function updateSpeakerText(obj, timeStampSec, onOffsets, eTypes, speakerIds)
            isValid = timeStampSec >= onOffsets(:, 1) & timeStampSec <= onOffsets(:, 2);
            typesList = eTypes(isValid);
            speakerIdsList = speakerIds(isValid);
            for ii = 1:size(obj.speakerPos, 1)
                obj.clearSpeakerText(ii);
            end
            for ii = 1:numel(typesList)
                obj.setSpeakerText(speakerIdsList(ii), typesList{ii})
            end
        end
    end
end