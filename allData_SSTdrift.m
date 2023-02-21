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
fil='/Users/sglanvil/Documents/CCR/meehl/data/SST_drift_data/extend_hist_rcp85_CESM1LE_192001-208012.nc';
raw=ncread(fil,'TS');
% fil='/Users/sglanvil/Documents/CCR/meehl/data/TREFHT/extend_TREFHT_CESM1LE_192001-208012.nc';
% raw=ncread(fil,'TREFHT');
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
varYearlyCLIM_LE{1}=varYearlyCLIM(:,:,timeCLIM>=1950 & timeCLIM<2030);
timeCLIM_LE{1}=timeCLIM(timeCLIM>=1950 & timeCLIM<2030);
name_LE{1}='CESM1LE';


% -------------------------- CLIM:E3SMv1 --------------------------
fil='/Users/sglanvil/Documents/CCR/meehl/data/SST_drift_data/extend_hist_ssp370_E3SMv1_185001-210012.nc';
raw=ncread(fil,'TS');
% fil='/Users/sglanvil/Documents/CCR/meehl/data/TREFHT/extend_TREFHT_E3SMv1_185001-210012.nc';
% raw=ncread(fil,'TREFHT');
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
varYearlyCLIM_LE{2}=varYearlyCLIM(:,:,timeCLIM>=1950 & timeCLIM<2030);
timeCLIM_LE{2}=timeCLIM(timeCLIM>=1950 & timeCLIM<2030);
name_LE{2}='E3SMv1';

% -------------------------- FORECAST --------------------------
modelList={'cesm1_fosi','cesm1_bruteforce','e3sm_fosi','e3sm_bruteforce'};
memberList={'001','002','003','EM'};
for imodel=1:4
    for imember=1:4
        fil=sprintf('/Users/sglanvil/Documents/CCR/meehl/data/SST_drift_data/ts_%s_%s_ALL.nc',...
            modelList{imodel},memberList{imember});
        raw=ncread(fil,'TS');
%         fil=sprintf('/Users/sglanvil/Documents/CCR/meehl/data/TREFHT/trefht_%s_%s_ALL.nc',...
%             modelList{imodel},memberList{imember});
%         raw=ncread(fil,'TREFHT');
        raw=raw(:,:,3:60,1:9); % remove Nov and Dec
        raw(:,:,59:60,:)=NaN; % add on some NaN months to get regular years
        time=[1985 1990 1995 2000 2005 2010 2015 2016 2017]; % through 2016 raw(..,1:8) for yr3-5 (yr5=2021)
        lead=[1986 1987 1988 1989 1990; ...
            1991 1992 1993 1994 1995; ...
            1996 1997 1998 1999 2000; ...
            2001 2002 2003 2004 2005; ...
            2006 2007 2008 2009 2010; ...
            2011 2012 2013 2014 2015; ...
            2016 2017 2018 2019 2020; ...
            2017 2018 2019 2020 2021; ...
            2018 2019 2020 2021 2022];
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


% -------------------------- OBSERVATIONS hteng --------------------------
fil='/Users/sglanvil/Documents/CCR/meehl/obs/air.2m.mon.mean.nc'; % updated Jan-2023
% fil='/glade/work/sglanvil/CCR/SST_drift/matlab_files/air.2m.mon.mean.nc';
lon0=ncread(fil,'lon');
lat0=ncread(fil,'lat');
raw=ncread(fil,'air'); % slp, precip, air
raw=raw(:,:,1:900); % just 1948 thru 2022 (75 years)
t1=datetime('15/Jan/1948'); 
t2=datetime('15/Dec/2022'); %
timeOBShteng=t1:t2;
timeOBShteng=timeOBShteng(day(timeOBShteng)==15); % datetime monthly option
timeOBShteng=unique(year(timeOBShteng));
[x,y]=meshgrid(lon0,lat0);
[xNew,yNew]=meshgrid(lon,lat);
for itime=1:size(raw,3)
    varMonthlyOBShteng(:,:,itime)=interp2(x,y,squeeze(raw(:,:,itime))',...
        xNew,yNew,'linear',1)'; 
end
for iyear=1:size(varMonthlyOBShteng,3)/12
    varYearlyOBShteng(:,:,iyear)=nanmean(varMonthlyOBShteng(:,:,(iyear-1)*12+1:(iyear-1)*12+12),3);
end
land_rep=repmat(land,1,1,size(varYearlyOBShteng,3),size(varYearlyOBShteng,4));
varYearlyOBShteng(land_rep>0.5)=NaN; % THIS ACTUALLY MATTERS A TON
% -------------------------- OBSERVATIONS hteng --------------------------


save('varYearlyOut_cesm1_e3sm_TS_2022',... % TREFHT or TS?
    'varYearlyCLIM_LE','timeCLIM_LE','name_LE',...
    'varYearly_FORECAST','time_FORECAST','name_FORECAST',...
    'varYearlyOBS','timeOBS','lon','lat',...
    'varYearlyOBShteng','timeOBShteng',...
    'lead_FORECAST');


