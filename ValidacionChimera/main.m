function main()

    clear all

    addpath Tool
    addpath Model
    addpath Data 
    addpath ValidationFunctions
    opts = detectImportOptions('../localidades.csv');
    opts = setvartype(opts, 1, 'string');
    dataLocal = readtable('../localidades.csv', opts);
    ListData = ["co";"Cafeteros"];	    
    ListData = [ListData; dataLocal{:,1}];
    

    for localityIndex = 1 : length(ListData)
        
        NameData = ListData(localityIndex);
	
	disp(NameData)	

        [ydata, Population, Cut, New, TitleLocality] = ReadDataJSON(NameData);        

         N = 1000;   % Number of estimations
        max1 = 5000;% maximum number of estimations before fixing
        max2 = 3000;% maximum number of estimations after fixing
        t1 = 60;   % minimum number of estimations threshold1
        t2 = 0.9;   % minimum number of curves threshold2

        opt = 'best';
        parallel = true;
%        nworkers = 8;
         nworkers = str2double(getenv('SLURM_NTASKS'));

         if New == 1 %check if it is a new locality  

            if isempty(Cut)

                MinDist = 20;
                MaxPoints = 10;
                [ydata, Cut] = FindExtPoint(ydata, MinDist, MaxPoints, false);

            end

            extpoint = zeros(length(Cut), 2);
            extpoint(1, :) = [1, Cut(1)];

            for i = 2 : length(Cut) 
                extpoint(i,:) = [Cut(i - 1), Cut(i)];
            end 

            NumberExtensionPoint = length(Cut);
            InformContainer = cell(1, NumberExtensionPoint);
            [T, xdata, TSaveJSON] = CreateTable(ydata, Population);
            Inform = vc_structCreate(T, N, max1, max2, New, xdata, ydata, TitleLocality);%create inform struct
            Inform.Cut = [1, Cut(1)];

            %Parameter estimation for first timeseries piece
            while sum(Inform.val) < 2 && ~Inform.failure

                if parallel
                    delete(gcp('nocreate'));
                    parpool(nworkers);
                end
                [T2, Residual] = FirstEstimation(T, N, Cut(1), ydata, xdata, Inform, parallel);
                Inform = vc_structChange(Inform, Residual, T2.Est);
                Inform = vc_validation(Inform, T2, t1, t2, opt, parallel,true);%Validation()
                clear T2;
                save('InformProgress.mat','Inform')

            end 
            disp("Finished: first section")
            Inform.TSaveJSON = TSaveJSON;
            InformContainer{1} = Inform;

            %Parameter estimation for several timeseries pieces as extensions
            if NumberExtensionPoint > 1
%                  T = Inform.T;
                 T = addprop(T, 'CutAux', "table");
                 for i = 2 : NumberExtensionPoint 

                     T.Properties.CustomProperties.CutAux = Cut(i - 1);
                     [T, ydataCut, xdata] = ExtEstimation(T, [extpoint(i - 1, 1), extpoint(i, 2)], i, Cut(i), ydata, Inform);
                     Inform = vc_structCreate(T, N, max1, max2, New, xdata, ydata, NameData);%create inform struct
                     Inform.Cut = Cut(i - 1 : i);

                     T = addprop(T , 'CutAux', "table");

                     while sum(Inform.val) < 2 && ~Inform.failure

                         if parallel
                            delete(gcp('nocreate'));
                            parpool(nworkers);
                         end

                        T.Properties.CustomProperties.CutAux = Cut(i - 1);                  

                        [T2, Residual] = MainEstimations(T, N, ydataCut, xdata, Inform, true, parallel);
                        Inform = vc_structChange(Inform, Residual, T2.Est);
                        Inform = vc_validation(Inform, T2, t1, t2, opt, parallel, true);
                        clear T2;
                        save('InformProgress.mat','Inform')

                     end
                      disp("Finished: " + i + " section")
                      InformContainer{i} = Inform;        

                end
            end   

%             WriteDataJSON(NameData, TSaveJSON, Inform);

            T.Nominal = Inform.Nominal;
            gsua_save(T)
            movefile("portable.mat", "Parameters/" + NameData + "Params.mat");

            save("Informs/" + NameData + "Inform", 'InformContainer','ydata')

         elseif New == 0

             disp("Update?")

             load("Parameters/" + NameData + "Params.mat",'T')
             load("Informs/" + NameData + "Inform.mat",'InformContainer')
%              T = gsua_load(T);
                 
             
             %InformContainer(end) = []; %%ESTO SOLO PARA LOCALIDADES MALAS (COLOMBIA, MEDELLIN y RESTO DE ANT)
             ydataOld = InformContainer{end}.ydata;
             ydataOld = [ydataOld, ydata(:,length(ydataOld):length(ydata))];
             ydata = ydataOld;
        
             % Check if it necessary to update the locality
            
             T = InformContainer{end}.T;
             T = gsua_load(T);
             T.Nominal = InformContainer{end}.Nominal;
             
             try
                 T = addprop(T, 'CutAux', "table");
                catch
             end
                          
             T.Properties.CustomProperties.output = [9, 10, 15];
             CutFinal = length(ydata);
             
             T.Properties.CustomProperties.Domain(2) = length(ydata) - 1;
             [UpgradeLocality, ~] = CheckingUpgrade(ydata, T, 1.03);
                
             %Recover Cut from informs
             Cut = RecoverCut(NameData); 

             if UpgradeLocality == 1

                disp("Updating")
                                
                T.Properties.CustomProperties.CutAux = Cut(end);               
                             
                extpointFinal = [Cut(end - 1), CutFinal - 10];
                [T, ydataCut,xdata] = ExtEstimation(T, extpointFinal, 3, CutFinal, ydata, InformContainer{end});

                Inform = vc_structCreate(T, N, max1, max2, New, xdata, ydata, NameData);%create inform struct
                Inform.Cut = sort([Cut(end), CutFinal]);

                while sum(Inform.val) < 2 && ~Inform.failure

                    if parallel

                        delete(gcp('nocreate'));
                        parpool(nworkers);

                    end

                    [T2, Residual] = MainEstimations(T, N, ydataCut, xdata,Inform, 3, parallel);
                    Inform = vc_structChange(Inform, Residual, T2.Est);
                    Inform = vc_validation(Inform, T2, t1, t2, opt, parallel, true);%Validation()
                    clear T2;
                    save('InformProgress.mat','Inform')

                end    

                T.Nominal = Inform.Nominal; 
                gsua_save(T)
                movefile("portable.mat", "Parameters/" + NameData + "Params.mat"); 

                TSaveJSON = InformContainer{1}.TSaveJSON;  
                InformContainer{end + 1} = Inform;

%                 WriteDataJSON(NameData, TSaveJSON, Inform);

                save("Informs/" + NameData + "Inform", 'InformContainer', 'ydata')

             else
                
                save("Informs/" + NameData + "Inform", 'InformContainer','ydata')

                Inform = vc_structCreate(T, N, max1, max2, New, 1:length(ydata), ydata, NameData);%create inform struct
                Inform.Cut = [Cut(end), CutFinal];
                TSaveJSON = InformContainer{1}.TSaveJSON;
                Inform.Nominal = InformContainer{end}.Nominal;
%                 WriteDataJSON(NameData, TSaveJSON, Inform); 

             end

         else
             disp("Error: must be 0 or 1")
         end

         delete(gcp('nocreate'));
         WriteDataJSON(NameData, TSaveJSON, Inform);
    end
    
    
end
