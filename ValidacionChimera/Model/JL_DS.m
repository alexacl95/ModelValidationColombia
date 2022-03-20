function [M, Mgamma] = JL_DS(dgamma)
    %Diffusion subsystem for JI
    %In is the input vector
    N = length(dgamma);
    M = zeros(N);
    Mgamma = M;

    for i= 1:N - 1
        Mgamma(i, i + 1) = dgamma(i);
        M(i, i + 1) = 1;
    end
    M = M - Mgamma;
end