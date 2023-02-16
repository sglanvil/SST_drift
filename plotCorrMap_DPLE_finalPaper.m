% February 15, 2023
clear; clc; close all;

printName='corrMap_TS_DPLE_multipanel';
cd('/glade/work/sglanvil/CCR/SST_drift/matlab_files/')
load('varYearlyOut_cesm1_fosi_full_TS_NEW.mat'); % ---------------- SPECIFY
load('/glade/work/sglanvil/CCR/SST_drift/matlab_files/diffOut_diff.mat');
% average of year3 & year5, cesm_fosi (aka DPLE)
% format: diff_save{itype,imodel} where {3:4,3}={year3:year5,cesm_fosi}
cesm1fosi=(diff_save{3,3}+diff_save{4,3})/2;

% -------------------------- GENERAL SETUP --------------------------
gradsmap=flip([103 0 31; 178 24 43; 214 96 77; 244 165 130; 253 219 199; ...
    209 229 240; 146 197 222; 67 147 195; 33 102 172; 5 48 97]/256);
gradsmap1=interp1(1:5,gradsmap(1:5,:),linspace(1,5,10));
gradsmap2=interp1(6:10,gradsmap(6:10,:),linspace(6,10,10));
gradsmap=[gradsmap1; gradsmap2];
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

methodAnomList={'15yr','total'};
methodRefList={'hindcast','LE'};
leadStartList=[3 3];
leadMidList=[4 5];
leadEndList=[5 7];
panelLetter={'a','b','c','d','e','f','g','h'};
subpos=[.07 .60 .22 .20; ...
        .30 .60 .22 .20; ...
        .07 .30 .22 .20; ...
        .30 .30 .22 .20; ...
        .53 .60 .22 .20; ...
        .76 .60 .22 .20; ...
        .53 .30 .22 .20; ...
        .76 .30 .22 .20];

figure;
icounter=0;
for imethodAnom=1:2
    methodAnom=methodAnomList{imethodAnom};
    for imethodRef=1:2
        methodRef=methodRefList{imethodRef};
        for ilead=1:2
            leadStart=leadStartList(ilead);
            leadMid=leadMidList(ilead);
            leadEnd=leadEndList(ilead);
            % -------------------------- GENERAL SETUP --------------------------
            icounter=icounter+1;
            subplot('position',subpos(icounter,:))
            hold on; box on;
            rectangle('Position',[0 -90 360 180],'FaceColor',[.8 .8 .8]);

            % -------------------------- FORECAST --------------------------
            imodel=1; imember=41;
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
            if strcmp(methodRef,'hindcast')==1
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
            if strcmp(methodAnom,'total')==1
                xfinal=anom_clim_model;
                yfinal=anom_clim_obs;
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

            ACC_area=ACC(lon>100 & lon<280,lat>-40 & lat<70);
            lat_area=lat(lat>-40 & lat<70);
            ACCzm_area=squeeze(nanmean(ACC_area,1))';
            ACCzm_area_cosine=squeeze(nansum(ACCzm_area.*cosd(lat_area))./nansum(cosd(lat_area))); 
            ACC_out=sprintf('%.2f',ACCzm_area_cosine);
          
            contourf(lon,lat,ACC',-1:0.1:1,'linestyle','none');
            plot(lonCoast,latCoast,'k','linewidth',1);
            colormap(gradsmap); clim([-1 1]);

            f=[1 2 3 4];
            v=[104 52; 136 52; 136 65; 104 65];
            patch('Faces',f,'Vertices',v,'FaceColor','white')
            text(0.03,0.90,ACC_out,'Units','normalized','fontsize',8,'fontweight','bold')

            set(gca,'ytick',-80:20:80,'yticklabel',[]);
            set(gca,'xtick',0:30:360,'xticklabel',...
                {'0' '30E' '60E' '90E' '120E' '150E' '180' '150W' '120W' '90W' '60W' '30W' '0'});
            if icounter==1
                ylabel('Ref Clim: hindcast','fontweight','bold');
            end
            if icounter==3
                ylabel('Ref Clim: LE','fontweight','bold');
            end
            if icounter==1 || icounter==3
                set(gca,'ytick',-80:20:80,'yticklabel',{'80S' '60S' '40S' '20S' '0' '20N' '40N' '60N' '80N'});
            end
            if icounter==1 || icounter==5
                title('Lead: 3-5yr')
            end
            if icounter==2 || icounter==6
                title('Lead: 3-7yr')
            end

            % Testing the subplot data
            % text(130,0,sprintf('%.1d-%.1d, %s, %s',leadStart,leadEnd,methodRef,methodAnom));

            set(gca,'fontsize',8);
            axis([100 280 -40 70]);
            set(gca,'layer','top')
        end
    end

end

annotation('textbox',[.07 .85 .45 .05],'string','\bfAnom: 15yr',...
    'edgecolor','black','horizontalalignment','center',...
    'verticalalignment','middle','fontsize',12);

annotation('textbox',[.53 .85 .45 .05],'string','\bfAnom: total',...
    'edgecolor','black','horizontalalignment','center',...
    'verticalalignment','middle','fontsize',12);


hc=colorbar('location','southoutside','position',[0.30 0.20 0.45 0.02]);
set(gcf,'renderer','painters')
print(printName,'-r300','-dpng');




