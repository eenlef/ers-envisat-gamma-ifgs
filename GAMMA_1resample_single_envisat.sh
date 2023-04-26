#!/bin/bash

## Script to resample an Envisat SLC to a primary SLC.

# The two dates need to be defined in advance, 
# as well as the track and frame.

# Natalie Forrest
## 2nd February 2023

##############################
# PRE-PROCESSING

echo "................................................................................................"
echo "PRE-PROCESSING"

echo "1. Defining parameters."

date1=$1          ## Primary SLC
date2=$2           ## Secondary SLC

track=$3           ## Track to process, e.g. track143_asc
frame=$4           ## Frame to process

#both=${date1}_${date2}
#output_both=$track/resampled_ifgs/$both

## List
## $nat/Geodesy/Envisat/metadata/output_data/1_metadata_track50.f2799.txt

output_resample_primary=$track/resampled_ifgs/1output_resampled/$date1
output_resample=$track/resampled_ifgs/1output_resampled/$date2

module load gamma/20201216

echo "2. Processing data $date1 and $date2, for $track and frame $frame."
## 1. Firstly, see if the SLC data has been extracted from the SAR file.
# 2. If they haven't: extract the data, apply orbits, and move to SLC_orbits file.

## For date 1

if [ ! -f $track/data/SLC_orbits/$date1/$date1.slc ]
then 
echo "SLC data for $date1 hasn't been extracted"

## If data doesn't exist, extract, orbits, and move.
mkdir $track/data/SLC/$date1/
mkdir $track/data/SLC_orbits/$date1/

echo "2a. Extracting data from ASA_IMS_1P file."
par_ASAR $track/data/ASA_IMS_1P/ASA_IMS_1PNESA${date1}* $track/data/SLC/$date1/$date1 > $track/data/SLC/$date1/extract_$date1.txt

echo "2b. Moving data to SLC_orbits folder & define variables."
cp $track/data/SLC/$date1/$date1.VV.SLC $track/data/SLC_orbits/$date1/$date1.slc
cp $track/data/SLC/$date1/$date1.VV.SLC.par $track/data/SLC_orbits/$date1/$date1.slc.par
### Define width of the SLC
widthslc1=`cat $track/data/SLC_orbits/$date1/$date1.slc.par | grep range_samples | awk '{print $2}'`

echo "2c. Applying orbits to SLC data."
DELFT_vec2 $track/data/SLC_orbits/$date1/$date1.slc.par $nat/Catalogues/ORBITS/ODR.ENVISAT1/eigen-cg03c/ >> $track/data/SLC/$date1/extract_$date1.txt

echo "2d. Multi-looking the SLC file."
# Multi-look the SLC file, using number of range looks of 1, and number of azimuth looks of 5
multi_look $track/data/SLC_orbits/$date1/$date1.slc $track/data/SLC_orbits/$date1/$date1.slc.par $track/data/SLC_orbits/$date1/$date1.mli $track/data/SLC_orbits/$date1/$date1.mli.par 1 5 >> $track/data/SLC/$date1/extract_$date1.txt

echo "2e. Creating png of MLI."
# Convert MLI to raster
raspwr $track/data/SLC_orbits/$date1/$date1.mli $widthslc1 >> $track/data/SLC_orbits/$date1/mli_$date1.txt
# Convert MLI raster to PNG
convert $track/data/SLC_orbits/$date1/$date1.mli.bmp $track/data/SLC_orbits/$date1/$date1.mli.png >> $track/data/SLC/$date1/extract_$date1.txt

else
echo "SLC data for $date1 has been extracted, moving onto second date."
fi
echo "................................................................................................"

## For date 2

if [ ! -f $track/data/SLC_orbits/$date2/$date2.slc ]
then 
echo "SLC data for $date2 hasn't been extracted"

## If data doesn't exist, extract, orbits, and move.
mkdir $track/data/SLC/$date2/
mkdir $track/data/SLC_orbits/$date2/

echo "3a. Extracting data from ASA_IMS_1P file."
par_ASAR $track/data/ASA_IMS_1P/ASA_IMS_1PNESA${date2}* $track/data/SLC/$date2/$date2 > $track/data/SLC/$date2/extract_$date2.txt

# For track 50, frame 2799
#par_ASAR $track/data/ASA_IMS_1P/ASA_IMS_1PNESA${date2}\*1820*.N1 $track/data/SLC/$date2/$date2 > $track/data/SLC/$date2/extract_$date2.txt

#ASA_IMS_1PNESA${date2}\*1820*.N1

echo "3b. Moving data to SLC_orbits folder."
cp $track/data/SLC/$date2/$date2.VV.SLC $track/data/SLC_orbits/$date2/$date2.slc
cp $track/data/SLC/$date2/$date2.VV.SLC.par $track/data/SLC_orbits/$date2/$date2.slc.par
### Define width of the SLC
widthslc2=`cat $track/data/SLC_orbits/$date2/$date2.slc.par | grep range_samples | awk '{print $2}'`

echo "3c. Applying orbits to SLC data."
DELFT_vec2 $track/data/SLC_orbits/$date2/$date2.slc.par $nat/Catalogues/ORBITS/ODR.ENVISAT1/eigen-cg03c/ >> $track/data/SLC/$date2/extract_$date2.txt

echo "3d. Multi-looking the SLC file."
# Multi-look the SLC file, using number of range looks of 1, and number of azimuth looks of 5
multi_look $track/data/SLC_orbits/$date2/$date2.slc $track/data/SLC_orbits/$date2/$date2.slc.par $track/data/SLC_orbits/$date2/$date2.mli $track/data/SLC_orbits/$date2/$date2.mli.par 1 5 >> $track/data/SLC/$date2/extract_$date2.txt

echo "3e. Creating png of MLI."
# Convert MLI to raster
raspwr $track/data/SLC_orbits/$date2/$date2.mli $widthslc2 >> $track/data/SLC_orbits/$date2/mli_$date2.txt
# Convert MLI raster to PNG
convert $track/data/SLC_orbits/$date2/$date2.mli.bmp $track/data/SLC_orbits/$date2/$date2.mli.png >> $track/data/SLC/$date2/extract_$date2.txt

else
echo "SLC data for $date2 has been extracted."

fi

echo "4. Defining variables from the SLC parameter file"

widthslc1=`cat $track/data/SLC_orbits/$date1/$date1.slc.par | grep range_samples | awk '{print $2}'`
widthslc2=`cat $track/data/SLC_orbits/$date2/$date2.slc.par | grep range_samples | awk '{print $2}'`

echo "................................................................................................"
echo "Processed Primary SLC --------- $date1, with a width of $widthslc1 and from Envisat."
echo "Processed Secondary SLC ------- $date2, with a width of $widthslc2 and from Envisat."
echo "................................................................................................"


#############################
#### Resample to Primary SLC

echo "RESAMPLING"

echo "1a. Create folder for resampling output for $date1."

if [ ! -d $output_resample_primary ] #if the interferogram directory doesn't exist:
then 
echo "Note: $output_resample_primary/ doesn't exist. Making now."
mkdir $output_resample_primary

# Copy date 1 files
cp $track/data/SLC_orbits/$date1/$date1.slc* $output_resample_primary
cp $track/data/SLC_orbits/$date1/$date1.mli $output_resample_primary
cp $track/data/SLC_orbits/$date1/$date1.mli.p* $output_resample_primary

else
echo "Note: $output_resample_primary/ already exists."
fi

echo "1b. Create folder for resampling output for $date2."

if [ ! -d $output_resample ] #if the interferogram directory doesn't exist:
then 
echo "Note: $output_resample/ doesn't exist. Making now."
mkdir $output_resample

# Copy date 2 files
cp $track/data/SLC_orbits/$date2/$date2.slc* $output_resample
cp $track/data/SLC_orbits/$date2/$date2.mli $output_resample
cp $track/data/SLC_orbits/$date2/$date2.mli.p* $output_resample

echo "2. Generate the offset files between the two SLCs."

## Generate initial offset file
create_offset $output_resample_primary/$date1.slc.par $output_resample/$date2.slc.par $output_resample/$both.off 1 1 1 0 > $output_resample/history.txt
## First 1: the algorithm for offset estimation is intensity cross-correlation
## Second & Third 1: number of interferogram range looks & azimuth looks are 1 and 1
## Zero: Interactive mode is off

## Estimate initial offset with orbital vectors within the parameter file
init_offset_orbit $output_resample_primary/$date1.slc.par $output_resample/$date2.slc.par $output_resample/$both.off >> $output_resample/history.txt

## Estimate initial offset (1): Multi-looked offset
init_offset $output_resample_primary/$date1.slc $output_resample/$date2.slc $output_resample_primary/$date1.slc.par $output_resample/$date2.slc.par $output_resample/$both.off 1 5 >> $output_resample/history.txt
 
## Estimate initial offset (2): Full resolution update
init_offset $output_resample_primary/$date1.slc $output_resample/$date2.slc $output_resample_primary/$date1.slc.par $output_resample/$date2.slc.par $output_resample/$both.off 1 1 >> $output_resample/history.txt

## Compute precise orbit & reiterate
# 128 128: range & azimuth patch size
# 1: SLC oversampling factor (default is 2)
# 8 8: number of offset estimates in range & azimuth direction (could be default from offset parameter file)
# 0.15: cross-correlation threshold

offset_pwr $output_resample_primary/$date1.slc $output_resample/$date2.slc $output_resample_primary/$date1.slc.par $output_resample/$date2.slc.par $output_resample/$both.off $output_resample/offs $output_resample/ccp 128 128 $output_resample/offsets 1 8 8 0.15 >> $output_resample/history.txt

offset_pwr $output_resample_primary/$date1.slc $output_resample/$date2.slc $output_resample_primary/$date1.slc.par $output_resample/$date2.slc.par $output_resample/$both.off $output_resample/offs $output_resample/ccp 64 64 $output_resample/offsets 1 8 8 0.10 >> $output_resample/history.txt

## Generate offsets polynomial & reiterate
# 0.15: cross-correlation threshold
# 3: number of polynomial parameters (options: 1,3,4,6)
offset_fit $output_resample/offs $output_resample/ccp $output_resample/$both.off $output_resample/coffs $output_resample/coffsets 0.15 3 0 >> $output_resample/history.txt
offset_fit $output_resample/offs $output_resample/ccp $output_resample/$both.off $output_resample/coffs $output_resample/coffsets 0.1 3 0 >> $output_resample/history.txt

echo "3. Resample second SLC to primary SLC geometry."

# Resample second SLC to first SLC geometry
SLC_interp $output_resample/$date2.slc $output_resample_primary/$date1.slc.par $output_resample/$date2.slc.par $output_resample/$both.off $output_resample/$date2.rslc $output_resample/$date2.rslc.par >> $output_resample/history.txt

# Multi-look resampled SLC.
multi_look $output_resample/$date2.rslc $output_resample/$date2.rslc.par $output_resample/$date2.rmli $output_resample/$date2.rmli.par 1 5 >> $output_resample/history.txt

# Convert to raster and png
raspwr $output_resample/$date2.rmli $widthslc1 >> $output_resample/history.txt
convert $output_resample/$date2.rmli.bmp $output_resample/$date2.rmli.png >> $output_resample/history.txt

echo ................................................................................................
echo "Completed! :)"
echo ................................................................................................

else
echo "Offset files already exist, moving on to next date..."
echo "Completed! :)"
echo ................................................................................................
fi





