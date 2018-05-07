function [slprise,block_final]=AX3_SleepRise_2hr(wtv_instance,wtv)
% [slprs]=AX3_SleepRise(wtv_instance);
% 
% version 2

% output var
slprise = [];
block_final = [];

% process wear-time input
wtvi_datevec = datevec(cell2mat(wtv_instance(:,1)));
wtvi_datenum = cell2mat(wtv_instance(:,1));
wtv_datenum = cell2mat(wtv(:,1));

% wear-time parameters
date_first = datenum(wtvi_datevec(1,1),wtvi_datevec(1,2),wtvi_datevec(1,3),0,0,0);
date_last = datenum(wtvi_datevec(end,1),wtvi_datevec(end,2),wtvi_datevec(end,3),0,0,0);
n_days = ceil(date_last - date_first);
datenum_min = 1/(24*3600);

%% process each day
for ix=1:(n_days+1)

    block_day = [];
    day_plus = (ix-1);

    % time markers at 12am, 6am, 10am, 6pm, 9pm, 12am
    this_midnight     = date_first + day_plus;
    this_earlymorning = this_midnight + datenum(0,0,0,6,0,0);
    this_morning      = this_midnight + datenum(0,0,0,10,0,0);
    this_evening      = this_midnight + datenum(0,0,0,18,0,0);
    this_latenight    = this_midnight + datenum(0,0,0,21,0,0);
    next_midnight     = date_first + day_plus + 1;

    jx_midnight   = find(wtvi_datenum<=this_midnight,1,'last');
    jx_morning    = find(wtvi_datenum<=this_morning,1,'last');
    jx_early      = find(wtvi_datenum<=this_earlymorning,1,'last');
    jx_evening    = find(wtvi_datenum<=this_evening,1,'last');
    jx_latenight  = find(wtvi_datenum<=this_latenight,1,'last');
    jx_nextday    = find(wtvi_datenum<=next_midnight,1,'last');

    % move indices back 1 to encompass entire interval
    jx_midnight_1   = max([jx_midnight-1,1]);
    jx_early_1      = max([jx_early-1,1]);
    jx_evening_1    = max([jx_evening-1,1]);
    
    
    %% check if monitor worn during sleep
    if(~isempty(jx_midnight) & ~isempty(jx_nextday))
      instance_24hr = wtv_instance(jx_midnight:jx_nextday,:);
    else
      instance_24hr = {0,0,0};
    end
    chk_24hr = instance_24hr(find(cell2mat(instance_24hr(:,2))==0),:);
    chk_24hr_sleep = sum(cell2mat(chk_24hr(:,3)));

    if(chk_24hr_sleep>240) %only continue if monitor was off for at least 4 hrs
        
        %% break day into 3 blocks of wear intervals
        
        % wtv_instance blocks of 12am-10am, 6am-9pm, & 6pm-12am
        if(~isempty(jx_midnight_1) & ~isempty(jx_morning))
          instance_morning = (jx_midnight_1:jx_morning);
        else
          instance_morning = [];
        end

        if(~isempty(jx_early_1) & ~isempty(jx_evening))
          instance_afternoon = (jx_early_1:jx_latenight);
        else
          instance_afternoon = [];
        end

        if(~isempty(jx_evening_1) & ~isempty(jx_nextday))
          instance_evening = (jx_evening_1:jx_nextday);
        else
          instance_evening = [];
        end
        
        %% get morning block
        tmp_block = {};
        tmpx = instance_morning;
        for jx=1:size(tmpx,2);
            % check if interval is "monitor off" of at least 60 minutes
            if(wtv_instance{tmpx(jx),2}==0 && wtv_instance{tmpx(jx),3}>=60)
                % check if start/end of this interval are good markers
                start_good = 0;
                end_good = 0;
                
                %the start/end times
                tmp_time1 = wtv_instance{tmpx(jx),1};
                tmp_time2 = wtv_instance{tmpx(jx),1} + datenum(0,0,0,0,wtv_instance{tmpx(jx),3},0);
                
                %check 4 hrs before & after
                jx0 = find(wtv_datenum(:,1)<=(tmp_time1-datenum(0,0,0,4,0,0)),1,'last');
                jx1 = find(wtv_datenum(:,1)>=tmp_time1,1,'first');
                jx2 = find(wtv_datenum(:,1)<=tmp_time2,1,'last');
                jx3 = find(wtv_datenum(:,1)>=(tmp_time2+datenum(0,0,0,4,0,0)),1,'first');
                
                jx0 = max([jx0,1]);
                jx1 = min([jx1+1,size(wtv,1)]);
                jx2 = max([jx2,1]);
                jx3 = min([jx3-1,size(wtv,1)]);
                
                %sum of wear-time before/after
                chk01 = wtv(jx0:jx1,:);
                chk01 = chk01(find(cell2mat(chk01(:,2))==1),:);
                chk23 = wtv(jx2:jx3,:);
                chk23 = chk23(find(cell2mat(chk23(:,2))==1),:);
                sum01 = sum(cell2mat(chk01(:,5)))/60;
                sum23 = sum(cell2mat(chk23(:,5)))/60;
                
                %also check 2 hrs before & after
                kx0 = find(wtv_datenum(:,1)<=(tmp_time1-datenum(0,0,0,2,0,0)),1,'last');
                kx3 = find(wtv_datenum(:,1)>=(tmp_time2+datenum(0,0,0,2,0,0)),1,'first');
                chk01b = wtv(kx0:jx1,:);
                chk01b = chk01b(find(cell2mat(chk01b(:,2))==1),:);
                chk23b = wtv(jx2:kx3,:);
                chk23b = chk23b(find(cell2mat(chk23b(:,2))==1),:);
                sum01b = sum(cell2mat(chk01b(:,5)))/60;
                sum23b = sum(cell2mat(chk23b(:,5)))/60;
                
                %markers are good if at least 30/15 minutes of accurate wear-time
                if(sum01>=30 && sum01b>=15)
                    start_good = 1;
                end
                if(sum23>=30 && sum23b>=15)
                    end_good = 1;
                end
                
                tmp_block = [tmp_block; [wtv_instance(tmpx(jx),:), start_good, end_good, sum01, sum01b, 0, sum23b, sum23]];
                
            end %if
        end %jx
        block_morning = tmp_block;
        
        %% get afternoon block
        tmp_block = {};
        tmpx = instance_afternoon;
        for jx=1:size(tmpx,2);
            % check if interval is "monitor on" of at least 60 minutes
            if(wtv_instance{tmpx(jx),2}==1 && wtv_instance{tmpx(jx),3}>=60)
                % check if start/end of this interval are good markers
                start_good = 0;
                end_good = 0;
                
                %the start/end times
                tmp_time1 = wtv_instance{tmpx(jx),1};
                tmp_time2 = wtv_instance{tmpx(jx),1} + datenum(0,0,0,0,wtv_instance{tmpx(jx),3},0);
                tmp_tlen  = wtv_instance{tmpx(jx),3}; 
                
                %check 4 hrs before & after
                jx0 = find(wtv_datenum(:,1)<=(tmp_time1-datenum(0,0,0,4,0,0)),1,'last');
                jx1 = find(wtv_datenum(:,1)>=tmp_time1,1,'first');
                jx2 = find(wtv_datenum(:,1)<=tmp_time2,1,'last');
                jx3 = find(wtv_datenum(:,1)>=(tmp_time2+datenum(0,0,0,4,0,0)),1,'first');
                
                jx0 = max([jx0,1]);
                jx1 = min([jx1+1,size(wtv,1)]);
                jx2 = max([jx2,1]);
                jx3 = min([jx3-1,size(wtv,1)]);
                
                %sum of wear-time before/after
                chk01 = wtv(jx0:jx1,:);
                chk01 = chk01(find(cell2mat(chk01(:,2))==1),:);
                chk23 = wtv(jx2:jx3,:);
                chk23 = chk23(find(cell2mat(chk23(:,2))==1),:);
                sum01 = sum(cell2mat(chk01(:,5)))/60;
                sum23 = sum(cell2mat(chk23(:,5)))/60;
                
                %sum of wear-time in-between
                chk12 = wtv(jx1:jx2,:);
                chk12 = chk12(find(cell2mat(chk12(:,2))==1),:);
                sum12 = sum(cell2mat(chk12(:,5)))/60;
                
                %also check 2 hrs before & after
                kx0 = find(wtv_datenum(:,1)<=(tmp_time1-datenum(0,0,0,2,0,0)),1,'last');
                kx3 = find(wtv_datenum(:,1)>=(tmp_time2+datenum(0,0,0,2,0,0)),1,'first');
                chk01b = wtv(kx0:jx1,:);
                chk01b = chk01b(find(cell2mat(chk01b(:,2))==1),:);
                chk23b = wtv(jx2:kx3,:);
                chk23b = chk23b(find(cell2mat(chk23b(:,2))==1),:);
                sum01b = sum(cell2mat(chk01b(:,5)))/60;
                sum23b = sum(cell2mat(chk23b(:,5)))/60;
                
                %markers are good if less than 30/15 minutes of accurate nonwear-time
                if(sum01<30 && sum01b<15 && sum12>=(tmp_tlen/4))
                    start_good = 1;
                end
                if(sum23<30 && sum23b<15 &&  sum12>=(tmp_tlen/4))
                    end_good = 1;
                end
                
                tmp_block = [tmp_block; [wtv_instance(tmpx(jx),:), start_good, end_good, sum01, sum01b, sum12, sum23b, sum23,]];
                
            end %if
        end %jx
        block_afternoon = tmp_block;
        
        %% get evening block
        tmp_block = {};
        tmpx = instance_evening;
        for jx=1:size(tmpx,2);
            % check if interval is "monitor off" of at least 60 minutes
            if(wtv_instance{tmpx(jx),2}==0 && wtv_instance{tmpx(jx),3}>=60)
                % check if start/end of this interval are good markers
                start_good = 0;
                end_good = 0;
                
                %the start/end times
                tmp_time1 = wtv_instance{tmpx(jx),1};
                tmp_time2 = wtv_instance{tmpx(jx),1} + datenum(0,0,0,0,wtv_instance{tmpx(jx),3},0);
                
                %check 4 hrs before & after
                jx0 = find(wtv_datenum(:,1)<=(tmp_time1-datenum(0,0,0,4,0,0)),1,'last');
                jx1 = find(wtv_datenum(:,1)>=tmp_time1,1,'first');
                jx2 = find(wtv_datenum(:,1)<=tmp_time2,1,'last');
                jx3 = find(wtv_datenum(:,1)>=(tmp_time2+datenum(0,0,0,4,0,0)),1,'first');
                
                jx0 = max([jx0,1]);
                jx1 = min([jx1+1,size(wtv,1)]);
                jx2 = max([jx2,1]);
                jx3 = min([jx3-1,size(wtv,1)]);
                
                %sum of wear-time before/after
                chk01 = wtv(jx0:jx1,:);
                chk01 = chk01(find(cell2mat(chk01(:,2))==1),:);
                chk23 = wtv(jx2:jx3,:);
                chk23 = chk23(find(cell2mat(chk23(:,2))==1),:);
                sum01 = sum(cell2mat(chk01(:,5)))/60;
                sum23 = sum(cell2mat(chk23(:,5)))/60;
                
                %also check 2 hrs before & after
                kx0 = find(wtv_datenum(:,1)<=(tmp_time1-datenum(0,0,0,2,0,0)),1,'last');
                kx3 = find(wtv_datenum(:,1)>=(tmp_time2+datenum(0,0,0,2,0,0)),1,'first');
                chk01b = wtv(kx0:jx1,:);
                chk01b = chk01b(find(cell2mat(chk01b(:,2))==1),:);
                chk23b = wtv(jx2:kx3,:);
                chk23b = chk23b(find(cell2mat(chk23b(:,2))==1),:);
                sum01b = sum(cell2mat(chk01b(:,5)))/60;
                sum23b = sum(cell2mat(chk23b(:,5)))/60;
                
                %markers are good if at least 30/15 minutes of accurate wear-time
                if(sum01>=30 && sum01b>=15)
                    start_good = 1;
                end
                if(sum23>=30 && sum23b>=15)
                    end_good = 1;
                end
                
                tmp_block = [tmp_block; [wtv_instance(tmpx(jx),:), start_good, end_good, sum01, sum01b, 0, sum23b, sum23]];
                
            end %if
        end %jx
        block_evening = tmp_block;
        
        %% gather on/off markers
        block_day = [block_morning; block_afternoon; block_evening];
        block_day = sortrows(block_day,1);
        
        
    end %chk_24hr_sleep
    
    block_final = [block_final; block_day];
    
end %ix


%% sort & delete duplicates
if(~isempty(block_final))
    block_final = sortrows(block_final,1);
    dup_ix = find(diff(cell2mat(block_final(:,1)))<eps);
    block_final(dup_ix,:) = [];
end


%% gather the final on/off markers
for kx=1:size(block_final,1)
    
    tmptime     = block_final{kx,1}; %start time marker
    tmponoff    = block_final{kx,2}; %on or off
    tmpstart    = block_final{kx,4}; %start goodness
    tmpend      = block_final{kx,5}; %end goodness
    
    tmptime2    = block_final{kx,1} + datenum(0,0,0,0,block_final{kx,3},0); %end time marker
    tmpoppo     = (~tmponoff); %opposite marker for end
    
    %check this marker is not start of day 0 or end of last day
    if( (tmptime-wtv_datenum(1,1))>datenum_min && (tmptime-wtv_datenum(end,1))<(datenum_min*60) )
        
        % gather start marker
        if(size(slprise,1)<1 && tmpstart) %if no prior on/off marker
            slprise = [slprise; [tmptime, tmponoff]]; %first on/off marker
        elseif(tmpstart)
            lasttime  = slprise(end,1);
            lastonoff = slprise(end,2);
            
            %check time is after last marker
            if((tmptime-lasttime)>datenum_min)
                %check if marker is same on/off
                if(tmponoff==lastonoff)
                    %yes same, update marker
                    slprise(end,:) = [tmptime, tmponoff];
                else
                    %no different, add as new marker
                    slprise = [slprise; [tmptime, tmponoff]];
                end
            end %if (tmptime-lasttime)...
            
        end %if size(slprs,1)...
    end %if (tmptime-wtvi_datenum(1,1)...
    
    if( (tmptime2-wtv_datenum(1,1))>datenum_min && (tmptime2-wtv_datenum(end,1))<(datenum_min*60) )
        % gather end marker
        if(size(slprise,1)<1 && tmpend) %if no prior on/off marker
            slprise = [slprise; [tmptime2, tmpoppo]]; %first on/off marker
        elseif(tmpend)
            lasttime  = slprise(end,1);
            lastonoff = slprise(end,2);
            
            %check time is after last marker
            if((tmptime2-lasttime)>datenum_min)
                %check if marker is same on/off
                if(tmpoppo==lastonoff)
                    %yes same
                    if((tmptime2-lasttime)<datenum(0,0,0,12,0,0)) %check time since last same-marker
                        %less than 12 hrs, update marker
                        slprise(end,:) = [tmptime2, tmpoppo];
                    else %too many hrs elapsed, count as whole new day instead
                        slprise = [slprise; [tmptime, tmponoff]];
                        slprise = [slprise; [tmptime2, tmpoppo]];
                    end
                else
                    %no different, add as new marker
                    slprise = [slprise; [tmptime2, tmpoppo]];
                end
            end %if (tmptime-lasttime)...
            
        end %if size(slprs,1)...
    end
    
    
end %kx


%% filter sleep-rise markers for on-off markers too close together
mx=1;
while(mx<=size(slprise,1))
    
    m1 = mx;                %index
    tx1 = slprise(m1,1);    %time at index
    mx1 = slprise(m1,2);    %on/off at index
    
    if(mx1==1) %if on marker
        nx1 = find(slprise(:,2)==0); %all off markers
        nx2 = find(nx1<m1,1,'last'); %find the previous off marker (if it exists)
        
        m0 = nx1(nx2); %index of previous off marker
        if(~isempty(m0)) %if previous off marker exists
            
            tx0 = slprise(m0,1); %time at previous
            mx0 = slprise(m0,2); %on/off at previous (should always be an off marker)
            
            %continue if markers are not at beginning/end of datastream
            if(tx0~=1 && tx1~=size(slprise,1))
                
                %check if "off - on" markers more than 3 hrs apart
                if( (tx1-tx0) < datenum(0,0,0,3,0,0))

                    % delete this pair of markers
                    slprise(m0:m1,:)=[];

                    % reset mx to begin search all over again
                    mx=0;
                end

                end
            
        end
    end
    mx = mx + 1;
end


%% filter sleep-rise on markers if multiple in a single day
mx=1;
while(mx<=size(slprise,1))
    
    m1 = mx;                %index
    tx1 = slprise(m1,1);    %time at index
    mx1 = slprise(m1,2);    %on/off at index
    
    if(mx1==1) %if on marker
        
        nx1 = find(slprise(:,2)==1); %all on markers
        nx2 = find(nx1<m1,1,'last'); %find the previous on marker (if it exists)
        
        m0 = nx1(nx2); %index of previous on marker

        if(~isempty(m0)) %if previous on marker exists
            
            tx0 = slprise(m0,1); %time at previous
            mx0 = slprise(m0,2); %on/off at previous (should always be an on marker)
            
            %check if "on" markers less than 12 hrs apart
            if( (tx1-tx0) < datenum(0,0,0,12,0,0))
                
                % delete the later pair of repeat markers
                slprise((m0+1):m1,:)=[];
                
                % reset mx to begin search all over again
                mx=0;
            end
        end
            
    end
    
    mx = mx+1;
end

