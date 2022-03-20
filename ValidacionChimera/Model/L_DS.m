function [M, Mj, Mgamma] = L_DS(dgamma, theta, lambda, alpha)
    N = length(dgamma) * 2;
    M = zeros(N);
    Mj = M;
    Mgamma = M;

    for i = 1 : N/2 - 1
        M([2 * i - 1, 2 * i], [i * 2 + 1, i * 2 + 2]) = [1 - lambda lambda; alpha 1 - alpha] * (1 - dgamma(i));
        Mj([2 * i - 1, 2 * i], [i * 2 + 1, i * 2 + 2]) = [1 0; 0 1] * (1 - dgamma(i));
        Mgamma([2 * i - 1, 2 * i], [i * 2 + 1, i * 2 + 2]) = [0 1; 1 0] * dgamma(i);
    end
    M = M * (1 - theta);
    Mj = Mj * theta;
end