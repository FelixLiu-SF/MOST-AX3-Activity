function [wtv_instance]=AX3_WearInstances(wtv)
% [wtv_instance]=AX3_WearInstances(wtv);
% calculate blocks of wear-time and switches

wtv_array = cell2mat(wtv(:,2));

wtv_1 = wtv{1,2};
epoch_m = round((wtv{2,1}-wtv{1,1})*(24*60));

wtv_diff = diff(wtv_array);

wtv_switch = find(wtv_diff~=0);

wtv_instance = {};

if(~isempty(wtv_switch))
% there is at least 1 switch from first wear-time status

  tmp_status = wtv_1; %start with the first status
  tmp_length = wtv_switch(1);
  wtv_instance = [wtv_instance; {wtv{1,1}, tmp_status, tmp_length*epoch_m}];


  for ix=1:size(wtv_switch,1)
    % continue every time wtv status changes

    wtv_change = wtv_diff(wtv_switch(ix));

    tmp_status = tmp_status + wtv_change;

    if(size(wtv_switch,1)>ix)
      tmp_length = wtv_switch(ix+1) - wtv_switch(ix);
    else
      tmp_length = size(wtv,1) - wtv_switch(ix);
    end

    wtv_instance = [wtv_instance; {wtv{wtv_switch(ix)+1,1}, tmp_status, tmp_length*epoch_m}];

  end %ix

else % no switches

  tmp_status = wtv_1;
  tmp_length = size(wtv,1);
  wtv_instance = [wtv_instance; {wtv{1,1}, tmp_status, tmp_length*epoch_m}];

end % ~isempty
