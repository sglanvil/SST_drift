% June 15, 2021
clear; clc; close all;

% NEW: /glade/work/sglanvil/CCR/SST_drift
% OLD: /glade/work/sglanvil/CCR/meehl

% initAll=[1985 1990 1995 2000 2005 2010 2015 2016 2017];
% ncar last init = Nov 2017 (time=122)
% kirtman last init = Nov 2018 (time=60)

% 1985 = 15 (5 cesm brute, 5 e3sm brute, 5 e3sm fosi)
% 1990 = 15
% 1995 = 15
% 2000 = 15 
% --------------------------------------------------------------
% 2005 = 11 (5 cesm brute, 3 e3sm brute, 3 e3sm fosi)
% 2010 = 11
% 2015 = 11
% 2016 = 11
% 2017 = 11
% 2018 = 11

% OLD STUFF:
% /glade/work/sglanvil/CCR/meehl/kirtman
% /glade/work/sglanvil/CCR/meehl/DPLE_CESM1_FOSI/kirtmanYears
% CESM1 FOSI (DPLE) originally called: /glade/work/sglanvil/CCR/meehl/DPLE_CESM1_FOSI/b.e11.BDP.f09_g16.5YEAR-11.EM.cam.h0.TS.198511-201012.nc
% see scritps in that directory or slightly above

% -------------------------- SPECIFY  --------------------------
dateBegin=datetime('15/Nov/1985');
dateEnd=datetime('15/Oct/2020');
monthALL=dateBegin:dateEnd;
monthALL=monthALL(day(monthALL)==15); % datetime monthly option
yearALL=unique(year(monthALL)); % datetime yearly option
yearALL(end)=[]; % remove that last year
% printName='drift_cesm1_e3sm_kirtmanFix_HadISST_NEW';
% printName='drift_cesm1_e3sm_kirtmanFix_HadISST_yr5fraction';

% -------------------------- GENERAL SETUP --------------------------
subpos1=[.06 .72 .20 .16; .06 .52 .20 .16; .06 .32 .20 .16; .06 .12 .20 .16];    
subpos2=[.30 .72 .20 .16; .30 .52 .20 .16; .30 .32 .20 .16; .30 .12 .20 .16];    
subpos3=[.54 .72 .20 .16; .54 .52 .20 .16; .54 .32 .20 .16; .54 .12 .20 .16];  
subpos4=[.78 .72 .20 .16; .78 .52 .20 .16; .78 .32 .20 .16; .78 .12 .20 .16];  
subpos=cat(3,subpos1,subpos2,subpos3,subpos4);
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

% -------------------------- OBSERVATIONS OLD --------------------------
% load /Users/sglanvil/Documents/CCR/meehl/SST_monthly_HADISST2_1979to2010_data.mat
% t1=datetime('15/Jan/1979');
% t2=datetime('15/Dec/2010');
% timeOBS=t1:t2;
% timeOBS=timeOBS(day(timeOBS)==15); % datetime monthly option
% varMonthlyOBS=sstOBS;
% varMonthlyOBS=varMonthlyOBS(:,:,find(timeOBS==dateBegin):find(timeOBS==dateEnd));
% for iyear=1:size(varMonthlyOBS,3)/12
%     varYearlyOBS(:,:,iyear)=nanmean(varMonthlyOBS(:,:,(iyear-1)*12+1:(iyear-1)*12+12),3);
% end

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
% -------------------------- FORECAST --------------------------
modelTitle={'CESM1 bruteforce','E3SM bruteforce','CESM1 FOSI','E3SM FOSI'};
model={'cesm1_bruteforce','e3sm_bruteforce','cesm1_fosi','e3sm_fosi'};
for imodel=1:4
    % ----------------------- WARNING (new directory for new data)
    % download data from glade: /glade/work/sglanvil/CCR/SST_drift/OTHERS/*EM_ALL.nc
    fil=sprintf('SST_drift_data/ts_%s_EM_ALL.nc',model{imodel});
    % fil=sprintf('ts_%s_EM_ALL.nc',model{imodel});
    raw=ncread(fil,'TS');
    raw=raw(:,:,1:60,:); % kirtman=60 vs ncar=122 (so just choose first 60)

    size(raw)
    
    lon0=ncread(fil,'lon');
    lat0=ncread(fil,'lat');
    [x,y]=meshgrid(lon0,lat0);
    [xNew,yNew]=meshgrid(lon,lat);
    clear varMonthly varYearly
    for init=1:8 % ---------------------- WARNING: choose or do size(raw,4)
        for itime=1:size(raw,3)
            varMonthly(:,:,itime,init)=interp2(x,y,squeeze(raw(:,:,itime,init))',...
                xNew,yNew,'linear',1)'; 
        end
        for iyear=1:size(raw,3)/12
            varYearly(:,:,iyear,init)=mean(varMonthly(:,:,...
                (iyear-1)*12+1:(iyear-1)*12+12,init),3,'omitnan');
        end
    end
    
    initAll=[1985 1990 1995 2000 2005 2010 2015 2016 2017];
    initExist=initAll(1:8); % --------------------- WARNING: choose
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
    for itype=1:4 % ----------------------------- Year5 Fraction? (yes or no)
        diff=eval(sprintf('diff_%s',type{itype}));
        diff_save{itype,imodel}=diff; % -------------------- SAVE

        diff(land>0.5)=NaN;
        diff(diff<-3)=-3;
        diff_year5(land>0.5)=NaN;
        diff_year5(diff_year5<-3)=-3;
        
%         diff=(diff./diff_year5)*100; % -------- Year5 Fraction? (yes or no)
%         diff(diff<0)=0;
%         diff(diff>100)=100;
%         diffzm_global=squeeze(mean(diff,1,'omitnan'))';
%         diff_global_cosine=squeeze(sum(diffzm_global.*cosd(lat),'omitnan')./...
%             sum(cosd(lat),'omitnan')); 
%         diff_avg=sprintf('%.1f',diff_global_cosine);
        
        rmse=sqrt(mean((diff).^2,3,'omitnan'));
        diff_60Sto60N=(rmse(:,lat>-60 & lat<60)); 
        lat_60Sto60N=lat(lat>-60 & lat<60);
        diffzm_60Sto60N=squeeze(mean(diff_60Sto60N,1,'omitnan'))';
        diff_60Sto60N_cosine=squeeze(sum(diffzm_60Sto60N.*cosd(lat_60Sto60N),'omitnan')./...
            sum(cosd(lat_60Sto60N),'omitnan')); 
        diff_avg=sprintf('%.2f',diff_60Sto60N_cosine);
        
        subplot('position',squeeze(subpos(itype,:,imodel)))
        hold on; box on;
        rectangle('Position',[0 -90 360 180],'FaceColor',[.8 .8 .8])
        
%         pcolor(lon,lat,diff'); shading flat;
%         colormap(cat(1,[1 1 1],gradsmap2)); caxis([0 100]);
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
        if imodel==1
            ylabel(typeTitle{itype},'fontweight','bold','fontsize',10);
        end
        if itype==1
            title(modelTitle{imodel},'fontsize',12);
        end
    end
end
sgtitle('Hindcast - Obs (inits = 1985,1990,1995,2000,2005,2010,2015,2016)');
% sgtitle('Fraction of Year 5 Drift (Hindcast-Obs)');
colorbar('location','southoutside','position',[0.25 0.04 0.5 0.02],'fontsize',10);
% colorbar('location','southoutside','position',[0.25 0.24 0.5 0.02],'fontsize',10);
set(gcf,'renderer','painters')
% print(printName,'-r300','-dpng');

% save('diffOut_cesm1_e3sm.mat','diff_save','lon','lat','land','lonCoast','latCoast');

%% -------------------------- correlations for each model --------------------------
% December 9, 2022
clear; clc; close all;
load('diffOut_cesm1_e3sm.mat'); % see: plotDrift_final.m: diff_save{itype,imodel}
model={'cesm1_bruteforce','e3sm_bruteforce','cesm1_fosi','e3sm_fosi'};
type={'month1','year1','year3','year5'};  
for itype=1:4
    [Rcesm,P]=corrcoef(diff_save{itype,1},diff_save{itype,4},'rows','pairwise');
    [Re3sm,P]=corrcoef(diff_save{itype,3},diff_save{itype,2},'rows','pairwise');
    [Rcesm(1,2) Re3sm(1,2)]
end
% Basically R=1 for both models, all leads

%% -------------------------- check sign for each model --------------------------
% December 9, 2022
clear; clc; close all;
printName='drift_cesm1_e3sm_kirtmanFix_HadISST_signTest';

subpos1=[.06 .72 .20 .16; .06 .52 .20 .16; .06 .32 .20 .16; .06 .12 .20 .16];    
subpos2=[.30 .72 .20 .16; .30 .52 .20 .16; .30 .32 .20 .16; .30 .12 .20 .16];    
subpos3=[.54 .72 .20 .16; .54 .52 .20 .16; .54 .32 .20 .16; .54 .12 .20 .16];  
subpos4=[.78 .72 .20 .16; .78 .52 .20 .16; .78 .32 .20 .16; .78 .12 .20 .16];  
subpos=cat(3,subpos1,subpos2,subpos3,subpos4);
panelLetter={'a','c','e','g','b','d','f','h'};

iletter=0;
load('diffOut_cesm1_e3sm.mat'); % see: plotDrift_final.m: diff_save{itype,imodel}
modelTitle={'CESM1','E3SMv1'};
for imodel=1:2
    typeTitle={'month 1','year 1','year 3','year 5'};  
    for itype=1:4
        A=sign(diff_save{itype,imodel});
        B=sign(diff_save{itype,imodel+2});
        C=A.*B;
        subplot('position',squeeze(subpos(itype,:,imodel+1)))
        hold on; box on;
        rectangle('Position',[0 -90 360 180],'FaceColor',[.8 .8 .8])
        pcolor(lon,lat,C'); shading flat;
        colormap([1 .3 .3; .3 .3 1]); clim([-1 1]);
        plot(lonCoast,latCoast,'k','linewidth',1);
        set(gca,'ytick',-90:30:90,'yticklabel',{'90S' '60S' '30S' '0' '30N' '60N' '90N'});
        set(gca,'xtick',0:90:360,'xticklabel',{'0' '90E' '180' '90W' '0'});

        iletter=iletter+1;
        f=[1 2 3 4];
        v=[300 60; 350 60; 350 85; 300 85];
        patch('Faces',f,'Vertices',v,'FaceColor','white')
        text(0.90,0.90,['(',panelLetter{iletter},')'],'Units','normalized',...
            'fontsize',8,'fontweight','bold','HorizontalAlignment','center');

        axis([0 360 -60 90]);        
        set(gca,'fontsize',8);
        if imodel==1
            ylabel(typeTitle{itype},'fontweight','bold','fontsize',10);
        end
        if itype==1
            title(modelTitle{imodel},'fontsize',12);
        end
    end
end
sgtitle('Bruteforce/FOSI Sign Agreement');
cb=colorbar('location','southoutside','position',[0.3 0.06 0.44 0.02],'fontsize',10);
set(cb,'ytick',-1:1,'yticklabel',{'opposite sign',' ','same sign'},'fontweight','bold');
set(gcf,'renderer','painters')
print(printName,'-r300','-dpng');
    
%% -------------------------- OBSERVATIONS --------------------------
% fil='/Users/sglanvil/Documents/CCR/hteng/data/air.2m.mon.mean.nc';
% t1=datetime('15/Jan/1948');
% t2=datetime('15/Dec/2019');
% timeOBS=t1:t2;
% timeOBS=timeOBS(day(timeOBS)==15); % datetime monthly option
% lat0=ncread(fil,'lat');
% lon0=ncread(fil,'lon');
% air=ncread(fil,'air');
% raw=air(:,:,1:12*(2019-1948+1));
% [x,y]=meshgrid(lon0,lat0);
% [xNew,yNew]=meshgrid(lon,lat);
% clear rawNew
% for itime=1:size(raw,3)
%     varMonthlyOBS(:,:,itime)=interp2(x,y,squeeze(raw(:,:,itime))',...
%         xNew,yNew,'linear',1)'; 
% end
% varMonthlyOBS=varMonthlyOBS(:,:,find(timeOBS==dateBegin):find(timeOBS==dateEnd));
% clear varOBS
% for iyear=1:size(varMonthlyOBS,3)/12
%     varYearlyOBS(:,:,iyear)=nanmean(varMonthlyOBS(:,:,(iyear-1)*12+1:(iyear-1)*12+12),3);
% end
