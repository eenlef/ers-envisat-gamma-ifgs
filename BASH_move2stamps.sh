#!/bin/bash

# Script to move all important files to StaMPS file format for each interferogram pair

## Files needed:

# ./SMALL BASELINES/yyyymmdd_yyyymmdd/yyyymmdd.rslc
#a resampled SLC for the master image in every interferogram

# ./SMALL BASELINES/yyyymmdd_yyyymmdd/yyyymmdd.rslc
#a resampled SLC for the slave image in every interferogram

# ./SMALL BASELINES/yyyymmdd_yyyymmdd/yyyymmdd.rslc.par
#the SLC parameter file for the super-master

# ./SMALL BASELINES/yyyymmdd_yyyymmdd/yyyymmdd_yyyymmdd.diff
#the interferograms

# ./SMALL BASELINES/yyyymmdd_yyyymmdd/yyyymmdd_yyyymmdd.base
#a base file for every interferogram


#############################
## Define parameters

echo MOVE FILES TO STAMPS FOLDER

#./bin/BASH_move2stamps.sh $date1 $date2

echo 1. Defining parameters.

date1=$1     ## This is the primary SLC, and is hard coded into the script.
#widthslc1=4903     ## Alternatively read from the SLC parameter file :)
#ers_sat_slc1=1

date2=$2            ## Secondary SLC
#date2=19960223

#dem_correction=$3 # option N (0) or Y (1).
#dem_correction=0 # option N (0) or Y (1). 
# No is default

both=${date1}_${date2}
output_both=$nat/Geodesy/ERS/track50/resampled_SLCs/20230329_output_ifg/$both
output_stamps=$nat/Geodesy/StaMPS/INSAR_19970905_2/SMALL_BASELINES/$both

super_primary=19970905

#module load gamma/20201216

echo 2. Creating StaMPS folder

# Make directory for interferogram & copy all files
if [ ! -d $output_stamps/ ] #if 3
then 
echo Note: $output_stamps/ "doesn't exist. Making now."
mkdir $output_stamps/

echo 3. Copying data to StaMPS folder

echo "A: $date1 RSLC"
cp $output_both/$date1.rslc $output_stamps

echo "B: $date2 RSLC"
cp $output_both/$date2.rslc $output_stamps

echo "C: The super-primary RSLC parameter file"
cp output_rslc/$super_primary.rslc.par $output_stamps

echo "D: The $both interferogram"
### THIS IS THE CRUCIAL INTERFEROGRAM WE WANT FOR StaMPS
cp $output_both/$both.diff_int1 $output_stamps/$both.diff

echo "E: The $both baselines file"
cp $output_both/$both.base1 $output_stamps/$both.base

echo "F: Coherence files"
cp $output_both/$both.cc $output_stamps

else
echo Note: $output_stamps "exists already."

## TERMINATE SCRIPT
#exit 0

fi #if 3

echo ................................................................................................
