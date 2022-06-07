% June 7, 2022

clear; clc; close all
printName='drift_histRuns_HadISST';

% -------------------------- GENERAL SETUP --------------------------
subpos1=[.30 .72 .20 .16; .30 .52 .20 .16; .30 .32 .20 .16; .30 .12 .20 .16];    
subpos2=[.54 .72 .20 .16; .54 .52 .20 .16; .54 .32 .20 .16; .54 .12 .20 .16];  
subpos=cat(3,subpos1,subpos2);
gradsmap=flip([103 0 31; 178 24 43; 214 96 77; 244 165 130; 253 219 199; ...
    209 229 240; 146 197 222; 67 147 195; 33 102 172; 5 48 97]/256);
gradsmap1=interp1(1:5,gradsmap(1:5,:),linspace(1,5,9));
gradsmap2=interp1(6:10,gradsmap(6:10,:),linspace(6,10,9));
gradsmap=[gradsmap1; gradsmap2];
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

% -------------------------- OBSERVATIONS NEW --------------------------
fil='/Users/sglanvil/Documents/CCR/meehl/data/HadISST_sst.nc';
lon0=ncread(fil,'longitude');
lat0=ncread(fil,'latitude');
lon0(lon0<0)=lon0(lon0<0)+360;
raw=ncread(fil,'sst')+273; % ----- from Celsius to Kelvin
raw(raw<0)=NaN; % ---------------- remove negative values (probably ice flags)
[lon0sorted,inx]=sort(lon0); % --- deal with some neg lon issues
raw=raw(inx,:,:); % -------------- deal with some neg lon issues
lon0=lon0(inx); % ---------------- deal with some neg lon issues
t1=datetime('15/Jan/1870');
t2=datetime('15/Dec/2021');
monthOBS=t1:t2;
monthOBS=monthOBS(day(monthOBS)==15); % datetime monthly option
yearOBS=unique(year(monthOBS));
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

figure
% -------------------------- FORECAST --------------------------
titleMODlist={'CESM1LE','E3SMv1HIST'};
fileMODlist={'b.e11.B20TRC5CNBDRD.f09_g16.EM.cam.h0.TS.192001-200512.nc',...
    'LE_ens.FV_oECv3_ICG.EM.cam.h0.TS.185001-201511.nc'};
t1list={'15/Jan/1920','15/Jan/1850'};
t2list={'15/Dec/2005','15/Nov/2015'};
initEnd=[4 5];
for iMOD=1:2
    fileMOD=sprintf('SST_drift_data/%s',fileMODlist{iMOD});
    raw=ncread(fileMOD,'TS');
    lon0=ncread(fileMOD,'lon');
    lat0=ncread(fileMOD,'lat');
    t1=datetime(t1list{iMOD});
    t2=datetime(t2list{iMOD});
    monthMOD=t1:t2;
    monthMOD=monthMOD(day(monthMOD)==15); % datetime monthly option
    yearMOD=unique(year(monthMOD));
    [x,y]=meshgrid(lon0,lat0);
    [xNew,yNew]=meshgrid(lon,lat);
    clear varMonthlyMOD varYearlyMOD
    for itime=1:size(raw,3)
        varMonthlyMOD(:,:,itime)=interp2(x,y,squeeze(raw(:,:,itime))',...
            xNew,yNew,'linear',1)'; 
    end
    for iyear=1:size(varMonthlyMOD,3)/12
        varYearlyMOD(:,:,iyear)=nanmean(varMonthlyMOD(:,:,(iyear-1)*12+1:(iyear-1)*12+12),3);
    end

    initAll=[1985 1990 1995 2000 2005 2010 2015 2016 2017];
    initExist=initAll(1:initEnd(iMOD)); % ------------------------- WARNING
    clear inx_month1 inx_year1 inx_year3 inx_year5
    for i=1:length(initExist)
        inxOBS_month1(i)=find(monthOBS==datetime(sprintf('15-Nov-%.4d',initExist(i))));
        inxOBS_year1(i)=find(yearOBS==initExist(i)+1);
        inxOBS_year3(i)=find(yearOBS==initExist(i)+3);
        inxOBS_year5(i)=find(yearOBS==initExist(i)+5);
        inxMOD_month1(i)=find(monthMOD==datetime(sprintf('15-Nov-%.4d',initExist(i))));
        inxMOD_year1(i)=find(yearMOD==initExist(i)+1);
        inxMOD_year3(i)=find(yearMOD==initExist(i)+3);
        inxMOD_year5(i)=find(yearMOD==initExist(i)+5);    
    end
    
    % -------------------------- DIFFERENCE --------------------------    
    diff_month1=nanmean(varMonthlyMOD(:,:,inxMOD_month1),3)-...
        nanmean(varMonthlyOBS(:,:,inxOBS_month1),3);
    diff_year1=nanmean(varYearlyMOD(:,:,inxMOD_year1),3)-...
        nanmean(varYearlyOBS(:,:,inxOBS_year1),3);
    diff_year3=nanmean(varYearlyMOD(:,:,inxMOD_year3),3)-...
        nanmean(varYearlyOBS(:,:,inxOBS_year3),3);
    diff_year5=nanmean(varYearlyMOD(:,:,inxMOD_year5),3)-...
        nanmean(varYearlyOBS(:,:,inxOBS_year5),3);

    % -------------------------- PLOT --------------------------
    typeTitle={'month 1','year 1','year 3','year 5'};  
    type={'month1','year1','year3','year5'};  
    for itype=1:4
        diff=eval(sprintf('diff_%s',type{itype}));
        diff(land>0)=NaN;
        diff(diff<-3)=-3;
        
        rmse=sqrt(nanmean((diff).^2,3));

        diff_60Sto60N=(rmse(:,lat>-60 & lat<60));
        lat_60Sto60N=lat(lat>-60 & lat<60);
        diffzm_60Sto60N=squeeze(nanmean(diff_60Sto60N,1))';
        diff_60Sto60N_cosine=squeeze(nansum(diffzm_60Sto60N.*cosd(lat_60Sto60N))./nansum(cosd(lat_60Sto60N))); 
        diff_avg=sprintf('%.2f',diff_60Sto60N_cosine);
                            
        subplot('position',squeeze(subpos(itype,:,iMOD)))
        hold on; box on;
        rectangle('Position',[0 -90 360 180],'FaceColor',[.8 .8 .8])
        contourf(lon,lat,diff',-3:0.25:3,'linestyle','none')
        colormap(gradsmap); caxis([-3 3]);
        plot(lonCoast,latCoast,'k','linewidth',1);
        set(gca,'ytick',-90:30:90,'yticklabel',{'90S' '60S' '30S' '0' '30N' '60N' '90N'});
        set(gca,'xtick',0:90:360,'xticklabel',{'0' '90E' '180' '90W' '0'});
        axis([0 360 -60 90]);
        
        f=[1 2 3 4];
        v=[8 62; 68 62; 68 85; 8 85];
        patch('Faces',f,'Vertices',v,'FaceColor','white')
        text(0.03,0.90,diff_avg,'Units','normalized','fontsize',8,'fontweight','bold')
    
        set(gca,'fontsize',8);
        if iMOD==1
            ylabel(typeTitle{itype},'fontweight','bold','fontsize',10);
        end
        if itype==1
            title(titleMODlist{iMOD},'fontsize',12);
        end
    end
end
sgtitle('Forecast - Obs (inits = 1985,1990,1995,2000,2005)');
cb=colorbar('location','southoutside','position',[0.25 0.04 0.5 0.02],'fontsize',10);
set(gcf,'renderer','painters')
print(printName,'-r300','-dpng');

                 
