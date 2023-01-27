% January 20, 2022
clear; clc; close all;

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

% -------------------------- GENERAL SETUP --------------------------


% -------------------------- SPECIFY  --------------------------
printName='diffMap_LEminusOBS_cesm_e3sm';
load('varYearlyOut_cesm1_e3sm_TS.mat');
varOBS=varYearlyOBShteng;
timeOBS=timeOBShteng;

figure
for imodel=1:2
    modelName=name_LE{imodel};
    var=varYearlyCLIM_LE{imodel};
    time=timeCLIM_LE{imodel};
    diff=mean(var(:,:,time>1984 & time<2018),3,'omitnan')-...
        mean(varOBS(:,:,timeOBS>1984 & timeOBS<2018),3,'omitnan');

    diff_60Sto60N=diff(:,lat>-60 & lat<60);
    lat_60Sto60N=lat(lat>-60 & lat<60);
    diffzm_60Sto60N=squeeze(mean(diff_60Sto60N,1,'omitnan'))';
    diffzm_60Sto60N_cosine=squeeze(sum(diffzm_60Sto60N.*cosd(lat_60Sto60N),'omitnan')....
        /sum(cosd(lat_60Sto60N),'omitnan')); 

    v=-10:0.5:10;
    subplot(2,2,imodel)
        hold on; box on;
        contourf(lon,lat,diff',v,'linestyle','none');
        plot(lonCoast,latCoast,'k','linewidth',1);
        colormap(gradsmap); caxis([-3 3]);
        title(sprintf('%s (%.2f)',modelName,diffzm_60Sto60N_cosine));
        set(gca,'ytick',-90:30:90);
        set(gca,'xtick',0:90:360,'xticklabel',{'0' '90E' '180' '90W' '0'});
        set(gca,'fontsize',13);
        axis tight
end
annotation('textbox',[.75 .25 .8 .1],'string','\bf*(60S-60N avg)',...
    'edgecolor','none','verticalalignment','bottom','fontsize',12);
sgtitle('LE - Observations (1985-2017 Time Mean)','fontweight','bold');
hc=colorbar('location','southoutside','position',[0.25 0.44 0.5 0.02]);
set(gcf,'renderer','painters')
print(printName,'-r300','-dpng');

