% August 15, 2022

clear; clc; close all;

printName='driftDiff_cesm1_e3sm_histRuns_HADISST';

load('diffOut_cesm1_e3sm.mat');
diffSave_forecasts=diff_save;
load('diffOut_histRuns.mat');
diffSave_histRuns=diff_save;
clear diff_save

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

figure;
modelTitle={'CESM1 bruteforce','E3SM bruteforce','CESM1 FOSI','E3SM FOSI'};
model={'cesm1_bruteforce','e3sm_bruteforce','cesm1_fosi','e3sm_fosi'};
for imodel=1:4
    typeTitle={'month 1','year 1','year 3','year 5'};  
    type={'month1','year1','year3','year5'};  
    for itype=1:4        
        Y=diffSave_forecasts{itype,imodel};
        if imodel==1 || imodel==3
            X=diffSave_histRuns{itype,1};
        end
        if imodel==2 || imodel==4
            X=diffSave_histRuns{itype,2};
        end
        diff=Y-X;
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
sgtitle('Hindcast Drift - Historical Drift');
cb=colorbar('location','southoutside','position',[0.25 0.04 0.5 0.02],'fontsize',10);
set(gcf,'renderer','painters')
print(printName,'-r300','-dpng');
