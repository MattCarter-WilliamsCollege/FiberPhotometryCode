
% This is a script to read in FP data, plot the raw data, and do the first
% round of analyses.
% 
% There are some user-defined variables -- edit the code to set them below.
%

% Kate Jensen, Matt Carter, Jessica Kim - August 23, 2019
clear all
close all

%% User-defined variables 
% consider making this interactive later

clear all %start with a clean slate (if desired)
set(0,'DefaultFigureWindowStyle','docked') %sets up so Matlab makes new figures into new tabs not new windows

BLOCKPATH = 'C:\Users\localpcaccount\Desktop\COHORT 1\EXPORTED DATA\COHORT 1 Tac1 PSTN  SATED FOOD DROP trial 2 - exported data\mouse 1'
save_filename = ['KateMouse' datestr(now,'YYmmDD_HHMMSS')]


%% Load in the data 

data = TDTbin2mat(BLOCKPATH, 'TYPE', {'epocs', 'scalars', 'streams'});

% extract the raw data
F405=double(data.streams.x405A.data); % these are 1xN [row] vectors of data
% build the time vector to go with the data
F465=double(data.streams.x465A.data); 

fs=data.streams.x405A.fs; %get sampling frequency - should be same for both
n=numel(F405)- 1; 
t=(0:1/fs:n/fs);


%% Plot the raw data

figure('Name','Raw Data')
plot(t,F405,'.','DisplayName','405','Color',[81 38 152]/255) % with a legend display name and a pretty color
hold all
plot(t,F465,'.','DisplayName','465','Color',[0 105 62]/255)

%some plot formatting
grid on
box on
set(gca,'LineWidth',1,'FontWeight','bold','FontSize',20)
title('Raw Data')
xlabel('Time (s) ')
ylabel('Total Fluorescence (a.u.) ')

% automatically show the legend
legend1 = legend(gca,'show');
set(legend1,'Location','northwest');

pause(2) %...pause to admire your data



%% Downsample and plot the raw data

% set up intervals and time vector:
sample_intervals = 0:round(fs):n; %as close as we can get to a 1Hz downsampled rate
t_downsampled = ( sample_intervals(1:end-1) + sample_intervals(2)/2 ) / fs;
% note to self: as currently coded, sample_intervals(2)/2 == round(fs)/2,
% and the *interval* is round(fs)/fs

% average raw data over each interval to downsample
clear F405_downsampled
clear F465_downsampled

for i = 1:(numel(sample_intervals)-1)
    F405_downsampled(i) = mean(F405(sample_intervals(i)+1:sample_intervals(i+1)));
    F465_downsampled(i) = mean(F465(sample_intervals(i)+1:sample_intervals(i+1)));
end

figure('Name','Downsampled Data')
plot(t_downsampled,F405_downsampled,'-','DisplayName','405 Downsampled','Color',[81 38 152]/255)
hold all
plot(t_downsampled,F465_downsampled,'-','DisplayName','465 Downsampled','Color',[0 105 62]/255)

%some plot formatting
grid on
box on
set(gca,'LineWidth',1,'FontWeight','bold','FontSize',20)
title('Downsampled Data')
xlabel('Time (s) ')
ylabel('Total Fluorescence (a.u.) ')

% automatically show the legend
legend1 = legend(gca,'show');
set(legend1,'Location','northwest');

pause(2)


%% Do you want to use the downsampled data henceforth? If so, run the following:

F405_working_data = F405_downsampled;
F465_working_data = F465_downsampled;
t_working_data = t_downsampled;

%otherwise stick with this:

%F405_working_data = F405;
%F465_working_data = F465;
%t_working_data = t;

%% Choose your baseline time interval(s)

% plot the data again so you can see it (in case you're running this cell
% separately from the rest):
figure('Name','Working Data')
plot(t_working_data,F405_working_data,'-','DisplayName','405','Color',[81 38 152]/255) % with a legend display name and a pretty color
hold all
plot(t_working_data,F465_working_data,'-','DisplayName','465','Color',[0 105 62]/255)

%some plot formatting
grid off
box off
set(gca,'LineWidth',1,'FontWeight','bold','FontSize',20)
title('Working Data')
xlabel('Time (s) ')
ylabel('Total Fluorescence (a.u.) ')

% automatically show the legend
legend1 = legend(gca,'show');
set(legend1,'Location','northeast');
%%%%%%%%%%%%%%% end of plot

% ask the user to input a time interval (or more):
baseline_time_interval = input('What is the baseline interval? Input as a vector with format [STARTTIME ENDTIME]: ');
%SECRET HINT: you could actually give it a list of time intervals, and
%it'll just average over all of them. Just format like this:
% 
% [STARTTIME_1 ENDTIME_1; STARTTIME_2 ENDTIME_2; STARTTIME_3 ENDTIME_3]
% etc...

% compute the baseline average over these time intervals (allowing for more
% than one start/end pair if the user typed them in:
baseline_data = false(size(t_working_data));
for i = 1:size(baseline_time_interval,1)
    %grab the data in this interval
    baseline_data = baseline_data | (t_working_data > baseline_time_interval(i,1) & t_working_data < baseline_time_interval(i,2)); 
end

% extract the and average the baseline data for each wavelength
F405_baselineF = mean(F405_working_data(baseline_data));
F465_baselineF = mean(F465_working_data(baseline_data));



% mark the baseline on the graph
hold all
plot(t_working_data(baseline_data),F405_baselineF*ones(1,sum(baseline_data)),'o')
plot(t_working_data(baseline_data),F465_baselineF*ones(1,sum(baseline_data)),'o')



input('Does this look ok? If not, give up all hope and start over. (By which I mean, this is where you deal with photobleaching. :)')


%% Normalized 

F405_DeltaFoverF = (F405_working_data - F405_baselineF)./F405_baselineF;
F465_DeltaFoverF = (F465_working_data - F465_baselineF)./F465_baselineF;

%% Detrend the raw data
% KEJ is pretty sure this section is what's causing your weird graph; but
% it's just a plot range thing in the end (if you believe that an
% exponential fit to de-trend is correct)

F405_DeltaFoverF_fit = fit(transpose(t_working_data(100:end)), transpose(F405_DeltaFoverF(100:end)), 'exp2');
F465_DeltaFoverF_fit = fit(transpose(t_working_data(100:end)), transpose(F465_DeltaFoverF(100:end)), 'exp2');

F405_DeltaFoverF = F405_DeltaFoverF - transpose(F405_DeltaFoverF_fit(t_working_data));
F465_DeltaFoverF = F465_DeltaFoverF - transpose(F465_DeltaFoverF_fit(t_working_data));

%% Plot Delta F/F
figure('Name','DeltaF/F')
plot(t_working_data,F405_DeltaFoverF,'-','DisplayName','405','Color',[81 38 152]/255,'LineWidth',1) % with a legend display name and a pretty color
hold all
plot(t_working_data,F465_DeltaFoverF,'-','DisplayName','465','Color',[0 105 62]/255,'LineWidth',1)
plot(t_working_data,F465_DeltaFoverF,'-','DisplayName','465','Color',[0 0 0],'LineWidth',1)

%some plot formatting
grid off
box off
set(gca,'LineWidth',1,'FontWeight','normal','FontSize',16)
%title('GCaMP Fluorescence Over Time')
xlabel('Time (s)')
ylabel('\DeltaF/F','FontSize',20)

%ylim([-0.1 0.05]) %sets y axis limits to this range

%fix the x-axis range
%xlim ([-150 150])

% automatically show the legend
%legend1 = legend(gca,'show');
%set(legend1,'Location','northwest');
%%%%%%%%%%%%%%% end of plot


%% Example of adding a dashed vertical line
% 
t_stim = 1865; %insert desired time here
hold all
plot(t_stim*[1 1],[-1 2],'--','Color','m','LineWidth',2)

%zoom in x around tstim
xlim(t_stim + [-150 150])
% if you want to auto zoom-in vertically more:
ylim([-0.2 0.2])

%% Take the mean of DeltaF over F over desired intervals

% plot the data again so you can see it (in case you're running this cell
% separately from the rest):
figure('Name','Mean DeltaF/F')
%plot(t_working_data,F405_DeltaFoverF,'-','DisplayName','405','Color',[81 38 152]/255) % with a legend display name and a pretty color
hold all
plot(t_working_data,F465_DeltaFoverF,'-','DisplayName','465','Color',[0 105 62]/255)

%some plot formatting
grid on
box on
set(gca,'LineWidth',1,'FontWeight','bold','FontSize',20)
title('GCaMP Fluorescence Over Time')
xlabel('Time (s)')
ylabel('\DeltaF/F')

% automatically show the legend
legend1 = legend(gca,'show');
set(legend1,'Location','northeast');
%%%%%%%%%%%%%%% end of plot 

% ask the user to input a time interval (or more):
time_intervals_of_interest = input('What are the interval(s) of interest? Input as a vector with format [STARTTIME ENDTIME]: ')
%it'll just average over all of them. Just format like this:: ');
%SECRET HINT: you could actually give it a list of time intervals, and
% 
% [STARTTIME_1 ENDTIME_1; STARTTIME_2 ENDTIME_2; STARTTIME_3 ENDTIME_3]
% etc...

% compute the average over each of these time intervals (allowing for more
% than one start/end pair if the user typed them in:
for i = 1:size(time_intervals_of_interest,1)
    %grab the data in this interval
    time_points_of_interest = t_working_data > time_intervals_of_interest(i,1) & t_working_data < time_intervals_of_interest(i,2); 
    %F405_mean = mean(F405_DeltaFoverF(time_points_of_interest));
    F465_mean = mean(F465_DeltaFoverF(time_points_of_interest));
    
    %eval(['F405_DeltaFoverF_mean_interval_' num2str(i) ' = F405_mean; '])
    eval(['F465_DeltaFoverF_mean_interval_' num2str(i) ' = F465_mean;'])
    
    % mark the interval average on the graph
    hold all
    %plot(t_working_data(time_points_of_interest),F405_mean*ones(1,sum(time_points_of_interest)),'-','LineWidth',2)
    plot(t_working_data(time_points_of_interest),F465_mean*ones(1,sum(time_points_of_interest)),'-','LineWidth',2)
end

%type in F465_mean to get the mean y value!! (or F405_mean if you want to look
%at the 405 data, first have to undo the % above where 405 is mentioned)




%% Undo additions made to the graph

%this will remove the last feature added to the graph
%use this multiple times for multiple screw ups
children = get(gca, 'children');
delete(children(1));

%% Save the data

%remove extra variables we don't want to save
clear legend1 fs i n 
clear data

save_filename = input('Name of file to be saved: ')

%save everything in some cleverly-named file
save(['C:\Users\localpcaccount\Documents\Data Analysis\' save_filename])
display(['Data has been saved to: C:\Users\localpcaccount\Documents\Data Analysis\' save_filename])

%% Select very specific chunks of data to analyze
% for example, if you have 10 minutes of recording but only want to analyze
% the last 5 minutes

%% RECTANGLE

%rectangle('Position',[location x,location y,length x,height y],'Curvature',0.2,'FaceColor','color')
rectangle('Position',[1150.2,0.3,39.8,0.025],'Curvature',0.2,'FaceColor','b')



