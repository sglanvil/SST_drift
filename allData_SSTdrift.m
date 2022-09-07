% August 31, 2022
clear; clc; close all;


% -------------------------- GENERAL SETUP --------------------------
load('coast.mat');
latCoast=lat;
lonCoast=long;
lonCoast(lonCoast<0)=lonCoast(lonCoast<0)+360;
lonCoast(lonCoast<1 & lonCoast>-1)=NaN;
filLand='/Users/sglanvil/Documents/CCR/hteng/data/T42land.nc';
land=ncread(filLand,'landfrac');
fil='/Users/sglanvil/Documents/CCR/hteng/data/T42.gw.nc';
lon=ncread(fil,'lon');
lat=ncread(fil,'lat');
% -------------------------- GENERAL SETUP --------------------------


% -------------------------- CLIM:CESM1LE --------------------------
fil='/Users/sglanvil/Documents/CCR/meehl/data/SST_drift_data/extend_hist_ssp370_E3SMv1_185001-210012.nc';
raw=ncread(fil,'TS');
t1=datetime('15/Jan/1850');
t2=datetime('15/Dec/2100'); 
timeCLIM=t1:t2;
timeCLIM=timeCLIM(day(timeCLIM)==15); % datetime monthly option
timeCLIM=unique(year(timeCLIM));
lon0=ncread(fil,'lon');
lat0=ncread(fil,'lat');
[x,y]=meshgrid(lon0,lat0);
[xNew,yNew]=meshgrid(lon,lat);
for itime=1:size(raw,3)
    varMonthlyCLIM(:,:,itime)=interp2(x,y,squeeze(raw(:,:,itime))',...
        xNew,yNew,'linear',1)'; 
end
for iyear=1:size(varMonthlyCLIM,3)/12
    varYearlyCLIM(:,:,iyear)=nanmean(varMonthlyCLIM(:,:,(iyear-1)*12+1:(iyear-1)*12+12),3);
end
land_rep=repmat(land,1,1,size(varYearlyCLIM,3));
varYearlyCLIM(land_rep>0.5)=NaN; % THIS ACTUALLY MATTERS A TON
varYearlyCLIM_LE{1}=varYearlyCLIM;
timeCLIM_LE{1}=timeCLIM;
name_LE{1}='CESM1LE';

% -------------------------- CLIM:E3SMv1 --------------------------
fil='/Users/sglanvil/Documents/CCR/meehl/data/SST_drift_data/extend_hist_rcp85_CESM1LE_192001-208012.nc';
raw=ncread(fil,'TS');
t1=datetime('15/Jan/1920');
t2=datetime('15/Dec/2080'); 
timeCLIM=t1:t2;
timeCLIM=timeCLIM(day(timeCLIM)==15); % datetime monthly option
timeCLIM=unique(year(timeCLIM));
lon0=ncread(fil,'lon');
lat0=ncread(fil,'lat');
[x,y]=meshgrid(lon0,lat0);
[xNew,yNew]=meshgrid(lon,lat);
for itime=1:size(raw,3)
    varMonthlyCLIM(:,:,itime)=interp2(x,y,squeeze(raw(:,:,itime))',...
        xNew,yNew,'linear',1)'; 
end
for iyear=1:size(varMonthlyCLIM,3)/12
    varYearlyCLIM(:,:,iyear)=nanmean(varMonthlyCLIM(:,:,(iyear-1)*12+1:(iyear-1)*12+12),3);
end
land_rep=repmat(land,1,1,size(varYearlyCLIM,3));
varYearlyCLIM(land_rep>0.5)=NaN; % THIS ACTUALLY MATTERS A TON
varYearlyCLIM_LE{2}=varYearlyCLIM;
timeCLIM_LE{2}=timeCLIM;
name_LE{2}='CESM1LE';

% -------------------------- FORECAST --------------------------
modelList={'cesm1_fosi','cesm1_bruteforce','e3sm_fosi','e3sm_bruteforce'};
memberList={'001','002','003','EM'};
for imodel=1:4
    for imember=1:4
        fil=sprintf('/Users/sglanvil/Documents/CCR/meehl/data/SST_drift_data/ts_%s_%s_ALL.nc',...
            modelList{imodel},memberList{imember});
        raw=ncread(fil,'TS');
        raw=raw(:,:,3:60,1:8); % remove Nov and Dec
        raw(:,:,59:60,:)=NaN; % add on some NaN months to get regular years
        time=[1985 1990 1995 2000 2005 2010 2015 2016]; % through 2016 raw(..,1:8) for yr3-5 (yr5=2021)
        lead=[1986 1987 1988 1989 1990; ...
            1991 1992 1993 1994 1995; ...
            1996 1997 1998 1999 2000; ...
            2001 2002 2003 2004 2005; ...
            2006 2007 2008 2009 2010; ...
            2011 2012 2013 2014 2015; ...
            2016 2017 2018 2019 2020; ...
            2017 2018 2019 2020 2021];
        lon0=ncread(fil,'lon');
        lat0=ncread(fil,'lat');
        [x,y]=meshgrid(lon0,lat0);
        [xNew,yNew]=meshgrid(lon,lat);
        for init=1:size(raw,4)
            for itime=1:size(raw,3)
                varMonthly(:,:,itime,init)=interp2(x,y,squeeze(raw(:,:,itime,init))',...
                    xNew,yNew,'linear',1)'; 
            end
            for iyear=1:size(varMonthly,3)/12
                varYearly(:,:,iyear,init)=nanmean(varMonthly(:,:,...
                    (iyear-1)*12+1:(iyear-1)*12+12,init),3);
            end    
        end
        land_rep=repmat(land,1,1,size(varYearly,3),size(varYearly,4));
        varYearly(land_rep>0.5)=NaN; % THIS ACTUALLY MATTERS A TON
        varYearly_FORECAST{imodel,imember}=varYearly;
        time_FORECAST{imodel,imember}=time;
        name_FORECAST{imodel,imember}=modelList{imodel};
        lead_FORECAST{imodel,imember}=lead;
    end
end


% -------------------------- OBSERVATIONS --------------------------
fil='/Users/sglanvil/Documents/CCR/meehl/data/HadISST_sst.nc';
lon0=ncread(fil,'longitude');
lat0=ncread(fil,'latitude');
lon0(lon0<0)=lon0(lon0<0)+360;
raw=ncread(fil,'sst')+273; % --- from Celsius to Kelvin
raw(raw<0)=NaN; % --- remove negative values (probably ice flags)
[lon0sorted,inx]=sort(lon0); % --- deal with some neg lon issues
raw=raw(inx,:,:); % --- deal with some neg lon issues
lon0=lon0(inx); % --- deal with some neg lon issues
t1=datetime('15/Jan/1870');
t2=datetime('15/Dec/2021');
timeOBS=t1:t2;
timeOBS=timeOBS(day(timeOBS)==15); % datetime monthly option
timeOBS=unique(year(timeOBS));
[x,y]=meshgrid(lon0,lat0);
[xNew,yNew]=meshgrid(lon,lat);
clear varMonthlyOBS varYearlyOBS
for itime=1:size(raw,3)
    varMonthlyOBS(:,:,itime)=interp2(x,y,squeeze(raw(:,:,itime))',...
        xNew,yNew,'linear',1)'; 
end
for iyear=1:size(varMonthlyOBS,3)/12
    varYearlyOBS(:,:,iyear)=nanmean(varMonthlyOBS(:,:,(iyear-1)*12+1:(iyear-1)*12+12),3);
end
land_rep=repmat(land,1,1,size(varYearlyOBS,3),size(varYearlyOBS,4));
varYearlyOBS(land_rep>0.5)=NaN; % THIS ACTUALLY MATTERS A TON
% -------------------------- OBSERVATIONS --------------------------

save('varYearlyOut_cesm1_e3sm',...
    'varYearlyCLIM_LE','timeCLIM_LE','name_LE',...
    'varYearly_FORECAST','time_FORECAST','name_FORECAST',...
    'varYearlyOBS','timeOBS','lon','lat',...
    'lead_FORECAST');
