function Inform = vc_structCreate(T,N,max1,max2,New,xdata,ydata,NameData)

    Inform = struct();
    Inform.failure = false;
    Inform.val = zeros(1, 2);
    T = rmprop(T,'Solver');
    
    Inform.T = T;
    Inform.residual = [];
    Inform.index = [];
    Inform.estimations = [];
    Inform.N = N;
    Inform.nestim = 0;
    Inform.maxestim1 = max1;
    Inform.maxestim2 = max2;
    Inform.New = New;
    Inform.xdata = xdata;
    Inform.local = NameData;
    Inform.ydata = ydata;

    names = {'\lambda_{fq}', '\vartheta_E', '\gamma_L', '\lambda_{qf}',...
        '\vartheta_P', '\gamma_H', 'z', '\eta_\vartheta', '\mu', '\nu'};

    npar = size(T, 1);
    lnames = length(names);
    
    Inform.flimit = npar - lnames;
    Inform.fixutil = table(T.Range);
    Inform.fixutil.Properties.RowNames = T.Properties.RowNames;
    Inform.fixutil.Properties.VariableNames = {'Range'};
    Inform.fixutil.fixing = zeros(npar, 1);
    Inform.fixutil.fixable = ones(npar, 1);
    Inform.fixutil{names, 'fixable'}=0;

    names = Inform.fixutil.Properties.RowNames;
    existence = sum(strcmp('BP', names));
    
    if existence == 1
        Inform.fixutil{'BP', 'fixable'} = 0;
    end

end