addpath Tool
addpath Model
addpath Data 
addpath ValidationFunctions

opts = detectImportOptions('../localidades.csv');
opts = setvartype(opts, 1, 'string');
dataLocal = readtable('../localidades.csv', opts);
ListData = "co";          
Localities = [ListData; dataLocal{:,1}];

for i = 1: length(Localities)
    vc_report_english(Localities(i))
end