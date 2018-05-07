function [wtv_summary]=AX3_WearSummary(wtv)

% output var
wtv_summary = [];

% process wear-time input
wtv_datevec = datevec(cell2mat(wtv(:,1)));
wtv_datenum = cell2mat(wtv(:,1:2));

% wear-time parameters
date_first = datenum(wtv_datevec(1,1),wtv_datevec(1,2),wtv_datevec(1,3),0,0,0);
date_last = datenum(wtv_datevec(end,1),wtv_datevec(end,2),wtv_datevec(end,3),0,0,0);
n_days = ceil(date_last - date_first);
epoch_m = round((wtv{2,1}-wtv{1,1})*(24*60));


%% process each day
for ix = 1:n_days
    
    e_start = date_first + datenum(0,0,(ix-1),0,0,0);
    e_stop  = date_first + datenum(0,0,(ix),0,0,0);
    
    jx_day = find(wtv_datenum(:,1)>=e_start & wtv_datenum(:,1)<e_stop);
    
    if(~isempty(jx_day))
        wtv_summary(ix,1) = (ix-1);
        wtv_summary(ix,2) = e_start;
        wtv_summary(ix,3) = size(jx_day,1)*epoch_m;
        wtv_summary(ix,4) = size(find(wtv_datenum(jx_day,2)==1),1)*epoch_m;
        wtv_summary(ix,5) = wtv_summary(ix,4)/wtv_summary(ix,3);


    else

        wtv_summary(ix,1) = (ix-1);
        wtv_summary(ix,2) = e_start;
        wtv_summary(ix,3) = 0;
        wtv_summary(ix,4) = 0;
        wtv_summary(ix,5) = 0;

    end
    
end