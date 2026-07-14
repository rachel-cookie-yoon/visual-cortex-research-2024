%% Separates BOLD signals from fMRI data by scene type (indoor and outdoor). Each variable contians the BOLD signals that occur during individual scenes under the corresponding scene type.

%% Define the extract_BOLD_signals Function

function BOLD_signals = extract_BOLD_signals(BOLD_data, start_time, end_time, TR)
    % Initialize an empty array for concatenating signals across runs
    BOLD_signals = [];
    
    % Initialize a cumulative time counter
    cumulative_time = 0;
    
    % Loop through each run
    for run = 1:length(BOLD_data)
        run_data = BOLD_data{run}; % Get BOLD data for this run
        run_length = length(run_data); % Number of volumes in this run
        run_time = run_length * TR; % Total time of this run in seconds
        
        % Define the start and end times for this run
        run_start_time = cumulative_time;
        run_end_time = cumulative_time + run_time;
        
        % Check if the scene falls within this run
        if start_time < run_end_time && end_time > run_start_time
            % Calculate the indices within this run
            run_start_idx = max(1, ceil((start_time - run_start_time) / TR) + 1);
            run_end_idx = min(run_length, floor((end_time - run_start_time) / TR) + 1);
            
            % Append the relevant BOLD signals to the array
            BOLD_signals = [BOLD_signals; run_data(run_start_idx:run_end_idx)];
        end
        
        % Update the cumulative time counter
        cumulative_time = cumulative_time + run_time;
    end
end

%% Main script
% Load required libraries and define paths
base_dir = '/Volumes/Extreme SSD/NEW RESEARCH (REDO)';
stimuli_annotation_file = fullfile(base_dir, 'stimuli_annotation.xlsx');

% Read stimuli annotation file
annotation_table = readtable(stimuli_annotation_file);
scene_info = table2cell(annotation_table); % Convert table to cell array

% Define subjects and ROIs
subjects = [01, 02, 03, 04, 05, 06, 09, 10, 14, 15, 16, 17, 18, 19, 20];
num_subjects = length(subjects);
ROIs = {'PPA_L', 'PPA_R', 'RSC_L', 'RSC_R', 'OPA_L', 'OPA_R', 'LOC_L', 'LOC_R'};
num_ROIs = length(ROIs);

% Define TR (Repetition Time)
TR = 2; % TR = 2 seconds

% Initialize containers for results
indoor_BOLD = cell(num_ROIs, num_subjects);
outdoor_BOLD = cell(num_ROIs, num_subjects);

% Loop through each subject
for s = 1:num_subjects
    subject_id = subjects(s);
    subject_data_dir = fullfile(base_dir, 'avg-BOLD');
    
    % Loop through each ROI
    for r = 1:num_ROIs
        ROI_name = ROIs{r};
        ROI_BOLD_file = fullfile(subject_data_dir, sprintf('sub-%02d_%s_avg_BOLD.mat', subject_id, ROI_name));
        
        % Load the BOLD data for this subject and ROI
        if exist(ROI_BOLD_file, 'file')
            loaded_data = load(ROI_BOLD_file); % This loads a structure
            BOLD_data = loaded_data.(lower(ROI_name)); % Assuming the variable is named (lowercase version) of ROI_name
            
            % Initialize containers for this subject and ROI
            indoor_BOLD{r, s} = cell(size(scene_info, 1), 1);
            outdoor_BOLD{r, s} = cell(size(scene_info, 1), 1);
            
            % Loop through each scene
            for i = 1:size(scene_info, 1)
                scene_type = scene_info{i, 3}; % Assuming 3rd column contains scene type (int/ext)
                start_time = scene_info{i, 1};
                end_time = scene_info{i, 2};
                
                % Extract BOLD signals for this scene
                BOLD_signals = extract_BOLD_signals(BOLD_data, start_time, end_time, TR);
                
                % Store the BOLD signals in the appropriate container
                if strcmp(scene_type, 'int')
                    indoor_BOLD{r, s}{i} = BOLD_signals;
                else
                    outdoor_BOLD{r, s}{i} = BOLD_signals;
                end
            end
        else
            fprintf('BOLD data file not found: %s\n', ROI_BOLD_file);
        end
    end
end

% Save the results
save(fullfile(base_dir, 'indoor_BOLD.mat'), 'indoor_BOLD');
save(fullfile(base_dir, 'outdoor_BOLD.mat'), 'outdoor_BOLD');

