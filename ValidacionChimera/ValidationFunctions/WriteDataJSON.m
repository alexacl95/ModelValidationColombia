function WriteDataJSON(NameData, TSaveJSON, Inform)

    jsonText = fileread(NameData + '.json');
    % Convert JSON formatted text to MATLAB data types
    jsonData = jsondecode(jsonText); 
    Names = readtable('Data/full_model_names.csv','Delimiter','TreatAsEmpty','ReadVariableNames',false);
    Names = Names.Var1;

    %Save extension parameters  
    T = Inform.T;
    T = gsua_load(T);
    
    T.Nominal = Inform.Nominal;
    T.Properties.CustomProperties.output = [9, 10, 15, 16]; 
    
    TSaveJSON{T.Properties.RowNames, 'auxNominal'} = T{T.Properties.RowNames, 'Nominal'};  
    NominalSave = cell2struct(num2cell(TSaveJSON.auxNominal), Names, 1);
    jsonData.x0 = NominalSave;
    
    D = T.Properties.CustomProperties.Domain(2);
    
    opt = T.Properties.CustomProperties.copt;
     
    % Create extension for saving difussion systems
    Range2 = T.Properties.CustomProperties.creator.Range(1:end,:);
    opt.rnames = T.Properties.RowNames;
        
    opt.out_names = T.Properties.CustomProperties.Vars;
    opt.range = Range2;    
    opt.action = 2;
    opt.domain = [0 D-1];
    T.Properties.CustomProperties.copt = opt;
    T.Properties.CustomProperties.Domain(2) = D-1;
    xdata = 0 : D - 1;  
    T.Properties.CustomProperties.output = [9, 10, 15, 16]; 
      
    gsua_deval(T.Nominal', T, xdata);
    
    load("nextTable.mat", 'T')
    
    if  any(strcmp("reg", T.Properties.RowNames))
        T{'reg', 'Nominal'} = 0;
    end
          
    T.Properties.CustomProperties.output = [9, 10, 15, 16]; 
        
    ysim = gsua_deval(T.Nominal', T, xdata);
    
    %simulated data
    jsonData.ActCasosSim = ysim(1,:);
    jsonData.MuertesSim = ysim(2,:);
    jsonData.RecuperadosSim = ysim(3,:);
    jsonData.TotalesSim = ysim(4,:);
    
    %real data
    jsonData.ActCasos = Inform.ydata(1,:);
    jsonData.Muertes = Inform.ydata(2,:);
    jsonData.Recuperados = Inform.ydata(3,:);
    
    % Difussion systems
    jsonData.M = T.Properties.CustomProperties.copt.M(:,end);
    jsonData.L = T.Properties.CustomProperties.copt.L(end,:);
    jsonData.JH = T.Properties.CustomProperties.copt.JH(end,:);
    jsonData.JL = T.Properties.CustomProperties.copt.JL(end,:);
    
    jsonData.domain = [0 Inform.Cut(end)-1];
       
    % Write to a json file
    jsonText2 = jsonencode(jsonData);
    fid = fopen('Outs/' + NameData + '.json', 'w');
    fprintf(fid, '%s', jsonText2);
    fclose(fid);    
end
