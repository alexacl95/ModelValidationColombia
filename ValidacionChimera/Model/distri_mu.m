function [y1]=distri_mu(A,B,len)
    x = linspace(0, 1, len);
    y1 = betapdf(x, A, B);%dist
    y1 = normalize(y1, 'range', [0 1]);
end