function cos=gsua_rcostf(ydata,yfunction,margin)
if nargin<3
    margin=1.1;
end

margin=abs(margin);

if margin<1
    margin=margin+1;
end

[inputs,lon] = size(ydata);
regulator=sum((ydata-ydata*margin).^2,2)/lon;
cost=(sum((ydata-yfunction).^2,2)/lon)./regulator;

for i=1:inputs
    cost(i)=((2-corr2(ydata(i,:),yfunction(i,:)))*cost(i))^2;
end
cos=sum(cost)/inputs;
end