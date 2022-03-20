function [UpgradeLocality, PartialResidual] = CheckingUpgrade(ydata, T, bound)
    
    % Complete simultion data
    xdata = 0:length(ydata) - 1;
    ysim = gsua_deval(T.Nominal', T, xdata);
     
    % Cut the real and simulated data
    Cut = T.Nominal({'BP'}); % last estimated breakpoint
    ydataCut = ydata(:, ceil(Cut):end);
    ysimCut = ysim(:, ceil(Cut):end);
    
    % checking cost function 
    PartialResidual = gsua_rcostf(ydataCut', ysimCut', bound);
        
    if PartialResidual >= 1
        UpgradeLocality = 1;
    else 
        UpgradeLocality = 0;
    end
end