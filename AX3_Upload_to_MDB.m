function AX3_Upload_to_MDB(mdbf_master, file_in)


%% MDB parameters
% mdbf_master = 'E:\MOST-Renewal-II\AX3\AX3_Database\AX3_UCSF_Master.accdb';

f_summary = {...
%     'RecordID'
    'Filename'
    'Filedate'
    'Clinic'
    'DeviceID'
    'SessionID'
    'StartTime'
    'StopTime'
    'Annotation'
    'SampleRate'
    'SampleCount'
    'NumberDays'
    'ValidDays6Hrs'
    'ValidDays10Hrs'
    'NonWearDetected'
    'OvernightWearDetected'
    'UpsideDownWearDetected'};
%     'FlaggedForReview'
%     'ReviewResult'
%     'Comments'};

f_days = {...
%     'RecordID'
    'Filename'
    'Filedate'
    'Clinic'
    'DeviceID'
    'SessionID'
    'DayNumber'
    'CalendarDate'
    'DayStart'
    'DayEnd'
    'MinutesRecorded'
    'MinutesDay'
    'MinutesWearTime'
    'MinutesValidWearTime'
    'MinutesNonwear'
    'MinutesUpsideDownWear'
    'OvernightWearDetected'
    'NumberNonwearBlocks'
    'NumberUpsideDownBlocks'};

f_nwb = {...
%     'RecordID'
    'Filename'
    'Filedate'
    'Clinic'
    'DeviceID'
    'SessionID'
    'DayNumber'
    'CalendarDate'
    'NWBlockNumber'
    'NWBlockTimeStart'
    'NWBlockTimeEnd'
    'NWBlockLength'};

f_udb = {...
%     'RecordID'
    'Filename'
    'Filedate'
    'Clinic'
    'DeviceID'
    'SessionID'
    'DayNumber'
    'CalendarDate'
    'UDBlockNumber'
    'UDBlockTimeStart'
    'UDBlockTimeEnd'
    'UDBlockLength'};

%% output parameters

x_summary = {};
x_days = {};
x_nwb = {};
x_udb = {};

%% load file
load(file_in,'day_summary','metadata');

%% collect summary data
if(exist('day_summary','var') && exist('metadata','var'))
    
    [fp,fn,fe] = fileparts(file_in);
    
    fn_parse = textscan(fn,'%s','Delimiter','_');
    fn_parse = fn_parse{1};
    
    tmp_site = fn_parse{1};
    tmp_date = datestr(datenum(fn_parse{2},'yyyymmdd'),29);
    tmp_cwaf = horzcat(fn_parse{3},'_',fn_parse{4},'.cwa');
    
    tmp_anno = regexpi(metadata.Annotation,'(MB|MI){0,}[0-9]{5}[A-Z]{4}','match');
    if(~isempty(tmp_anno))
        tmp_anno = tmp_anno{end};
    else
        tmp_anno = '';
    end
    
    x_summary{1,1}  = tmp_cwaf;
    x_summary{1,2}  = tmp_date;
    x_summary{1,3}  = tmp_site;
    x_summary{1,4}  = num2str(metadata.DeviceID);
    x_summary{1,5}  = num2str(metadata.SessionID);
    x_summary{1,6}  = datestr(metadata.StartTime,31);
    x_summary{1,7}  = datestr(metadata.StopTime,31);
    x_summary{1,8}  = tmp_anno;
    x_summary{1,9}  = metadata.SampleRate;
    x_summary{1,10} = metadata.SampleCount;
    x_summary{1,11} = size(day_summary,2);
    
    counter_6   = 0;
    counter_10  = 0;
    counter_nw  = 0;
    counter_udw = 0;
    counter_ovn = 0;
    
    for jx=1:size(day_summary,2)
        
        dummy_rise  = [];
        dummy_slp   = [];
        dummy_ovn   = 0;
        
        tmp_total   = day_summary(jx).total_minutes;
        tmp_raw_wtv = day_summary(jx).raw_wtv_minutes;
        tmp_wtv     = day_summary(jx).wtv_minutes;
        tmp_udw     = day_summary(jx).udw_minutes;
        tmp_nw      = day_summary(jx).nw_minutes;
        tmp_perc    = day_summary(jx).raw_wtv_percentage;
        tmp_nwb     = day_summary(jx).nonwear_blocks;
        tmp_udb     = day_summary(jx).udw_blocks;
        tmp_slprise = day_summary(jx).slprise;
        tmp_date    = day_summary(jx).date;
        
        if(~isempty(tmp_slprise))
            tmp_rise = tmp_slprise(find(tmp_slprise(:,2)==1,1,'first'),:);
            dummy_rise = tmp_rise;
            if(~isempty(tmp_rise))
                tmp_rise = datestr(tmp_rise(1,1),31);
            else
                tmp_rise = [];
            end
        else
            tmp_rise = [];
        end
        if(~isempty(tmp_slprise))
            tmp_slp = tmp_slprise(find(tmp_slprise(:,2)==0,1,'last'),:);
            dummy_slp = tmp_slp;
            if(~isempty(tmp_slp))
                tmp_slp = datestr(tmp_slp(1,1),31);
            else
                tmp_slp = [];
            end
        else
            tmp_slp = [];
        end
        
        if(~isempty(tmp_rise) && ~isempty(tmp_slp))
            tmp_dm = round((datenum(tmp_slp) - datenum(tmp_rise))*(24*60));
        else
            tmp_dm = 0;
        end
        
        if(~isempty(tmp_date))
            tmp_date = datestr(datenum(tmp_date,'yyyymmdd'),29);
        end
        
        if(jx>1 && tmp_total>=480)
            if(tmp_wtv>=360 && tmp_total>=960)
                counter_6 = counter_6+1;
            end
            if(tmp_wtv>=600 && tmp_total>=960)
                counter_10 = counter_10+1;
            end
            if(tmp_nw>=1)
                counter_nw = 1;
            end
            if(tmp_udw>=1)
                counter_udw = 1;
            end
            if(tmp_perc>=0.75 && tmp_total>=960)
                dummy_ovn = 1;
                counter_ovn = 1;
            end
            if( (~isempty(dummy_rise)) && (~isempty(dummy_slp)))
                if((dummy_slp - dummy_rise)>1)
                    dummy_ovn = 1;
                    counter_ovn = 1;
                end
            end
        end
        
        x_days(jx,1:5)  = x_summary(1,1:5);
        x_days{jx,6}    = day_summary(jx).daynum;
        x_days{jx,7}    = tmp_date;
        x_days{jx,8}    = tmp_rise;
        x_days{jx,9}    = tmp_slp;
        x_days{jx,10}   = tmp_total;
        x_days{jx,11}   = tmp_dm;
        x_days{jx,12}   = tmp_raw_wtv;
        x_days{jx,13}   = tmp_wtv;
        x_days{jx,14}   = tmp_nw;
        x_days{jx,15}   = tmp_udw;
        x_days{jx,16}   = dummy_ovn;
        x_days{jx,17}   = size(tmp_nwb,1);
        x_days{jx,18}   = size(tmp_udb,1);
        
        if(~isempty(tmp_nwb))
            for kx=1:size(tmp_nwb,1)
                x_nwb(end+1,1:7)    = x_days(jx,1:7);
                x_nwb{end,8}        = kx;
                x_nwb{end,9}        = datestr(tmp_nwb(kx,1),31);
                x_nwb{end,10}       = datestr( (tmp_nwb(kx,1) + datenum(0,0,0,0,tmp_nwb(kx,3),0)),31);
                x_nwb{end,11}       = tmp_nwb(kx,3);
            end
        end
        
        if(~isempty(tmp_udb))
            for kx=1:size(tmp_udb,1)
                x_udb(end+1,1:7)    = x_days(jx,1:7);
                x_udb{end,8}        = kx;
                x_udb{end,9}        = datestr(tmp_udb(kx,1),31);
                x_udb{end,10}       = datestr( (tmp_udb(kx,1) + datenum(0,0,0,0,tmp_udb(kx,3),0)),31);
                x_udb{end,11}       = tmp_udb(kx,3);
            end
        end
        
    end
    
    x_summary{1,12} = counter_6;
    x_summary{1,13} = counter_10;
    x_summary{1,14} = counter_nw;
    x_summary{1,15} = counter_ovn;
    x_summary{1,16} = counter_udw;
    
    %upload data to mdb scoresheet
    conn = RobustMSAccessConn(mdbf_master);
    try
        ping(conn);
        if(~isempty(x_summary))
            fastinsert(conn,'tblAX3_Summary',f_summary,x_summary); pause(1);
        end
        if(~isempty(x_days))
            fastinsert(conn,'tblAX3_Days',f_days,x_days); pause(1);
        end
        if(~isempty(x_nwb))
            fastinsert(conn,'tblAX3_NonwearBlocks',f_nwb,x_nwb); pause(1);
        end
        if(~isempty(x_udb))
            fastinsert(conn,'tblAX3_UpsideDownBlocks',f_udb,x_udb); pause(1);
        end
        close(conn);
    catch inserterr
        disp('Upload error');
        disp(inserterr.message);
        disp(file_in);
        close(conn);
    end
    
else
    disp('Error loading data');
    disp(file_in);
end

