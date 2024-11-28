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
thresholds = fastMultiOtsu(counts, binCenters, N);

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
subplot(1, 3, 3), histogram(img(:), 256), xline(threshold, 'r', 'LineWidth', 2), title(['Histogram with ', num2str(N), ' Thresholds']);

%% Fast Multilevel Otsu Implementation
function thresholds = fastMultiOtsu(counts, binCenters, N)
    
    % Compute the cumulative sums for faster variance computation
    totalPixels = sum(counts);
    cumSum = cumsum(counts);
    cumMean = cumsum(counts .* binCenters);
    %globalMean = cumulativeMean(end) / totalPixels;

    % Cache the optimal thresholds and corresponding indices
    cache = zeros(N+1, length(binCenters));
    indices = zeros(N+1, length(binCenters));

    % 1 treshold
    for t = 1:length(binCenters)

        % Class weights
        w0 = cumSum(t);
        w1 = totalPixels - w0;

        % Class variances
        m0 = cumMean(t) / w0;
        m1 = (cumMean(end) - cumMean(t)) / w1;

        % Between-class variance
        cache(1, t) = w0 * w1 * (m0 - m1)^2;
        indices(1, t) = t;
    end

    % Mutliple thresholds
    for n = 2:N+1
        for t = n:length(binCenters)
            maxVariance = -inf;
            bestIdx = 0;

            % Search for the best threshold
            for k = n-1:t-1
                w0 = cumSum(t) - cumSum(k);
                w1 = cumSum(k);
                m0 = (cumMean(t) - cumMean(k)) / w0;
                m1 = cumMean(k) / w1;

                % Calculate between-class variance
                variance = w0 * w1 * (m0 - m1)^2;

                % Update cache
                if variance + cache(n-1, k) > maxVariance
                    maxVariance = variance + cache(n-1, k);
                    bestIdx = k;
                end
            end
            cache(n, t) = maxVariance;
            indices(n, t) = bestIdx;
        end
    end

    % Backtrack phase
    thresholds = zeros(1, N);
    currentIndex = length(binCenters);
    for n = N:-1:1
        thresholds(n) = binCenters(indices(n, currentIndex));
        currentIndex = indices(n, currentIndex);
    end
end