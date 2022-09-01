% August 31, 2022
clear; clc; close all;

% -------------------------- SPECIFY  --------------------------
addpath /Users/sglanvil/Documents/CCR/meehl % acccess sgfun_driftMeehl
printName='corr_timeseries_cesm1_e3sm';
load('varYearlyOut_cesm1_e3sm.mat');
leadStart=3;
leadMid=4;
leadEnd=5;

% -------------------------- GENERAL SETUP --------------------------
plotLine={'-','-','--','--'};
plotColor=[1 0 0; 0 0 1; 1 0 0; 0 0 1];
figure;
hold on; box on;
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
for imodel=1:4
    varYearly=varYearly_FORECAST{imodel};
    time=time_FORECAST{imodel};
    if imodel==1 || imodel==2
        varYearlyCLIM=varYearlyCLIM_LE{1}; % CESM1LE
        timeCLIM=timeCLIM_LE{1};
    else
        varYearlyCLIM=varYearlyCLIM_LE{2}; % E3SMv1
        timeCLIM=timeCLIM_LE{2};
    end
    
    varYearlyCLIM=varYearly;
    timeCLIM=time;
    
    [forecast,obs,titleNames]=...
        sgfun_driftMeehl(varYearly,varYearlyOBS,varYearlyCLIM,...
        time,timeOBS,timeCLIM,lon,lat,leadStart,leadEnd,leadMid);

    anom_clim_model=forecast(:,:,:,4);
    anom_clim_obs=obs(:,:,:,4);
    xfinal=squeeze(anom_clim_obs);
    yfinal=squeeze(anom_clim_model);
    
    clear uncenteredR
    for itime=1:length(time)
        xMap=xfinal(lon>100 & lon<280,lat>-40 & lat<70,itime);
        yMap=yfinal(lon>100 & lon<280,lat>-40 & lat<70,itime);
        a=nansum(nansum(xMap.*yMap));
        b=sqrt(nansum(nansum(xMap.^2)));
        c=sqrt(nansum(nansum(yMap.^2)));
        uncenteredR(itime)=a/(b*c);    
    end
%     plotLineTrans=0.25;
%     plotLineWidth=1;
%     if imember==4 % ensemble mean
        plotLineWidth=2;
        plotLineTrans=1;
%     end
    h(imodel)=plot(time,uncenteredR,...
        'color',[plotColor(imodel,:) plotLineTrans],...
        'linestyle',plotLine{imodel},'linewidth',plotLineWidth);    
end
text(1997,0.6,'1985-2005, 4 initializations','fontsize',13);
legend(h,{'CESM1 bruteforce','E3SM bruteforce','CESM1 FOSI','E3SM FOSI'},...
        'fontsize',13,'box','off')
title('TS "anom\_model\_clim" Pattern Correlation (40S-70N, 100E-80W)');
set(gca,'fontsize',15);
axis([1960 2018 -0.6 1]);
    
set(gcf,'renderer','painters')
% print(printName,'-r300','-dpng');




