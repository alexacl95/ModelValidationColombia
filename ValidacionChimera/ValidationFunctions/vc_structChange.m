function Inform = vc_structChange(Inform, residual, estimations)

    if Inform.nestim > 0 
        
        residual = [residual, Inform.residual];
        estimations = [estimations, Inform.estimations];
        
        [residual, Idx] = sort(residual);
        estimations = estimations(:, Idx);
        
        Inform.residual = residual;
        Inform.estimations = estimations;

    else
        Inform.residual = residual;
        Inform.estimations = estimations;
    end

end