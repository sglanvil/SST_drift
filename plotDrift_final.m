% June 15, 2021
clear; clc; close all;

% new: /glade/work/sglanvil/CCR/SST_drift
% old: /glade/work/sglanvil/CCR/meehl

% ncar last init = Nov 2017
% kirtman last init = Nov 2018

% files on cheyenne: 
% /glade/work/sglanvil/CCR/meehl/kirtman
% /glade/work/sglanvil/CCR/meehl/DPLE_CESM1_FOSI/kirtmanYears
% CESM1 FOSI (DPLE) originally called: /glade/work/sglanvil/CCR/meehl/DPLE_CESM1_FOSI/b.e11.BDP.f09_g16.5YEAR-11.EM.cam.h0.TS.198511-201012.nc
% see scritps in that directory or slightly above

% -------------------------- SPECIFY  --------------------------
dateBegin=datetime('15/Nov/1985');
dateEnd=datetime('15/Oct/2005');
printName='drift_cesm1_e3sm_kirtmanFix_HadISST';

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
raw(raw<0)=NaN; % --- why are there NEGATIVE sst (Kelvin) values?!
[lon0sorted,inx]=sort(lon0); % --- deal with some neg lon issues
raw=raw(inx,:,:); % --- deal with some neg lon issues
lon0=lon0(inx); % --- deal with some neg lon issues
t1=datetime('15/Jan/1870');
t2=datetime('15/Dec/2021');
timeOBS=t1:t2;
timeOBS=timeOBS(day(timeOBS)==15); % datetime monthly option
[x,y]=meshgrid(lon0,lat0);
[xNew,yNew]=meshgrid(lon,lat);
clear rawNew
for itime=1:size(raw,3)
    rawNew(:,:,itime)=interp2(x,y,squeeze(raw(:,:,itime))',...
        xNew,yNew,'linear',1)'; 
end
varMonthlyOBS=rawNew;
varMonthlyOBS=varMonthlyOBS(:,:,find(timeOBS==dateBegin):find(timeOBS==dateEnd));
clear varYearlyOBS
for iyear=1:size(varMonthlyOBS,3)/12
    varYearlyOBS(:,:,iyear)=nanmean(varMonthlyOBS(:,:,(iyear-1)*12+1:(iyear-1)*12+12),3);
end



figure;
% -------------------------- FORECAST --------------------------
modelTitle={'CESM1 bruteforce','E3SM bruteforce','CESM1 FOSI','E3SM FOSI'};
model={'cesm1_bruteforce','e3sm_bruteforce','cesm1_fosi','e3sm_fosi'};
for imodel=1:4
    fil=sprintf('ts_%s_EM_ALL.nc',model{imodel});
    raw=ncread(fil,'TS');
    raw=raw(:,:,1:60,:); % kirtman=60 vs ncar=122 (just choose first 60)
    
% initAll=[1985 1990 1995 2000 2005 2010 2015 2016 2017];
% kirtman is adding inits as we go (maybe up to 2018)
% ncar only has through 2017

    lon0=ncread(fil,'lon');
    lat0=ncread(fil,'lat');
    [x,y]=meshgrid(lon0,lat0);
    [xNew,yNew]=meshgrid(lon,lat);
    for init=1:size(raw,4) % use as many inits as you can
        for itime=1:size(raw,3)
            varMonthly(:,:,itime,init)=interp2(x,y,squeeze(raw(:,:,itime,init))',...
                xNew,yNew,'linear',1)'; 
        end
        for iyear=1:size(raw,3)/12
            varYearly(:,:,iyear,init)=nanmean(varMonthly(:,:,...
                (iyear-1)*12+1:(iyear-1)*12+12,init),3);
        end
    end
    
    % -------------------------- DIFFERENCE --------------------------
    diff_month1=nanmean(varMonthly(:,:,1,:),4)-nanmean(varMonthlyOBS(:,:,1:5*12:end),3);
    diff_year1=nanmean(varYearly(:,:,1,:),4)-nanmean(varYearlyOBS(:,:,1:5:end),3);
    diff_year3=nanmean(varYearly(:,:,3,:),4)-nanmean(varYearlyOBS(:,:,3:5:end),3);
    diff_year5=nanmean(varYearly(:,:,5,:),4)-nanmean(varYearlyOBS(:,:,5:5:end),3);

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
                            
        subplot('position',squeeze(subpos(itype,:,imodel)))
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
        if imodel==1
            ylabel(typeTitle{itype},'fontweight','bold','fontsize',10);
        end
        if itype==1
            title(modelTitle{imodel},'fontsize',12);
        end
    end
end
sgtitle('Ensemble Mean Forecast - Observations (1985-2005, 4 initializations)');
cb=colorbar('location','southoutside','position',[0.25 0.04 0.5 0.02],'fontsize',10);
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