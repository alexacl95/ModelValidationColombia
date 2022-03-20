function [T, Residual] = MainEstimations(T, N, ydata, xdata, Inform, extension, parallel)
    
   if parallel
       parforArg=inf;
   else
       parforArg=0;
   end
   
    % Define the model outputs
    T.Properties.CustomProperties.output = [9,10,15];
    
    % Define the optimization algorithm options
    Solver='fmincon';
    Opt = optimoptions('fmincon','UseParallel',false,'MaxFunctionEvaluations',30000, ...
    'MaxIterations', 3000, 'Display','off');              
                   
    Best = zeros(size(T, 1), N);  % Matrix that saves factor's estimated values
    Residual = zeros(1, N);      % Vector that saves estimations cost function value
    T.Range = Inform.fixutil.Range;
    
    M = gsua_dmatrix(T, N, 'Method' , 'Sobol');
    
    if extension == true 
        
        if  strcmp(T.Properties.RowNames{end}, 'BP')
            M(:, end) = T.Properties.CustomProperties.CutAux;
            
        else 
            M(:, end - 1) = T.Properties.CustomProperties.CutAux;
        end
        BeginCut = round(T{'BP','Range'}(1));
        T.Properties.CustomProperties.Domain(1) = BeginCut;
        xdata = BeginCut : xdata(end);
        ydata = ydata( : , xdata + 1);
    end    
    
    parfor (j = 1:N,parforArg)
%     for j = 1:N
        [T_est, ResTemp, ~] = gsua_pe(T,xdata,ydata,...
                              'solver',Solver,'N',1,'opt',Opt,'save',false,'ipoint', M(j, :));
        Best(:,j) = T_est.Estfmincon;
        Residual(j) = ResTemp;
    end
        
    %Sort the estimated values according its cost function value
    [Residual, Idx] = sort(Residual);
    T.Est = Best(:, Idx);
    
end