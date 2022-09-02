#!/bin/bash

module load nco

sourceDir='/glade/work/sglanvil/CCR/SST_drift/kirtmanData/'
destDir='/glade/work/sglanvil/CCR/SST_drift/OTHERS/'
var='ts'

#echo ------------------ BEGIN UNLIMIT ------------------ 
#for fullpath in ${sourceDir}${var}*; do
#       filename=$(sed -e 's/.*\///' <<< ${fullpath} | sed -e 's/\.nc//')
#       echo ${sourceDir}${filename}.nc
#       ncks  --mk_rec_dmn time -O ${sourceDir}${filename}.nc ${sourceDir}${filename}.nc 
#done
#echo ------------------ UNLIMIT DONE -------------------

#mkdir -p ${destDir}

#for yearStart in 1985 1990 1995 2000 2005 2010 2015 2016 2017 2018; do
#        yearEnd=$(($yearStart + 5))
#        echo $yearStart $yearEnd
#        ncea -O ${sourceDir}${var}_e3sm_fosi_ens*_s11${yearStart}_e10${yearEnd}.nc ${destDir}${var}_e3sm_fosi_EM_s11${yearStart}_e10${yearEnd}.nc
#        ncea -O ${sourceDir}${var}_e3sm_bruteforce_ens*_s11${yearStart}_e10${yearEnd}.nc ${destDir}${var}_e3sm_bruteforce_EM_s11${yearStart}_e10${yearEnd}.nc
#        ncea -O ${sourceDir}${var}_cesm1_bruteforce_ens*_s11${yearStart}_e10${yearEnd}.nc ${destDir}${var}_cesm1_bruteforce_EM_s11${yearStart}_e10${yearEnd}.nc
#done

#ncecat -O ${destDir}${var}_e3sm_fosi_EM_s* ${destDir}${var}_e3sm_fosi_EM_ALL.nc
#ncecat -O ${destDir}${var}_e3sm_bruteforce_EM_s* ${destDir}${var}_e3sm_bruteforce_EM_ALL.nc
#ncecat -O ${destDir}${var}_cesm1_bruteforce_EM_s* ${destDir}${var}_cesm1_bruteforce_EM_ALL.nc

# -------- concate each member
for imember in {1..3}; do
        echo ${imember}
        ncecat -O ${sourceDir}${var}_e3sm_fosi_ens${imember}_s11*_e10*.nc ${destDir}${var}_e3sm_fosi_00${imember}_ALL.nc
        ncecat -O ${sourceDir}${var}_e3sm_bruteforce_ens${imember}_s11*_e10*.nc ${destDir}${var}_e3sm_bruteforce_00${imember}_ALL.nc
        ncecat -O ${sourceDir}${var}_cesm1_bruteforce_ens${imember}_s11*_e10*.nc ${destDir}${var}_cesm1_bruteforce_00${imember}_ALL.nc
done
