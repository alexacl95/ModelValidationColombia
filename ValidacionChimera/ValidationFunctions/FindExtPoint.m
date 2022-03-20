function [ydata, Cut] = FindExtPoint(ydata, MinDist, MaxPoints, show)

    %[TF,S1,S2]
    [TF,~,~] = ischange(ydata(1,:),'linear','MaxNumChanges',MaxPoints);
    ipt2 = find(TF==1);
    rlon = length(ydata(1,:));
    flag = true;
    
    while flag
        for i=1:length(ipt2)-1
            reg = ipt2(i+1) - ipt2(i);
            if reg<MinDist
                ipt2(i+1) = [];
                break
            end
            if i==length(ipt2)-1
                flag = false;
            end
        end
    end
    
    if show
        clf
        %segline = S1.*(1:length(ydata(1,:))) + S2;
        plot(ydata(1,:))
        hold on
        for i=1:length(ipt2)
            xline(ipt2(i))
        end
    end
    Cut = [ipt2,rlon];
    if Cut(end)-Cut(end-1)<10
        Cut(end)=[];
        try
            ydata(:,ipt2(end)+1:end)=[];
        catch
            disp('Last cut is the last position')
        end
    end
end