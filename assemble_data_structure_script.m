% This is a script to run through the folders with data in them and collect
% all the important data together into a single data structure. 
% By having this script handy, we can easily re-run or re-collect in the
% future if we realize we wanted a different set of data or for a new set
% of experiments.
%
% Kate "The Great" Jensen - January 25, 2020


% probably should 'clear all' before running just to keep things tidy
 clear all 

%% First, get some USER input about where to look for the desired data:

% where are the sub-folders of data that we want to rifle through?
folder =  'C:\Users\localpcaccount\Desktop\Matt Final Org\All Experiments';

% go there:
cd(folder)

% automatically grab the list of subfolders
subfolder_list = dir;

%display('This is the complete list of subfolders that I found here:')
%for i=1:length(subfolder_list); display(subfolder_list(i).name); end
%display(' ')

%USER just let this run and code will ask you which ones to include (or you
%can create/edit active_subfolder_list manually)

%the first two in the list will always be '.' and '..', which is kindof
%silly; definitely not useful...so remove these right away
%(if later these aren't just '.' or '..', or you want to do the removal
%manually, just comment out the next line)
subfolder_list(1:2) = []; %this removes entries 1 and 2, and makes what used to be #3 become #1

subfolders_to_include = true(length(subfolder_list),1); %set up list to keep track of selection about to happen; default is to include the folder
disp('Automatically looking for possible data folders...')
disp('For the following, type ''n'' to skip this folder, or ''Enter'' to keep it in the active list.')
for i = 1:length(subfolder_list)
    %display(subfolder_list(i).name)
    s = input(['Include mouse data found in this folder?:  ' subfolder_list(i).name   '  '],'s');
    if strcmp(s,'n') %if USER put in *anything* other than 'n', include this folder's data for collection
        subfolders_to_include(i,1) = false;
    end %otherwise it's already true (= will be included)
end
%use the results of this user input to compile the list of subfolders to be
%rummaged through:
active_subfolder_list = subfolder_list(subfolders_to_include);

%let the user check that this looks right
disp('You have selected the following folders. Before continuing, check that this list is correct.')
disp(' ')
for i=1:length(active_subfolder_list); display(active_subfolder_list(i).name); end



%% Next, automatically go through all of the desired subfolders and build the data structure with desired information

%initialize the data structure if it doesn't already exist in the
%workspace...
if ~exist('all_data','var') %if the all_data data structure doesn't already exist in the workspace, will start building from entry line #1
    k = 1; %this will be counting index for adding data
    fprintf('all_data data structure does not yet exist and will be created by this script. \n')
else %plan to append the new data; will *not* overwrite the existing entries. If you want to start fresh, clear all_data from the workspace first.
    k = length(all_data)+1; %starts on the *next* line
    fprintf(' all_data data structure already exists in the workspace. \n New data will be appended to existing structure. \n If you want to start fresh, clear all_data from the workspace first. \n')
end 


%%
%run through everything in the folders and subfolders; use j to index
%through subfolders because it's not used in any of the previous analysis
%scripts

%the index k was initialized by the previous cell, and will be used to
%index into all_data

for j = 1:length(active_subfolder_list)
    % enter this subfolder
    cd([folder '\' active_subfolder_list(j).name]) %note that '\' joins folders in Windows; would need to switch to '/' in Mac/Linux/Unix
    % get the list of 'mouse' subsubfolders:
    subsubfolder_list = dir('mouse*'); %will get all the trials out of all of these
    % run through all the subfolders
    for m = 1:length(subsubfolder_list) %sortof the "mouse number" count
        cd([folder '\' active_subfolder_list(j).name '\' subsubfolder_list(m).name]) %direct full path into this subsubfolder
        % finally, get the list of .mat files that are here, then read them
        % in and copy the data into the data structure trial by trial
        data_file_list = dir('*.mat'); %all the .mat data files present
        for df = 1:length(data_file_list)
            %load this .mat file
            load(data_file_list(df).name) %this is a LOT of data, so takes a moment...
            
            %add all the key information from this trial, mouse, and
            %condition to the overall data structure: 
            %%% first the essential "what and where-to-find-it" info: %%%
            all_data(k).folder = folder;
            all_data(k).condition = active_subfolder_list(j).name;
            all_data(k).condition_number = j; %should make it a little easier to sort through the conditions later
            all_data(k).subsubfolder = subsubfolder_list(m).name;
            %extract the mouse number, actually as a number:
            all_data(k).mouse_number = str2num(subsubfolder_list(m).name(7:end));
            all_data(k).data_filename = data_file_list(df).name;
            all_data(k).trial_number = df; %which trial in the list for this mouse?
            
            %%% next the actual data that we want to work with, including
            %%% original raw-but-downsampled data and the processed data;
            %%% this will allow us to re-process later as needed without
            %%% having to do all of the importing again -- refering to
            %%% Copy_of_KateIsAwesome1 MATLAB MASTER SCRIPT.m to figure out
            %%% what to put here   
            all_data(k).fs = fs; %original sampling frequency
            
            % all the raw, downsampled data (roughly downsampled to 1Hz):
            all_data(k).t_downsampled = t_downsampled;
            all_data(k).F405_downsampled = F405_downsampled;
            all_data(k).F465_downsampled = F465_downsampled; 
            % you might need to load these into the workspace as
            % ..._working_data to use with existing code
            
            all_data(k).t_stim = t_stim; %in seconds, when was the stimulus added
            
            %baseline time intervals (were used for determining the signal
            %baseline in further analysis/normalization):
            all_data(k).baseline_time_interval = baseline_time_interval;
            all_data(k).F405_baselineF = F405_baselineF; %log these, as-computed using saved baseline interval
            all_data(k).F465_baselineF = F465_baselineF; 
            
            %Normalized data DeltaFoverF = (F-baselineF)/baselineF AND
            %AFTER "Detrending" (same variable name, so detrending
            %overwrites the original baseline subtraction):
%%%%%%%%%%%%% KEJ is concerned that there could be some issues in
%%%%%%%%%%%%% detrending; the algorithm should be looked at again carefully
            all_data(k).F405_DeltaFoverF = F405_DeltaFoverF;
            all_data(k).F465_DeltaFoverF = F465_DeltaFoverF;
            
            
            % for debugging only, plot the data as it goes by...
            if 1
                figure(12347)
                hold off
                plot(t_downsampled,F405_DeltaFoverF,'-','DisplayName','405','Color',[81 38 152]/255)
                hold all
                plot(t_downsampled,F465_DeltaFoverF,'-','DisplayName','465','Color',[0 105 62]/255)
                plot(t_stim*[1 1],[-1 1],'--','LineWidth',2)

                grid on;  box on; 
                set(gca,'LineWidth',1,'FontWeight','bold','FontSize',20)
                title(['Cond ' num2str(j) ' M' num2str(all_data(k).mouse_number) ' Tr' num2str(df) ' \DeltaF over F'])
                xlabel('Time (s) ')
                ylabel('Total Fluorescence (a.u.) ')
                
                % automatically show the legend
                legend1 = legend(gca,'show');
                set(legend1,'Location','northwest');
                
                pause(0.2)
                %input('all good???')
            end
            
            
            
            %finally, increment k before going on to the next trial:
            k = k+1;
        end
        
        
        
    end
end

disp(['all_data now has ' num2str(k-1) ' entries!'])
 
% Pop back up to main folder and save
cd(folder)
save all_data.mat all_data active_subfolder_list %database and what folders it came from
