function [hf]=AX3_review_matlab(tmpf,data,wtv,udw,wtv_instance,udw_instance,slprise,block_final)

% process filename 

[fp,fn,fe] = fileparts(tmpf);

% interpolate time data
[t] = AX3_interpolatetime(data);

% create figure
hf = figure('Visible','off','Position',[20,50,1870,1060]);
ha = gca;
hold on;

% get some parameters
wx = size(wtv,1);
[y,m,d,H,M,S]=datevec(wtv{2,1} - wtv{1,1});
epoch_m = round((H*60)+(M)+(S/60));
epoch_datenum_m = datenum(0,0,0,0,epoch_m,0);

wix = size(wtv_instance,1);
uix = size(udw_instance,1);

% plot the wear time & upside-down wear

for ix=1:wix

    tmp_wtv = wtv_instance{ix,2};
    
    if(tmp_wtv==1)
        
        epoch1 = wtv_instance{ix,1};
        epoch_sz = datenum(0,0,0,0,wtv_instance{ix,3},0);
        epoch2 = epoch1 + epoch_sz;
        
        t1 = find(t>=epoch1,1,'first');
        t2 = find(t<epoch2,1,'last');
        t1 = min([t1,length(t)]);
        t2 = max([t2,1]);
    
    if(t2-t1>1)
        rectangle(ha,'Position',[epoch1,-2,epoch_sz,4],'FaceColor',[0.5, 0.5, 0.5],'EdgeColor',[0.5, 0.5, 0.5]);
    end
    
    end
end

for ix=1:uix
    
    tmp_udw = udw_instance{ix,2};
    
    if(tmp_udw==1)
        
        epoch1 = udw_instance{ix,1};
        epoch_sz = datenum(0,0,0,0,udw_instance{ix,3},0);
        epoch2 = epoch1 + epoch_sz;
        
        t1 = find(t>=epoch1,1,'first');
        t2 = find(t<epoch2,1,'last');
        t1 = min([t1,length(t)]);
        t2 = max([t2,1]);
    
    if(t2-t1>1)
        rectangle(ha,'Position',[epoch1,-2,epoch_sz,4],'FaceColor',[0.25, 0.25, 0.25],'EdgeColor',[0.25, 0.25, 0.25]);
    end
    
    end
end

set(hf,'Visible','on');

hl = {};
for ix=1:size(slprise,1)
    switch slprise(ix,2)
        case 0
            hl{ix} = plot(ha,[slprise(ix,1),slprise(ix,1)],[-2,2],'m--','LineWidth',2);
        case 1
            hl{ix} = plot(ha,[slprise(ix,1),slprise(ix,1)],[-2,2],'c--','LineWidth',2);
    end
end

% plot(ha,t([1,end]),[1,1],'k');
% plot(ha,t([1,end]),[-1,-1],'k');

x1 = double(data.x(1:1000:end))/256;
y1 = double(data.y(1:1000:end))/256;
z1 = double(data.z(1:1000:end))/256;

x1(x1>2) = 2;
y1(y1>2) = 2;
z1(z1>2) = 2;

x1(x1<-2) = -2;
y1(y1<-2) = -2;
z1(z1<-2) = -2;

plot(ha,t(1:1000:end),x1,'r');
plot(ha,t(1:1000:end),y1,'g');
plot(ha,t(1:1000:end),z1,'b');

[yr1,mo1,day1,HH1,MM1,SS1] = datevec(t(1));
[yr2,mo2,day2,HH2,MM2,SS2] = datevec(t(end));

HHdiv = floor(HH1/4);
HHmajor = HHdiv*4;

set(ha,'XTick',[datenum(yr1,mo1,day1,HHmajor,0,0):datenum(0,0,0,2,0,0):datenum(yr2,mo2,day2,HH2+1,0,0)],...
    'XTickLabelRotation',45,'XMinorTick','on');
ha.XAxis.MinorTickValues= [datenum(yr1,mo1,day1,HHmajor,0,0):datenum(0,0,0,0,30,0):datenum(yr2,mo2,day2,HH2+1,0,0)];
datetick(ha,'x','mm.dd HH:MM','keepticks');

title(strrep(strrep(fn,'\','\\'),'_','\_'));


