function [forecast,obs,timeFinal,titleNames]=...
    sgfun_driftMeehl(varYearly,varYearlyOBS,varYearlyCLIM,...
    time,timeOBS,timeCLIM,lead,lon,lat,leadStart,leadEnd,leadMid)
    % Created August 27, 2022
    % Input:
    % varYearly(lon,lat,lead,time)
    % varYearlyOBS(lon,lat,timeOBS)
    % varyearlyCLIM(lon,lat,timeCLIM)
    % leadStart=3 (for example)
    % leadEnd=7 (for example)
    % leadMid=5 (for example)
    
    eqCheck=isequaln(varYearly,varYearlyCLIM);
    if eqCheck==1
        clear varYearlyCLIM timeCLIM
%         disp('CLIM = forecast itself');
        firstLeadYear=nanmin(nanmin(lead));
        lastLeadYear=nanmax(nanmax(lead));
        timeCLIM=firstLeadYear:lastLeadYear;
        for i=1:length(timeCLIM)
            [a,b]=find(lead==timeCLIM(i),1);
            varYearlyCLIM(:,:,i)=varYearly(:,:,b,a);
        end
    end

    nlon=length(lon);
    nlat=length(lat);
    ntime=length(time);
    
    drift=nanmean(nanmean(varYearly,3),4)-nanmean(varYearlyOBS,3); 
    BC=varYearly-drift;
    persist_obs=NaN(nlon,nlat,ntime);
    BC_15yr_obs=NaN(nlon,nlat,ntime);
    anom_15yr_obs=NaN(nlon,nlat,ntime);
    anom_clim_obs=NaN(nlon,nlat,ntime);
    persist_model=NaN(nlon,nlat,ntime);
    BC_15yr_model=NaN(nlon,nlat,ntime);
    anom_15yr_model=NaN(nlon,nlat,ntime);
    anom_clim_model=NaN(nlon,nlat,ntime);

    % -------------------------- CALCULATION --------------------------
    for init=1:length(time) 
        initOBS=find(timeOBS==time(init));
        initCLIM=find(timeCLIM==time(init));
        [init initOBS initCLIM]
        
        if initOBS>=15
            persist_obs(:,:,init)=...
                nanmean(varYearlyOBS(:,:,initOBS+leadStart:initOBS+leadEnd),3)-...
                nanmean(varYearlyOBS(:,:,initOBS-14:initOBS),3);
            persist_model(:,:,init)=...
                nanmean(varYearlyOBS(:,:,initOBS-4:initOBS),3)-...
                nanmean(varYearlyOBS(:,:,initOBS-14:initOBS),3);

            BC_15yr_obs(:,:,init)=...
                nanmean(varYearlyOBS(:,:,initOBS+leadStart:initOBS+leadEnd),3)-...
                nanmean(varYearlyOBS(:,:,initOBS-14:initOBS),3);
            BC_15yr_model(:,:,init)=...
                nanmean(BC(:,:,leadStart:leadEnd,init),3)-...
                nanmean(varYearlyOBS(:,:,initOBS-14:initOBS),3);

            anom_15yr_obs(:,:,init)=...
                nanmean(varYearlyOBS(:,:,initOBS+leadStart:initOBS+leadEnd),3)-...
                nanmean(varYearlyOBS(:,:,initOBS-14:initOBS),3);
        end
        if initCLIM>=15
            anom_15yr_model(:,:,init)=...
                nanmean(varYearly(:,:,leadStart:leadEnd,init),3)-...
                nanmean(varYearlyCLIM(:,:,initCLIM-14:initCLIM),3);
        end

        anom_clim_obs(:,:,init)=...
            nanmean(varYearlyOBS(:,:,initOBS+leadStart:initOBS+leadEnd),3)-...
            nanmean(varYearlyOBS,3); 
        anom_clim_model(:,:,init)=...
            nanmean(varYearly(:,:,leadStart:leadEnd,init),3)-...
            nanmean(varYearlyCLIM,3); 
        
        timeFinal(init)=time(init)+leadMid;
    end

    forecast=cat(4,persist_model,BC_15yr_model,anom_15yr_model,anom_clim_model);
    obs=cat(4,persist_obs,BC_15yr_obs,anom_15yr_obs,anom_clim_obs);
    titleNames={'(a) Persistence','(b) BC\_15yr\_obs',...
        '(c) anom\_15yr\_model','(d) anom\_model\_clim'};
end
