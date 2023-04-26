#!/bin/bash

## Script to create resampled interferograms for StaMPS.
# Resampling all the SLCs to one common geometry - 19970905
# Start from 1992/05/05 to 1999/10/14

# This script is a test to batch process resampling for a single secondary SLC to a primary SLC.
# After this, I will resample all the SLCs, but don't make interferograms for all of the resampled SLCs.
# Aim as best as you can to make this an automated process.

## Natalie Forrest
## 30th September 2022: updated 2nd November 2022

#############################
## Define parameters

echo Define parameters...

date1=19960222  ## This is the primary SLC.
date2=19960223  ## Secondary SLC
widthslc1=4903 ## Alternatively read from the SLC parameter file :)
widthslc2=4904
widthdem=3461
ers_sat_slc1=1
ers_sat_slc2=2

echo ................................................................................................
echo Processing primary SLC --------- $date1, with a width of $widthslc1 and from ERS-$ers_sat_slc1.
echo Processing secondary SLC ------- $date2, with a width of $widthslc2 and from ERS-$ers_sat_slc2.
echo ................................................................................................

# Delete old files
#rm -rf data/SLC/$date1/*
#rm -rf data/SLC/$date2/*

#rm -rf output_other/$date1/*
#rm -rf output_other/$date2/*

#rm -rf data/SLC_orbits/$date1/*
#rm -rf data/SLC_orbits/$date2/*

##############################
# PRE-PROCESSING
## 1. Started with the extracted SLC and SLC.par files, with the orbital correction applied. I also added the .dem and .dem_par files.

echo Pre-processing....
echo ................................................................................................

# Firstly, I extracted the slc and slc.par files from the SAR_IMS_1P files (source: ESA website).
par_ASAR data/SAR_IMS_1P/SAR_IMS_1PNESA${date1}* data/SLC/$date1
par_ASAR data/SAR_IMS_1P/SAR_IMS_1PNESA${date2}* data/SLC/$date2

# Make the directories for output_other/$date
mkdir output_other/$date1/
mkdir output_other/$date2/

mkdir data/SLC/$date1/
mkdir data/SLC/$date2/

mkdir data/SLC_orbits/$date1/
mkdir data/SLC_orbits/$date2/

# Copy the VV.SLC files to output_other/$date file
cp data/SLC/$date1.VV.SLC data/SLC_orbits/$date1/$date1.slc
cp data/SLC/$date1.VV.SLC.par data/SLC_orbits/$date1/$date1.slc.par
cp data/SLC/$date2.VV.SLC data/SLC_orbits/$date2/$date2.slc
cp data/SLC/$date2.VV.SLC.par data/SLC_orbits/$date2/$date2.slc.par

# Apply the orbital state vectors
DELFT_vec2 data/SLC_orbits/$date1/$date1.slc.par /nfs/a1/raw/ers_sar/orbits/ERS$ers_sat_slc1/
DELFT_vec2 data/SLC_orbits/$date2/$date2.slc.par /nfs/a1/raw/ers_sar/orbits/ERS$ers_sat_slc2/

# Copy the SLC with orbits applied to output_other/$date file
cp data/SLC_orbits/$date1/$date1.slc output_other/$date1/$date1.slc
cp data/SLC_orbits/$date1/$date1.slc.par output_other/$date1/$date1.slc.par
cp data/SLC_orbits/$date2/$date2.slc output_other/$date2/$date2.slc
cp data/SLC_orbits/$date2/$date2.slc.par output_other/$date2/$date2.slc.par

echo ................................................................................................

##############################
## 2. I then multilook these files to check they look ok.

echo Multi-look all the data...
echo ................................................................................................

# Multi-look the SLC file, using number of range looks of 1, and number of azimuth looks of 5
multi_look output_other/$date1/$date1.slc output_other/$date1/$date1.slc.par output_other/$date1/$date1.mli output_other/$date1/$date1.mli.par 1 5
multi_look output_other/$date2/$date2.slc output_other/$date2/$date2.slc.par output_other/$date2/$date2.mli output_other/$date2/$date2.mli.par 1 5

# Display the multilooked file, note that $widthslc1 and $widthslc2 is the width of each MLI file
dispwr $date1.mli $widthslc1 &

echo ................................................................................................
echo Converting png of MLI...
echo ................................................................................................

# Convert MLI to raster
raspwr output_other/$date1/$date1.mli $widthslc1 
raspwr output_other/$date2/$date2.mli $widthslc2 

# Convert MLI raster to PNG
convert output_other/$date1/$date1.mli.bmp output_other/$date1/$date1.mli.png
convert output_other/$date2/$date2.mli.bmp output_other/$date2/$date2.mli.png

################################
## 3. I generate the pre-interferogram files, starting with the offset & co-registration files

echo ................................................................................................
echo Generate the offset files between the two files.
echo ................................................................................................

## Generate initial offset file
create_offset output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/$date1_$date2.off 1 1 1 0
## First 1: the algorithm for offset estimation is intensity cross-correlation
## Second & Third 1: number of interferogram range looks & azimuth looks are 1 and 1
## Zero: Interactive mode is off

## Estimate initial offset with orbital vectors within the parameter file
init_offset_orbit output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/$date1_$date2.off

## Estimate initial offset (1): Multi-looked offset
init_offset output_other/$date1/$date1.slc output_other/$date2/$date2.slc output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/$date1_$date2.off 1 5
 
## Estimate initial offset (2): Full resolution update
init_offset output_other/$date1/$date1.slc output_other/$date2/$date2.slc output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/$date1_$date2.off 1 1

## Compute precise orbit & reiterate
# 128 128: range & azimuth patch size
# 1: SLC oversampling factor (default is 2)
# 8 8: number of offset estimates in range & azimuth direction (could be default from offset parameter file)
# 0.15: cross-correlation threshold

offset_pwr output_other/$date1/$date1.slc output_other/$date2/$date2.slc output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/$date1_$date2.off output_other/$date2/offs output_other/$date2/ccp 128 128 output_other/$date2/offsets 1 8 8 0.15

offset_pwr output_other/$date1/$date1.slc output_other/$date2/$date2.slc output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/$date1_$date2.off output_other/$date2/offs output_other/$date2/ccp 64 64 output_other/$date2/offsets 1 8 8 0.10

## John Elliott has the following, and uses the data from the offset file instead (better for automated processes)
# offset_pwr $date1.slc $date2.slc $date1.slc.par $date2.slc.par $date1_$date2.off offs ccp - - offsets

## Generate offsets polynomial & reiterate
# 0.15: cross-correlation threshold
# 3: number of polynomial parameters (options: 1,3,4,6)
offset_fit output_other/$date2/offs output_other/$date2/ccp output_other/$date2/$date1_$date2.off output_other/$date2/coffs output_other/$date2/coffsets 0.15 3 0
offset_fit output_other/$date2/offs output_other/$date2/ccp output_other/$date2/$date1_$date2.off output_other/$date2/coffs output_other/$date2/coffsets 0.1 3 0
offset_fit output_other/$date2/offs output_other/$date2/ccp output_other/$date2/$date1_$date2.off output_other/$date2/coffs output_other/$date2/coffsets 0.1 4 0

## John Elliott has the following, and uses the data from the offset file instead (better for automated processes)
# offset_fit offs ccp $date1_$date2.off coffs coffsets - 4

echo ................................................................................................

################################
## 4. Next, I resample the second SLC to the first slc geometry, which would allow me to make the interferogram

echo Resample second SLC to first SLC geometry...
echo ................................................................................................

# Resample second SLC to first SLC geometry
SLC_interp output_other/$date2/$date2.slc output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/$date1_$date2.off output_other/$date2/$date2.rslc output_other/$date2/$date2.rslc.par

# Multi-look resampled SLC.
multi_look output_other/$date2/$date2.rslc output_other/$date2/$date2.rslc.par output_other/$date2/$date2.rmli output_other/$date2/$date2.rmli.par 1 5

# Convert to raster and png
raspwr output_other/$date2/$date2.rmli $widthslc1
convert output_other/$date2/$date2.rmli.bmp output_other/$date2/$date2.rmli.png

# Copy to output_rslc/$date2
mkdir output_other/$date2

cp -r output_other/$date2/$date2.rslc* output_rslc
cp -r output_other/$date2/$date2.rmli* output_rslc

# Then you're done! all the SLC files will have been resampled to the geometry of the primary SLCs :)
