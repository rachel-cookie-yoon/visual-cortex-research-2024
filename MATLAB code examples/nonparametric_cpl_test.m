% Performs a nonparametric test on characteristic path lengths derived from fMRI data.

first = 'init';
second = 'rep';

% Define base directory and subject IDs
baseDir = sprintf('/Volumes/Extreme SSD/NEW RESEARCH (REDO)/scene-MATRIX/collapsed_%s_%s', first, second);
subjectIDs = {'01', '02', '03', '04', '05', '06', '09', '10', '14', '15', '16', '17', '18', '19', '20'};
numSubjects = length(subjectIDs);

% Initialize arrays to hold characteristic path lengths
firstCPLs = zeros(1, numSubjects);
secondCPLs = zeros(1, numSubjects);

% Calculate characteristic path lengths for original labels
for i = 1:numSubjects
    subjectID = subjectIDs{i};
    firstFile = fullfile(baseDir, ['sub-', subjectID, '_init_corr_matrices.mat']);
    secondFile = fullfile(baseDir, ['sub-', subjectID, '_rep_corr_matrices.mat']);
    
    % Load correlation matrices
    firstData = load(firstFile);
    secondData = load(secondFile);
    
    % Assuming correlation matrices are stored in variable `corrMatrix`
    firstMatrix = firstData.(sprintf('avg_%s_corr_matrix', first));
    secondMatrix = secondData.(sprintf('avg_%s_corr_matrix', second));
    
    % Calculate characteristic path length
    firstCPLs(i) = calculateCPL(firstMatrix);
    secondCPLs(i) = calculateCPL(secondMatrix);
    
    fprintf('Processed subject %s\n', subjectID);
end

% Compute observed difference in characteristic path lengths
observedDifference = mean(firstCPLs) - mean(secondCPLs);

% Initialize array to store differences from permutations
numPermutations = 2^numSubjects - 1;
permutedDifferences = zeros(1, numPermutations);

% Generate all possible permutations
for perm = 1:numPermutations
    % Convert perm to binary and use it to shuffle labels
    binaryPerm = decimalToBinaryVector(perm, numSubjects);
    
    shuffledFirstCPLs = firstCPLs;
    shuffledSecondCPLs = secondCPLs;
    
    for i = 1:numSubjects
        if binaryPerm(i) == 1
            temp = shuffledFirstCPLs(i);
            shuffledFirstCPLs(i) = shuffledSecondCPLs(i);
            shuffledSecondCPLs(i) = temp;
        end
    end
    
    % Compute the difference in characteristic path lengths for this permutation
    permutedDifferences(perm) = mean(shuffledFirstCPLs) - mean(shuffledSecondCPLs);
    
    if mod(perm, 1000) == 0
        fprintf('Processed permutation %d/%d\n', perm, numPermutations);
    end
end

% Calculate p-value
pValue = sum(abs(permutedDifferences) >= abs(observedDifference)) / numPermutations;

% Display the result
fprintf('Mean of subject CPLs for %s scenes: %.4f\n', first, mean(firstCPLs));
fprintf('Mean of subject CPLs for %s scenes: %.4f\n', second, mean(secondCPLs));
fprintf('Observed difference: %.4f\n', observedDifference);
fprintf('p-value: %.4f\n', pValue);


% Function to calculate characteristic path length
function cpl = calculateCPL(foo)
    rois = {'PPA_L', 'PPA_R', 'RSC_L', 'RSC_R', 'OPA_L', 'OPA_R', 'LOC_L', 'LOC_R'};
    
    % Create threshold of 0.1
    foo(foo < 0.1) = 0;

    % Create graph
    G = graph(foo, rois, 'omitselfloops');
 
    % Extract edges and weights
    edges = G.Edges;
    
    % Invert the weights (correlations)
    edges.Weight = 1 ./ edges.Weight;
    
    % Remove any Inf values resulting from inversion
    valid_edges = ~isinf(edges.Weight);
    edges = edges(valid_edges, :);
    
    % Create new graph with inverted weights
    G2 = graph(edges.EndNodes(:,1), edges.EndNodes(:,2), edges.Weight, rois);
    
    % Calculate distances
    distanceMatrix = distances(G2);
    
    % Calculate characteristic path length
    cpl = mean(distanceMatrix(distanceMatrix ~= Inf));
end

% Helper function to convert decimal to binary vector
function binaryVector = decimalToBinaryVector(decimal, numBits)
    binaryVector = zeros(1, numBits);
    idx = 1;
    while decimal > 0
        binaryVector(idx) = mod(decimal, 2);
        decimal = floor(decimal / 2);
        idx = idx + 1;
    end
end
