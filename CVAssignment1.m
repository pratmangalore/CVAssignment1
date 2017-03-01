numImages = 14;
files = cell(1,numImages);
for i = 1:numImages
    files{i} = fullfile('C:\Users','Pratik','Pictures','CV Assignment', sprintf('%d.jpg', i));
end

magnification = 25;

[imagePoints, boardSize] = detectCheckerboardPoints(files);

squareSize = 23; 
worldPoints = generateCheckerboardPoints(boardSize, squareSize);

% Calibrating the camera.
cameraParams = estimateCameraParameters(imagePoints, worldPoints);

%figure; showReprojectionErrors(cameraParams);
%title('Reprojection Errors');


imOrig = imread(fullfile('C:\Users','Pratik','Pictures','CV Assignment', '15.jpg'));
%figure; imshow(imOrig, 'InitialMagnification', magnification);
%title('Input Image');
[im, newOrigin] = undistortImage(imOrig, cameraParams);
%figure; imshow(im, 'InitialMagnification', magnification);
%title('Undistorted Image');

imHSV = rgb2hsv(im);
saturation = imHSV(:, :, 2);
t = graythresh(saturation);
imCoin = (saturation > t);

figure; imshow(imCoin, 'InitialMagnification', magnification);
imwrite(imCoin,'SegmentedPen.bmp');
title('Segmented Pen');

blobAnalysis = vision.BlobAnalysis('AreaOutputPort', true,...
    'CentroidOutputPort', false,...
    'BoundingBoxOutputPort', true,...
    'MinimumBlobArea', 200, 'ExcludeBorderBlobs', true);
[areas, boxes] = step(blobAnalysis, imCoin);

[~, idx] = sort(areas, 'Descend');

boxes = double(boxes(idx(1), :));

boxes(:,1:2) = bsxfun(@plus, boxes(:,1:2), newOrigin);

scale = magnification / 10;
imDetectedCoins = imresize(im, scale);

imDetectedCoins = insertObjectAnnotation(imDetectedCoins, 'rectangle', ...
    scale * boxes, 'Pen');


[imagePoints, boardSize] = detectCheckerboardPoints(im);

[R, t] = extrinsics(imagePoints, worldPoints, cameraParams);

box1 = double(boxes(1, :));
imagePoints1 = [box1(1:2); box1(1) + box1(3), box1(2) - box1(4)];

worldPoints1 = pointsToWorld(cameraParams, R, t, imagePoints1);
dist = sqrt((worldPoints1(1,1) - worldPoints(2,1))^2 + (worldPoints1(1,2)-worldPoints1(2,2))^2);

fprintf('Measured Length of Pen = %0.2f cm\n', dist / 10);

figure; imshow(imDetectedCoins);
title('Detected Pen');
imwrite(imDetectedCoins,'Detected.bmp');