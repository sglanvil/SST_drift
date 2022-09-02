#!/bin/bash

module load nco

ncarVar='TS'
sourceDir=/glade/campaign/cesm/collections/CESM1-DPLE/atm/proc/tseries/monthly/${ncarVar}/
destDir=/glade/work/sglanvil/CCR/SST_drift/CESM1_FOSI_3mem/
var='ts'

mkdir -p ${destDir}

# -------- make ensemble mean and then concatenate
for yearStart in 1985 1990 1995 2000 2005 2010 2015 2016 2017; do
#for yearStart in {1954..2017}; do
        yearEnd=$(($yearStart + 10))
        echo $yearStart $yearEnd
        ncea -O ${sourceDir}b.e11.BDP.f09_g16.${yearStart}-11.00[1-3].cam.h0.${ncarVar}.${yearStart}11-${yearEnd}12.nc ${destDir}b.e11.BDP.f09_g16.${yearStart}-11.EM.cam.h0.${ncarVar}.${yearStart}11-${yearEnd}12.nc
done

ncecat -O ${destDir}b.e11.BDP.f09_g16.*-11.EM.cam.h0.${ncarVar}.*.nc ${destDir}${var}_cesm1_fosi_EM_ALL.nc

# -------- concate each member
#for imember in {001..040}; do
#       echo ${imember}
#       ncecat -O ${sourceDir}b.e11.BDP.f09_g16.*-11.${imember}.cam.h0.${ncarVar}.*11-*12.nc ${destDir}${var}_cesm1_fosi_${imember}_ALL.nc
#done

