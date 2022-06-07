#!/bin/bash

# Note: en2 is missing
dir=/glade/campaign/cgd/ccr/E3SMv1-LE/FV_regridded/

find ${dir} -name "*.TS.*" -type f -exec cp {} . \;

module load nco
#rm LE_ens.FV_oECv3_ICG.EM.cam.h0.TS.185001-201511.nc
#ncea -O *.nc LE_ens.FV_oECv3_ICG.EM.cam.h0.TS.185001-201511.nc
