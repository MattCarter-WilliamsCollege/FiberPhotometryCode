% this is a script to calculate area_under_curve and maxF from an existing
% all_data structure


% ...and do some hopefully-useful exporting

% designed to work with Jess Kim's research data
% Kate Jensen - June 11, 2020


% assume all_data is already loaded in the workspace.
% you'll get an error if it isn't


fig = figure('Name','after t_stim'); %create a figure that we'll use

for n = 1:length(all_data) % can change to re-do specific n, or start later than n=1, etc.

% do a single one:
%for n = 9
    
% do a range
%for n = 9:14
    
    % n = 1; %later will loop through
    
    % grab the data we want to look at:
    
    t = all_data(n).t_downsampled;
    F465_DeltaFoverF = all_data(n).F465_DeltaFoverF;
    
    t_stim = all_data(n).t_stim;
    
    %% for debugging, take a look at this to see what we're working with
    if 0
        plot(t,F465_DeltaFoverF,'-','LineWidth',1)
        hold all
        plot(t_stim*[1 1],[-0.2 0.2],'--','LineWidth',2)
        plot([0 max(t)],[0 0],'k-')
        %zoom in there in x
        xlim([t_stim-50 t_stim+100])
        ylim([-0.05 0.15])
        
        %more readable graph:
        set(gca,'LineWidth',1,'FontWeight','bold','FontSize',20)
        grid on
        
        hold off
    end
    
    
    %% next, identify the boundaries of the peak, by eyeball test
    
    % plot for the user the time just before and a while (~200s) after t_stim:
    
    figure(fig)
    
    %plot the data
    plot(t,F465_DeltaFoverF,'-','LineWidth',1)
    hold all
    %add t_stim marker and emphasize zero line
    plot(t_stim*[1 1],[-0.2 0.2],'--','LineWidth',2)
    plot([0 max(t)],[0 0],'k-')
    
    %zoom in there in x to [before after] t_stim, default interval:
    interval_to_display = [-200 200]; %in seconds
    xlim(t_stim + interval_to_display)
    %auto set y-limits for this interval
    data_in_this_interval = (t > t_stim+interval_to_display(1)) & (t < t_stim+interval_to_display(2));
    ylim([min(F465_DeltaFoverF(data_in_this_interval))-0.05, max(F465_DeltaFoverF(data_in_this_interval))+0.05])
    
    %more readable graph:
    set(gca,'LineWidth',1,'FontWeight','bold','FontSize',20)
    grid on
    title(['n = ' num2str(n)])
    
    % set up a graphical interfact "grab" to select the points that should
    % start and end this interval (based on example from the internet...)
    datacursormode on
    dcm_obj = datacursormode(fig);
    input('select START time of peak, then ENTER')
    cursor_info = getCursorInfo(dcm_obj);
    peak_interval = cursor_info.Position(1); % save time info for this point
    
%     % quick check -- is the peak "starting" before t_stim? if so, override the
%     % user choice so starts at the first point right after t_stim
%     if peak_interval < t_stim
%         peak_interval = t_stim;
%         %and let user know that happened
%         display('peak start reset to just after t_stim')
%     end
    
    %repeat to have user idenfity end of peak
    datacursormode on
    dcm_obj = datacursormode(fig);
    input('select END time of peak, then ENTER')
    cursor_info = getCursorInfo(dcm_obj);
    peak_interval(1,2) = cursor_info.Position(1); % save time info for end point
    %record in the data structure what interval will be used, for future
    %reference
    all_data(n).peak_interval = peak_interval;
    
    %identify these data that will be analyzed as the peak
    data_in_peak = (t >= peak_interval(1)) & (t <= peak_interval(2));
    
    % as a sanity check, highlight the area that will be analyzed
    hold all
    plot(t(data_in_peak),F465_DeltaFoverF(data_in_peak),'-','LineWidth',2)
    
    pause(0.5) %so you have a moment to see what's going on
    
    hold off
    
    
    %% now that have identified the peak interval, analyze what's in here
    
    % use Matlab's built-in trapezoidal integration method to get area under
    % the curve:
    AUC = trapz(t(data_in_peak),F465_DeltaFoverF(data_in_peak));
    all_data(n).AUC = AUC; %store info in all_data
    
    % maxF next; be careful about where "baseline" is...
    
    %first find maximum value -- where is the peak of the peak?
    peak_max_value = max(F465_DeltaFoverF(data_in_peak));
    % when in time does this occur?
    t_peak_max_value = t(data_in_peak & F465_DeltaFoverF == peak_max_value);
    
    % next, find minimum value before the peak -- either at t_stim, or a little
    % after:
    if peak_interval(1) <= t_stim % then start measuring from the very first value after t_stim
        peak_min_value = F465_DeltaFoverF(find(t>t_stim,1,'first'));
    else % peak starts *after* t_stim, so want to measure from the minimum before the peak
        pre_peak_data = (t > t_stim) & (t < t_peak_max_value);
        peak_min_value = min(F465_DeltaFoverF(pre_peak_data));
    end
    
    % maxF is the difference between these:
    maxF = peak_max_value - peak_min_value;
    all_data(n).maxF = maxF;
    
    
    
    
end


%% Next, a bit of averaging of AUC and maxF

% run back through all_data, and compute the average over trials on the
% same mouse for the same condition

% extract the information we need for this -- the condition number, mouse
% number, and AUC and maxF results -- from the whole data set:
clear condition_mouse_AUC_maxF
for n = 1:length(all_data)
    %fill in the condition and mouse number information, combining to make
    %a unique combination so easy to identify
    condition_mouse_AUC_maxF(n,1) = [100*all_data(n).condition_number+all_data(n).mouse_number];
    %check that this row has had its AUC and maxF calculated already
    if ~isempty(all_data(n).AUC)
        condition_mouse_AUC_maxF(n,2:3) = [all_data(n).AUC all_data(n).maxF];
    end %otherwise will just be zeros, and this indicates that this shouldn't be included in the averaging
end

% what are all of the unique condition + mouse combinations?
unique_mouseconditions = unique(condition_mouse_AUC_maxF(:,1));

% now run through each unique combination, and average over the results for
% that...and store in the all_data structure
for k = 1:length(unique_mouseconditions)
    avg_AUC = mean(condition_mouse_AUC_maxF(condition_mouse_AUC_maxF(:,1)==unique_mouseconditions(k),2));
    avg_maxF = mean(condition_mouse_AUC_maxF(condition_mouse_AUC_maxF(:,1)==unique_mouseconditions(k),3));
    % store these in the first row in all_data where they occur
    all_data(find(condition_mouse_AUC_maxF(:,1)==unique_mouseconditions(k),1,'first')).avg_AUC = avg_AUC;
    all_data(find(condition_mouse_AUC_maxF(:,1)==unique_mouseconditions(k),1,'first')).avg_maxF = avg_maxF;
end


%% Export both regular and averaged data to Excel spreadsheet for convenient further analysis

% note that these files will be exported to whatever directory the main
% Matlab workspace is pointed to ... so you might want to set your "Current
% Folder" to somewhere useful before you run this section

% set up headers as the first line to write in the Excel files:
condition_mouse_AUC_maxF = {'Condition','Mouse','AUC','maxF'}; %repurpose this variable for preparing the data export
condition_mouse_AUC_maxF_avgs = {'Condition','Mouse','Avg AUC','Avg maxF'};
k=2; %where to start filling in average data (so appends correctly below the header)

for n = 1:length(all_data)
    % this time grab the condition name and mouse number as their original
    % "names" (that is, character strings, not just numbers)
    
    % add the data after the header
    condition_mouse_AUC_maxF(n+1,:) = {all_data(n).condition,all_data(n).mouse_number,all_data(n).AUC,all_data(n).maxF};
    
    % if this row also contains the averaged information for this mouse,
    % add to the collection of averaged data
    if ~isempty(all_data(n).avg_AUC)
        condition_mouse_AUC_maxF_avgs(k,:) = {all_data(n).condition,all_data(n).mouse_number,all_data(n).avg_AUC,all_data(n).avg_maxF};
        k = k+1;
    end
end

% now write these arrays to Excel files
xlswrite('condition_mouse_AUC_maxF.xls',condition_mouse_AUC_maxF)
xlswrite('condition_mouse_AUC_maxF_avgs.xls',condition_mouse_AUC_maxF_avgs)


% note that these files will be exported to whatever directory the main
% Matlab workspace is pointed to ... so you might want to set your "Current
% Folder" to somewhere useful before you run this section











%% Kate & Jess's planning discussion :)

% ... brb gotta refill my water glass HAHA NICE! water is life
% ok all set. this code at least won't trail off into dehydration


% this means identifying where the peak starts and stops,
% where "starts" is defined as the last negative value before the peak
% shoots up (a way of identifying where it crosses zero); and
% where "stops" is defined as the first time you have 2 (3? make
% adjustable) points that stay below zero

% (I need to think about this a few minutes)

%this will definitely make it more manual and more time consuming for me,
%but would it be easier if I manually input the time points? similar to how
%we defined what the baseline interval to be, I can go through each
%individual trial and just manually input where I want the boundaries to
%be....im just thinking that each trial is going to be different and it
%might be difficult to "define" where the stopping point is (like how you
%said above to be 2 or 3 times it crosses zero)

% maybe...it's like, to know where it shoots up, you have to have a sense
% of where the peak is already; and I think they last different amounts of
% time...right?

%yes

% this is a situation where your eye might actually be more reliable than
% an algorithm... but I can set that up so it's not so tedious.

%I agree with you. because to me I can clearly see where the peak is and
%where the signal begins to go back to "normal"

% ok, let me try a different approach... do you have a sense of the max a
% peak might be? 100s? 500s? here it looks like it's about 150...
%the peak almost always is right after the tstim like the example here. so
%i would gauge around 150-300s to be a generous window of the interval in
%which the maxF would occur. Is that what you're asking?

%YUP
%but in terms of AUC, it is more variable of what the time interval is.
%sometimes it takes a while for the signal to normalize again and sometimes
%not.

% so the end of the AUC might be a while away?

%not drastically a while away, but its more variable... this is where I
%think my eyeball will be better than an algorithm like what you said
%before.....I can show you an example using some fuzzy plots...let me bring
%them up on the screen

%so for the pic on the left, the AUC stopping point would be around 25s?
%and the pic on the right might be around 50

%ok, I've got an idea to try












