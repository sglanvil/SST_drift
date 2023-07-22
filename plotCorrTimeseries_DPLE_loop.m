% October 24, 2022
clear; clc; close all;

cd('/glade/work/sglanvil/CCR/SST_drift/matlab_files/')

% -------------------------- SPECIFY  --------------------------
% methodRef='hindcast'; % 'itself-->hindcast' or 'LE' or 'LEadjusted'
% methodAnom and lead stuff moved to for loop below
% leadStart=3;
% leadMid=4;
% leadEnd=5;
methodAnom='15yr';

printName=sprintf('corrTimeseries_TS_DPLE_multipanel_%s_allYears_yeager_updated',methodAnom);

load('varYearlyOut_cesm1_fosi_full_TS_2022.mat'); % --------- SPECIFY ---------
gw=ncread('/glade/work/sglanvil/CCR/SST_drift/matlab_files/T42.gw.nc','gw');
gw=repmat(gw',length(lon),1);

load('/glade/work/sglanvil/CCR/SST_drift/matlab_files/diffOut_diff.mat');
% average of year3 & year5, cesm_fosi (aka DPLE)
% format: diff_save{itype,imodel} where {3:4,3}={year3:year5,cesm_fosi}
cesm1fosi=(diff_save{3,3}+diff_save{4,3})/2;

methodRefList={'hindcast','LE'};
leadStartList=[3 3];
leadMidList=[4 5];
leadEndList=[5 7];
panelLetter={'a','b','c','d'};

plotLine={'-','--','-','--'};
plotColor=[1 0 0; 1 0 0; 0 0 1; 0 0 1];
figure;
icounter=0;
for imethodRef=1:2
    methodRef=methodRefList{imethodRef};
    for ilead=1:2
        leadStart=leadStartList(ilead);
        leadMid=leadMidList(ilead);
        leadEnd=leadEndList(ilead);
        % -------------------------- GENERAL SETUP --------------------------
        icounter=icounter+1;
        subplot(2,2,icounter)
        titleName=sprintf('(%s) Lead: %.1d-%.1dyr, Ref Clim: %s',panelLetter{icounter},leadStart,leadEnd,methodRef);
        hold on; box on; grid on;
        plot([1960 2030],[0.5 0.5],'color',[.5 .5 .5],'linestyle','--');
        plot([1960 2030],[0 0],'k');
        volcYear=[1963 1974 1982 1991 2006 2011];
        volcName={'Agung' 'Fuego' 'El Chichon' 'Pinatubo' 'Tavurvur' 'Nabro'};
        for ivolc=2:6
            plot([volcYear(ivolc) volcYear(ivolc)],[-1 1],...
                'color',[.5 .5 .5],'linestyle',':');
            text(volcYear(ivolc)+1,-0.67,volcName{ivolc},'rotation',90,'color',[.5 .5 .5],'fontsize',8);
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

            timeWant=1940:2022;
            dataModel_final=NaN(length(lon),length(lat),length(timeWant));
            dataLE_final=NaN(length(lon),length(lat),length(timeWant));
            dataObs_final=NaN(length(lon),length(lat),length(timeWant));
            for i=1:length(timeWant)
                inxModel=find(timeModel==timeWant(i));
                inxLE=find(timeLE==timeWant(i));
                inxObs=find(timeObs==timeWant(i));
                if isempty(inxModel)~=1
                    dataModel_final(:,:,i)=dataModel(:,:,inxModel);
                end
                if isempty(inxLE)~=1
                    dataLE_final(:,:,i)=dataLE(:,:,inxLE);                
                end
                if isempty(inxObs)~=1
                    dataObs_final(:,:,i)=dataObs(:,:,inxObs);
                end
            end
            dataModel=dataModel_final; 
            dataLE=dataLE_final;
            dataObs=dataObs_final;
            timeModel=timeWant;
            clear *_final

            if strcmp(methodRef,'hindcast')==1
                dataRef=dataModel;
            end
            if strcmp(methodRef,'LE')==1
                dataRef=dataLE;
            end
            if strcmp(methodRef,'LEadjusted')==1
                dataRef=dataLE+cesm1fosi;
            end
            
            anom_15yr_model=NaN(length(lon),length(lat),length(timeWant));
            anom_15yr_obs=NaN(length(lon),length(lat),length(timeWant));
            anom_clim_model=NaN(length(lon),length(lat),length(timeWant));
            anom_clim_obs=NaN(length(lon),length(lat),length(timeWant));

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
            if strcmp(methodAnom,'total')==1
                xfinal=anom_clim_model;
                yfinal=anom_clim_obs;
            end
            
            uncenteredR=NaN(1,length(timeModel));
            for init=1:length(timeModel)
                xMap=xfinal(lon>100 & lon<280,lat>-40 & lat<70,init);
                yMap=yfinal(lon>100 & lon<280,lat>-40 & lat<70,init);
                a=nansum(nansum(xMap.*yMap.*gw(lon>100 & lon<280,lat>-40 & lat<70)));
                b=sqrt(nansum(nansum((xMap.^2).*gw(lon>100 & lon<280,lat>-40 & lat<70))));
                c=sqrt(nansum(nansum((yMap.^2).*gw(lon>100 & lon<280,lat>-40 & lat<70))));
                uncenteredR(init)=a/(b*c);    
            end

            plotLineWidth=1;
            plotLineTrans=0.10;
            plotMarker='none';
            if imember==41 % ensemble mean
                plotLineWidth=1.5;
                plotLineTrans=1;
                plotMarker='none';
                timeMeanR=nanmean(uncenteredR);
                stddevR=nanstd(uncenteredR);
            end
            timeFinal(isnan(uncenteredR))=[];
            uncenteredR(isnan(uncenteredR))=[];
            h(imodel)=plot(timeFinal,uncenteredR,'marker',plotMarker,...
                'color',[plotColor(imodel,:) plotLineTrans],...
                'linestyle',plotLine{imodel},'linewidth',plotLineWidth,...
                'markerfacecolor',plotColor(imodel,:),'markersize',4);    
        end
        text(1972,0.9,[sprintf('%.2f',timeMeanR) ' \pm ' sprintf('%.2f',stddevR)],...
            'fontsize',8,'fontweight','bold','horizontalalignment','left');
        set(gca,'ytick',-1:0.2:1,'xtick',1950:10:2030)
        set(gca,'fontsize',8);
        title(titleName,'fontsize',10);
        axis([1970 2022 -0.7 1]);
    end
end






% modelList={'cesm1_fosi','cesm1_bruteforce','e3sm_fosi','e3sm_bruteforce'};
load('varYearlyOut_cesm1_e3sm_TS_2022.mat'); % --------- SPECIFY ---------

icounter=-1;
for imethodRef=1:2
    methodRef=methodRefList{imethodRef};
    for ilead=1 % ----------------------------- can only do 3-5 yr
        leadStart=leadStartList(ilead);
        leadMid=leadMidList(ilead);
        leadEnd=leadEndList(ilead);
        % -------------------------- FORECAST --------------------------
        icounter=icounter+2;
        subplot(2,2,icounter)
        hold on; box on; grid on;        
        for imodel=1:4
            for imember=4 % just the EM  
                varYearly=varYearly_FORECAST{imodel,imember};
                timeModel=time_FORECAST{imodel,imember};
                nameModel=name_FORECAST{imodel,imember};
                dataModel=squeeze(nanmean(varYearly(:,:,leadStart:leadEnd,:),3));
                dataObs=varYearlyOBShteng;
                timeObs=timeOBShteng;
                if contains(nameModel,'cesm')==1
                    dataLE=varYearlyCLIM_LE{1}; 
                    timeLE=timeCLIM_LE{1};
                end
                if contains(nameModel,'e3sm')==1 
                    dataLE=varYearlyCLIM_LE{2};
                    timeLE=timeCLIM_LE{2};
                end
                
                timeWant=1940:2022;
                dataModel_final=NaN(length(lon),length(lat),length(timeWant));
                dataLE_final=NaN(length(lon),length(lat),length(timeWant));
                dataObs_final=NaN(length(lon),length(lat),length(timeWant));
                for i=1:length(timeWant)
                    inxModel=find(timeModel==timeWant(i));
                    inxLE=find(timeLE==timeWant(i));
                    inxObs=find(timeObs==timeWant(i));
                    if isempty(inxModel)~=1
                        dataModel_final(:,:,i)=dataModel(:,:,inxModel);
                    end
                    if isempty(inxLE)~=1
                        dataLE_final(:,:,i)=dataLE(:,:,inxLE);                
                    end
                    if isempty(inxObs)~=1
                        dataObs_final(:,:,i)=dataObs(:,:,inxObs);
                    end
                end
                dataModel=dataModel_final; 
                dataLE=dataLE_final;
                dataObs=dataObs_final;
                timeModel=timeWant;
                clear *_final
                
                if strcmp(methodRef,'hindcast')==1
                    dataRef=dataModel;
                end
                if strcmp(methodRef,'LE')==1
                    dataRef=dataLE;
                end
                
                anom_15yr_model=NaN(length(lon),length(lat),length(timeWant));
                anom_15yr_obs=NaN(length(lon),length(lat),length(timeWant));
                anom_clim_model=NaN(length(lon),length(lat),length(timeWant));
                anom_clim_obs=NaN(length(lon),length(lat),length(timeWant));
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
                if strcmp(methodAnom,'total')==1
                    xfinal=anom_clim_model;
                    yfinal=anom_clim_obs;
                end
        
                uncenteredR=NaN(1,length(timeModel));
                for init=1:length(timeModel)
                    xMap=xfinal(lon>100 & lon<280,lat>-40 & lat<70,init);
                    yMap=yfinal(lon>100 & lon<280,lat>-40 & lat<70,init);
                    a=nansum(nansum(xMap.*yMap.*gw(lon>100 & lon<280,lat>-40 & lat<70)));
                    b=sqrt(nansum(nansum((xMap.^2).*gw(lon>100 & lon<280,lat>-40 & lat<70))));
                    c=sqrt(nansum(nansum((yMap.^2).*gw(lon>100 & lon<280,lat>-40 & lat<70))));
                    uncenteredR(init)=a/(b*c);    
                end
                plotLineWidth=1;
                plotLineTrans=0.25;
                plotMarker='none';
                faceColor='none';
                if imember==4 % ensemble mean
                    plotLineWidth=1.5;
                    plotLineTrans=1;
                    plotMarker='o';
                    faceColor=plotColor(imodel,:);
                    if contains(nameModel,'bruteforce')==1
                        faceColor=[1 1 1];
                    end
                end
                timeFinal(isnan(uncenteredR))=[];
                uncenteredR(isnan(uncenteredR))=[];
                
                h(imodel)=plot(timeFinal,uncenteredR,'marker',plotMarker,...
                    'color',[plotColor(imodel,:) plotLineTrans],...
                    'linestyle','none','linewidth',plotLineWidth,...
                    'markerfacecolor',faceColor,'markersize',4);    
            end
        end
        set(gca,'ytick',-1:0.2:1,'xtick',1950:10:2030)
        set(gca,'fontsize',8);
        axis([1970 2022 -0.7 1]);
    end
end

set(gcf,'renderer','painters')
print(printName,'-r300','-dpng');



