% this is a script to build up to paper-quality plotting
%
% (will also want to build a script to do some re-analysis /
% re-normalization of the data, since KEJ is worried about the "detrending"
% step, but this part is independent and can always rerun this script after
% re-normalizing to re-plot).
%
% Requires all_data to be loaded into the Matlab workspace. (There's a
% command just below that will go get it for you too.)
%
% Kate Jensen - January 26, 2020


%% load the data -- either manually, or from here:

clear all
load('all_data.mat')


%% Build matrix of DeltaF/F aligned by t_stim
% this will be used to make a heatmap like subfigure *F* in the example
% manuscript, and also for doing statistics on what comes next

% build a separate matrix for each test Condition

% what are all of the conditions? I numbered them...
clear condition_number_list mouse_number_list
for i=1:length(all_data)
    condition_number_list(i,1) = all_data(i).condition_number; %tells me what and where all of the conditions are...
    mouse_number_list(i,1) = all_data(i).mouse_number;
    t_stim_list(i,1) = all_data(i).t_stim;
end
[all_condition_numbers, IA]  = unique(condition_number_list); %this is just the list of unique numbers

% in the condition of interest
for c_index = 1:numel(all_condition_numbers) %[1] %this indexes into the list of all_condition_numbers
    %this condition is...
    disp(['Currently doing analysis and plotting for condition: ' all_data(IA(c_index)).condition]) 
    
    %before starting to collect the data together, check what the *maximum*
    %t_stim for this condition was, because that will set the left edge
    %pixel of the heat map / matrix -- sets the reference t_stim
    t_stim_reference = max(t_stim_list(condition_number_list==all_condition_numbers(c_index)));
    %%%%%%%%%%%%% IF WANT *ALL* CONDITION MATRICES TO LINE UP THE SAME,
    %%%%%%%%%%%%% THEN THIS WOULD JUST BE max(t_stim_list) (the overall
    %%%%%%%%%%%%% max value)
    
    %what mice #s were tested under this condition? 
    %(this Matlab is getting a little fancy; don't worry!)
    mouse_numbers_this_condition = unique(mouse_number_list(condition_number_list==all_condition_numbers(c_index)));
    
    %now need to run through each mouse and all of its trials, pull out its
    %DeltaF/F data for both 405 and 465 wavelengths, and shift it to line
    %up the time axes...
    % after talking with Jessica (evening of 1/26), build two matrices: one
    % that has every trial for every mouse separately, and one that
    % averages together what each mouse did
    
    %run through the mice and trials for this condition...
    clear y_axis_labels  %build this up for the figure later
    k = 1;
    clear this_condition_matrix_F405 this_condition_matrix_F465 this_condition_avgd_matrix_F405 this_condition_avgd_matrix_F465 %will be all mice, all trials for this condition
    for m = 1:numel(mouse_numbers_this_condition)
        mousestr = ['mouse ' num2str(mouse_numbers_this_condition(m))];
        disp(mousestr)
        
        %how many trials? and what entries are they in the data structure?
        select_vector = (condition_number_list==all_condition_numbers(c_index) & mouse_number_list==mouse_numbers_this_condition(m));
        num_trials_this_mouse = sum(select_vector); %don't necessarily need this...
        index_list = find(select_vector); %this tells me where these experiment entries are in the data structure
        
        %now run through, grab all of these trials, and build a
        %mini-mouse-matrix out of them
        clear this_mouse_matrix_F405 this_mouse_matrix_F465
        for transitions = 1:num_trials_this_mouse
            n = index_list(transitions);
            %how much to shift the vector entries by to match up the t_stims...
            fs = all_data(n).fs;
            time_index_shift = round((t_stim_reference - all_data(n).t_stim)./(round(fs)/fs));
            
            %pick up the data:
            F405_DeltaFoverF = all_data(n).F405_DeltaFoverF;
            F465_DeltaFoverF = all_data(n).F465_DeltaFoverF;
            
            %stick it in the this-mouse matrix
            this_mouse_matrix_F405(transitions,1+time_index_shift:size(F405_DeltaFoverF,2)+time_index_shift) = F405_DeltaFoverF;
            this_mouse_matrix_F465(transitions,1+time_index_shift:size(F465_DeltaFoverF,2)+time_index_shift) = F465_DeltaFoverF;
            
            this_condition_matrix_F405(k,1+time_index_shift:size(F405_DeltaFoverF,2)+time_index_shift) = F405_DeltaFoverF;
            this_condition_matrix_F465(k,1+time_index_shift:size(F465_DeltaFoverF,2)+time_index_shift) = F465_DeltaFoverF;
            y_axis_labels{k} = mousestr;
            
            k = k+1; %keep k counting
            

            
        end
        
        %mark `null' entries as NaN at the end -- the only time
        %something can be identically zero is if it's a non-entry, and I
        %think marking them now will make them easier to identify later
        %on...
        this_mouse_matrix_F405(this_mouse_matrix_F405 == 0) = NaN;
        this_mouse_matrix_F465(this_mouse_matrix_F465 == 0) = NaN;

        %average the existing entries at each time to collapse this mouse's
        %data as best as possible...
        clear this_mouse_averaged_F405 this_mouse_averaged_F465
        for col = 1:size(this_mouse_matrix_F405,2)
            this_mouse_averaged_F405(1,col) =  mean(this_mouse_matrix_F405(~isnan(this_mouse_matrix_F405(:,col)),col));
            this_mouse_averaged_F465(1,col) =  mean(this_mouse_matrix_F465(~isnan(this_mouse_matrix_F465(:,col)),col));
        end
        
        %append these onto the averaged matrix for this condition:
        this_condition_avgd_matrix_F405(m,1:size(this_mouse_averaged_F405,2)) = this_mouse_averaged_F405;
        this_condition_avgd_matrix_F465(m,1:size(this_mouse_averaged_F465,2)) = this_mouse_averaged_F465;
       

       
    end %of all the different mice and trials for this condition
        
          %mark `null' entries as NaN at the end -- the only time
        %something can be identically zero is if it's a non-entry, and I
        %think marking them now will make them easier to identify later
        %on...
        this_condition_avgd_matrix_F405(this_condition_avgd_matrix_F405 == 0) = NaN;
        this_condition_avgd_matrix_F465(this_condition_avgd_matrix_F465 == 0) = NaN;
        this_condition_matrix_F405(this_condition_matrix_F405 == 0) = NaN;
        this_condition_matrix_F465(this_condition_matrix_F465 == 0) = NaN;
    
        
        % while we're here, extract the *mean* and *standard error* data
        % for later plotting 
        clear this_condition_F405_mean this_condition_F405_SE this_condition_F465_mean this_condition_F465_SE
        for col = 1:size(this_condition_matrix_F405,2)
            this_condition_F405_mean(1,col) =  mean(this_condition_matrix_F405(~isnan(this_condition_matrix_F405(:,col)),col));
            %calculating standard error (SE) as the standard devation
            %divided by the square root of the number of samples:
            this_condition_F405_SE(1,col) = std(this_condition_matrix_F405(~isnan(this_condition_matrix_F405(:,col)),col))/sqrt(sum(~isnan(this_condition_matrix_F405(:,col))));
            this_condition_F465_mean(1,col) =  mean(this_condition_matrix_F465(~isnan(this_condition_matrix_F465(:,col)),col));
            this_condition_F465_SE(1,col) = std(this_condition_matrix_F465(~isnan(this_condition_matrix_F465(:,col)),col))/sqrt(sum(~isnan(this_condition_matrix_F465(:,col))));
        end 
        
        
        %build the new time axis for the big matrices:
        t_downsampled_shifted = ((1:size(this_condition_matrix_F405,2))-1/2)*round(fs)/fs - t_stim_reference;
    
        %save the four matrices *this* condition specifically
        %EVAL with condition number
        eval(['condition_' num2str(all_condition_numbers(c_index)) '_avgd_matrix_F405 = this_condition_avgd_matrix_F405;'])
        eval(['condition_' num2str(all_condition_numbers(c_index)) '_avgd_matrix_F465 = this_condition_avgd_matrix_F465;'])
        eval(['condition_' num2str(all_condition_numbers(c_index)) '_matrix_F405 = this_condition_matrix_F405;'])
        eval(['condition_' num2str(all_condition_numbers(c_index)) '_matrix_F465 = this_condition_matrix_F465;'])
        eval(['condition_' num2str(all_condition_numbers(c_index)) '_t_downsampled_shifted = t_downsampled_shifted;'])
        
        eval(['condition_' num2str(all_condition_numbers(c_index)) '_F405_mean = this_condition_F405_mean;'])
        eval(['condition_' num2str(all_condition_numbers(c_index)) '_F405_SE = this_condition_F405_SE;'])
        eval(['condition_' num2str(all_condition_numbers(c_index)) '_F465_mean = this_condition_F465_mean;'])
        eval(['condition_' num2str(all_condition_numbers(c_index)) '_F465_SE = this_condition_F465_SE;'])
        eval(['condition_' num2str(all_condition_numbers(c_index)) '_mouse_numbers = mouse_numbers_this_condition;'])
        
        eval(['save condition_' num2str(all_condition_numbers(c_index)) '_summary.mat y_axis_labels c_index IA mouse_numbers_this_condition condition_' num2str(all_condition_numbers(c_index)) '_mouse_numbers this_condition_F405_mean this_condition_F405_SE this_condition_F465_mean this_condition_F465_SE t_downsampled_shifted this_condition_avgd_matrix_F405 this_condition_avgd_matrix_F465 this_condition_matrix_F405 this_condition_matrix_F465 ' ...
            'condition_' num2str(all_condition_numbers(c_index)) '_avgd_matrix_F405 condition_' num2str(all_condition_numbers(c_index)) '_avgd_matrix_F465 condition_' num2str(all_condition_numbers(c_index)) '_matrix_F405 condition_' num2str(all_condition_numbers(c_index)) '_matrix_F465 ' ... 
            'condition_' num2str(all_condition_numbers(c_index)) '_F405_mean condition_' num2str(all_condition_numbers(c_index)) '_F405_SE condition_' num2str(all_condition_numbers(c_index)) '_F465_mean condition_' num2str(all_condition_numbers(c_index)) '_F465_SE' ]) 
        
        
        %% PLOTTING
        % can also run this cell later after re-loading any of the
        % summary.mat files:
        figure('Name',[all_data(IA(c_index)).condition ' all trials heatmap F465'])
        imagesc(t_downsampled_shifted,1:size(this_condition_matrix_F465,1),this_condition_matrix_F465);
        hold all
        plot([0 0],[1 size(this_condition_matrix_F465,1)],'k--','LineWidth',1)
        
        set(gca,'LineWidth',1,'FontWeight','bold','FontSize',14)
        box on
        yticks(1:size(this_condition_matrix_F465,1))
        %yticklabels(y_axis_labels)
        caxis([-0.2 0.2]) %estimating, because initial "detrend" is messing up the scale
        xlabel('Time (s) ')
        title([all_data(IA(c_index)).condition ' all trials heatmap F465'])
        
        xlim([-50 50])
        
        %%if using colormap from kate jensen's 'kmap4' is in the
        %%workspace. Double click and click Finish to add to the workspaceThis can be found in the desktop folder called
        %%'KEJ_25Jan2020_new_scripts_from_Kate
        colormap(kmap4)
        
    %%%%%%%%%%%%%%    
        figure('Name',[all_data(IA(c_index)).condition ' mouse-averaged heatmap F465'])
        imagesc(t_downsampled_shifted,1:size(this_condition_avgd_matrix_F465,1),this_condition_avgd_matrix_F465);
        hold all
        plot([0 0],[1 size(this_condition_avgd_matrix_F465,1)],'k--','LineWidth',1)
        
        set(gca,'LineWidth',1,'FontWeight','bold','FontSize',18)
   
        32
        %yticks(1:numel(mouse_numbers_this_condition))
        %yticklabels(mouse_numbers_this_condition)
        caxis([-0.2 0.1]) %estimating, because initial "detrend" is messing up the scale
        %xlabel('Time (s) ')
        %ylabel('Mice ')
        title([all_data(IA(c_index)).condition ' mouse-averaged heatmap F465'])
        
        %fix the x-axis range
        xlim([-50 50])
        
        %Colormap and Make the colorbar visible
        colormap(kmap4)
        colorbar
     
        
     %%%%%%%%%%%%    
        figure('Name',[all_data(IA(c_index)).condition ' fuzzy line plots DeltaF/F F405 and F465'])
        %lay down error bars first
    %NOPE:    errorbar(t_downsampled_shifted,this_condition_F405_mean,this_condition_F405_SE)
        % the filled error plot turns out to be a little tricky... got some
        % help from the internets
        x_vector = [t_downsampled_shifted, t_downsampled_shifted(end:-1:1)];
        
        %405 standard error first
        %patch = fill(x_vector, [this_condition_F405_mean+this_condition_F405_SE, this_condition_F405_mean(end:-1:1)-this_condition_F405_SE(end:-1:1)], [81 38 152]/255);
        %set(patch, 'edgecolor', 'none');
        %set(patch, 'FaceAlpha', 0.5); %makes semi transparent
        hold all
        
        %465 standard error next 
        patch = fill(x_vector, [this_condition_F465_mean+this_condition_F465_SE, this_condition_F465_mean(end:-1:1)-this_condition_F465_SE(end:-1:1)], [1 0 1]);
        set(patch, 'edgecolor', 'none');
        set(patch, 'FaceAlpha', 0.5); %makes semi transparent     
        
        %now add the data
        %plot(t_downsampled_shifted, this_condition_F405_mean, 'DisplayName','405', 'LineWidth', 1.0,'Color',[81 38 152]/255)
        plot(t_downsampled_shifted, this_condition_F465_mean, 'DisplayName','465', 'LineWidth', 1.0,'Color',[0.25, 0.25, 0.25]/255)
       
        %fix the automatic y-axis limits
        ylim(ylim)
        
        %fix the x-axis range
        xlim ([-40 100])
        
        %note t_stim on the plot
        plot([0 0],[-0.5 0.5],'k-','LineWidth',1.0)
    
        %some plot formatting
        grid off; box on
        set(gca,'LineWidth',1,'FontWeight','bold','FontSize',20)
        title(['\DeltaF/F with SE averaged over all trials for ' all_data(IA(c_index)).condition])
        xlabel('Time (s) ')
        ylabel('?F/F' )
        

        %set the vertical limits manually
        ylim([-0.2 0.2])
        hold all
         
        %insert horizontal line at 0%%%%
         h = yline(0)
         set(h,'LineWidth',1.5, 'Color',[0.25, 0.25, 0.25]/255)
     
       
        %automatically show the legend
        %legend1 = legend(gca,'show');
        %set(legend1,'Location','northeast');
        
        
        
    
end %going through all of the conditions



