function [udw]=AX3_upsidedown(data,wtv)
% Calculate AX3 upside down monitor
% [udw]=AX3_upsidedown(data,epoch_m)

% interpolate time data
[t] = AX3_interpolatetime(data);

%declare variables
udw = cell(size(wtv,1),3); %upside-down wear output

%calculate epochs
epoch_m = round((wtv{2,1} - wtv{1,1})*(24*60));
last_epoch = size(wtv,1);

period_s = 60;
n_period = round((epoch_m*60)/period_s);


% calculate upside-down wear
% hw = waitbar(0,'Calculating upside-down wear');
for ix=1:last_epoch
    
%     waitbar((ix/last_epoch),hw,'Calculating upside-down wear');
    
    tmp_t1 = wtv{ix,1};
    tmp_wt = wtv{ix,2};
    
    udw{ix,1} = tmp_t1;
    
    if(tmp_wt==1) %only calculate in valid wear-time epoch
        
        % get epoch data
        epoch1 = tmp_t1;
        epoch2 = datenum(0,0,0,0,epoch_m,0) + tmp_t1;
        
        t1 = find(t>=epoch1,1,'first');
        t2 = find(t<epoch2,1,'last');
        
        t1 = min([t1,length(t)]);
        t2 = max([t2,1]);
        
        if(t2-t1>1)
            t_epoch = t(t1:t2);
            x1 = double(data.x(t1:t2))/256;
            y1 = double(data.y(t1:t2))/256;
            z1 = double(data.z(t1:t2))/256;
        else
            t_epoch = 0;
            x1=0;
            y1=0;
            z1=0;
        end
        
        udw_periods = [];
        for jx=1:n_period %break epoch into 60-sec periods
            
            % get indices for current period
            period1 = (jx-1)*datenum(0,0,0,0,0,period_s) + t_epoch(1);
            period2 = (jx)*datenum(0,0,0,0,0,period_s) + t_epoch(1);
            
            p1 = find(t_epoch>=period1,1,'first');
            p2 = find(t_epoch<period2,1,'last');
            
            if(isempty(p1))
                p1=1;
            end
            if(isempty(p2))
                p2=size(t_epoch,2);
            end
            
            udw_periods(jx,1) = period1;
            
            % get mean 3D vector of current period
            mean_x = mean(x1(p1:p2));
            mean_y = mean(y1(p1:p2));
            mean_z = mean(z1(p1:p2));
            
            % correct monitor orientation is
            %(+)x towards patient caudal (ground)
            %(+)y towards patient left
            %(+)z towards patient anterior
            
            %get vertical & horizontal magnitudes
            m_vert = mean_x;
            m_horz = sqrt(mean_y.^2 + mean_z.^2);
            
            %convert to spherical coordinates 
            %theta is radians from +x towards +y
            %phi is radians from sqrt(x^2+y^2) towards +z
            [theta,phi,r]=cart2sph(mean_x,mean_y,mean_z);
            
            %convert to degrees
            theta_deg = (theta/(pi))*180;
            phi_deg = (phi/(pi))*180;
            
            udw_periods(jx,3:7) = [theta_deg,phi_deg,r,m_vert,m_horz];
            
            %orientation thresholds
%             if(abs(m_vert) > abs(2*m_horz))
            if(abs(m_vert) > abs(0.25*m_horz))
                %monitor is probably not on its side
                if(abs(theta_deg)<=90)
                    %monitor is probably upside-down
                    udw_periods(jx,2) = 1;
%                 elseif(abs(phi_deg)>=165)
%                     %monitor is probably upside-down
%                     udw_periods(jx,2) = 1;
                else
                    %monitor is probably right-side-up
                    udw_periods(jx,2) = 0;
                end
            else
                %monitor is probably on its side, ignore this period
                udw_periods(jx,2) = 0;
            end %m_vert
            
        end %jx
        
        if(size(find(udw_periods(:,2)==1),1)>0)
            udw{ix,2} = 1;
            udw{ix,3} = udw_periods;
        else
            udw{ix,2} = 0;
        end
        
    else
        udw{ix,2} = 0;
        
    end %tmp_wt==1
    
end %ix
% close(hw);

