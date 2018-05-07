%% Proc CWA data

addpath('E:\MOST-Renewal-II\AX3');

% data directories
matdir = 'E:\MOST-Renewal-II\AX3\AX3_MAT_Data\';
figdir = 'E:\MOST-Renewal-II\AX3\AX3_FIG_Data\';
pngdir = 'E:\MOST-Renewal-II\AX3\AX3_PNG_Data\';

dv = datevec(now);
yyyy = num2str(dv(1));
mm = zerofillstr(dv(2),2);

chkdir = matdir;
destdir_mat = horzcat(matdir,yyyy,mm,'01\');
destdir_fig = horzcat(figdir,yyyy,mm,'01\');
destdir_png = horzcat(pngdir,yyyy,mm,'01\');

if(~exist(destdir_mat)); mkdir(destdir_mat); end;
if(~exist(destdir_fig)); mkdir(destdir_fig); end;
if(~exist(destdir_png)); mkdir(destdir_png); end;

% get list of existing data files

[~,~,chk_list] = foldertroll(chkdir,'.mat');

% get list of .cwa files
[~,~,cwa_list1] = foldertroll('Z:\Clinics\UAB\Axivity-AX3','.cwa');
[~,~,cwa_list2] = foldertroll('Z:\Clinics\UIowa\Axivity-AX3','.cwa');

cwa_list3 = [[cwa_list1, repcell([size(cwa_list1,1),1],'SITE01')];...
    [cwa_list2, repcell([size(cwa_list2,1),1],'SITE02')] ];

% loop through .cwa files and process new files

nlist = size(cwa_list3,1);
stopper = 0;
hw = waitbar(0,'0');
pause(0.25);

for ix=1:nlist
    
    waitbar((ix/nlist),hw,num2str(ix));
    
    try
        
        % filename parts
        tmpf = cwa_list3{ix,1};
        tmpp = cwa_list3{ix,2};
        tmpn = cwa_list3{ix,3};
        tmps = cwa_list3{ix,4};

        [~,tmp_dt,~] = fileparts(tmpp(1:end-1));
        [~,tmpn_rt,~] = fileparts(tmpn);

        % filename
        chk_name = horzcat(tmps,'_',tmp_dt,'_',tmpn_rt,'\.mat');
        
        % filepaths for saving
        sv_mat = horzcat(destdir_mat,tmps,'_',tmp_dt,'_',tmpn_rt,'.mat');
        sv_fig = horzcat(destdir_fig,tmps,'_',tmp_dt,'_',tmpn_rt,'.fig');
        sv_png = horzcat(destdir_png,tmps,'_',tmp_dt,'_',tmpn_rt,'.png');
        
        
        % check if data file already exists, continue if not
        if(isempty(indcfind(chk_list(:,3),chk_name,'regexpi')))
            
            % check if counter is too high, if so,  stop and continue next time
            if(stopper<=125)
                stopper = stopper+1;
            
                disp({ix, tmp_dt, tmpn});
                
                tic;

                % process and save data
                [data,metadata]=AX3_quickdata(tmpf);
                save(sv_mat,'data','metadata');
                pause(0.25);

                [wtv]=AX3_weartime(data,5,6);
                save(sv_mat,'wtv','-append');
                pause(0.25);

                [udw]=AX3_upsidedown(data,wtv);
                save(sv_mat,'udw','-append');
                pause(0.25);

                [wtv_instance]=AX3_WearInstances(wtv);
                [udw_instance]=AX3_UDWInstances(udw);
                [slprise4,blocks4]=AX3_SleepRise_4hr(wtv_instance,wtv);
                [slprise2,blocks2]=AX3_SleepRise_2hr(wtv_instance,wtv);
                [day_summary]=AX3_DaySummary(wtv,wtv_instance,udw_instance,slprise2,blocks2);

                save(sv_mat,'wtv_instance','udw_instance','slprise4','blocks4','slprise2','blocks2','day_summary','-append');
                pause(0.25);
                
                % create and save figures/PNGs
                hf = AX3_review_matlab(tmpf,data,wtv,udw,wtv_instance,udw_instance,slprise2,blocks2);
                print(hf,sv_png,'-dpng');
                savefig(hf,sv_fig);
                close(hf);
                pause(0.25);
            
                clear data wtv udw wtv_instance udw_instance slprise4 blocks4 slprise2 blocks2 day_summary hf;
                
                toc
            end
        end
    catch ax3_err
        disp(ax3_err.message);
    end
    pause(0.25);
end
close(hw);


%% Proc database file

% master mdb database file
master_mdbf = 'E:\MOST-Renewal-II\AX3\AX3_Database\AX3_UCSF_Master.accdb';

% savename for new copy
ds = datestr(now,'yyyymmdd');
copy_mdbf = horzcat('E:\MOST-Renewal-II\AX3\AX3_Database\AX3_UCSF_Master_',ds,'.accdb');

% get existing master mdbf data
[x_summary,f_summary] = MDBquery(master_mdbf,'SELECT * FROM tblAX3_Summary');
col_filename = indcfind(f_summary,'^Filename$','regexpi');
col_filedate = indcfind(f_summary,'^Filedate$','regexpi');
col_clinic   = indcfind(f_summary,'^Clinic$','regexpi');

% get list of newly processed data and loop through each file
[~,~,file_list] = foldertroll(destdir_mat,'.mat');

for ix=1:size(file_list,1)
    
    file_in = file_list{ix,1};
    
    % check data file against existing mdbf data
    [fp,fn,fe] = fileparts(file_in);
    
    fn_parse = textscan(fn,'%s','Delimiter','_');
    fn_parse = fn_parse{1};
    
    tmp_site = fn_parse{1};
    tmp_date = datestr(datenum(fn_parse{2},'yyyymmdd'),29);
    tmp_cwaf = horzcat(fn_parse{3},'_',fn_parse{4},'\.cwa');
    
    if(~isempty(tmp_site) && ~isempty(tmp_date) && ~isempty(tmp_cwaf))
        
        jx1 = indcfind(x_summary(:,col_filename),tmp_cwaf,'regexpi');
        jx2 = indcfind(x_summary(:,col_filedate),tmp_date,'regexpi');
        jx3 = indcfind(x_summary(:,col_clinic),tmp_site,'regexpi');

        jx4 = intersect(jx1,intersect(jx2,jx3));

        % continue if file not already in mdbf database
        if(isempty(jx4))

            try
                disp({ix, tmp_site, tmp_date, tmp_cwaf});

                AX3_Upload_to_MDB(master_mdbf, file_in);
            catch
                disp(horzcat('Error with uploading, deleting file: ',fn));
                delete(file_in);
            end
        end
    end
    
end
pause(0.25);

% make a snapshot copy of the master mdbf 
copyfile(master_mdbf, copy_mdbf, 'f');
pause(0.25);

exit;