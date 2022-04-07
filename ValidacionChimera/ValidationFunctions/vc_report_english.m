function  vc_report_english(NameData)

    import mlreportgen.report.* 
    import mlreportgen.dom.* 
    addpath Model
    addpath Tool
    close all
    
    margin = 3;%margin for cost function in UA
    %Load generated data from validations
    load("Informs/" + NameData + "Inform.mat",'InformContainer','ydata')
    rpt = Report("Informs/InformsPDF/" + NameData + "Report",'pdf'); 

    tp = TitlePage; 
    Localidad = InformContainer{1}.local;
    tp.Title = "Validation process for" + Localidad; 
    tp.Author = "The epidemiology research group, EAFIT"; 
    add(rpt, tp); 
    add(rpt, TableOfContents); 

    numsec = length(InformContainer);
    
    Hei = '1in'; 
    Wid = '1.5in';     

    % Iterate over the number of extensions    
    for i = 1 : numsec
        
        Inform = InformContainer{i};
        
        try
            csbRange = Inform.csb;
        catch
            csbRange = [];
        end
        
        ch1 = Chapter; 
        ch1.Title = "Extension number" + num2str(i); 
        sec1 = Section; 
        sec1.Title = 'Basic information'; 
        %xdata = Inform.xdata;
        xdata = 0:Inform.Cut(2)-1;
        Cut = Inform.Cut;
        
        
        if isfield(Inform,'BeginCut')
            interval = [Inform.BeginCut, Cut(2)];
        else
            interval = [Cut(1), Cut(2)];
        end

        if Inform.failure
            status = "FAIL.";
        else
            status = "COMPLETED.";
        end

        para1 = Paragraph("The extension to be validated consists of the time series from the data"...
            + string(interval(1)) + " to the " + string(interval(2)) +...
            ". The status of the validation is: " + status); 
        
        nsims = Inform.N;
        nestim = Inform.nestim;
        nfixed = sum(Inform.fixutil.fixing);
        
        if nfixed == 0
            testim = nestim + nsims;
        else
            testim = Inform.maxestim1 + (nfixed-1)*Inform.maxestim2 + nestim + nsims;
        end
        
        para2 = Paragraph("The number of estimations needed to perform the validation was"...
            + string(testim) + ".");
        
        add(sec1, para1) 
        add(sec1, para2)
        add(ch1, sec1) 

        sec2 = Section; 
        sec2.Title = 'Estimated parameters with their intervals'; 
        
        para3 = Paragraph("It was necessary to fix "...
            + string(nfixed) + " parameters of " + string(Inform.flimit) +...
            " that could be fixed to complete validation.");
        
        add(sec2, para3)
        
         tableStyles = { ColSep("solid"), ...
                     RowSep("solid"), ...
                     Border("solid") };

         tableHeaderStyles = { BackgroundColor("lightgray"), ...
                               Bold(true) };
% 
%         headerLabels = ["Fixed Params", "New fixed", "Fixed values"];
%         InitialFixedParams = {string(InformContainer{1,i}.fixutil.Row(InformContainer{1, i}.fixutil.fixable == 1, : ))'};
%         NewFixedParams = {string(InformContainer{1,i}.fixutil.Row(InformContainer{1, i}.fixutil.fixing == 1, : ))'};
% 
%         if isempty(NewFixedParams{1}) == 1 
% 
%             NewFixedParams = {["Not fixed"]};
%             NewFixedValues = {["Not fixed"]};
% 
%         else
%             NewFixedValues = {string(InformContainer{1, i}.fixutil.Nomianl(InformContainer{1, i}.fixutil.fixing == 1,:))'};
%         end
% 
%         tableData(1, : ) = [InitialFixedParams, NewFixedParams, NewFixedValues];
% 
%         cellTbl = FormalTable(headerLabels, tableData);
%         cellTbl.Style = [cellTbl.Style, tableStyles];
%         cellTbl.Header.Style = [cellTbl.Header.Style, tableHeaderStyles];
%         cellTbl.TableEntriesInnerMargin = "2pt";

        residual = Inform.residual;
        estimations = Inform.estimations;
        selectEstim = residual < residual(1) * 2;
        
        if sum(selectEstim) <= 1
            selectEstim(1 : 1) = true;
        end
        
        fixutil = Inform.fixutil;
        fixed = logical(fixutil.fixing);
        estimations2 = estimations(:, selectEstim);
        T = Inform.T;
        T.Properties.CustomProperties.Fixed = fixed;
        T2 = gsua_dia(T, estimations2, false);
        T2.Est = [];
        
        if ~isempty(csbRange)
            T2.Range = csbRange;
            paraCsb = Paragraph("Due to a deviation from the median" +...
                " the CSB method was activated to obtain the parameter intervals."); 
            add(sec2, paraCsb)
        end
        
        T2.Best = Inform.Nominal;
        T2{:,:} = round(T2{:,:},4);
        aux = arrayfun(@ (n) num2str(n),T2{:,:},'UniformOutput',false);
        aux2 = table(aux(:,1));
        aux2.Rango = [aux(:,1),aux(:,2)];
        aux2.Nominal = aux(:,3);
        aux2.Mejor = aux(:,5);
        aux2.Index = aux(:,4);
        aux2(:,1)=[];
        aux2.Properties.RowNames = T2.Properties.RowNames;

        %cellTbl = FormalTable(headerLabels, tableData);
        cellTbl = FormalTable(aux2);
        cellTbl.Style = [cellTbl.Style, tableStyles];
        cellTbl.Header.Style = [cellTbl.Header.Style, tableHeaderStyles];
        cellTbl.TableEntriesInnerMargin = "2pt";

        add(sec2, cellTbl) 
        add(ch1, sec2) 

        sec3 = Section; 
        sec3.Title = 'Identifiability analisys'; 
        
        %T = Inform.T;
        T.Est = estimations2;
        T(fixed, : ) = [];
        gsua_ia(T, T.Est, false, true); % Identifiability table
        
        for h = [3 4 6]
            
            figure(h)
            fig = Figure(gcf); 
            fig.Snapshot.Height = Hei; 
            fig.Snapshot.Width = Wid; 
            
            add(sec3, fig); 
            
        end
        
        add(ch1, sec3); 

        sec4 = Section; 
        sec4.Title = 'Uncertainty analisys'; 
        
        T = Inform.T;
        T = gsua_load(T);
        T.Est = estimations2;
        T.Properties.CustomProperties.Fixed = logical(fixed);
        T = gsua_dia(T, T.Est);%Identifiability table
        T.Properties.CustomProperties.output = [9 10 15];
        T.Properties.CustomProperties.Vars = {'S_f', 'S_q',...
            'E_f', 'E_q', 'L_f','L_q','H_f','H_q','Detected','Dead',...
                'R','T','RJH','RJL','REcovered','Tot','JH','JL','J_{~P}','J_{P}'};
        
        if ~isempty(csbRange)
            T.Range = csbRange;
        end
            
        M = gsua_dmatrix(T, 500);
        ycut = ydata(:, xdata + 1);
        
        figure(7)
        Y_test=gsua_pardeval(M,T,xdata,false);
        
        
        cos=gsua_costfMulti(Y_test(:,Cut(1):Cut(2),:),ycut(:,Cut(1):Cut(2)),margin,false);
        BFM_esc=[cos',M];
        [BFM_esc,order]=sortrows(BFM_esc); 
        try
            sup = find(BFM_esc(:,1)<1, 1, 'last' );  
            gsua_plot('UncertaintyAnalysis',T,Y_test(order,:,:),xdata,ycut,sup);
        catch
            gsua_plot('UncertaintyAnalysis',T,Y_test(order,:,:),xdata,ycut);
        end

        fig = Figure(gcf); 
        fig.Snapshot.Height = Hei; 
        fig.Snapshot.Width = Wid; 
        
        add(sec4, fig); 
        add(ch1, sec4); 
        add(rpt, ch1); 
        
        close all 

    end

    close(rpt)

end