function Cut = RecoverCut(NameData)    

    %Recover Cut from last inform
    load("Informs/" + NameData + "Inform.mat", "InformContainer")
    Cut = InformContainer{end}.Cut;
    
%     %Overwrite the json file
%     jsonText = fileread(NameData + '.json');
%     % Convert JSON formatted text to MATLAB data types
%     jsonData = jsondecode(jsonText);     
%     
%     jsonData.Cut = Cut;
%     
%     jsonText2 = jsonencode(jsonData);
%     fid = fopen('Data/' + NameData + '.json', 'w');
%     fprintf(fid, '%s', jsonText2);
%     fclose(fid);        
    
end