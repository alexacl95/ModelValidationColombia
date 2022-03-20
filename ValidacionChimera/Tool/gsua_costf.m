function cos=gsua_costf(inputs,regulator,len,ydata,yfunction)
cost=(sum((ydata-yfunction).^2,2)/len)./regulator;
for i=1:inputs
    auxcost=((2-corr2(ydata(i,:),yfunction(i,:)))*cost(i))^2;
    if isnan(auxcost)
        cost(i)=cost(i)^2;
    else
        cost(i)=auxcost;
    end
end
cos=sum(cost)/inputs;
end