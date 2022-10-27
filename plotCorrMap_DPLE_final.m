% October 24, 2022
clear; clc; close all;

% -------------------------- SPECIFY  --------------------------
cd('/glade/work/sglanvil/CCR/SST_drift/matlab_files/')
leadStart=3;
leadMid=4;
leadEnd=5;

printName=sprintf('corrMap_TS_DPLE_REFcesm1le_%.1dto%.1dyr_final',leadStart,leadEnd);
load('varYearlyOut_cesm1_fosi_full.mat');

% -------------------------- GENERAL SETUP --------------------------
gradsmap=flip([165 0 38; 215 48 39; 244 109 67; 253 174 97; 254 224 144; ...
    224 243 248; 171 217 233; 116 173 209; 69 117 180; 49 54 149]/256);
gradsmap=interp1(1:length(gradsmap),gradsmap,linspace(1,length(gradsmap),20));
gradsmap(10:11,:)=1;
load('coast.mat');
latCoast=lat;
lonCoast=long;
lonCoast(lonCoast<0)=lonCoast(lonCoast<0)+360;
lonCoast(lonCoast<1 & lonCoast>-1)=NaN;
filLand='T42land.nc';
land=ncread(filLand,'landfrac');
fil='T42.gw.nc';
lon=ncread(fil,'lon');
lat=ncread(fil,'lat');

% -------------------------- FORECAST --------------------------
imodel=1;
imember=41;

varYearly=varYearly_FORECAST{imember};
dataModel=squeeze(nanmean(varYearly(:,:,leadStart:leadEnd,:),3));
timeModel=time_FORECAST{imember};
dataLE=varYearlyCLIM_LE{1};
timeLE=timeCLIM_LE{1};
dataObs=varYearlyOBShteng;
timeObs=timeOBShteng;
dataRef=dataLE;

% ------------------ make times the same as timeModel ------------------
dataObs=dataObs(:,:,timeObs>=timeModel(1) & timeObs<=timeModel(end));
dataLE=dataLE(:,:,timeLE>=timeModel(1) & timeLE<=timeModel(end));

anom_15yr_model=NaN(128,64,64);
anom_15yr_obs=NaN(128,64,64);
anom_clim_model=NaN(128,64,64);
anom_clim_obs=NaN(128,64,64);
for init=20:length(timeModel)-leadEnd
    anom_15yr_model(:,:,init)=dataModel(:,:,init)-...
        nanmean(dataRef(:,:,init-19:init-5),3);
    anom_15yr_obs(:,:,init)=nanmean(dataObs(:,:,init+leadStart:init+leadEnd),3)-...
        nanmean(dataObs(:,:,init-14:init),3);
end
for init=1:length(timeModel)-leadEnd
    anom_clim_model(:,:,init)=dataModel(:,:,init)-...
        nanmean(dataRef,3);
    anom_clim_obs(:,:,init)=nanmean(dataObs(:,:,init+leadStart:init+leadEnd),3)-...
        nanmean(dataObs,3);
end
timeFinal=timeModel+leadMid;
 

figure
for methodAnom={'15yr' 'clim'}
    if strcmp(methodAnom,'15yr')==1
        xfinal=anom_15yr_model;
        yfinal=anom_15yr_obs;
        icounter=1;
    end
    if strcmp(methodAnom,'clim')==1
        xfinal=anom_clim_model;
        yfinal=anom_clim_obs;
        icounter=2;
    end
    anomFF=xfinal;
    anomAA=yfinal;
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

    subplot(2,2,icounter)
        hold on; grid on; box on;
        pcolor(lon,lat,ACC');
        shading flat;
        plot(lonCoast,latCoast,'k','linewidth',1);
        colormap(gradsmap); caxis([-1 1]);
        title(join([methodAnom,": ",ACC_avg]));
        set(gca,'fontsize',13);
        axis tight
end
sgtitle(sprintf('DPLE (%.1d-%.1dyr lead) with CESM1LE Ref',leadStart,leadEnd));
hc=colorbar('location','southoutside','position',[0.25 0.44 0.5 0.02]);
set(gcf,'renderer','painters')
print(printName,'-r300','-dpng');

