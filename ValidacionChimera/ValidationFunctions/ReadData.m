function [ydata, Population, extpoint, Cut, New] = ReadData(NameData)
    
    load("Data/" + NameData);         %timeSeries
    load("Data/" + NameData + "Info");%BreakPoint + Population
    
    Extension = length(Cases);
    
    ydata = zeros(3,Extension);    
    ydata(1,:) = Cases';
    ydata(2,:) = Dead';
    ydata(3,:) = Recovered';
    
end
