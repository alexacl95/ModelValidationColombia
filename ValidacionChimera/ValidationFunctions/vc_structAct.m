function Inform = vc_structAct(Inform)

    fixutil = Inform.fixutil;
    fixing = sum(fixutil.fixing);
    
    if isfield(Inform,'thres2')
        thres2 = Inform.thres2;
        cass = sum([100, 500]<thres2);
        switch cass
            case 0
                fpar = 3;
            case 1
                fpar = 2;
            otherwise
                fpar = 1;
        end
    else
        fpar = 1;
    end
    
    if fixing == Inform.flimit
        
        Inform.failure = true;
        Inform.Nominal = Inform.estimations(:, 1);
        
        return
    
    end
    
    if fixing + fpar > Inform.flimit
        fpar = Inform.flimit - fixing;
    end

    switch fixing 
        
        case 0 % if there is not something fixed
            
            Inform.nestim = Inform.nestim + Inform.N; 
            
            if Inform.nestim > Inform.maxestim1
                Inform.nestim = 0;
                for h = 1:fpar
                    Inform = vc_fixing(Inform, fixutil);
                end
            end
            
        otherwise % if there is something fixed
            Inform.nestim = Inform.nestim + Inform.N; 
            
            if Inform.nestim > Inform.maxestim2
                Inform.nestim = 0;
                for h = 1:fpar
                    Inform = vc_fixing(Inform, fixutil);
                end
            end
    end

        function Inform = vc_fixing(Inform, fixutil)
            
            index = Inform.index;
            fixable = logical(fixutil.fixable);
            maxim = max(index(fixable));
            flag = true;
            j = 0;

            while flag
                j = j + 1;
                fix = find(index == maxim);
                if fixutil.fixable(fix(j)) == 1
                    flag = false;
                end
            end
            
            fixutil.fixing(fix(j)) = 1;
            fixutil.Range(fix(j),:) = [Inform.Median(fix(j)), Inform.Median(fix(j))];
            Inform.fixutil = fixutil;
            
            disp("Fixing params")
        
        end
end