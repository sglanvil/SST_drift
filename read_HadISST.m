% March 9, 2022
% https://www.metoffice.gov.uk/hadobs/hadisst/data/download.html
% 1870-2021 monthly observational SST  (152 months)
% Cheyenne: fil=/glade/work/sglanvil/CCR/meehl/HadISST_sst.nc

fil='/Users/sglanvil/Documents/CCR/meehl/data/HadISST_sst.nc';
lon0=ncread(fil,'longitude');
lat0=ncread(fil,'latitude');
raw=ncread(fil,'sst');

%%
clear; clc; close all;

fil='/home/sglanvil/CCR/htengScripts/IPO/T42.gw.nc';
lon=ncread(fil,'lon');
lat=ncread(fil,'lat');

for iyear=1979:2010
    iyear
    fil=sprintf('/project/cas/terray/obs/HadISST2/HadISST2_prelim_0to360_alldays_sst_%.4d.nc',iyear);
    raw=ncread(fil,'sst');
    lon0=ncread(fil,'longitude');   
    lat0=double(ncread(fil,'latitude'));
    [x,y]=meshgrid(lon0,lat0);
    [xNew,yNew]=meshgrid(lon,lat);
    clear rawNew
    for itime=1:size(raw,3)
        rawNew(:,:,itime)=interp2(x,y,squeeze(raw(:,:,itime))',...
            xNew,yNew,'linear',1)'; 
    end
end
