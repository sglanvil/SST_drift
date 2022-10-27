% October 24, 2022
clear; clc; close all;

cd('/glade/work/sglanvil/CCR/SST_drift/matlab_files/')

% -------------------------- SPECIFY  --------------------------
methodRef='itself'; % 'itself' or 'LE' or 'LEadjusted'
methodAnom='15yr'; % 'persist' or '15yr' or 'clim'
leadStart=3;
leadMid=4;
leadEnd=5;

titleName=sprintf('TS "anom\\_%s" Correlation (40S-70N, 100E-80W)',methodAnom);
printName=sprintf('corrTimeseries_TS_DPLE_%s_%s_%.1dto%.1dyr_final',methodRef,methodAnom,leadStart,leadEnd);
load('varYearlyOut_cesm1_fosi_full.mat');
gw=ncread('/glade/work/sglanvil/CCR/SST_drift/matlab_files/T42.gw.nc','gw');
gw=repmat(gw',length(lon),1);

load('/glade/work/sglanvil/CCR/SST_drift/matlab_files/diffOut_diff.mat');
% average of year3 & year5, cesm_fosi (aka DPLE)
% format: diff_save{itype,imodel} where {3:4,3}={year3:year5,cesm_fosi}
cesm1fosi=(diff_save{3,3}+diff_save{4,3})/2;

% -------------------------- GENERAL SETUP --------------------------
plotLine={'-','--','-','--'};
plotColor=[1 0 0; 1 0 0; 0 0 1; 0 0 1];
figure;
hold on; box on; grid on;
plot([1960 2020],[0.53 0.53],'color',[.5 .5 .5],'linestyle','--');
plot([1960 2020],[0 0],'k');
volcYear=[1963 1974 1982 1991 2006 2011];
volcName={'Agung' 'Fuego' 'El Chichon' 'Pinatubo' 'Tavurvur' 'Nabro'};
for ivolc=1:6
    plot([volcYear(ivolc) volcYear(ivolc)],[-1 1],...
        'color',[.5 .5 .5],'linestyle','--');
    text(volcYear(ivolc)+1,-0.57,volcName{ivolc},'rotation',90,'color',[.5 .5 .5]);
end

% -------------------------- FORECAST --------------------------
imodel=1;
for imember=1:41 % 1:41
    varYearly=varYearly_FORECAST{imember};
    dataModel=squeeze(nanmean(varYearly(:,:,leadStart:leadEnd,:),3));
    timeModel=time_FORECAST{imember};
    
    dataLE=varYearlyCLIM_LE{1};
    timeLE=timeCLIM_LE{1};
    
    dataObs=varYearlyOBShteng;
    timeObs=timeOBShteng;
    
    % ------------------ make times the same as timeModel ------------------
    dataObs=dataObs(:,:,timeObs>=timeModel(1) & timeObs<=timeModel(end));
    dataLE=dataLE(:,:,timeLE>=timeModel(1) & timeLE<=timeModel(end));
    
    if strcmp(methodRef,'itself')==1
        dataRef=dataModel;
    end
    if strcmp(methodRef,'LE')==1
        dataRef=dataLE;
    end
    if strcmp(methodRef,'LEadjusted')==1
        dataRef=dataLE+cesm1fosi;
    end
    
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
    
    if strcmp(methodAnom,'15yr')==1
        xfinal=anom_15yr_model;
        yfinal=anom_15yr_obs;
    end
    if strcmp(methodAnom,'clim')==1
        xfinal=anom_clim_model;
        yfinal=anom_clim_obs;
    end

    clear uncenteredR
    for init=1:length(timeModel)
        xMap=xfinal(lon>100 & lon<280,lat>-40 & lat<70,init);
        yMap=yfinal(lon>100 & lon<280,lat>-40 & lat<70,init);
        a=nansum(nansum(xMap.*yMap.*gw(lon>100 & lon<280,lat>-40 & lat<70)));
        b=sqrt(nansum(nansum((xMap.^2).*gw(lon>100 & lon<280,lat>-40 & lat<70))));
        c=sqrt(nansum(nansum((yMap.^2).*gw(lon>100 & lon<280,lat>-40 & lat<70))));
        uncenteredR(init)=a/(b*c);    
    end
    plotLineTrans=0.10;
    plotLineWidth=1;
    if imember==41 % ensemble mean
        plotLineWidth=2;
        plotLineTrans=1;
    end
    h(imodel)=plot(timeFinal,uncenteredR,...
        'color',[plotColor(imodel,:) plotLineTrans],...
        'linestyle',plotLine{imodel},'linewidth',plotLineWidth);    
end
text(2016,0.93,sprintf('%.1d-%.1dyr lead',leadStart,leadEnd),...
    'fontsize',13,'fontweight','bold','horizontalalignment','right');
text(2016,0.85,sprintf('Ref Climo: %s',methodRef),...
    'fontsize',13,'fontweight','bold','horizontalalignment','right');
legend(h,{'CESM1 fosi'},...
        'fontsize',13,'box','off','location','northwest')
title(titleName);
set(gca,'fontsize',15);
axis([1960 2018 -0.6 1]);
set(gcf,'renderer','painters')

print(printName,'-r300','-dpng');




