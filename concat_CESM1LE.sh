#!/bin/bash

# Note: ensemble member 001 is missing
dir=/glade/campaign/cesm/collections/cesmLE/CESM-CAM5-BGC-LE/atm/proc/tseries/monthly/TS/

cp ${dir}b.e11.B20TRC5CNBDRD.f09_g16.*.cam.h0.TS.192001-200512.nc .

#module load nco
#rm b.e11.B20TRC5CNBDRD.f09_g16.EM.cam.h0.TS.192001-200512.nc
#ncea -O b.e11.B20TRC5CNBDRD.f09_g16.*.cam.h0.TS.192001-200512.nc b.e11.B20TRC5CNBDRD.f09_g16.EM.cam.h0.TS.192001-200512.nc
