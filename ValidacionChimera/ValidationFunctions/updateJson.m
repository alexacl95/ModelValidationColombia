addpath Tool	
addpath Model
addpath Data 
addpath ValidationFunctions

opts = detectImportOptions('../localidades.csv');
opts = setvartype(opts, 1, 'string');

dataLocal = readtable('../localidades.csv', opts);
ListData = dataLocal{:,1};
ListData(end+1:end+2) = ["co";"Cafeteros"]

for i = 1:length(ListData)
    NameData = ListData(i)
    load("Informs/" + NameData + "Inform.mat")
    TSaveJSON = InformContainer{1}.TSaveJSON;
    Inform = InformContainer{end};
    WriteDataJSON(NameData, TSaveJSON, Inform)
end
