%% Load the image
img = imread('denoised_image_13.png');

% Convert the image to grayscale (why?)
img = rgb2gray(img);

% Normalize the image into [0, 1] range
img = double(img) / 255;

%% Compute the Histogram
[counts, binEdges] = histcounts(img(:), 256);
binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;

%% Pre-Compute Cumulative Sums and Means
cumSum = cumsum(counts);
cumMean = cumsum(counts .* binCenters);
globalMean = cumMean(end) / cumSum(end);

%% Compute Between-Class Variance for Each Threshold
totalPixels = cumSum(end);
betweenClassVariance = (globalMean * cumSum - cumMean).^2 ./ (cumSum .* (totalPixels - cumSum));

% Remove NaN values
betweenClassVariance(isnan(betweenClassVariance)) = 0;

%% Find the Optimal Threshold
[~, thresholdIdx] = max(betweenClassVariance);
threshold = binCenters(thresholdIdx);

%% Apply the Threshold
binaryImage = img > threshold;

%% Visualization
figure;
subplot(1, 3, 1), imshow(img), title('Original Image');
subplot(1, 3, 2), imshow(binaryImage), title('Binary Image');
subplot(1, 3, 3), histogram(img(:), 256), xline(threshold, 'r', 'LineWidth', 2), title('Histogram with Threshold');