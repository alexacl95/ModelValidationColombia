function [T, Residual] = FirstEstimation(T, N, Cut, ydata, xdata,Inform,parallel)
       
    % Data segmentation
    ydataCut(1,:) = ydata(1, 1 : Cut);
    ydataCut(2,:) = ydata(2, 1 : Cut);
    ydataCut(3,:) = ydata(3, 1 : Cut);
    xdataCut = xdata(1 : Cut);
    
    [T, Residual] = MainEstimations(T, N, ydataCut, xdataCut,Inform, false, parallel);

end