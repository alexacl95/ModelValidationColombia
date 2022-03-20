function [T,ydataCut,xdata] = ExtEstimation(T, extpoint, i, cut, ydata, Inform)
    
    % Data segmentation
    ydataCut(1, : ) = ydata(1, 1 : cut);
    ydataCut(2, : ) = ydata(2, 1 : cut);
    ydataCut(3, : ) = ydata(3, 1 : cut);
   
    opt = T.Properties.CustomProperties.copt;
    
    % Check if it is the first extension
    if i == 2
        Range2 = [T.Properties.CustomProperties.creator.Range(9 : end, : );...
                    extpoint(1), extpoint(2)];
        opt.rnames = [T.Properties.RowNames(3 : end); "BP"];
    
    elseif i > 2
        
        Range2 = T.Properties.CustomProperties.creator.Range(1:end,:);
        Range2(end-1, :) = [extpoint(1), extpoint(2)];
        opt.rnames = T.Properties.RowNames;
    
    end
    
    % setting extension properties
    opt.out_names = T.Properties.CustomProperties.Vars;
    opt.range = Range2;    
    opt.action = 2;
    %D = length(ydataCut(1, : ));
    opt.domain = [0 cut];
    T.Properties.CustomProperties.copt = opt;
    T.Properties.CustomProperties.Domain(2) = cut;
    xdata = 0 : cut - 1;    
    gsua_deval(Inform.Nominal', T, xdata);
    load("nextTable.mat", 'T')   
    
end


    
