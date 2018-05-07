function [udw_instance]=AX3_UDWInstances(udw)
% [udw_instance]=AX3_UDWInstances(udw);
% calculate blocks of upside-down-wear and switches

udw_array = cell2mat(udw(:,2));

udw_1 = udw{1,2};
epoch_m = round((udw{2,1}-udw{1,1})*(24*60));

udw_diff = diff(udw_array);

udw_switch = find(udw_diff~=0);

udw_instance = {};

if(~isempty(udw_switch))
% there is at least 1 switch from first wear-time status

  tmp_status = udw_1; %start with the first status
  tmp_length = udw_switch(1);
  udw_instance = [udw_instance; {udw{1,1}, tmp_status, tmp_length*epoch_m}];


  for ix=1:size(udw_switch,1)
    % continue every time udw status changes

    udw_change = udw_diff(udw_switch(ix));

    tmp_status = tmp_status + udw_change;

    if(size(udw_switch,1)>ix)
      tmp_length = udw_switch(ix+1) - udw_switch(ix);
    else
      tmp_length = size(udw,1) - udw_switch(ix);
    end

    udw_instance = [udw_instance; {udw{udw_switch(ix)+1,1}, tmp_status, tmp_length*epoch_m}];

  end %ix

else % no switches

  tmp_status = udw_1;
  tmp_length = size(udw,1);
  udw_instance = [udw_instance; {udw{1,1}, tmp_status, tmp_length*epoch_m}];

end % ~isempty
