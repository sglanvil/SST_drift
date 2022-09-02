% August 31, 2022
clear; clc; close all;

% -------------------------- SPECIFY  --------------------------
addpath /Users/sglanvil/Documents/CCR/meehl % acccess sgfun_driftMeehl
printName='corrTimeseries_cesm1_e3sm_itself_15yr';
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
    for imember=1:4
        varYearly=varYearly_FORECAST{imodel,imember};
        time=time_FORECAST{imodel,imember};
        lead=lead_FORECAST{imodel,imember};
        if imodel==1 || imodel==2
            varYearlyCLIM=varYearlyCLIM_LE{1}; % CESM1LE
            timeCLIM=timeCLIM_LE{1};
        else
            varYearlyCLIM=varYearlyCLIM_LE{2}; % E3SMv1
            timeCLIM=timeCLIM_LE{2};
        end

        varYearlyCLIM=varYearly;
        timeCLIM=time;

        [forecast,obs,timeFinal,titleNames]=...
            sgfun_driftMeehl(varYearly,varYearlyOBS,varYearlyCLIM,...
            time,timeOBS,timeCLIM,lead,lon,lat,leadStart,leadEnd,leadMid);

        xfinal=squeeze(forecast(:,:,:,3));
        yfinal=squeeze(obs(:,:,:,3));

        clear uncenteredR
        for itime=1:length(timeFinal)
            xMap=xfinal(lon>100 & lon<280,lat>-40 & lat<70,itime);
            yMap=yfinal(lon>100 & lon<280,lat>-40 & lat<70,itime);
            a=nansum(nansum(xMap.*yMap));
            b=sqrt(nansum(nansum(xMap.^2)));
            c=sqrt(nansum(nansum(yMap.^2)));
            uncenteredR(itime)=a/(b*c);    
        end
        plotLineTrans=0.25;
        plotLineWidth=1;
        if imember==4 % ensemble mean
            plotLineWidth=2;
            plotLineTrans=1;
        end
        h(imodel)=plot(timeFinal,uncenteredR,...
            'color',[plotColor(imodel,:) plotLineTrans],...
            'linestyle',plotLine{imodel},'linewidth',plotLineWidth);    
    end
end
text(1964,0.9,'1985-2016','fontsize',14);
text(1964,0.8,'8 inits','fontsize',14);
text(1964,0.7,'3-5yr lead','fontsize',14);
legend(h,{'CESM1 fosi','CESM1 bruteforce','E3SM FOSI','E3SM bruteforce'},...
        'fontsize',13,'box','off')
title('TS "anom\_15yr" Pattern Correlation (40S-70N, 100E-80W)');
set(gca,'fontsize',15);
axis([1960 2018 -0.8 1]);
    
set(gcf,'renderer','painters')
print(printName,'-r300','-dpng');




