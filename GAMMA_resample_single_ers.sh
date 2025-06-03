#!/bin/bash

## Script to create resampled ERS interferograms for StaMPS.
# Resampling all the SLCs to one common geometry - 19970905
# Start from 1992/05/05 to 1999/10/14

# This script is a test to batch process resampling for a single secondary SLC to a primary SLC.
# After this, I will resample all the SLCs, but don't make interferograms for all of the resampled SLCs.
# Aim as best as you can to make this an automated process.

## Natalie Forrest
## 30th September 2022: updated 4th November 2022

#############################
## Define parameters

echo ................................................................................................
echo PRE-PROCESSING

echo 1. Defining parameters.

date1=19970905     ## This is the primary SLC, and is hard coded into the script.
#widthslc1=4903      ## Alternatively read from the SLC parameter file :)
#ers_sat_slc1=1

date2=$1            ## Secondary SLC
#date2=19960223

module load gamma/20201216

echo 2. Processing data $date1 and $date2.


##############################
# PRE-PROCESSING
## 1. Started with the extracted SLC and SLC.par files, with the orbital correction applied. I also added the .dem and .dem_par files.

### Firstly, I extracted the slc and slc.par files from the SAR_IMS_1P files (source: ESA website).

# Make directory for extracted files (if the don't exist)
# For date 1

if [ ! -d data/SLC/$date1/ ]
then 
mkdir data/SLC/$date1/
echo Note: data/SLC/$date1/ "doesn't exist"
echo Creating directory data/SLC/$date1/

else
echo Note: data/SLC/$date1/ "already exists"
fi

# Make directory for date 2
if [ ! -d data/SLC/$date2/ ]
then 
mkdir data/SLC/$date2/
echo Note: data/SLC/$date2/ "doesn't exist"
echo Creating directory data/SLC/$date2/

else
echo Note: data/SLC/$date2/ "already exists"
fi
echo ................................................................................................

######## Extract files (if they don't exist)
## If the data in the data/SLC/ folder doesn't exist, then assume you need to:

# 1 Make the directories for output_other/$date and extract files from SAR file
# 2 Make directories for files, including data with orbits applied
# 3 Copy the VV.SLC files to output_other/$date file 

#####################################################################
# Date 1

echo PRE-PROCESSING FOR $date1

# If the extracted VV data file doesn't exist, then... extract, orbits, define parameters!
if [ ! -f data/SLC/$date1/$date1.VV.SLC ]
then 
echo Note: Extracted files "for" $date1 "don't exist"

# Extract files

echo 1. Extracting files to data/SLC/$date1/ directory.

par_ASAR $nat/Geodesy/ERS/track50/data/SAR_IMS_1P/SAR_IM*_1PNESA${date1}* data/SLC/$date1/$date1 > data/SLC/$date1/extract_$date1.txt

# par_ASAR $nat/Geodesy/ERS/track50/data/SAR_IMS_1P/SAR_IMS_1PNESA${date1}* $date1 > extract_$date1.txt
# par_ASAR $nat/Geodesy/ERS/track50/data/SAR_IMS_1P/SAR_IMS_1PNESA${date2}* $date2 > extract_$date2.txt

echo 2. Copying files to the orbits directory.

mkdir output_other/$date1/
mkdir data/SLC_orbits/$date1/

cp data/SLC/$date1/$date1.VV.SLC data/SLC_orbits/$date1/$date1.slc
cp data/SLC/$date1/$date1.VV.SLC.par data/SLC_orbits/$date1/$date1.slc.par

#cp $date1.VV.SLC $date1.slc
#cp $date1.VV.SLC.par $date1.slc.par
#cp $date2.VV.SLC.par $date2.slc.par
#cp $date2.VV.SLC $date2.slc

echo 3. Defining variables from the SLC parameter files - width of SLC and ERS satellite number.

### Define width of the SLC and the satellite number
widthslc1=`cat data/SLC_orbits/$date1/$date1.slc.par | grep range_samples | awk '{print $2}'`
ers_sat_slc1=`cat data/SLC_orbits/$date1/$date1.slc.par | grep title | awk 'BEGIN { FS="."} ; {print $2}' | cut -c 2`

#widthslc1=`cat $date1.slc.par | grep range_samples | awk '{print $2}'`
#ers_sat_slc1=`cat $date1.slc.par | grep title | awk 'BEGIN { FS="."} ; {print $2}' | cut -c 2`
#widthslc2=`cat $date2.slc.par | grep range_samples | awk '{print $2}'`
#ers_sat_slc2=`cat $date2.slc.par | grep title | awk 'BEGIN { FS="."} ; {print $2}' | cut -c 2`

echo 4. Applying the orbital state variables.

# Apply the orbital state vectors
DELFT_vec2 data/SLC_orbits/$date1/$date1.slc.par /nfs/a1/raw/ers_sar/orbits/ERS$ers_sat_slc1/ > data/SLC/$date1/orbits_$date1.txt

#DELFT_vec2 $date1.slc.par /nfs/a1/raw/ers_sar/orbits/ERS$ers_sat_slc1/ > orbits_$date1.txt
#DELFT_vec2 $date2.slc.par /nfs/a1/raw/ers_sar/orbits/ERS$ers_sat_slc2/ > orbits_$date2.txt

echo 5. Copying the SLC with orbits applied to output_other/$date1/ "file"

# Copy the SLC with orbits applied to output_other/$date file
cp data/SLC_orbits/$date1/$date1.slc output_other/$date1/$date1.slc
cp data/SLC_orbits/$date1/$date1.slc.par output_other/$date1/$date1.slc.par

echo 6. Multi-looking the SLC file.

# Multi-look the SLC file, using number of range looks of 1, and number of azimuth looks of 5
multi_look output_other/$date1/$date1.slc output_other/$date1/$date1.slc.par output_other/$date1/$date1.mli output_other/$date1/$date1.mli.par 1 5 > data/SLC/$date1/mli_$date1.txt

echo 7. Creating png of MLI.
echo ................................................................................................

# Convert MLI to raster
raspwr output_other/$date1/$date1.mli $widthslc1 > data/SLC/$date1/mli2raster_$date1.txt

# Convert MLI raster to PNG
convert output_other/$date1/$date1.mli.bmp output_other/$date1/$date1.mli.png > data/SLC/$date1/mli2png_$date1.txt


# Otherwise, these files already exist
else
echo File $date1 already extracted, defining parameters - width of SLC and ERS satellite number
echo Moving onto next date...
echo ................................................................................................

# Define the parameters for Date 1
widthslc1=`cat data/SLC_orbits/$date1/$date1.slc.par | grep range_samples | awk '{print $2}'`
ers_sat_slc1=`cat data/SLC_orbits/$date1/$date1.slc.par | grep title | awk 'BEGIN { FS="."} ; {print $2}' | cut -c 2`

fi

#####################################################################
# Date 2

echo PRE-PROCESSING FOR $date2

# If the extracted VV data file doesn't exist, then... extract, orbits, define parameters!
if [ ! -f data/SLC/$date2/$date2.VV.SLC ]
then 
echo Note: Extracted files "for" $date2 "don't exist"

# Extract files

echo 1. Extracting files to data/SLC/$date2/ directory.

par_ASAR $nat/Geodesy/ERS/track50/data/SAR_IMS_1P/SAR_IM*_1PNESA${date2}* data/SLC/$date2/$date2 > data/SLC/$date2/extract_$date2.txt

echo 2. Copying files to the orbits directory.

mkdir output_other/$date2/
mkdir data/SLC_orbits/$date2/

cp data/SLC/$date2/$date2.VV.SLC data/SLC_orbits/$date2/$date2.slc
cp data/SLC/$date2/$date2.VV.SLC.par data/SLC_orbits/$date2/$date2.slc.par

echo 3. Defining variables from the SLC parameter files - width of SLC and ERS satellite number.

### Define width of the SLC and the satellite number
widthslc2=`cat data/SLC_orbits/$date2/$date2.slc.par | grep range_samples | awk '{print $2}'`
ers_sat_slc2=`cat data/SLC_orbits/$date2/$date2.slc.par | grep title | awk 'BEGIN { FS="."} ; {print $2}' | cut -c 2`

echo 4. Applying the orbital state variables.

# Apply the orbital state vectors
DELFT_vec2 data/SLC_orbits/$date2/$date2.slc.par /nfs/a1/raw/ers_sar/orbits/ERS$ers_sat_slc2/ > data/SLC/$date2/orbits_$date2.txt

echo 5. Copying the SLC with orbits applied to output_other/$date2/ "file"

# Copy the SLC with orbits applied to output_other/$date file
cp data/SLC_orbits/$date2/$date2.slc output_other/$date2/$date2.slc
cp data/SLC_orbits/$date2/$date2.slc.par output_other/$date2/$date2.slc.par

echo 6. Multi-looking the SLC file.

# Multi-look the SLC file, using number of range looks of 1, and number of azimuth looks of 5
multi_look output_other/$date2/$date2.slc output_other/$date2/$date2.slc.par output_other/$date2/$date2.mli output_other/$date2/$date2.mli.par 1 5 > data/SLC/$date2/mli_$date2.txt

echo 7. Creating png of MLI.

# Convert MLI to raster
raspwr output_other/$date2/$date2.mli $widthslc2 > data/SLC/$date2/mli2raster_$date2.txt

# Convert MLI raster to PNG
convert output_other/$date2/$date2.mli.bmp output_other/$date2/$date2.mli.png > data/SLC/$date2/mli2png_$date2.txt


# Otherwise, these files already exist
else
echo File $date2 already extracted, defining parameters - width of SLC and ERS satellite number

# Define the parameters for Date 2
widthslc2=`cat data/SLC_orbits/$date2/$date2.slc.par | grep range_samples | awk '{print $2}'`
ers_sat_slc2=`cat data/SLC_orbits/$date2/$date2.slc.par | grep title | awk 'BEGIN { FS="."} ; {print $2}' | cut -c 2`

fi

echo ................................................................................................
echo Processed Primary SLC --------- $date1, with a width of $widthslc1 and from ERS-$ers_sat_slc1.
echo Processed Secondary SLC ------- $date2, with a width of $widthslc2 and from ERS-$ers_sat_slc2.
echo ................................................................................................

################################
## 2. I generate the pre-interferogram files, starting with the offset & co-registration files

echo GENERATING PRE-INTERFEROGRAM FILES
echo Checking whether offset files already exist...

##################################
## Old section of script: here, if the offset already exists, I would delete and redo.
## Now, if it exists, I skip over this data.

# If the offset files exist already, then...
#if [ -f output_other/$date2/offs ]
#then 

#echo Note: Offset files already exist. Deleting now...

## THEN delete any offset files
#rm output_other/$date2/${date1}_${date2}.off
#rm output_other/$date2/offs
#rm output_other/$date2/ccp
#rm output_other/$date2/offsets
#rm output_other/$date2/coffs
#rm output_other/$date2/coffsets
#rm output_other/$date2/$date2.rslc*

#fi
###################################

# If files don't exist, make them! Else, skip.
if [ ! -f output_other/$date2/offs ]
then 

echo No previous offset files exist. Creating now...
echo ................................................................................................

echo 1. Generate the offset files between the two files.

## Generate initial offset file
create_offset output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/${date1}_${date2}.off 1 1 1 0 > output_other/$date2/createoffset.txt

## First 1: the algorithm for offset estimation is intensity cross-correlation
## Second & Third 1: number of interferogram range looks & azimuth looks are 1 and 1
## Zero: Interactive mode is off

echo 2. Estimate initial offset using orbits.

## Estimate initial offset with orbital vectors within the parameter file
init_offset_orbit output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/${date1}_${date2}.off >> output_other/$date2/createoffset.txt

echo 3. Estimate initial offset, takes about 10 seconds.

## Estimate initial offset (1): Multi-looked offset
init_offset output_other/$date1/$date1.slc output_other/$date2/$date2.slc output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/${date1}_${date2}.off 1 5 >> output_other/$date2/createoffset.txt
 
## Estimate initial offset (2): Full resolution update
init_offset output_other/$date1/$date1.slc output_other/$date2/$date2.slc output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/${date1}_${date2}.off 1 1 >> output_other/$date2/createoffset.txt

echo 4. Compute precise orbit.

## Compute precise orbit & reiterate
# 128 128: range & azimuth patch size
# 1: SLC oversampling factor (default is 2)
# 8 8: number of offset estimates in range & azimuth direction (could be default from offset parameter file)
# 0.15: cross-correlation threshold

offset_pwr output_other/$date1/$date1.slc output_other/$date2/$date2.slc output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/${date1}_${date2}.off output_other/$date2/offs output_other/$date2/ccp 128 128 output_other/$date2/offsets 1 8 8 0.15 >> output_other/$date2/createoffset.txt

offset_pwr output_other/$date1/$date1.slc output_other/$date2/$date2.slc output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/${date1}_${date2}.off output_other/$date2/offs output_other/$date2/ccp 64 64 output_other/$date2/offsets 1 8 8 0.10 >> output_other/$date2/createoffset.txt

echo 5. Generate offset polynomial.

## Generate offsets polynomial & reiterate
# 0.15: cross-correlation threshold
# 3: number of polynomial parameters (options: 1,3,4,6)

offset_fit output_other/$date2/offs output_other/$date2/ccp output_other/$date2/${date1}_${date2}.off output_other/$date2/coffs output_other/$date2/coffsets 0.15 3 0 >> output_other/$date2/createoffset.txt

offset_fit output_other/$date2/offs output_other/$date2/ccp output_other/$date2/${date1}_${date2}.off output_other/$date2/coffs output_other/$date2/coffsets 0.1 3 0 >> output_other/$date2/createoffset.txt

offset_fit output_other/$date2/offs output_other/$date2/ccp output_other/$date2/${date1}_${date2}.off output_other/$date2/coffs output_other/$date2/coffsets 0.1 4 0 >> output_other/$date2/createoffset.txt

## John Elliott has the following, and uses the data from the offset file instead (better for automated processes)
# offset_fit offs ccp $date1_$date2.off coffs coffsets - 4

echo ................................................................................................

echo RESAMPLE SECOND SLC TO FIRST SLC GEOMETRY

echo 1. Resample secondary SLC to primary SLC geometry, takes about 20 seconds.

# Resample second SLC to first SLC geometry
SLC_interp output_other/$date2/$date2.slc output_other/$date1/$date1.slc.par output_other/$date2/$date2.slc.par output_other/$date2/${date1}_${date2}.off output_other/$date2/$date2.rslc output_other/$date2/$date2.rslc.par > output_other/$date2/resample.txt

echo 2. Multi-look resampled SLC.

# Multi-look resampled SLC.
multi_look output_other/$date2/$date2.rslc output_other/$date2/$date2.rslc.par output_other/$date2/$date2.rmli output_other/$date2/$date2.rmli.par 1 5 >> output_other/$date2/resample.txt

echo 3. Convert MLI to raster and PNG, and move to output_rslc folder.

# Convert to raster and png
raspwr output_other/$date2/$date2.rmli $widthslc1 >> output_other/$date2/resample.txt >> output_other/$date2/resample.txt
convert output_other/$date2/$date2.rmli.bmp output_other/$date2/$date2.rmli.png >> output_other/$date2/resample.txt

# Copy to output_rslc/$date2

cp -r output_other/$date2/$date2.rslc* output_rslc
cp -r output_other/$date2/$date2.rmli* output_rslc
echo ................................................................................................


echo "Completed! :)"
echo ................................................................................................

else

echo Offset files already exist, moving on to next date...
echo "Completed! :)"
echo ................................................................................................

fi

# Then you're done! all the SLC files will have been resampled to the geometry of the primary SLCs :)

