function [ydata, Population, Cut, New, TitleLocality] = ReadDataJSON(NameData)
    
    data = jsondecode(fileread("Data/" + NameData + ".json"));
    
    TitleLocality = data.name; 
    if isfield(data, "Cut")
        Cut = data.Cut;
    else
        Cut = [];
    end
    
    ydata(1,:) = data.ActCasos';
    ydata(2,:) = data.Muertes';
    ydata(3,:) = data.Recuperados';
    Population = data.Poblacion;
    
    if isfield(data, "x0")
        New = 0;        
    else
        New = 1;
    end
    
end
