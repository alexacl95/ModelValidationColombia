function T2 = gsua_dia(T,T_est,outlier)

if nargin <3
    outlier=false;
end
Fixed = T.Properties.CustomProperties.Fixed;
npars = size(T,1);
ind = zeros(npars,1);
if isempty(Fixed)
    Fixed = false(1,npars);
end
if outlier
    disp('Removing outliers...')
    [~,~,RD,chi_crt]=DetectMultVarOutliers(T_est');
    id_in=RD<chi_crt(4);
    T_est=T_est(:,id_in);
    disp(num2str(sum(id_in))+" outliers were removed")
end

T.Est=T_est;
T.Nominal=T.Est(:,1);
T2 = T;
try
    T(Fixed,:)=[];
catch
end

Normalized=zeros(size(T,1),size(T.Est,2));
for i=1:size(T,1)
    Normalized(i,:)=(T.Est(i,:)-T.Range(i,1))/(T.Range(i,2)-T.Range(i,1));
end

RHO = corr(T.Est');

x=T.Est;
med=median(x,2);
N=size(x,2);
desv=std(x,[],2);

lb = med-1.96*sqrt(pi/2)*desv/sqrt(N);
up = med+1.96*sqrt(pi/2)*desv/sqrt(N);

if (any(lb(lb<T.Range(:,1))))||(any(up(up>T.Range(:,2))))
    lb(lb<T.Range(:,1))= T.Range(lb<T.Range(:,1),1);
    up(up>T.Range(:,2))= T.Range(up>T.Range(:,2),2);   
end



boxin=(up-lb)./(T.Range(:,2)-T.Range(:,1));
len=length(boxin);
corrin=nansum(abs(RHO))/len;
extrin=sum(abs(RHO)>0.5)/len;
ind(~Fixed)=(2*boxin'+corrin+extrin)/4;

try
T2.Range(~Fixed,:)=[lb,up];
T2.index=ind;
T2.Nominal(~Fixed)=med;
catch
end
try
T2.Range(Fixed,:)=[T2.Est(Fixed,1),T2.Est(Fixed,1)];
T2.Nominal(Fixed)=T2.Est(Fixed,1);
catch 
end


end