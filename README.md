# SST_drift

```
CESM1 FOSI
- 64 inits (1954-2017)
- 122 month leads (~10 yr forecasts)
- 40 members
```

```
CESM1 BRUTE | E3SM BRUTE | E3SM FOSI
- 10 inits (1985, 1990, 1995, 2000, 2005, 2010, 2015, 2016, 2017, 2018)
- 60 month leads (5 yr forecasts)
- 5 members each
```

```
CESM1LE (missing member 001)
/glade/campaign/cesm/collections/cesmLE/CESM-CAM5-BGC-LE/atm/proc/tseries/monthly/TS
b.e11.B20TRC5CNBDRD.f09_g16.0[02-34].cam.h0.TS.192001-200512.nc
```

```
E3SMv1HIST (missing member 2)
/glade/campaign/cgd/ccr/E3SMv1-LE/FV_regridded/
any files without "test" or "ssp"
```

```
new: /glade/work/sglanvil/CCR/SST_drift
old: /glade/work/sglanvil/CCR/meehl

initAll=[1985 1990 1995 2000 2005 2010 2015 2016 2017];
ncar last init = Nov 2017
kirtman last init = Nov 2018
```

```
1985 = 13 (5 cesm brute, 5 e3sm brute, 3 e3sm fosi)
1990 = 13
1995 = 13
2000 = 13 

2005 = 11 (5 cesm brute, 3 e3sm brute, 3 e3sm fosi)
2010 = 11
2015 = 11
2016 = 11
2017 = 11
2018 = 11
```

```
## Info
load('/Users/sglanvil/Documents/CCR/meehl/data/diffOut_histRuns')
cesmLE=(diff_save{3,1}+diff_save{4,1})/2; % CESM, avg of year3 and year5
e3smLE=(diff_save{3,2}+diff_save{4,2})/2; % E3SM, avg of year3 and year5

load('/Users/sglanvil/Documents/CCR/meehl/data/diffOut_cesm1_e3sm.mat')
cesmBRUTE=(diff_save{3,1}+diff_save{4,1})/2; % CESMb, avg of year3 and year5
e3smBRUTE=(diff_save{3,2}+diff_save{4,2})/2; % E3SMb, avg of year3 and year5
cesmFOSI=(diff_save{3,3}+diff_save{4,3})/2; % CESMf, avg of year3 and year5
e3smFOSI=(diff_save{3,4}+diff_save{4,4})/2; % E3SMf, avg of year3 and year5

cesmBRUTEadj=cesmLE-cesmBRUTE;
cesmFOSIadj=cesmLE-cesmFOSI;
e3smBRUTEadj=e3smLE-e3smBRUTE;
e3smFOSIadj=e3smLE-e3smFOSI;
```
