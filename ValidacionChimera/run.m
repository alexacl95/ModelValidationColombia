%Update localities
main

%Update json files
addpath Tool	
addpath Model
addpath Data 
addpath ValidationFunctions

opts = detectImportOptions('../localidades.csv');
opts = setvartype(opts, 1, 'string');

dataLocal = readtable('../localidades.csv', opts);
ListData = ["co";"Cafeteros"];	    
ListData = [ListData; dataLocal{:,1}];

for i = 1:length(ListData)
    NameData = ListData(i)
    load("Informs/" + NameData + "Inform.mat")
    TSaveJSON = InformContainer{1}.TSaveJSON;
    Inform = InformContainer{end};
    WriteDataJSON(NameData, TSaveJSON, Inform)
end
