% March 21, 2023
% extra plot for Yeager/Meehl to see how DPLE (all year/members) differs from subset DPLE

clear; clc; close all;

printName='drift_cesm1_fosi_full_yeager';

% -------------------------- GENERAL SETUP --------------------------
subpos1=[.06 .82 .20 .14; .06 .65 .20 .14; .06 .48 .20 .14; .06 .31 .20 .14; .06 .10 .20 .14];    
subpos2=[.30 .82 .20 .14; .30 .65 .20 .14; .30 .48 .20 .14; .30 .31 .20 .14; .30 .10 .20 .14];    
subpos3=[.54 .82 .20 .14; .54 .65 .20 .14; .54 .48 .20 .14; .54 .31 .20 .14; .54 .10 .20 .14];  
subpos4=[.78 .82 .20 .14; .78 .65 .20 .14; .78 .48 .20 .14; .78 .31 .20 .14; .78 .10 .20 .14];  
subpos=cat(3,subpos1,subpos2,subpos3,subpos4);
panelLetter={'a','b','c','d'};

gradsmap=flip([103 0 31; 178 24 43; 214 96 77; 244 165 130; 253 219 199; ...
    209 229 240; 146 197 222; 67 147 195; 33 102 172; 5 48 97]/256);
gradsmap1=interp1(1:5,gradsmap(1:5,:),linspace(1,5,12));
gradsmap2=interp1(6:10,gradsmap(6:10,:),linspace(6,10,12));
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
raw=ncread(fil,'sst')+273; % --- from Celsius to Kelvin
raw(raw<0)=NaN; % --- remove negative values (probably ice flags)
[lon0sorted,inx]=sort(lon0); % --- deal with some neg lon issues
raw=raw(inx,:,:); % --- deal with some neg lon issues
lon0=lon0(inx); % --- deal with some neg lon issues
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
    varYearlyOBS(:,:,iyear)=mean(varMonthlyOBS(:,:,(iyear-1)*12+1:(iyear-1)*12+12),3,'omitnan');
end

figure;

iletter=0;
load('varMonthlyOut_cesm1_fosi_full_TS_2022.mat');
raw=raw(:,:,1:60,:); % kirtman=60 vs ncar=122 (so just choose first 60)
size(raw)
lon0=lon;
lat0=lat;
fil='/Users/sglanvil/Documents/CCR/hteng/data/T42.gw.nc';
lon=ncread(fil,'lon');
lat=ncread(fil,'lat');
[x,y]=meshgrid(lon0,lat0);
[xNew,yNew]=meshgrid(lon,lat);
clear varMonthly varYearly
for init=1:size(raw,4) % ---------------------- WARNING: choose or do size(raw,4)
    for itime=1:size(raw,3)
        varMonthly(:,:,itime,init)=interp2(x,y,squeeze(raw(:,:,itime,init))',...
            xNew,yNew,'linear',1)'; 
    end
    for iyear=1:size(raw,3)/12
        varYearly(:,:,iyear,init)=mean(varMonthly(:,:,...
            (iyear-1)*12+1:(iyear-1)*12+12,init),3,'omitnan');
    end
end

initAll=1954:2017;
initExist=initAll(initAll>=1985 & initAll<=2016); % --------------------- WARNING: choose

clear inx_month1 inx_year1 inx_year3 inx_year5
for i=1:length(initExist)
    inx_month1(i)=find(monthOBS==datetime(sprintf('15-Nov-%.4d',initExist(i))));
    inx_year1(i)=find(yearOBS==initExist(i)+1);
    inx_year3(i)=find(yearOBS==initExist(i)+3);
    inx_year5(i)=find(yearOBS==initExist(i)+5);
end

% -------------------------- DIFFERENCE --------------------------    
diff_month1=mean(varMonthly(:,:,1,:),4,'omitnan')-mean(varMonthlyOBS(:,:,inx_month1),3,'omitnan');
diff_year1=mean(varYearly(:,:,1,:),4,'omitnan')-mean(varYearlyOBS(:,:,inx_year1),3,'omitnan');
diff_year3=mean(varYearly(:,:,3,:),4,'omitnan')-mean(varYearlyOBS(:,:,inx_year3),3,'omitnan');
diff_year5=mean(varYearly(:,:,5,:),4,'omitnan')-mean(varYearlyOBS(:,:,inx_year5),3,'omitnan');

% -------------------------- PLOT --------------------------
typeTitle={'month 1','year 1','year 3','year 5'};  
type={'month1','year1','year3','year5'};  
for itype=1:4 
    diff=eval(sprintf('diff_%s',type{itype}));
    diff(land>0.5)=NaN;
    diff(diff<-3)=-3;
    diff(diff>3)=3;

    rmse=sqrt(mean((diff).^2,3,'omitnan'));
    rmse_60Sto60N=(rmse(:,lat>-60 & lat<60)); 
    lat_60Sto60N=lat(lat>-60 & lat<60);
    rmseZM_60Sto60N=squeeze(mean(rmse_60Sto60N,1,'omitnan'))';
    rmseCOS_60Sto60N_cosine=squeeze(sum(rmseZM_60Sto60N.*cosd(lat_60Sto60N),'omitnan')./...
        sum(cosd(lat_60Sto60N),'omitnan')); 
    rmse_out=sprintf('%.2f',rmseCOS_60Sto60N_cosine);
    
    subplot('position',squeeze(subpos(itype,:,3)))
    hold on; box on;
    rectangle('Position',[0 -90 360 180],'FaceColor',[.8 .8 .8])

    contourf(lon,lat,diff',-3:0.25:3,'linestyle','none')
    colormap(gradsmap); clim([-3 3]);

    plot(lonCoast,latCoast,'k','linewidth',1);
    set(gca,'ytick',-90:30:90,'yticklabel',{'90S' '60S' '30S' '0' '30N' '60N' '90N'});
    set(gca,'xtick',0:90:360,'xticklabel',{'0' '90E' '180' '90W' '0'});
    axis([0 360 -60 90]);
    
    f=[1 2 3 4];
    v=[8 62; 68 62; 68 85; 8 85];
    patch('Faces',f,'Vertices',v,'FaceColor','white')
    text(0.03,0.90,rmse_out,'Units','normalized','fontsize',8,'fontweight','bold')

    set(gca,'fontsize',8);
end

set(gcf,'renderer','painters')
print(printName,'-r300','-dpng');
