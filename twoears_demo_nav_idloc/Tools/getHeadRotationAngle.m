function rotateAngle = getHeadRotationAngle(headOrientation, azRef)
%
% Select a head rotation angle that can be used for the Surrey BRIRs by
% rotating the BRIRs instead of rotating the head.
%
% Reference azimuths (azRef) are only used to make sure we do not rotate
% the head in such a way that no BRIRs are available.

rotationAngles = [40:-5:10 -10:-5:-40];
while true
    rotateAngle = rotationAngles(randi(length(rotationAngles)));
    newHO = mod(headOrientation + rotateAngle, 360);
    
    
    relAzRef = mod(azRef - newHO, 360);
    relAzRef = convertAzimuthsWP1ToSurrey(relAzRef);

    % Make sure source azimuths relative to the new head orientation stay 
    % within [-90 90]
    if max(abs(relAzRef)) <= 90
        break;
    end
end

