% Dec 19, 2023
% based on .../CCR/meehl/data/plotDrift_finalPaper.m
clear; clc; close all;

% -------------------------- SPECIFY  --------------------------
printName='/glade/work/sglanvil/CCR/SST_drift/matlab_files/drift_highRes_update1';

% -------------------------- GENERAL SETUP --------------------------
gradsmap=flip([103 0 31; 178 24 43; 214 96 77; 244 165 130; 253 219 199; ...
    209 229 240; 146 197 222; 67 147 195; 33 102 172; 5 48 97]/256);
gradsmap1=interp1(1:5,gradsmap(1:5,:),linspace(1,5,12));
gradsmap2=interp1(6:10,gradsmap(6:10,:),linspace(6,10,12));
gradsmap=[gradsmap1; gradsmap2];
load('/glade/work/sglanvil/CCR/SST_drift/matlab_files/coast.mat');
latCoast=lat;
lonCoast=long;
lonCoast(lonCoast<0)=lonCoast(lonCoast<0)+360;
lonCoast(lonCoast<1 & lonCoast>-1)=NaN;
filLand='/glade/work/sglanvil/CCR/SST_drift/matlab_files/T42land.nc';
land=ncread(filLand,'landfrac');
fil='/glade/work/sglanvil/CCR/SST_drift/matlab_files/T42.gw.nc';
lon=ncread(fil,'lon');
lat=ncread(fil,'lat');

% -------------------------- OBSERVATIONS NEW --------------------------
fil='/glade/work/sglanvil/CCR/SST_drift/matlab_files/HadISST_sst.nc';
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

% -------------------------- E3SM-HR Kirtman --------------------------
% original /glade/campaign/cgd/ccr/nanr/E3SM/HR-E3SMv1
fil='/glade/work/sglanvil/CCR/meehl/kirtmanHighRes/TS_e3smHR_bruteforce_EM_ALL.nc';
raw=ncread(fil,'TS');
lon0=ncread(fil,'lon');
lat0=ncread(fil,'lat');
[x,y]=meshgrid(lon0,lat0);
[xNew,yNew]=meshgrid(lon,lat);
varMonthly_E3SMHR=NaN(length(lon),length(lat),24,size(raw,4));
varYearly_E3SMHR=NaN(length(lon),length(lat),24/2,size(raw,4));
for init=1:size(raw,4)
    for itime=1:size(raw,3)
        varMonthly_E3SMHR(:,:,itime,init)=interp2(x,y,squeeze(raw(:,:,itime,init))',...
            xNew,yNew,'linear',1)'; 
    end
    for iyear=1:size(raw,3)/12
        varYearly_E3SMHR(:,:,iyear,init)=mean(varMonthly_E3SMHR(:,:,...
            (iyear-1)*12+1:(iyear-1)*12+12,init),3,'omitnan');
    end
end

% -------------------------- CESM-HR Kirtman Years --------------------------
% 1990, 2000, 2010, and 2016 (4 initializations total) 62 month lengths
fil='/glade/work/sglanvil/CCR/meehl/cesmHighRes/kirtmanYears/b.e13.BDP-HR.ne120_t12.EM.cam.h0.TS.ALLkirtmanYears.nc'; 
raw=ncread(fil,'TS',[1 1 1],[Inf 24 Inf]);
lon0=ncread(fil,'lon',[1 1],[Inf 1]);
lat0=ncread(fil,'lat',[1 1],[Inf 1]);
varMonthly_CESMHR=NaN(length(lon),length(lat),24,size(raw,3));
varYearly_CESMHR=NaN(length(lon),length(lat),24/2,size(raw,3));
for init=1:size(raw,3)
    init
    for itime=1:size(raw,2)
        varMonthly_CESMHR(:,:,itime,init)=griddata(lon0,lat0,...
            squeeze(raw(:,itime,init)),xNew,yNew,'linear')';
    end
    for iyear=1:size(raw,2)/12
        varYearly_CESMHR(:,:,iyear,init)=mean(varMonthly_CESMHR(:,:,...
            (iyear-1)*12+1:(iyear-1)*12+12,init),3,'omitnan');
    end
end

% -------------------------- CESM-HR ALL Years --------------------------
% 1982-2018 (19 initializations total) 62 month lengths
% fil='/glade/work/sglanvil/CCR/meehl/cesmHighRes/b.e13.BDP-HR.ne120_t12.EM.cam.h0.TS.ALL.nc'; 
% raw=ncread(fil,'TS',[1 1 1],[Inf 24 Inf]);
% lon0=ncread(fil,'lon',[1 1],[Inf 1]);
% lat0=ncread(fil,'lat',[1 1],[Inf 1]);
% varMonthly_CESMHR=NaN(length(lon),length(lat),24,size(raw,3));
% varYearly_CESMHR=NaN(length(lon),length(lat),24/2,size(raw,3));
% for init=1:size(raw,3)
%     init
%     for itime=1:size(raw,2)
%         varMonthly_CESMHR(:,:,itime,init)=griddata(lon0,lat0,...
%             squeeze(raw(:,itime,init)),xNew,yNew,'linear')';
%     end
%     for iyear=1:size(raw,2)/12
%         varYearly_CESMHR(:,:,iyear,init)=mean(varMonthly_CESMHR(:,:,...
%             (iyear-1)*12+1:(iyear-1)*12+12,init),3,'omitnan');
%     end
% end

% -------------------------- Calculate E3SM-HR Hist diff from OBS --------------------------    
% /glade/derecho/scratch/nanr/E3SMv1-HR
% ignore data before 1971, just use this case (1971-2014):
% 202101027-maint-1.0-tro.A_WCYCL20TRS_CMIP6_HR.ne120_oRRS18v3_ICG.unc12.cam.h0.*.nc
fil='/glade/work/sglanvil/CCR/meehl/E3SM_HR_HISTORICAL.cam.h0.197101-201412.nc';
t1=datetime('15/Jan/1971');
t2=datetime('15/Dec/2014');
monthHIST=t1:t2;
monthHIST=monthHIST(day(monthHIST)==15); % datetime monthly option
startInx=find(monthHIST==datetime('15-Jan-1984')); % inx to begin the ncread
raw=double(ncread(fil,'TS',[1 startInx],[Inf Inf]));
lon0=ncread(fil,'lon');
lat0=ncread(fil,'lat');
varYearly0_E3SMhist=NaN(size(raw,1),size(raw,2)/12);
varYearly_E3SMhist=NaN(length(lon),length(lat),size(raw,2)/12);
% ---> make yearly average first (efficiecy; we don't need the monthly)
for iyear=1:size(raw,2)/12
    iyear
    varYearly0_E3SMhist(:,iyear)=mean(raw(:,...
        (iyear-1)*12+1:(iyear-1)*12+12),2,'omitnan');
end
% ---> now griddata
for iyear=1:size(raw,2)/12
    iyear
    varYearly_E3SMhist(:,:,iyear)=griddata(lon0,lat0,...
        squeeze(varYearly0_E3SMhist(:,iyear)),xNew,yNew,'linear')';
end

% -------------------------- Calculate CESM-HR Hist diff from OBS --------------------------    
fil='/glade/campaign/collections/cmip/CMIP6/CESM-HR/HighResMIP/B1950TR/HR/B.E.13.B1950TRC5.ne120_t12.cesm-ihesp-1950-2014.013/atm/proc/tseries/month_1/B.E.13.B1950TRC5.ne120_t12.cesm-ihesp-1950-2014.013.cam.h0.TS.195001-201412.nc';
t1=datetime('15/Jan/1950');
t2=datetime('15/Dec/2014');
monthHIST=t1:t2;
monthHIST=monthHIST(day(monthHIST)==15); % datetime monthly option
startInx=find(monthHIST==datetime('15-Jan-1984')); % inx to begin the ncread
raw=double(ncread(fil,'TS',[1 startInx],[Inf Inf]));
lon0=ncread(fil,'lon');
lat0=ncread(fil,'lat');
varYearly0_CESMhist=NaN(size(raw,1),size(raw,2)/12);
varYearly_CESMhist=NaN(length(lon),length(lat),size(raw,2)/12);
% ---> make yearly average first (efficiecy; we don't need the monthly)
for iyear=1:size(raw,2)/12
    iyear
    varYearly0_CESMhist(:,iyear)=mean(raw(:,...
        (iyear-1)*12+1:(iyear-1)*12+12),2,'omitnan');
end
% ---> now griddata
for iyear=1:size(raw,2)/12
    iyear
    varYearly_CESMhist(:,:,iyear)=griddata(lon0,lat0,...
        squeeze(varYearly0_CESMhist(:,iyear)),xNew,yNew,'linear')';
end

%%

close all;
figure
panelLetter={'a','b','c','e','f','g','d','h'};
iletter=0;
for imodel=1:2
    % -------------------------- FIND COINCIDING TIMESPAN --------------------------    
    if imodel==1
        initExist=[1985 1990 1995 2000 2005 2010 2015 2016 2017];
        subpos=[.20 .80 .30 .15; .20 .60 .30 .15; .20 .40 .30 .15];   
        titleName="E3SM-HR (9 init)";
        modelName="E3SM";
        varMonthly=varMonthly_E3SMHR;
        varYearly=varYearly_E3SMHR;
    elseif imodel==2
        initExist=[1990 2000 2010 2016];
        titleName="CESM-HR (4 init, coincide E3SM)";
%         initExist=1982:2:2018;
%         titleName='CESM-HR (19 init)';
        subpos=[.55 .80 .30 .15; .55 .60 .30 .15; .55 .40 .30 .15];  
        modelName="CESM";
        varMonthly=varMonthly_CESMHR;
        varYearly=varYearly_CESMHR;
    end
    clear inx_month1 inx_year1 inx_year2 
    for i=1:length(initExist)
        inx_month1(i)=find(monthOBS==datetime(sprintf('15-Nov-%.4d',initExist(i))));
        inx_year1(i)=find(yearOBS==initExist(i)+1);
        inx_year2(i)=find(yearOBS==initExist(i)+2);
    end
    % -------------------------- DIFFERENCE --------------------------    
    diff_month1=mean(varMonthly(:,:,1,:),4,'omitnan')-mean(varMonthlyOBS(:,:,inx_month1),3,'omitnan');
    diff_year1=mean(varYearly(:,:,1,:),4,'omitnan')-mean(varYearlyOBS(:,:,inx_year1),3,'omitnan');
    diff_year2=mean(varYearly(:,:,2,:),4,'omitnan')-mean(varYearlyOBS(:,:,inx_year2),3,'omitnan');
    % -------------------------- PLOT --------------------------
    typeTitle={'month 1','year 1','year 2'};  
    type=["month1","year1","year2"];  
    for itype=1:3
        diff=eval(sprintf('diff_%s',type{itype}));
        diff(land>0.5)=NaN;
        diff(diff<-3)=-3;
        diff(diff>3)=3;

        % RMSE 60S-60N
        rmse=sqrt(mean((diff).^2,3,'omitnan'));
        rmse_60Sto60N=(rmse(:,lat>-60 & lat<60)); 
        lat_60Sto60N=lat(lat>-60 & lat<60);
        rmseZM_60Sto60N=squeeze(mean(rmse_60Sto60N,1,'omitnan'))';
        rmseCOS_60Sto60N_cosine=squeeze(sum(rmseZM_60Sto60N.*cosd(lat_60Sto60N),'omitnan')./...
            sum(cosd(lat_60Sto60N),'omitnan')); 
        rmse_out=sprintf('%.2f',rmseCOS_60Sto60N_cosine);

        % Global avg of anomalies (map)
        diff_90Sto90N=(diff(:,lat>-90 & lat<90)); 
        lat_90Sto90N=lat(lat>-90 & lat<90);
        avgZM_90Sto90N=squeeze(mean(diff_90Sto90N,1,'omitnan'))';
        avgCOS_90Sto69N_cosine=squeeze(sum(avgZM_90Sto90N.*cosd(lat_90Sto90N),'omitnan')./...
            sum(cosd(lat_90Sto90N),'omitnan')); 
        disp(modelName+" "+type{itype}+" "+avgCOS_90Sto69N_cosine)
        
        subplot('position',subpos(itype,:))
        hold on; box on;
        rectangle('Position',[0 -90 360 180],'FaceColor',[.8 .8 .8])
        contourf(lon,lat,diff',-3:0.25:3,'linestyle','none')
        colormap(gradsmap); clim([-3 3]);
        plot(lonCoast,latCoast,'k','linewidth',1);
        set(gca,'ytick',-90:30:90,'yticklabel',[]);
        set(gca,'xtick',0:90:360,'xticklabel',{'0' '90E' '180' '90W' '0'});
        axis([0 360 -60 90]);

        f=[1 2 3 4];
        v=[8 62; 50 62; 50 85; 8 85];
        patch('Faces',f,'Vertices',v,'FaceColor','white')
        text(0.03,0.90,rmse_out,'Units','normalized','fontsize',8,'fontweight','bold')

        iletter=iletter+1;
        f=[1 2 3 4];
        v=[325 60; 350 60; 350 85; 325 85];
        patch('Faces',f,'Vertices',v,'FaceColor','white')
        text(0.94,0.90,['(',panelLetter{iletter},')'],'Units','normalized',...
            'fontsize',8,'fontweight','bold','HorizontalAlignment','center');

        if imodel==1
            set(gca,'ytick',-90:30:90,'yticklabel',{'90S' '60S' '30S' '0' '30N' '60N' '90N'});
            ylabel(typeTitle{itype},'fontweight','bold','fontsize',10);
        end
        if itype==1
            title(titleName)
        end
        set(gca,'fontsize',12);
    end
end



% -------------------------- plot E3SM Hist Diff --------------------------
diff=mean(varYearly_E3SMhist(:,:,:),3,'omitnan')-...
    mean(varYearlyOBS(:,:,yearOBS>1984 & yearOBS<2014),3,'omitnan');
diff(land>0.5)=NaN;
diff(diff<-3)=-3;
diff(diff>3)=3;
% RMSE 60S-60N
rmse=sqrt(mean((diff).^2,3,'omitnan'));
rmse_60Sto60N=(rmse(:,lat>-60 & lat<60)); 
lat_60Sto60N=lat(lat>-60 & lat<60);
rmseZM_60Sto60N=squeeze(mean(rmse_60Sto60N,1,'omitnan'))';
rmseCOS_60Sto60N_cosine=squeeze(sum(rmseZM_60Sto60N.*cosd(lat_60Sto60N),'omitnan')./...
    sum(cosd(lat_60Sto60N),'omitnan')); 
rmse_E3SMhist=sprintf('%.2f',rmseCOS_60Sto60N_cosine);
% Global avg of anomalies (map)
diff_90Sto90N=(diff(:,lat>-90 & lat<90)); 
lat_90Sto90N=lat(lat>-90 & lat<90);
avgZM_90Sto90N=squeeze(mean(diff_90Sto90N,1,'omitnan'))';
avgCOS_90Sto69N_cosine=squeeze(sum(avgZM_90Sto90N.*cosd(lat_90Sto90N),'omitnan')./...
    sum(cosd(lat_90Sto90N),'omitnan')); 
disp(" ")
disp("E3SM Hist "+avgCOS_90Sto69N_cosine)
disp(" ")
subplot('position',[.20 .15 .30 .15])
    hold on; box on;
    rectangle('Position',[0 -90 360 180],'FaceColor',[.8 .8 .8])
    contourf(lon,lat,diff',-3:0.25:3,'linestyle','none');
    colormap(gradsmap); clim([-3 3]);
    plot(lonCoast,latCoast,'k','linewidth',1);
    set(gca,'ytick',-90:30:90,'yticklabel',{'90S' '60S' '30S' '0' '30N' '60N' '90N'});
    set(gca,'xtick',0:90:360,'xticklabel',{'0' '90E' '180' '90W' '0'});
    axis([0 360 -60 90]);

    f=[1 2 3 4];
    v=[8 62; 50 62; 50 85; 8 85];
    patch('Faces',f,'Vertices',v,'FaceColor','white');
    text(0.03,0.90,rmse_E3SMhist,'Units','normalized','fontsize',8,'fontweight','bold');

    iletter=iletter+1;
    f=[1 2 3 4];
    v=[325 60; 350 60; 350 85; 325 85];
    patch('Faces',f,'Vertices',v,'FaceColor','white')
    text(0.94,0.90,['(',panelLetter{iletter},')'],'Units','normalized',...
        'fontsize',8,'fontweight','bold','HorizontalAlignment','center');

    ylabel('LE error','fontweight','bold','fontsize',10);
    title('E3SM-HR Historical')
    set(gca,'fontsize',12);



% -------------------------- plot CESM Hist Diff --------------------------
diff=mean(varYearly_CESMhist(:,:,:),3,'omitnan')-...
    mean(varYearlyOBS(:,:,yearOBS>1984 & yearOBS<2014),3,'omitnan');
diff(land>0.5)=NaN;
diff(diff<-3)=-3;
diff(diff>3)=3;
% RMSE 60S-60N
rmse=sqrt(mean((diff).^2,3,'omitnan'));
rmse_60Sto60N=(rmse(:,lat>-60 & lat<60)); 
lat_60Sto60N=lat(lat>-60 & lat<60);
rmseZM_60Sto60N=squeeze(mean(rmse_60Sto60N,1,'omitnan'))';
rmseCOS_60Sto60N_cosine=squeeze(sum(rmseZM_60Sto60N.*cosd(lat_60Sto60N),'omitnan')./...
    sum(cosd(lat_60Sto60N),'omitnan')); 
rmse_CESMhist=sprintf('%.2f',rmseCOS_60Sto60N_cosine);
% Global avg of anomalies (map)
diff_90Sto90N=(diff(:,lat>-90 & lat<90)); 
lat_90Sto90N=lat(lat>-90 & lat<90);
avgZM_90Sto90N=squeeze(mean(diff_90Sto90N,1,'omitnan'))';
avgCOS_90Sto69N_cosine=squeeze(sum(avgZM_90Sto90N.*cosd(lat_90Sto90N),'omitnan')./...
    sum(cosd(lat_90Sto90N),'omitnan')); 
disp(" ")
disp("CESM Hist "+avgCOS_90Sto69N_cosine)
disp(" ")
subplot('position',[.55 .15 .30 .15])
    hold on; box on;
    rectangle('Position',[0 -90 360 180],'FaceColor',[.8 .8 .8])
    contourf(lon,lat,diff',-3:0.25:3,'linestyle','none');
    colormap(gradsmap); clim([-3 3]);
    plot(lonCoast,latCoast,'k','linewidth',1);
    set(gca,'ytick',-90:30:90,'yticklabel',[]);
    set(gca,'xtick',0:90:360,'xticklabel',{'0' '90E' '180' '90W' '0'});
    axis([0 360 -60 90]);

    f=[1 2 3 4];
    v=[8 62; 50 62; 50 85; 8 85];
    patch('Faces',f,'Vertices',v,'FaceColor','white');
    text(0.03,0.90,rmse_CESMhist,'Units','normalized','fontsize',8,'fontweight','bold');

    iletter=iletter+1;
    f=[1 2 3 4];
    v=[325 60; 350 60; 350 85; 325 85];
    patch('Faces',f,'Vertices',v,'FaceColor','white')
    text(0.94,0.90,['(',panelLetter{iletter},')'],'Units','normalized',...
        'fontsize',8,'fontweight','bold','HorizontalAlignment','center');

    ylabel('LE error','fontweight','bold','fontsize',10);
    title('CESM-HR Historical')
    set(gca,'fontsize',12);




colorbar('location','southoutside','position',[0.27 0.04 0.5 0.02],'fontsize',8);
set(gcf,'renderer','painters')
print(printName,'-r300','-dpng');

