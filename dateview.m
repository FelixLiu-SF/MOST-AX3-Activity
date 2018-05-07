function dateview(cell_in)

switch lower(class(cell_in))
    case 'cell'
        tmp_view = [cellfun(@datestr,cell_in(:,1),'UniformOutput',0), cell_in(:,2:end)];
    case 'double'
        tmp_view = mat2cell(cell_in,ones([size(cell_in,1),1]),ones([1,size(cell_in,2)]));
        tmp_view = [cellfun(@datestr,tmp_view(:,1),'UniformOutput',0), tmp_view(:,2:end)];
end

disp(tmp_view);