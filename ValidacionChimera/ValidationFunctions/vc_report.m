function  vc_report(NameData)

    import mlreportgen.report.* 
    import mlreportgen.dom.* 
    addpath Model
    addpath Tool
    close all
    
    margin = 3;%margin for cost function in UA
    %Load generated data from validations
    load("Informs/" + NameData + "Inform.mat",'InformContainer','ydata')
    rpt = Report("Informs/" + NameData + "Report",'pdf'); 

    tp = TitlePage; 
    Localidad = InformContainer{1}.local;
    tp.Title = "Validación para " + Localidad; 
    tp.Author = "Grupo de investigación en epidemiología, EAFIT"; 
    add(rpt, tp); 
    add(rpt, TableOfContents); 

    numsec = length(InformContainer);

    % Iterate over the number of extensions    
    for i = 1 : numsec
        
        Inform = InformContainer{i};
        
        try
            csbRange = Inform.csb;
        catch
            csbRange = [];
        end
        
        ch1 = Chapter; 
        ch1.Title = "Tramo número " + num2str(i); 
        sec1 = Section; 
        sec1.Title = 'Información básica'; 
        %xdata = Inform.xdata;
        xdata = 0:Inform.Cut(2)-1;
        Cut = Inform.Cut;
        
        
        if isfield(Inform,'BeginCut')
            interval = [Inform.BeginCut, Cut(2)];
        else
            interval = [Cut(1), Cut(2)];
        end

        if Inform.failure
            status = "FALLIDA.";
        else
            status = "COMPLETADA.";
        end

        para1 = Paragraph("El tramo a validar consiste en la serie de tiempo desde el dato "...
            + string(interval(1)) + " hasta el dato " + string(interval(2)) +...
            ". El estado de la validación es: " + status); 
        
        nsims = Inform.N;
        nestim = Inform.nestim;
        nfixed = sum(Inform.fixutil.fixing);
        
        if nfixed == 0
            testim = nestim + nsims;
        else
            testim = Inform.maxestim1 + (nfixed-1)*Inform.maxestim2 + nestim + nsims;
        end
        
        para2 = Paragraph("El número de estimaciones necesarias para realizar la validación fue de "...
            + string(testim) + ".");
        
        add(sec1, para1) 
        add(sec1, para2)
        add(ch1, sec1) 

        sec2 = Section; 
        sec2.Title = 'Parámetros estimados con sus intervalos'; 
        
        para3 = Paragraph("Fue necesario fijar "...
            + string(nfixed) + " parámetros de " + string(Inform.flimit) +...
            " que podían fijarse para completar la validación.");
        
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
            paraCsb = Paragraph("Debido a una desviación de la mediana " +...
                "se activó el método CSB para obtener los intervalos de parámetros."); 
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
        sec3.Title = 'Análisis de identificabilidad'; 
        
        %T = Inform.T;
        T.Est = estimations2;
        T(fixed, : ) = [];
        gsua_ia(T, T.Est, false, true); % Identifiability table
        
        for h = [3 4 6]
            
            figure(h)
            fig = Figure(gcf); 
            fig.Snapshot.Height = '4in'; 
            fig.Snapshot.Width = '6in'; 
            
            add(sec3, fig); 
            
        end
        
        add(ch1, sec3); 

        sec4 = Section; 
        sec4.Title = 'Análisis de incertidumbre'; 
        
        T = Inform.T;
        T = gsua_load(T);
        T.Est = estimations2;
        T.Properties.CustomProperties.Fixed = logical(fixed);
        T = gsua_dia(T, T.Est);%Identifiability table
        T.Properties.CustomProperties.output = [9 10 15];
        T.Properties.CustomProperties.Vars = {'S_f', 'S_q',...
            'E_f', 'E_q', 'L_f','L_q','H_f','H_q','Detectados','Fallecidos',...
                'R','T','RJH','RJL','Recuperados','Tot','JH','JL','J_{~P}','J_{P}'};
        
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
            sup=find(BFM_esc(:,1)<1, 1, 'last' );  
            gsua_plot('UncertaintyAnalysis',T,Y_test(order,:,:),xdata,ycut,sup);
        catch
            gsua_plot('UncertaintyAnalysis',T,Y_test(order,:,:),xdata,ycut);
        end

        fig = Figure(gcf); 
        fig.Snapshot.Height = '4in'; 
        fig.Snapshot.Width = '6in'; 
        
        add(sec4, fig); 
        add(ch1, sec4); 
        add(rpt, ch1); 
        
        close all 

    end

    close(rpt)

end