%% Load the image
img = imread('denoised_image_13.png');

% Convert the image to grayscale (why?)
img = rgb2gray(img);

% Normalize the image into [0, 1] range
img = double(img) / 255;

%% Define the number of tresholds
N = 4;

%% Compute histogram
[counts, binEdges] = histcounts(img(:), 256);
binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;

%% Initialize thresholds for recursive Otsu
thresholds = multilevelOtsu(counts, binCenters, N);

%% Apply thresholds to quantize the image into N+1 levels
quantizedImage = zeros(size(img));
levels = linspace(0, 1, N+1);

for i = 1:N
    quantizedImage(img > thresholds(i)) = levels(i + 1);
end
quantizedImage(img <= thresholds(1)) = levels(1);

%% Visualization
figure;
subplot(1, 3, 1), imshow(img), title('Original Image');
subplot(1, 3, 2), imshow(quantizedImage), title(['Quantized Image (N=', num2str(N), '+1)']);
subplot(1, 3, 3), histogram(img(:), 256), xline(thresholds, 'r', 'LineWidth', 2), title(['Histogram with ', num2str(N), ' Thresholds']);

imwrite(img, 'DenoisedImage_GrayScale.png')
imwrite(quantizedImage, 'DenoisedImage_Quantized.png')

%% Multilevel Otsu Implementation
function thresholds = multilevelOtsu(counts, binCenters, N)
   
    thresholds = zeros(1, N);
    bins = 1:length(binCenters);

    for k = 1:N
        maxVariance = 0;
        bestThresholdIdx = 0;

        for t = bins

            % Split histogram
            w0 = sum(counts(1:t));
            w1 = sum(counts(t+1:end));

            % Check for empty classes
            if w0 == 0 || w1 == 0
                continue;
            end

            % Compute means
            m0 = sum(binCenters(1:t) .* counts(1:t)) / w0;
            m1 = sum(binCenters(t+1:end) .* counts(t+1:end)) / w1;

            % Compute between-class variance
            variance = w0 * w1 * (m0 - m1)^2;

            % Update
            if variance > maxVariance
                maxVariance = variance;
                bestThresholdIdx = t;
            end
        end

        % Store best threshold and split bins for next iteration
        thresholds(k) = binCenters(bestThresholdIdx);
        counts(1:bestThresholdIdx) = 0;
    end
    thresholds = sort(thresholds);
end