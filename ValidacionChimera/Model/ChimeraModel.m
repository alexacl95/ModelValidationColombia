function sol = ChimeraModel(params,domain,ins)

    domain = domain(2);         % Simulation domain
    M = zeros(23, domain + 1);  % Simulation matriz
   
    %Configurable initial conditions
    M(4,1) = params(2,:);       % E_3
    M(14,1) = params(4,:);      % J_1
    M(16,1) = params(5,:);      % J_L
    M(17,1) = params(6,:);      % D
    M(20,1) = params(7,:);      % R_j
    M(21,1) = params(8,:);      % RJ_L
  
    %Parameters
    beta_L = params(9,:);       % beta_L
    beta_T = params(10,:);      % beta_T 
    beta_P = params(11,:);      % beta_P
    phi_EP = params(12,:);      % phi_{EP}
    lambda_fq = params(13,:);   % lambda_fq_{fq}
    vartheta_E = params(14,:);  % varvartheta_E_E
    gamma_L = params(15,:);     % gamma_L_L
    k_L  = params(16,:);        % k_L
    k_P  = params(17,:);        % k_P
    phi_T   = params(18,:);     % phi_T
    lambda_qf = params(19,:);   % lambda_{qf}
    psi_e = params(20,:);       % psi_e
    phi_PH = params(21,:);      % phi_{PH}
    delta = params(22,:);       % delta
    
    %Inputs
    m = params(23,:);           %Number of inmigrants
    
    %Modifying parameters
    eta_L = params(24,:);       % eta_L
    vartheta_P = params(25,:);  % vartheta_P
    eta = params(26,:);         % gamma_H
    z = params(27,:);           % z
    phi_PL = params(28,:);      % phi_{PL}
    eta_vartheta = params(29,:);% eta_vartheta
    nons = params(30,:);        % initial proportion of inmune population
    
    %Difussion system parameters
    a_L = params(31,:);         % a_L
    b_L = params(32,:);         % b_L
    a_mu = params(33,:);        % a_mu
    b_mu = params(34,:);        % b_mu
    mu = params(35,:);          % mu
    a_H = params(36,:);         % a_H
    b_H = params(37,:);         % b_H
    nu = params(38,:);          % nu
    lon = round(params(39,:));  % time
    
    lambda_H = lambda_fq^eta_L;
    alpha_H = lambda_qf^(1/eta_L);
    vartheta_E_L = vartheta_P;
    vartheta_E_H = vartheta_E_L^eta_vartheta;

    %Parameters for building the difussion matrices
    dgamma_L = distri_est(a_L, b_L, lon);
    dmu = distri_mu(a_mu, b_mu, lon);
    dgamma_L2 = distri_est(a_H, b_H, lon);
    dgamma_L = dgamma_L * gamma_L;
    dgamma_L2 = dgamma_L2 * eta;
    dmu = dmu * mu;
    len = length(dgamma_L);
    
    [ML, ML_j, ML_gamma_L] = L_DS(dgamma_L, vartheta_E_H, lambda_H, alpha_H);
    [MJL, MJL_gamma_L] = JL_DS(dgamma_L);
    [MJH, MJH_mu, MJH_gamma_L] = JH_DS(dmu, dgamma_L2);

    L = zeros(domain + 1, len * 2);
    JH = zeros(domain + 1, len);
    JL = JH;
    
    JH(1) = params(4,:);    
    JL(1) = params(5,:);
         
    M(1, 1) = params(1,:) * (1 - nons);      % N_0
    M(9, 1) = params(3,:) * delta;           % A1
    M(11, 1) = params(3,:) * (1 - delta);    % A1
    
    M(18, 1) = params(1,:) * nons + params(7,:) + params(8,:); % Recovered or inmune initial population
    k_L = k_P * k_L;
    M(19, 1) = sum(M([9, 11], 1)) * k_P + M(7, 1) * k_L;       % T
    C = sum(M(1:18, 1)) * k_L;                                % Max virus concentration

    
    %% Starting the model simulation cycle
    for i=1:domain
       
        % Population definition    
        E_f = sum(M(3:4, i));                           % Free exposed
        H_f = M(7, i);                                  % Free infected
        L_f = sum(M([9,11], i));                        % asintomaticos libres
        N_f = M(1, i) + E_f + H_f + L_f + M(18, i);     % Total population in free circulation
        N_q = sum(M([2,5:6,8,10,12,13:16,22:23], i));   % Total population in quarantine 
        N_t = N_f + N_q;                                % Total population    
        
        % Contact probabilities definition
        tota = sum(M(7:16, i));
        aleph = 1 + nu*tota/(M(1, i) + tota);
        if M(1, i) > 1
            red = (M(1, i)/N_t)^aleph;
            PA = z * L_f * red;
            PI = H_f * red * z;
            
            % Probability of infection with pre-symptomatic individuals
            probL = 1 - ((M(1, i) - 1)/M(1, i))^PA;     % 
            % Probability of infection with symptomatic individuals
            probH = 1 - ((M(1, i) - 1)/M(1, i))^PI;
        else
            probL = 0;
            probH = 0;
        end
        
        % Probability of infection with the environmental repository
        Phi_T = min(((M(19, i)/C)^aleph), 1);
      
        % Susceptible population in free circulation
        M(1, i + 1) = (1 - psi_e) * m + lambda_qf * M(2, i) + (1 - beta_P * probL) *...
                   (1 - beta_L * probH) * (1 - Phi_T * beta_T) *...
                   (1 - lambda_fq) * M(1, i);                               % S_f
               
        % Susceptible population in quarantine
        M(2, i + 1) = (1 - (beta_P) * probL) * (1 - beta_L * probH) * (1 - Phi_T * beta_T) *...
                    (lambda_fq) * M(1, i) + (1 - lambda_qf) * M(2, i);      % S_q            
               
        % Exposed population in free circulation
        M(3, i + 1) = (beta_P * probL + (1 - (beta_P * probL)) * (beta_L * probH)...
                    + (1 - (beta_P * probL)) * (1 - (beta_L * probH)) *...
                    Phi_T * beta_T) * (1 - lambda_fq) * M(1, i);            % E_f^1

        M(4, i + 1) =  psi_e * m + lambda_qf * M(5, i) + (1 - lambda_fq) * M(3, i)...
                     + exp( - phi_EP) * ((lambda_qf) * M(6, i) + ...
                     (1 - lambda_fq) * M(4,i));                             % E_f^2
        
        %Exposed in quarantine
        M(5, i + 1) = (beta_P * probL + (1 - (beta_P * probL)) * (beta_L * probH)...
                    + (1 - (beta_P * probL)) * (1 - (beta_L * probH)) * ...
                    Phi_T * beta_T) * (lambda_fq) * M(1, i);                %E_q^1
                        
        M(6, i + 1) = (1 - lambda_qf)* M(5, i) + (lambda_fq) * M(3, i) +...
                  exp(-phi_EP) * ((1 - lambda_qf) * M(6, i) + ...
                  (lambda_fq) * M(4, i));                                   %E_q^2
        
        % Low symptomatic population (Presymptomatic + Symptomatic)
        M(11, i + 1) = (1 - delta) * (1 - vartheta_E) * (1 - exp( - phi_EP)) * ((1 - lambda_fq) * M(4, i)...
                    + (lambda_qf) * M(6, i)) + (1-vartheta_E_L) * (exp( - phi_PL))...
                    * ((1 - lambda_fq) * M(11, i) + lambda_qf * M(12, i)); %A1
        
        M(12, i + 1) = (1 - delta) * (1 - vartheta_E) * (1 - exp( - phi_EP)) * ((lambda_fq) * M(4, i)...
            + (1 - lambda_qf) * M(6, i)) + (1 - vartheta_E_L) * (exp( - phi_PL)) * (lambda_fq * M(11, i)...
            + (1 - lambda_qf) * M(12, i));%QA_1       
        
        % Identified Low symptomatic population (as difussion system)
        L_gamma_L = sum(L(i,:) * ML_gamma_L) + sum(L(i,end-1: end));      
        L_j = L(i,:) * ML_j;
        L_j = L_j(1:2:end) + L_j(2:2:end);
        L(i+1,:) = L(i,:) * ML;
        L(i+1,1:2) = [(1 - lambda_fq) * M(11, i) + lambda_qf * M(12, i), lambda_fq * M(11, i)...
            + (1 - lambda_qf) * M(12, i)] * (1 - vartheta_E_L) * (1 - exp( - phi_PL));
        
        M(7, i + 1) = sum(L(i+1,1:2:end));
        
        M(8, i + 1) = sum(L(i+1,2:2:end));
            
        % High symptomatic population (Presymptomatic + Symptomatic)
        M(9, i + 1) = delta * (1 - vartheta_E) * (1 - exp( - phi_EP)) * ((1 - lambda_fq) * M(4, i)...
            + (lambda_qf) * M(6, i)) + (1 - vartheta_E_L) * (exp( - phi_PH)) * ((1 - lambda_fq) * M(9, i)...
            + lambda_qf * M(10, i)); %I1
        
        M(10, i + 1) = delta * (1 - vartheta_E) * (1 - exp( - phi_EP)) * ((lambda_fq) * M(4, i) + (1 - lambda_qf)...
            * M(6,i)) + (1 - vartheta_E_L) * (exp( - phi_PH)) * (lambda_fq * M(9, i) + (1 - lambda_qf) * M(10, i));%QI1

        %Detecciones JH  
        M(13, i + 1) = vartheta_E_L * (exp( - phi_PH)) * (M(9, i) + M(10, i)) + M(13, i) * exp( - phi_PH);%JI_1
        
        M(22, i + 1) = (M(6, i) + M(4, i)) * vartheta_E * (1 - exp( - phi_EP)) * delta + M(22, i) * exp( - phi_PH);
        
        JI_gamma_L = sum(JH(i,:) * MJH_gamma_L);
        JI_mu = sum(JH(i,:) * MJH_mu) + JH(i,end);
        JH(i+1,:) = JH(i,:) * MJH;
        JH(i+1,1) = (M(13, i) + M(22, i)) * (1 - exp( - phi_PH)) + (1 - exp( - phi_PH)) * (M(9, i) + M(10, i));%J2
        
        M(14, i + 1) = sum(JH(i+1,:));%JI_2 en adelante
        
        %Detecciones de JL
        M(15, i + 1) = vartheta_E_L * (exp( - phi_PL)) * (M(11, i) + M(12, i)) + M(15, i) * exp( - phi_PL);%JA_1
        
        M(23, i + 1) = (M(6, i) + M(4, i)) * vartheta_E * (1 - exp( - phi_EP)) * (1 - delta) + M(23, i) * exp( - phi_PL);
        
        JA_gamma_L = sum(JL(i,:) * MJL_gamma_L) + JL(i,end);
        JL(i+1,:) = JL(i,:) * MJL;
        JL(i+1,1) = (M(15, i) + M(23, i)) * (1 - exp( - phi_PL)) + vartheta_E_L * (1 - exp( - phi_PL)) * (M(11, i) + M(12, i));%%J_A2
        JL(i+1,:) = JL(i+1,:) + L_j;
        
        M(16, i + 1) = sum(JL(i+1,:));%JA_2 en adelante
        
        %D, R y V
        M(17, i + 1) = M(17, i) + JI_mu;%D
        M(18, i + 1) = M(18, i) + JA_gamma_L + JI_gamma_L + L_gamma_L; %R
        
        M(19,i+1) = (1 - min(M(19, i)/C, 1)) * ( k_L * H_f + k_P * L_f)...
                    + exp(-phi_T) * M(19, i); %T  
        M(20, i + 1) = M(20, i) + JI_gamma_L; %RI_j
        M(21, i + 1) = M(21, i) + JA_gamma_L; %RA_j

    end
        
    
    outs = [M(1:2,:); sum(M([3, 4],:)); sum(M([5, 6],:)); sum(M([9, 11],:)); sum(M([10, 12],:));...
            M(7:8,:); sum(M([13:16, 22:23],:)); M(17:21,:); sum(M([20, 21],:)); sum(M([7:16, 22:23],:));...
            M(14,:); sum(M([13, 15:16, 22:23],:)); sum(M(13:16,:)); sum(M(22:23,:))];
    
    sol = struct();
    sol.x = 0:domain;
    sol.y = outs;    
    
    if ins.action == 2
        nom=params(9:end,:);
        out_names=ins.out_names;
        model='ChimeraExtension';
        if isfield(ins,'domain')
            dom=ins.domain;
        else
            dom=[domain+1 domain*2];
        end
        pr=ins.range;
        nom(end+1,:)=(pr(end,1)+pr(end,2))/2;
        ins.M=M;
        ins.action=1;
        ins.L=L;
        ins.JL=JL;
        ins.JH=JH;
        if sum(M(1:2, end)) < M(1, 1) * 0.1
            pr = [pr; 0 0.25];
            nom(end+1,:) = (pr(end, 1) + pr(end, 2))/2;
            ins.rnames{end+1}='reg';
        else
            pr = [pr;0 0];
            nom(end+1,:)=0;
        end
        [T,~]=gsua_dataprep(model,pr,'domain',dom,'out_names',out_names,'nominal',nom,'opt',ins);
        T.Properties.RowNames = ins.rnames;
        save('nextTable.mat','T');
    end
end