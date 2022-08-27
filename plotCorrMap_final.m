% August 16, 2022
clear; clc; close all;

% -------------------------- SPECIFY  --------------------------
printName='corrMap_FORCASTcesm1fosi_CLIMcesm1le_OBShadisst';

% -------------------------- GENERAL SETUP --------------------------
subpos=[.25 .65 .5 .2; .25 .375 .5 .2; .25 .1 .5 .2];   
% gradsmap=flip([103 0 31; 178 24 43; 214 96 77; 244 165 130; 253 219 199; ...
%     209 229 240; 146 197 222; 67 147 195; 33 102 172; 5 48 97]/256);
% gradsmap1=interp1(1:5,gradsmap(1:5,:),linspace(1,5,10));
% gradsmap2=interp1(6:10,gradsmap(6:10,:),linspace(6,10,10));
% gradsmap=[gradsmap1; gradsmap2];
gradsmap=flip([103 0 31; 178 24 43; 214 96 77; 244 165 130; 253 219 199; ...
    209 229 240; 146 197 222; 67 147 195; 33 102 172; 5 48 97]/256);
gradsmap=flip([165 0 38; 215 48 39; 244 109 67; 253 174 97; 254 224 144; ...
    224 243 248; 171 217 233; 116 173 209; 69 117 180; 49 54 149]/256);
gradsmap=interp1(1:length(gradsmap),gradsmap,linspace(1,length(gradsmap),20));
gradsmap(10:11,:)=1;

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

% -------------------------- CLIM --------------------------
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
% -------------------------- CLIM --------------------------

% -------------------------- FORECAST --------------------------
fil='/Users/sglanvil/Documents/CCR/meehl/data/SST_drift_data/ts_cesm1_fosi_EM_ALL.nc';
raw=ncread(fil,'TS');
raw=raw(:,:,3:end,1:7); % remove beginning months (Nov and Dec)
time=[1985 1990 1995 2000 2005 2010 2015 2016 2017]; % init years for cesm1_fosi
time=[1985 1990 1995 2000 2005 2010 2015]; % through 2015
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
% -------------------------- FORECAST --------------------------

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


% -------------------------- CALCULATION --------------------------
addpath /Users/sglanvil/Documents/CCR/meehl
leadStart=3;
leadEnd=5;
leadMid=round(nanmean(leadStart:leadEnd));
[forecast,obs,titleNames]=...
    sgfun_driftMeehl(varYearly,varYearlyOBS,varYearlyCLIM,...
    time,timeOBS,timeCLIM,lon,lat,leadStart,leadEnd,leadMid);

titleNames={'Persistence','BC\_15yr\_obs',...
    'anom\_15yr\_model','anom\_model\_clim'};
figure
for imethod=3:4
    x0=squeeze(obs(:,:,:,imethod));
    y0=squeeze(forecast(:,:,:,imethod));
    anomFF=squeeze(y0);
    anomAA=squeeze(x0);
    a=(anomFF.*anomAA);
    b=(anomFF).^2;
    c=(anomAA).^2;
    aTM=squeeze(nanmean(a,3)); % calculate time means (TM)
    bTM=squeeze(nanmean(b,3));
    cTM=squeeze(nanmean(c,3));
    ACC=aTM./sqrt(bTM.*cTM);
    
    ACC_60Sto60N=ACC(:,lat>-60 & lat<60);
    lat_60Sto60N=lat(lat>-60 & lat<60);
    ACCzm_60Sto60N=squeeze(nanmean(ACC_60Sto60N,1))';
    ACC_60Sto60N_cosine=squeeze(nansum(ACCzm_60Sto60N.*cosd(lat_60Sto60N))./nansum(cosd(lat_60Sto60N))); 
    ACC_avg=sprintf('%.2f',ACC_60Sto60N_cosine);

    subplot(2,2,imethod-2)
        hold on; grid on; box on;
        pcolor(lon,lat,ACC');
        shading flat;
        plot(lonCoast,latCoast,'k','linewidth',1);
        colormap(gradsmap); caxis([-1 1]);
        title(join([titleNames{imethod},": ",ACC_avg]));
        set(gca,'fontsize',13);
        axis tight
end
sgtitle('\bfDPLE/CESM1FOSI (3-5yr lead) with CESM1LE clim ref');
hc=colorbar('location','southoutside','position',[0.25 0.44 0.5 0.02]);
set(gcf,'renderer','painters')
print(printName,'-r300','-dpng');
% for different colorbar, see similar: hteng_dple_anomalies_map_figure.png
