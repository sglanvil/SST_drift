% August 31, 2022
clear; clc; close all;

% -------------------------- GENERAL SETUP --------------------------
load('/glade/work/sglanvil/CCR/SST_drift/matlab_files/coast.mat');
latCoast=lat;
lonCoast=long;
lonCoast(lonCoast<0)=lonCoast(lonCoast<0)+360;
lonCoast(lonCoast<1 & lonCoast>-1)=NaN;
filLand='/glade/work/sglanvil/CCR/SST_drift/matlab_files/T42land.nc';
land=ncread(filLand,'landfrac');
fil='/glade/work/sglanvil/CCR/SST_drift/matlab_files/T42.gw.nc';
lon=ncread(fil,'lon');
lat=ncread(fil,'lat');
% -------------------------- GENERAL SETUP --------------------------

% -------------------------- FORECAST --------------------------
for i=1:40
    memberList{i}=sprintf('%.3d',i);
end
memberList{end+1}='EM';

for imember=1:length(memberList)
    disp(imember)
    fil=sprintf('/glade/work/sglanvil/CCR/SST_drift/CESM1_FOSI_FULL/ts_cesm1_fosi_%s_ALL.nc',...
        memberList{imember});
    raw=ncread(fil,'TS');
    raw=raw(:,:,3:122,:); % remove first Nov/Dec
    time=1954:2017; 
    clear lead
    for i=1954:2017
        lead(i-1953,:)=i+1:i+10;
    end
    lon0=ncread(fil,'lon');
    lat0=ncread(fil,'lat');
    [x,y]=meshgrid(lon0,lat0);
    [xNew,yNew]=meshgrid(lon,lat);
    clear varMonthly varYearly
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
    varYearly_FORECAST{imember}=varYearly;
    time_FORECAST{imember}=time;
    name_FORECAST{imember}='cesm1_fosi';
    lead_FORECAST{imember}=lead;
end

% -------------------------- CLIM:CESM1LE --------------------------
fil='/glade/work/sglanvil/CCR/SST_drift/CESM1LE/extend_hist_rcp85_CESM1LE_192001-208012.nc';
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
varYearlyCLIM_LE{1}=varYearlyCLIM;
timeCLIM_LE{1}=timeCLIM;
name_LE{1}='CESM1LE';



% -------------------------- OBSERVATIONS --------------------------
fil='/glade/work/sglanvil/CCR/SST_drift/matlab_files/HadISST_sst.nc';
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


save('/glade/work/sglanvil/CCR/SST_drift/matlab_files/varYearlyOut_cesm1_fosi_full.mat',...
    'varYearlyCLIM_LE','timeCLIM_LE','name_LE',...
    'varYearly_FORECAST','time_FORECAST','name_FORECAST',...
    'varYearlyOBS','timeOBS','lon','lat',...
    'lead_FORECAST');
