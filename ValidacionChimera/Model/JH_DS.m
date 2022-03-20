function [M,Mmu,Mgamma]=JH_DS(dmu,dgamma)
    %Diffusion subsystem for JI
    %In is the input vector
    N = length(dgamma);
    M = zeros(N);
    Mmu = M;
    Mgamma = M;

    for i = 1:N - 1
        Mmu(i, i + 1) = dmu(i);
        Mgamma(i, i + 1) = (1 - dmu(i)) * dgamma(i);
        M(i, i + 1) = 1;
    end
    M = M -(Mmu + Mgamma);

end