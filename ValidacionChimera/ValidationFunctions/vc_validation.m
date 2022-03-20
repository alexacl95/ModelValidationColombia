function Inform = vc_validation(Inform, T, t1, t2, opt, parallel, csb)

    if nargin < 7
        csb = false;
    end
    RangeSaver = T.Range;
    residual = Inform.residual;
    estimations = Inform.estimations;
    Cut = Inform.Cut;
    xdata = Cut(1) : Cut(2);
    initt1 = 2;                                         % First limit for t1
    margin = 3;                                         % margin for the second criteria
    ncurves = 1000;                                     % Curves for uncertainty
    valin = true;                                       % Validation flag
    Inform.val = zeros(1, 2);
    t2 = round(ncurves * t2);
    if strcmp(opt,'median')
        yexp = Inform.ydata;
    end

    while valin
        selectEstim = residual < residual(1) * initt1;
        
        if sum(selectEstim) <= 1
            Inform.nestim = Inform.nestim+Inform.N;
            return;
        end
        
        thres1 = sum(selectEstim);                      % Threshold of minimum estimations
        estimations = estimations(:, selectEstim);
        residual = residual(selectEstim);
        fixutil = Inform.fixutil;
        fixed = fixutil.fixing;
        T.Properties.CustomProperties.Fixed = logical(fixed);
        T = gsua_dia(T, estimations);                   % Identifiability table
        Inform.index = T.index;                         % Identibiability index
        Inform.Median = T.Nominal;
        
        if thres1 < t1
            Inform = vc_structAct(Inform);
            return
        end
        
        Inform.val(1)=1;                                % Pass the first threshold
        
        if csb
            ybest = gsua_deval(estimations(:,1), T, xdata);
            ymedian = gsua_deval(T.Nominal, T, xdata);
            activator = gsua_costfMulti(ymedian, ybest, 0.3, false);
            if activator > 1
                disp("-----CSB ACTIVATED!-----")
                if parallel
                    nworkers = str2double(getenv('SLURM_NTASKS'));
                    delete(gcp('nocreate'));
                    parpool(nworkers);
                end
                Toat = T;
                Toat.Range = RangeSaver;
                Toat.Nominal = estimations(:,1);
                Toat.Properties.CustomProperties.Domain = [Cut(1) , Cut(2)];
                Toat = gsua_oatr(Toat, 'parallel',parallel, 'correct', true);
                Tcsb = gsua_csb(Toat, 1000, 'reps', 250, 'stop', 0.9, 'parallel', parallel, 'correct', true);
                csbL = Tcsb.Range(:,1);
                csbU = Tcsb.Range(:,2);

%                     if (any(csbL(csbL<T.Range(:,1))))||(any(csbU(csbU>T.Range(:,2))))
%                         csbL(csbL<T.Range(:,1))= T.Range(csbL<T.Range(:,1),1);
%                         csbU(csbU>T.Range(:,2))= T.Range(csbU>T.Range(:,2),2);   
%                     end

                Inform.csb = [csbL , csbU];
                valin = false;
                Inform.val=[1 , 1]; 
                continue
            end
        end

        M = gsua_dmatrix(T, ncurves);                   % UA criteria matrix
        ydata = gsua_pardeval(M, T, xdata, parallel);   % UA data
        yfun = gsua_deval(estimations(:,1), T, xdata);  % Best fit
        costf = gsua_costfMulti(ydata, yfun, margin, parallel);% UA cost function
        thres2 = sum(costf < 1);                        % Threshold of the best fit band

        if thres2 < t2
            initt1 = initt1 - 0.02 * initt1;
            Inform.thres2 = thres2;
        else
            Inform.val(2) = 1;                          % Pass the second threshold
            valin = false;
        end

    end

    switch opt
        case 'median'
            T.Properties.CustomProperties.output = [9,10,15];
            % Define the optimization algorithm options
            Solver='fmincon';
            Opt = optimoptions('fmincon','UseParallel',parallel,'MaxFunctionEvaluations',30000, ...
            'MaxIterations', 3000, 'Display','off');     
            
            ycut = yexp(:, xdata + 1);
            [T_est, ~, ~] = gsua_pe(T,xdata,ycut,'solver',Solver,'N',1,...
                'opt',Opt,'save',false,'ipoint', T.Nominal');
            Inform.Nominal = T_est.Estfmincon;             
        
        case 'best'
            Inform.Nominal = estimations(:, 1);
        otherwise 
            disp('chose *median* or *best*')
    end

end