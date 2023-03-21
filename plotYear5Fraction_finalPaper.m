% June 15, 2021
clear; clc; close all;

% -------------------------- SPECIFY  --------------------------
dateBegin=datetime('15/Nov/1985');
dateEnd=datetime('15/Oct/2020');
monthALL=dateBegin:dateEnd;
monthALL=monthALL(day(monthALL)==15); % datetime monthly option
yearALL=unique(year(monthALL)); % datetime yearly option
yearALL(end)=[]; % remove that last year
printName='drift_cesm1_e3sm_kirtmanFix_HadISST_yr5fraction';

% -------------------------- GENERAL SETUP --------------------------
subpos1=[.06 .82 .20 .14; .06 .65 .20 .14; .06 .48 .20 .14; .06 .31 .20 .14; .06 .27 .20 .14];    
subpos2=[.30 .82 .20 .14; .30 .65 .20 .14; .30 .48 .20 .14; .30 .31 .20 .14; .30 .27 .20 .14];    
subpos3=[.54 .82 .20 .14; .54 .65 .20 .14; .54 .48 .20 .14; .54 .31 .20 .14; .54 .27 .20 .14];  
subpos4=[.78 .82 .20 .14; .78 .65 .20 .14; .78 .48 .20 .14; .78 .31 .20 .14; .78 .27 .20 .14];  
subpos=cat(3,subpos1,subpos2,subpos3,subpos4);
panelLetter={'a','e','i','b','f','j','c','g','k','d','h','l','m','n','o','p'};

gradsmap=flip([103 0 31; 178 24 43; 214 96 77; 244 165 130; 253 219 199; ...
    209 229 240; 146 197 222; 67 147 195; 33 102 172; 5 48 97]/256);
gradsmap1=interp1(1:5,gradsmap(1:5,:),linspace(1,5,10));
gradsmap2=interp1(6:10,gradsmap(6:10,:),linspace(6,10,10));
% gradsmap=[gradsmap1; gradsmap2];
gradsmap=[gradsmap2];
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


iletter=0;
figure;
% -------------------------- FORECAST --------------------------
modelTitle={'CESM1 Bruteforce','E3SMv1 Bruteforce','CESM1 FOSI','E3SMv1 FOSI'};
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
    typeTitle={'month1/year5','year1/year5','year3/year5','year5/year5'};  
    type={'month1','year1','year3','year5'};  
    for itype=1:3
        diff=eval(sprintf('diff_%s',type{itype}));

        diff(land>0.5)=NaN;
        diff(diff<-3)=-3;
        diff(diff>3)=3;

        diff_year5(land>0.5)=NaN;
        diff_year5(diff_year5<-3)=-3;
        diff_year5(diff_year5>3)=3;

        diff=(diff./diff_year5)*100; 
        diff(diff<0)=NaN;
        diff(diff>100)=100;
        avgZM_global=squeeze(mean(diff,1,'omitnan'))';
        avgCOS_global=squeeze(sum(avgZM_global.*cosd(lat),'omitnan')./...
            sum(cosd(lat),'omitnan')); 
        avg_out=sprintf('%.1f',avgCOS_global);

        subplot('position',squeeze(subpos(itype,:,imodel)))
        hold on; box on;
        rectangle('Position',[0 -90 360 180],'FaceColor',[.8 .8 .8])

        pcolor(lon,lat,diff'); shading flat;
        colormap(gradsmap); clim([0 100]);

        plot(lonCoast,latCoast,'k','linewidth',1);
        set(gca,'ytick',-90:30:90,'yticklabel',{'90S' '60S' '30S' '0' '30N' '60N' '90N'});
        set(gca,'xtick',0:90:360,'xticklabel',{'0' '90E' '180' '90W' '0'});
        axis([0 360 -60 90]);
        
        f=[1 2 3 4];
        v=[8 62; 68 62; 68 85; 8 85];
        patch('Faces',f,'Vertices',v,'FaceColor','white')
        text(0.03,0.90,avg_out,'Units','normalized','fontsize',8,'fontweight','bold')

        iletter=iletter+1;
        f=[1 2 3 4];
        v=[300 60; 350 60; 350 85; 300 85];
        patch('Faces',f,'Vertices',v,'FaceColor','white')
        text(0.90,0.90,['(',panelLetter{iletter},')'],'Units','normalized',...
            'fontsize',8,'fontweight','bold','HorizontalAlignment','center');

        set(gca,'fontsize',8);
        if imodel==1
            ylabel(typeTitle{itype},'fontweight','bold','fontsize',10);
        end
        if itype==1
            title(modelTitle{imodel},'fontsize',12);
        end
    end
end



load('varYearlyOut_cesm1_e3sm_TS.mat');
modelTitle={'CESM1 Historical','E3SMv1 Historical','CESM1 Historical','E3SMv1 Historical'};
varOBS=varYearlyOBShteng;
timeOBS=timeOBShteng;
icounter=0;
for iloop=1:2
    for imodel=1:2
        modelName=name_LE{imodel};
        var=varYearlyCLIM_LE{imodel};
        time=timeCLIM_LE{imodel};
        diff=mean(var(:,:,time>1984 & time<2018),3,'omitnan')-...
            mean(varOBS(:,:,timeOBS>1984 & timeOBS<2018),3,'omitnan');
        diff(land>0.5)=NaN;
        diff(diff<-3)=-3;
        diff(diff>3)=3;
        
        icounter=icounter+1;
        subplot('position',squeeze(subpos(5,:,icounter)))
            hold on; box on;
            rectangle('Position',[0 -90 360 180],'FaceColor',[.8 .8 .8])

            diff=(diff_year5./diff)*100; 
            diff(diff<0)=NaN;
            diff(diff>100)=100;
            avgZM_global=squeeze(mean(diff,1,'omitnan'))';
            avgCOS_global=squeeze(sum(avgZM_global.*cosd(lat),'omitnan')./...
                sum(cosd(lat),'omitnan')); 
            avg_out=sprintf('%.1f',avgCOS_global);
    
            pcolor(lon,lat,diff'); shading flat;
            colormap(gradsmap); clim([0 100]);

            plot(lonCoast,latCoast,'k','linewidth',1);
            set(gca,'ytick',-90:30:90,'yticklabel',{'90S' '60S' '30S' '0' '30N' '60N' '90N'});
            set(gca,'xtick',0:90:360,'xticklabel',{'0' '90E' '180' '90W' '0'});
            axis([0 360 -60 90]);

            f=[1 2 3 4];
            v=[8 62; 68 62; 68 85; 8 85];
            patch('Faces',f,'Vertices',v,'FaceColor','white');
            text(0.03,0.90,avg_out,'Units','normalized','fontsize',8,'fontweight','bold');

            iletter=iletter+1;
            f=[1 2 3 4];
            v=[300 60; 350 60; 350 85; 300 85];
            patch('Faces',f,'Vertices',v,'FaceColor','white')
            text(0.90,0.90,['(',panelLetter{iletter},')'],'Units','normalized',...
                'fontsize',8,'fontweight','bold','HorizontalAlignment','center');

            set(gca,'fontsize',8);
            if icounter==1
                ylabel('year5/LE','fontweight','bold','fontsize',10);
            end
            title(modelTitle{icounter},'fontsize',12);
    end
end
colorbar('location','southoutside','position',[0.27 0.21 0.5 0.02],'fontsize',8);

set(gcf,'renderer','painters')
print(printName,'-r300','-dpng');

