function [day_summary]=AX3_DaySummary(wtv,wtv_instance,udw_instance,slprise,blocks)

%% output var
day_summary = struct(...
    'daynum',[],...
    'date',[],...
    'total_minutes',[],...
    'raw_wtv_minutes',[],...
    'wtv_minutes',[],...
    'udw_minutes',[],...
    'nw_minutes',[],...
    'slprise',[],...
    'blocks',[],...
    'raw_wtv_percentage',[],...
    'wtv_instance',[],...
    'udw_instance',[],...
    'nonwear_blocks',[],...
    'udw_blocks',[],...
    'day_minutes',[]);

%% wear-time
wtv_datevec = datevec(cell2mat(wtv(:,1)));
wtv_datenum = cell2mat(wtv(:,1:2));

date_first = datenum(wtv_datevec(1,1),wtv_datevec(1,2),wtv_datevec(1,3),0,0,0);
date_last = datenum(wtv_datevec(end,1),wtv_datevec(end,2),wtv_datevec(end,3),0,0,0);
n_days = ceil(date_last - date_first);
epoch_m = round((wtv{2,1}-wtv{1,1})*(24*60));


%% wear-time instances
wtvi_datenum = cell2mat(wtv_instance(:,1:2));

%% upside-down wear
udwi_datenum = cell2mat(udw_instance(:,1:2));

%% slprise
if(~isempty(slprise))
    kx_rise = find(slprise(:,2)==1);
    kx_sleep = find(slprise(:,2)==0);
else
    kx_rise = [];
    kx_sleep = [];
end

if(~isempty(blocks))
    blocks_datenum = cell2mat(blocks(:,1));
else
    blocks_datenum = [];
end

%% process each day
for ix = 1:n_days
    
    % empty vars
    e_start = [];
    e_stop = [];
    jx_wtv = [];
    jx_slprise = [];
    jx_rise = [];
    jx_sleep = [];
    jx_blocks = [];
    jx_wtvi = [];
    jx_udwi = [];
    tmp_wtvi = [];
    tmp_udwi = [];
    tmp_nonwtvi = [];
    tmp_onlyudwi = [];
    d_start = [];
    d_stop = [];
    
    % get date cut-offs at midnights
    e_start = date_first + datenum(0,0,(ix-1),0,0,0);
    e_stop  = date_first + datenum(0,0,(ix),0,0,0);    
    
    day_summary(ix).daynum = (ix-1);
    day_summary(ix).date = datestr(e_start,'yyyymmdd');
    
    % get raw times for the day
    jx_wtv = find(wtv_datenum(:,1)>=e_start & wtv_datenum(:,1)<e_stop);
    
    day_summary(ix).total_minutes = size(jx_wtv,1)*epoch_m;
    day_summary(ix).raw_wtv_minutes = size(find(wtv_datenum(jx_wtv,2)==1),1)*epoch_m;
    day_summary(ix).raw_wtv_percentage = day_summary(ix).raw_wtv_minutes/day_summary(ix).total_minutes;
    
    % get the sleep/rise time markers
    if(~isempty(slprise))
        jx_slprise = find(slprise(:,1)>=e_start & slprise(:,1)<e_stop);
        jx_rise = intersect(jx_slprise,kx_rise); 
    else
        jx_slprise = [];
        jx_rise = [];
    end
    
    if(isempty(jx_rise))
        day_summary(ix).wtv_minutes = 0;
        day_summary(ix).udw_minutes = 0;
        
        % get blocks
        if(~isempty(blocks_datenum))
            jx_blocks = find(blocks_datenum(:,1)>=e_start & blocks_datenum(:,1)<e_stop);
        else
            jx_blocks = [];
        end
        if(~isempty(jx_blocks))
            day_summary(ix).blocks = blocks(jx_blocks,:);
        end
        
    else
        % get rise and sleep markers
        jx_sleep = kx_sleep(find(kx_sleep>jx_rise(end),1,'first'));
        
        day_summary(ix).slprise = [slprise(jx_rise,:); slprise(jx_sleep,:)];
        
        d_start = slprise(jx_rise(1),1)-datenum(0,0,0,0,1,0);
        d_stop = slprise(jx_sleep,1)+datenum(0,0,0,0,1,0);
        
        if(~isempty(jx_rise) && ~isempty(jx_sleep))
            
            % get wtv during day
            jx_wtvi = find(wtvi_datenum(:,1)>=d_start(1) & wtvi_datenum(:,1)<d_stop(1));
            tmp_wtvi = cell2mat(wtv_instance(jx_wtvi,:));
            
            if(~isempty(tmp_wtvi))
                % get wear instances during days
                day_summary(ix).wtv_minutes = sum(tmp_wtvi(find(tmp_wtvi(:,2)==1),3));
                day_summary(ix).wtv_instance = tmp_wtvi;

                % get non-wear instances during day
                tmp_nonwtvi = tmp_wtvi(find(tmp_wtvi(1:(end-1),2)==0),:);
                if(size(tmp_nonwtvi,1)<1)
                    tmp_nonwtvi = [];
                    day_summary(ix).nw_minutes = 0;
                else
                    day_summary(ix).nonwear_blocks = tmp_nonwtvi;
                    day_summary(ix).nw_minutes = sum(tmp_nonwtvi(find(tmp_nonwtvi(:,2)==0),3));
                end
                
            else
                day_summary(ix).wtv_minutes = 0;
                day_summary(ix).nw_minutes = 0;
            end
            
            % get udw during day
            jx_udwi = find(udwi_datenum(:,1)>=d_start(1) & udwi_datenum(:,1)<d_stop(1));
            tmp_udwi = cell2mat(udw_instance(jx_udwi,:));
            
            if(~isempty(tmp_udwi))
                day_summary(ix).udw_minutes = sum(tmp_udwi(find(tmp_udwi(:,2)==1),3));
                day_summary(ix).udw_instance = tmp_udwi;

                % get udw instances during day
                tmp_onlyudwi = tmp_udwi(find(tmp_udwi(:,2)==1),:);
                day_summary(ix).udw_blocks = tmp_onlyudwi;
            else 
                day_summary(ix).udw_minutes = 0;
            end
            
        end
        
        % get blocks
        jx_blocks = find(blocks_datenum(:,1)>=e_start & blocks_datenum(:,1)<e_stop);
        if(~isempty(jx_blocks))
            day_summary(ix).blocks = blocks(jx_blocks,:);
        end
    end
    
end %ix
    

    
    