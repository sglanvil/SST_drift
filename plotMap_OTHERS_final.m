% October 24, 2022
clear; clc; close all;

cd('/glade/work/sglanvil/CCR/SST_drift/matlab_files/')

% -------------------------- SPECIFY  --------------------------
methodAnom='clim'; % 'persist' or '15yr' or 'clim'
methodRef='LEadjusted'; % 'itself' or 'LE' or 'LEadjusted'
leadStart=3;
leadMid=4;
leadEnd=5;

initYear=2005;

printName=sprintf('TS_map_init%.4d_cesm1_e3sm_%s_%s_%.1dto%.1dyr',...
    initYear,methodRef,methodAnom,leadStart,leadEnd);

% -------------------------- GENERAL SETUP --------------------------
gradsmap=flip([103 0 31; 178 24 43; 214 96 77; 244 165 130; 253 219 199; ...
    209 229 240; 146 197 222; 67 147 195; 33 102 172; 5 48 97]/256);
% gradsmap=flip([165 0 38; 215 48 39; 244 109 67; 253 174 97; 254 224 144; ...
%     224 243 248; 171 217 233; 116 173 209; 69 117 180; 49 54 149]/256);
gradsmap1=interp1(1:5,gradsmap(1:5,:),linspace(1,5,10));
gradsmap2=interp1(6:10,gradsmap(6:10,:),linspace(6,10,10));
gradsmap=[gradsmap1; gradsmap2];


load('/glade/work/sglanvil/CCR/SST_drift/matlab_files/coast.mat');
latCoast=lat;
lonCoast=long;
lonCoast(lonCoast<0)=lonCoast(lonCoast<0)+360;
lonCoast(lonCoast<1 & lonCoast>-1)=NaN;

load('varYearlyOut_cesm1_e3sm_TS.mat');
gw=ncread('T42.gw.nc','gw');
gw=repmat(gw',length(lon),1);

load('/glade/work/sglanvil/CCR/SST_drift/matlab_files/diffOut_diff.mat');
% average of year3 & year5, cesm_fosi (aka DPLE)
% format: diff_save{itype,imodel} where {3:4,3}={year3:year5,cesm_fosi}
cesmbrute=(diff_save{3,1}+diff_save{4,1})/2; % average of year3 & year5
e3smbrute=(diff_save{3,2}+diff_save{4,2})/2;
cesmfosi=(diff_save{3,3}+diff_save{4,3})/2;
e3smfosi=(diff_save{3,4}+diff_save{4,4})/2;

% -------------------------- FORECAST --------------------------
imember=4; % ensemble mean
for imodel=1:4
    
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
    if contains(nameModel,'cesm')==1 && contains(nameModel,'fosi')==1
        LEadjust=cesmfosi;
        nameNice='cesm fosi';
    end
    if contains(nameModel,'cesm')==1 && contains(nameModel,'bruteforce')==1
        LEadjust=cesmbrute;
        nameNice='cesm bruteforce';
    end
    if contains(nameModel,'e3sm')==1 && contains(nameModel,'fosi')==1
        LEadjust=e3smfosi;
        nameNice='e3sm fosi';
    end
    if contains(nameModel,'e3sm')==1 && contains(nameModel,'bruteforce')==1
        LEadjust=e3smbrute;
        nameNice='e3sm bruteforce';
    end

    timeWant=1960:2020;
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

    if strcmp(methodRef,'itself')==1
        dataRef=dataModel;
    end
    if strcmp(methodRef,'LE')==1
        dataRef=dataLE;
    end
    if strcmp(methodRef,'LEadjusted')==1
        dataRef=dataLE+LEadjust;
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
    if strcmp(methodAnom,'clim')==1
        xfinal=anom_clim_model;
        yfinal=anom_clim_obs;
    end

    init_inx=find(timeModel==initYear);

    xMap=xfinal(lon>100 & lon<280,lat>-40 & lat<70,init_inx);
    yMap=yfinal(lon>100 & lon<280,lat>-40 & lat<70,init_inx);
    a=nansum(nansum(xMap.*yMap.*gw(lon>100 & lon<280,lat>-40 & lat<70)));
    b=sqrt(nansum(nansum((xMap.^2).*gw(lon>100 & lon<280,lat>-40 & lat<70))));
    c=sqrt(nansum(nansum((yMap.^2).*gw(lon>100 & lon<280,lat>-40 & lat<70))));
    uncenteredR=a/(b*c);   

    v=-1:0.1:1;
    subplot(3,2,imodel);
        hold on; grid on; box on;
        contourf(lon,lat,squeeze(xfinal(:,:,init_inx))',v,'linestyle','none')
        plot(lonCoast,latCoast,'k','linewidth',1);
        colormap(gradsmap); caxis([-1 1]);
        title(sprintf('%s (R=%.2f)',nameNice,uncenteredR));
        axis([100 360 -40 70])    
end
subplot(3,2,6);
        hold on; grid on; box on;
        contourf(lon,lat,squeeze(yfinal(:,:,init_inx))',v,'linestyle','none')
        plot(lonCoast,latCoast,'k','linewidth',1);
        colormap(gradsmap); caxis([-1 1]);
        title('Observations');
        axis([100 360 -40 70])   
        
annotation('textbox',[.12 .2 .5 .1],'string',sprintf('TS "anom\\_%s" for init=%.4d',methodAnom,initYear),...
    'edgecolor','none','verticalalignment','bottom','fontweight','bold','fontsize',13);
annotation('textbox',[.12 .15 .5 .1],'string',sprintf('%.1d-%.1dyr lead (%.1d-%.1d)',...
    leadStart,leadEnd,initYear+leadStart,initYear+leadEnd),...
    'edgecolor','none','verticalalignment','bottom','fontweight','bold','fontsize',13);
annotation('textbox',[.12 .1 .5 .1],'string',sprintf('Ref Climo: %s',methodRef),...
    'edgecolor','none','verticalalignment','bottom','fontweight','bold','fontsize',13);
hc=colorbar('location','southoutside','position',[0.25 0.04 0.5 0.02]);
set(hc,'xtick',-1:0.2:1);
set(gcf,'renderer','painters')

print(printName,'-r300','-dpng');
