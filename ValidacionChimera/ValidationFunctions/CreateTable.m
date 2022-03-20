function [T, xdata, AuxTable] = CreateTable(ydata, Population)

    VarNames = {'N_0', 'E^2_0', 'P_0', 'J_1', 'J_{L}', 'D', 'R_j', 'RJ_L'};

    OutNames = {'S_f', 'S_q', 'E_f', 'E_q', 'L_f','L_q','H_f','H_q','J','D',...
                'R','T','RJH','RJL','RJ','Tot','JH','JL','J_{~P}','J_{P}'};

    ParNames = {'\beta_L','\beta_T', '\beta_P', '\phi_{EP}', ...
              '\lambda_{fq}', '\vartheta_E', '\gamma_L', 'k_L', ...
              'k_P', '\phi_T', '\lambda_{qf}', '\psi_e', '\phi_{PH}', ...
              '\delta', 'm', '\eta_L', '\vartheta_P', '\gamma_H', 'z', ...
              '\phi_{PL}', '\eta_\vartheta', 'nons', 'a_L', 'b_L', ...
              'a_\mu', 'b_\mu', '\mu', 'a_H', 'b_H', '\nu', 'lon'};

    FullNames = [VarNames, ParNames];

    ModelName = 'ChimeraModel';

    Range1 = [
            Population Population;    % N_0
            0 2000;                   % E^2_0
            0 400;                    % P_0
            ydata(1, 1) ydata(1, 1);  % J_1
            0 0;                      % J_L
            ydata(2, 1) ydata(2, 1);  % D
            ydata(3, 1) ydata(3, 1);  % R_j
            0 0;                      % RJ_L
            ];

    Range2=[
            0.7849 0.7849;  % beta_L
            0.028 0.028;    % beta_T          
            0.297 0.297;    % beta_P
            0.13 0.13;      % phi_{EP}
            0	1;          % lambda_{fq}
            0	1;          % vartheta_E
            0   1;          % gamma_L
            1   10;         % k_L
            1   1;          % k_P
            4.4 4.4;        % phi_T
            0	1;          % lambda_{qf}
            0	0;          % psi_e
            1.4 1.4;        % phi_{PH}
            0   0.15;       % delta
            0   0;          % Migration input
            0   1;          % eta_L
            0   1;          % vartheta_P
            0   1;          % gamma_H 
            0   30;         % z 
            0.69 0.69;      % phi_{PL}
            0   1;          % eta_vartheta
            0   0;          % nons
            1   15;         % a_L
            1   15;         % b_L
            1   15;         % a_mu
            1   15;         % b_mu
            0   1;          % mu
            1   15;         % a_H
            1   15;         % b_H
            0  500;         % nu
            41  41          % lon
            ];
        
    RangeT = [Range1; Range2];

    D = length(ydata(1, : ));
    Domain = [0 D - 1];
    xdata = 0 : D - 1;
    
    RangeTAux = [RangeT; 0 0; 0 0];
    auxNominal = (RangeTAux(:,1) + RangeTAux(:,2))/2;
    AuxTable = table(auxNominal);
    extNames = {'BP','reg'};
    AuxTable.Properties.RowNames = [FullNames,extNames];

    [T, ~] = gsua_dataprep(ModelName, RangeT, 'domain', Domain, 'names', FullNames, 'out_names', OutNames);
    T.Properties.CustomProperties.output = [9, 10, 15];
    
end