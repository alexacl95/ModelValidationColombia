function ysim2 = simulateScnarios(T, Nominal1, Nominal2, D, ydata)
    xdata = 0 : D - 1;  
    xdata2 = 0 : length(ydata)-1; 
    
    T.Properties.CustomProperties.output = [9, 10, 15]; 
    T.Properties.CustomProperties.Domain = [0, length(ydata)-1];
    
    y = gsua_deval(T.Nominal',T,0:length(ydata)-1);
    T.Nominal(end) = Nominal1(end,end);    
    
    opt = T.Properties.CustomProperties.copt;
         
    % Create extension for saving difussion systems
    Range2 = T.Properties.CustomProperties.creator.Range(1:end,:);
    opt.rnames = T.Properties.RowNames;
            
    opt.out_names = T.Properties.CustomProperties.Vars;
    opt.range = Range2;    
    opt.action = 2;
    opt.domain = [0 D-1];
    T.Properties.CustomProperties.copt = opt;
    T.Properties.CustomProperties.Domain = [0 D-1];
    T.Properties.CustomProperties.output = [9, 10, 15]; 
          
    gsua_deval(T.Nominal', T, xdata);
    copyfile nextTable.mat nextTableOriginal.mat    
    load("nextTable.mat", 'T')
        
    if  any(strcmp("reg", T.Properties.RowNames))
        T{'reg', 'Nominal'} = 0;
    end
              
    T.Properties.CustomProperties.output = [9, 10, 15]; 
    
    n = length(Nominal1);

    ysim2 = zeros(n,3,xdata2(end)+1);

    for i = 1:n
        
        load("nextTableOriginal.mat", 'T')
        opt = T.Properties.CustomProperties.copt;     
        % Create extension for saving difussion systems
        Range2 = T.Properties.CustomProperties.creator.Range(1:end,:);
        opt.rnames = T.Properties.RowNames;            
        opt.out_names = T.Properties.CustomProperties.Vars;
        opt.range = Range2;    
        opt.action = 2;
        opt.domain = [0 D-1];
        T.Properties.CustomProperties.copt = opt;
        T.Properties.CustomProperties.output = [9, 10, 15]; 
        evalc('gsua_deval(Nominal1(:,i), T, xdata)');
    
        load("nextTable.mat", 'T')
        T.Properties.CustomProperties.Domain = [0 length(xdata2)-1];
        T.Properties.CustomProperties.output = [9, 10, 15]; 
        evalc('ysim2(i,:,:) = gsua_deval(Nominal2(:,i), T, xdata2)');
    end 


    d1 = datetime('06/03/2020','InputFormat','dd/MM/uuuu');
    days = d1:1:d1+length(ydata)-1;
    Names = ["Active cases", "Dead", "Recovered"];

    close all
    figure
    for i = 1:3
        subplot(3,1,i)
        hold on
        grid on
        plot(days, squeeze(ysim2(:,i,:))','color', [.5 .5 .5],'LineWidth',1)
        plot(days, y(i,:),'r','LineWidth',1.5)
        plot(days, ydata(i,:),'--k','LineWidth',1.5)
        if i<3
            set(gca,'XColor', 'none','XColor','none')
        end
        xlim([d1 d1+length(ydata)-1])
        xline(600,'--','color',[0 0.4470 0.7410],'LineWidth',1.5)
        ylabel(Names(i),'fontweight','bold')
    end
    export_fig MonteCarlo.png -transparent -m3
end
