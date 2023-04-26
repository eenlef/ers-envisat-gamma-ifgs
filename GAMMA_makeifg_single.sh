#!/bin/bash

## Script to create resampled SLCs and form interferogram

# This script is a batch process for generating an interferogram between two resampled SLCs.

## Natalie Forrest
## 30th September 2022: updated 6th December 2022

#############################
## Define parameters

## ./bin/GAMMA_makeifg_single.sh $date1 $date2 $dem_correction

# For new run, update the location to output interferograms & products

echo ................................................................................................
echo PRE-PROCESSING

echo 1. Defining parameters.

date1=$1     ## This is the primary SLC, and is hard coded into the script.
#widthslc1=4903     ## Alternatively read from the SLC parameter file :)
#ers_sat_slc1=1

date2=$2            ## Secondary SLC
#date2=19960223

dem_correction=1
#dem_correction=$3 # option N (0) or Y (1). 
# No is default


## Define output folders - CHANGE THIS FOR NEW RUNS	
both=${date1}_${date2}
#output_both=output_ifg/$both
output_both=$nat/Geodesy/ERS/track50/resampled_SLCs/20230329_output_ifg/$both

## Are we creating for StaMPS? If yes, don't filter & geocode:
stamps=1 # set to 0 if not for stamps

module load gamma/20201216

echo "DEM correction parameter:" $dem_correction

echo 2. Processing data $date1 and $date2.

##############################
# PRE-PROCESSING
## 1. Started with the extracted SLC and SLC.par files, with the orbital correction applied. I also added the .dem and .dem_par files.

### Before this, check if no_topo folder exists and then if we don't want the terrain correction, end the script, or skip to line 559
if [ -d $output_both/${both}_notopo/ ] && [ ! $dem_correction -eq 1 ]
then
echo "You've requested the data with no terrain correction."
echo Files already exist - "Completed :)"
echo ................................................................................................

## TERMINATE SCRIPT
exit 0
fi

# Make directory for interferogram 
if [ ! -d 20230329_output_ifg/$both/ ] #if 3
then 
echo Note: 20230329_output_ifg/$both/ "doesn't exist. Making now."
mkdir 20230329_output_ifg/$both

#output_both=output_ifg/$both
#output_both=$nat/Geodesy/ERS/track50/resampled_SLCs/20230329_output_ifg/$both

else
echo Note: $output_both "exists already."
fi #if 3

echo ................................................................................................


######## Extract files (if they don't exist)
## If the data in the data/SLC/ folder doesn't exist, then assume you need to:

# 1 Make the directories for output_ifg/$both and extract files from output_rslc folder
# 2 Define the parameters (width & satellite number)


echo PRE-PROCESSING

# If the resampled SLC data doesn't exist, then copy it from that directory and define parameters
if [ ! -f $output_both/$date1.rslc ] #if 4
then 
echo "Resampled data not in folder yet: copying over now"

echo 1. Copying resampled files to the $output_both directory.

cp output_rslc/$date1.* $output_both/
#cp output_other/$date1.rslc.par $both

cp output_rslc/$date2.* $output_both/
#cp output_other/$date2.rslc.par $both

echo 2. Defining variables from the SLC parameter files - width of SLC and ERS satellite number.

# Otherwise, these files already exist
else #if 4
echo Resampled data already present, defining parameters - width of SLC and ERS satellite number.

fi #if 4

### Define width of the SLC and the satellite number for date1
widthslc1=`cat $output_both/$date1.rslc.par | grep range_samples | awk '{print $2}'`
ers_sat_slc1=`cat $output_both/$date1.rslc.par | grep title | awk 'BEGIN { FS="."} ; {print $2}' | cut -c 2`

### Define width of the SLC and the satellite number for date2
widthslc2=`cat $output_both/$date2.rslc.par | grep range_samples | awk '{print $2}'`
ers_sat_slc2=`cat $output_both/$date2.rslc.par | grep title | awk 'BEGIN { FS="."} ; {print $2}' | cut -c 2`

echo ................................................................................................
echo Primary SLC --------- $date1, with a width of $widthslc1 and from ERS-$ers_sat_slc1.
echo Secondary SLC ------- $date2, with a width of $widthslc2 and from ERS-$ers_sat_slc2.
echo ................................................................................................

################################
## 2. I generate the pre-interferogram files, starting with the offset & co-registration files

#echo GENERATING PRE-INTERFEROGRAM FILES
#echo Checking whether offset files already exist...

# If files don't exist, make them! Else, skip.
if [ ! -f $output_both/$both.off ] #if 8
then 

echo No previous offset files exist. Creating now...
echo ................................................................................................

echo 1. Generate the offset files between the two files.

## Generate initial offset file
create_offset $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off 1 1 1 0 > $output_both/history.txt

## First 1: the algorithm for offset estimation is intensity cross-correlation
## Second & Third 1: number of interferogram range looks & azimuth looks are 1 and 1
## Zero: Interactive mode is off

#echo 2. Estimate initial offset using orbits.

## Estimate initial offset with orbital vectors within the parameter file
init_offset_orbit $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off >> $output_both/history.txt

#echo 3. Estimate initial offset, takes about 10 seconds.

## Estimate initial offset (1): Multi-looked offset
init_offset $output_both/$date1.rslc $output_both/$date2.rslc $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off 1 5 >> $output_both/history.txt
 
## Estimate initial offset (2): Full resolution update
init_offset $output_both/$date1.rslc $output_both/$date2.rslc $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off 1 1 >> $output_both/history.txt

#echo 4. Compute precise orbit.

## Compute precise orbit & reiterate
# 128 128: range & azimuth patch size
# 1: SLC oversampling factor (default is 2)
# 8 8: number of offset estimates in range & azimuth direction (could be default from offset parameter file)
# 0.15: cross-correlation threshold

offset_pwr $output_both/$date1.rslc $output_both/$date2.rslc $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/offs $output_both/ccp 128 128 $output_both/offsets 1 8 8 0.15 >> $output_both/history.txt

#offset_pwr $output_both/$date1.rslc $output_both/$date2.rslc $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/offs $output_both/ccp 64 64 $output_both/offsets 1 8 8 0.10 >> $output_both/history.txt

#echo 5. Generate offset polynomial.

## Generate offsets polynomial & reiterate
# 0.15: cross-correlation threshold
# 3: number of polynomial parameters (options: 1,3,4,6)

offset_fit $output_both/offs $output_both/ccp $output_both/$both.off $output_both/coffs $output_both/coffsets 0.15 3 0 >> $output_both/history.txt

#offset_fit $output_both/offs $output_both/ccp $output_both/$both.off $output_both/coffs $output_both/coffsets 0.1 3 0 >> $output_both/history.txt

#offset_fit $output_both/offs $output_both/ccp $output_both/$both.off $output_both/coffs $output_both/coffsets 0.1 4 0 >> $output_both/history.txt

## John Elliott has the following, and uses the data from the offset file instead (better for automated processes)
# offset_fit offs ccp $date1_$date2.off coffs coffsets - 4

#echo ................................................................................................

#echo RESAMPLE SECOND SLC TO FIRST SLC GEOMETRY

#echo 1. Resample secondary SLC to primary SLC geometry, takes about 20 seconds.

# Resample second SLC to first SLC geometry
#SLC_interp $output_both/$date2.rslc $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$date2.rslc $output_both/$date2.rslc.par >> $output_both/history.txt

#echo 2. Multi-look resampled SLC.

# Multi-look resampled SLC.
#multi_look $output_both/$date2.rslc $output_both/$date2.rslc.par $output_both/$date2.rmli $output_both/$date2.rmli.par 1 5 >> $output_both/history.txt

#echo 3. Convert MLI to raster and PNG, and move to output_rslc folder.

# Convert to raster and png
#raspwr $output_both/$date2.rmli $widthslc1 >> $output_both/history.txt
#convert $output_both/$date2.rmli.bmp $output_both/$date2.rmli.png >> $output_both/history.txt


## Calculate coherence
#cc_wave $both.int $date1.mli $date2.mli $both.cc $widthslc1 5 5 1


else #if 8

echo Offset files already exist.

fi #if 8

echo "Offset file generation completed! :)"
echo ................................................................................................


################################
## 4. Next, I make the interferogram

echo CALCULATING INTERFEROGRAM

# If files don't exist, make them! Else, skip.
if [ ! -f $output_both/$both.int ] #if 9
then 

echo 1. "Interferogram doesn't exist, creating now."
# Calculate interferogram from co-registered SLC image data
# 1 is range looks, 5 is azimuth looks
# 1 1: apply range spectral shift filter, and azimuth common band filter
SLC_intf $output_both/$date1.rslc $output_both/$date2.rslc $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$both.int 1 5 - - 1 1 >> $output_both/history.txt

else

echo 1. "Interferogram already exists."

fi #if 9

################################
# 5. Are we doing the terrain correction?
## If no, estimate interferometric baseline.
## If yes, skip that and work out terrain correction.

##### Estimation of interferometric baseline
## Only do this if we aren't doing the terrain correction:

# If we aren't doing the terrain correction, then calculate baseline.
# If the DEM correction indicator is not 1 (either defined as 0, or not defined), then:
if [ ! $dem_correction -eq 1 ]
then 

## If baseline hasn't yet been calculated: (Nested if 12)
   if [ ! -f $output_both/$both.flt ]
   then

   echo 2. Estimating interferometric baseline
## 1 Estimate the baseline using the orbital information. 
## FFT is estimated in window of 1024x1024 pixels.
   base_init $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$both.int $output_both/$both.base 2 1024 1024 >> $output_both/history.txt

#base_init $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$both.int $output_both/$both.base 4 1024 1024 >> $output_both/history.txt

# John: 
# base_init $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$both.int $output_both/$both.base 0

   echo 3. Estimating perpendicular baseline.
## 2 Displays how the parallel and perpendicular component of the baseline changes 
## both along- and across-track
   base_perp $output_both/$both.base $output_both/$date1.rslc.par $output_both/$both.off >> $output_both/$both.base.perp

# However, when incorporating topographic phase, removing curved Earth phase trend is performed later

   echo "4. Calculating and removing curved Earth phase trend, takes about 60 seconds)."
##### Curved Earth phase trend removal ("flattening")
## 3 Calculate the phase trend expected for a smooth curved earth
   ph_slope_base $output_both/$both.int $output_both/$date1.rslc.par $output_both/$both.off $output_both/$both.base $output_both/$both.flt >> $output_both/history.txt

#   echo 5. Remove flat earth trend.
#   sub_phase $output_both/$both.flt $output_both/$both.sim_unw $output_both/$both.diff_par $output_both/$both.diff_flt 1 >> $output_both/history.txt

   echo 5. Converting initial interferogram to PNG.

   rasmph $output_both/$both.int $widthslc1 >> $output_both/history.txt
   convert $output_both/$both.int.bmp $output_both/$both.int.png >> $output_both/history.txt

   echo 6. Converting flattened interferogram to PNG.

   rasmph $output_both/$both.flt $widthslc1 >> $output_both/history.txt
   convert $output_both/$both.flt.bmp $output_both/$both.flt.png >> $output_both/history.txt

   else # if 12 (nested)
   echo 2. Baseline files already calculated.
   fi # if 12 (nested)

echo ................................................................................................
echo GEOCODING MLI AND DEM PREPARATION
echo "You have chosen to not do the DEM correction."

echo Creating and moving content to folder ${both}_notopo
mv $both ${both}_notopo

## IF NOT DOING TERRAIN CORRECTION, END HERE.
#________________________________________________________________

## ELSE, if we are doing the terrain correction
else # if 10
echo We are doing a terrain correction, so not calculating baselines just yet - Skip to Step 6.

echo 6. Converting initial interferogram to PNG.

rasmph $output_both/$both.int $widthslc1 >> $output_both/history.txt
convert $output_both/$both.int.bmp $output_both/$both.int.png >> $output_both/history.txt

#fi  #if 10

#else # if 9
#echo 1. Initial interferogram exists, skipping to next step.

#fi #if 9

echo ................................................................................................
echo GEOCODING MLI AND DEM PREPARATION
echo "You have chosen to do the DEM correction."

# If the DEM correction hasn't be done yet, then do it:
   if [ ! -f $output_both/EQA.dem ] # if 11 (nested in If 10, saying that we want terrain correction)
   then 

################################
## 5. Next, I geocode the primary MLI file

   echo 1. Calculate terrain-geocoding lookup table.

## Calculate terrain-geocoding lookup table and DEM derived data products
# EQA.dem refers to the segment of the whole dem which is relevant to the date1 mli.
# $date1.lt is the geocoding lookup table
# sim_sar s the simulated SAR backscatter image in DEM geometry
# u v inc psi: angles which define the translation of from $date1 radar to DEM geometry
# pix: pixel area normalisation factor
# 8 2: number of DEM pixels to add around the frame, and the 2 flag says that the actual value should be added to DEM gaps.
   gc_map1 $output_both/$date1.rmli.par - data/topo/grevena.dem_par data/topo/grevena.dem $output_both/EQA.dem_par $output_both/EQA.dem $output_both/$date1.lt 2 2 $output_both/$date1.sim_sar $output_both/u $output_both/v $output_both/inc $output_both/psi $output_both/pix $output_both/$date1.ls_map 8 2 >> $output_both/history.txt

#   gc_map1 $output_both/$date1.rmli.par - $data/topo/grevena_cop30_merged.dem_par $data/topo/grevena_cop30_merged.dem $output_both/EQA.dem_par $output_both/EQA.dem $output_both/$date1.lt 2 2 $output_both/$date1.sim_sar $output_both/u $output_both/v $output_both/inc $output_both/psi $output_both/pix $output_both/$date1.ls_map 8 2 >> $output_both/history.txt

   echo 1b. Defining width of the DEM:

   width_dem=`cat $output_both/EQA.dem_par | grep width | awk '{print $2}'`

   echo $width_dem pixels.

## For 19960222 example:
# Width of EQA.dem is $width_dem, length 2745
# Width of mli is 4903, length 5335

#################################
## 6. I then calculate the terrain correction - with help from Megan Udy & John Elliott

   echo 2. Calculate terrain correction.

# Refine the geocoding lookup table, by calculating terrain-based normalisation factors
# pix_sigma0 pix_gamma0
   pixel_area $output_both/$date1.rmli.par $output_both/EQA.dem_par $output_both/EQA.dem $output_both/$date1.lt $output_both/$date1.ls_map $output_both/inc $output_both/pix_sigma0 $output_both/pix_gamma0 >> $output_both/history.txt

### Correction to geocoding table based upon simulated and real MLI image

   echo 3. Correcting geocoding table using sim_sar.
   create_diff_par $output_both/$date1.rmli.par - $output_both/$date1.diff_par 1 0 >> $output_both/history.txt

   offset_pwrm $output_both/pix_sigma0 $output_both/$date1.rmli $output_both/$date1.diff_par $output_both/offs $output_both/cpp 256 256 $output_both/offsets 2 64 64 0.5 >> $output_both/history.txt

   offset_fitm $output_both/offs $output_both/cpp $output_both/$date1.diff_par $output_both/coffs $output_both/coffsets 0.5 1 >> $output_both/history.txt

   gc_map_fine $output_both/$date1.lt $width_dem $output_both/$date1.diff_par $output_both/$date1.lt_fine 1 >> $output_both/history.txt

# Geocode mli image using lookup table
   echo 4. Geocoding MLI image with lookup table.
   geocode_back $output_both/$date1.rmli $widthslc1 $output_both/$date1.lt_fine $output_both/EQA.mli $width_dem - 2 0 >> $output_both/history.txt

### Transforming DEM heights into SAR Geometry of MLI
   echo 5. Transform DEM data into SAR geometry. #5335
   geocode $output_both/$date1.lt_fine $output_both/EQA.dem $width_dem $output_both/$date1.hgt $widthslc1 - 2 0 >> $output_both/history.txt

#dishgt $output_both/$date1.hgt $output_both/$date1.rmli $widthslc1

# Geocode back DEM
   echo 6. Geocode back DEM.
   geocode_back $output_both/$date1.hgt $widthslc1 $output_both/$date1.lt_fine $output_both/$date1.hgt.geo $width_dem - 0 0 >> $output_both/history.txt

   echo ................................................................................................
###################################
## 7. I then remove the terrain correction
   echo CALCULATE BASELINES

   echo 1. Estimating interferometric baseline
## 1 Estimate the baseline using the orbital information. 
## FFT is estimated in window of 1024x1024 pixels.
   base_init $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$both.int $output_both/$both.base 2 1024 1024 >> $output_both/history.txt

#base_init $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$both.int $output_both/$both.base 4 1024 1024 >> $output_both/history.txt

# John: 
# base_init $output_both/$date1.rslc.par $output_both/$date2slc.par $output_both/$both.off $output_both/$both.int $output_both/$both.base 0

   echo 2. Estimating perpendicular baseline.
## 2 Displays how the parallel and perpendicular component of the baseline changes 
## both along- and across-track
   base_perp $output_both/$both.base $output_both/$date1.rslc.par $output_both/$both.off >> $output_both/$both.base.perp

# However, when incorporating topographic phase, removing curved Earth phase trend is performed later

#   echo "3. Calculating and removing curved Earth phase trend, takes about 60 seconds)."
##### Curved Earth phase trend removal ("flattening")
## 3 Calculate the phase trend expected for a smooth curved earth
#   ph_slope_base $output_both/$both.int $output_both/$date1.rslc.par $output_both/$both.off $output_both/$both.base $output_both/$both.flt >> $output_both/history.txt

#   echo 4. Remove flat earth trend.
#   sub_phase $output_both/$both.flt $output_both/$both.sim_unw $output_both/$both.diff_par $output_both/$both.diff_flt 1 >> $output_both/history.txt

   echo ................................................................................................
   echo REMOVE TERRAIN CORRECTION

# Simulate unwrapped topographic phase
   echo 1. Simulate unwrapped topographic phase.
   phase_sim $output_both/$date1.rslc.par $output_both/$both.off $output_both/$both.base $output_both/$date1.hgt $output_both/$both.sim_unw 0 0 >> $output_both/history.txt

# Parameter file for ifgm
   echo 2. Create ifg parameter file.
   create_diff_par $output_both/$both.off - $output_both/$both.diff_par 0 0 >> $output_both/history.txt

# Subtract topographic phase - doesn't work 7th Dec
   echo 3. Subtract topographic phase.
   sub_phase $output_both/$both.int $output_both/$both.sim_unw $output_both/$both.diff_par $output_both/$both.diff_int 1 >> $output_both/history.txt # works better
#sub_phase $output_both/$both.flt $output_both/$both.sim_unw $output_both/$both.diff_par $output_both/$both.diff_flt 1 >> $output_both/history.txt

# Removal of linear phase trends
   echo 4. Subtract linear phase trends.
#   base_init $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$both.diff_int $output_both/$both.base_res 4 >> $output_both/history.txt

# Edited to account for not removing the orbital ramp
   base_init $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$both.diff_int $output_both/$both.base_res 0 >> $output_both/history.txt

# Improved baseline
   echo 5. Improving baseline.
   base_add $output_both/$both.base $output_both/$both.base_res $output_both/$both.base1 1 >> $output_both/history.txt

# Generate unwrapped phase with new baseline
   echo 6. Generate unwrapped phase with new baseline.
   phase_sim $output_both/$date1.rslc.par $output_both/$both.off $output_both/$both.base1 $output_both/$date1.hgt $output_both/$both.sim_unw1 0 0 - - >> $output_both/history.txt

# Subtract new simulated phase 
   echo 7. Subtract new simulated phase.
   sub_phase $output_both/$both.int $output_both/$both.sim_unw1 $output_both/$both.diff_par $output_both/$both.diff_int1 1 0 >> $output_both/history.txt
#dismph $output_both/$both.diff_int1 $widthslc1 &

   echo 8. Convert to PNG.
   rasmph $output_both/$both.diff_int1 $widthslc1 >> $output_both/history.txt
   convert $output_both/$both.diff_int1.bmp $output_both/$both.diff_int1.png >> $output_both/history.txt

############################################################
# GEOCODE INTERFEROGRAM
   echo ................................................................................................
   echo GEOCODE INTERFEROGRAM

   echo "1. Geocode back to map geometry"
   geocode_back $output_both/$both.diff_int1 $widthslc1 $output_both/$date1.lt_fine $output_both/$both.diff.geo $width_dem - 0 1 >> $output_both/history.txt

# Display Unwrapped Geocoded
#dismph $output_both/$both.diff.geo $width_dem &

   echo "2. Save as PNG"
# Output raster
   rasmph $output_both/$both.diff.geo $width_dem >> $output_both/history.txt

# Convert to png with transparency of black masked out
   convert $output_both/$both.diff.geo.bmp -transparent black $output_both/$both.diff.geo.png >> $output_both/history.txt

#### SKIP THIS SECTION IF you don't want to filter (otherwise takes like 10 mins)

#############
# FILTERING #
#############

   echo "3. Filter in radar geometry 1st time and save as PNG (takes about 3 minutes)"
   adf $output_both/$both.diff_int1 $output_both/$both.diff_sm $output_both/$both.smcc $widthslc1 0.3 128 7 - 0 - 0.2 >> $output_both/history.txt
   rasmph_pwr $output_both/$both.diff_sm $output_both/$date1.rmli $widthslc1 - - 1 1 - $output_both/$both.diff_sm.bmp >> $output_both/history.txt
   convert $output_both/$both.diff_sm.bmp $output_both/$both.diff_sm.png >> $output_both/history.txt

   echo "4. Filter 2nd time and save as PNG"
# 2nd Filter
   adf $output_both/$both.diff_sm $output_both/$both.diff_sm2 $output_both/$both.smcc2 $widthslc1 0.4 64 7 - 0 - 0.2 >> $output_both/history.txt
   rasmph_pwr $output_both/$both.diff_sm2 $output_both/$date1.rmli $widthslc1 - - 1 1 - $output_both/$both.diff_sm2.bmp >> $output_both/history.txt
   convert $output_both/$both.diff_sm2.bmp $output_both/$both.diff_sm2.png >> $output_both/history.txt

   echo "5. Filter 3rd time and save as PNG"
# 3rd Filter
   adf $output_both/$both.diff_sm2 $output_both/$both.diff_sm3 $output_both/$both.smcc3 $widthslc1 0.5 32 7 - 0 - 0.2 >> $output_both/history.txt

#dismph_pwr $output_both/$both.diff_sm3 $output_both/$date1.rmli $widthslc1

# Output raster
   rasmph_pwr $output_both/$both.diff_sm3 $output_both/$date1.rmli $widthslc1 - - 1 1 - $output_both/$both.diff_sm3.bmp >> $output_both/history.txt
   convert $output_both/$both.diff_sm3.bmp $output_both/$both.diff_sm3.png >> $output_both/history.txt

########################
# GEOCODE Filtered Ifgm - back in normal map geometry

   echo "6. Geocode back the filtered interferogram and save as PNG"
   geocode_back $output_both/$both.diff_sm3 $widthslc1 $output_both/$date1.lt_fine $output_both/$both.diff_sm.geo $width_dem - 0 1 >> $output_both/history.txt
#dismph $output_both/$both.diff_sm.geo $width_dem & >> $output_both/history.txt

   rasmph $output_both/$both.diff_sm.geo $width_dem >> $output_both/history.txt
   convert $output_both/$both.diff_sm.geo.bmp $output_both/$both.diff_sm.geo.png >> $output_both/history.txt

#   rasdt_pwr $output_both/$both.diff_sm.geo $output_both/EQA.mli $width_dem - - 1 1 - - - - $output_both/$both.diff_sm.geo.pwr.bmp >> $output_both/history.txt
#   convert $output_both/$both.diff_sm.geo.pwr.bmp $output_both/$both.diff_sm.geo.pwr.png >> $output_both/history.txt

########################
# Generate COHERENCE files
    echo "7. Generate coherence files"
cc_wave $output_both/$both.int $output_both/$date1.rmli $output_both/$date2.rmli $output_both/$both.cc $widthslc1 5 5 1 >> $output_both/history.txt
rasdt_pwr $output_both/$both.cc - $widthslc1 >> $output_both/history.txt


###############
# UNWRAPPING
#   echo ................................................................................................
#   echo UNWRAPPING 

#   echo 1. Generate phase unwrapping mask "in radar geometry"
########## MCF
# Phase unwrapping mask
#   rascc_mask $output_both/$both.smcc3 $output_both/$date1.rmli $widthslc1 1 1 0 1 1 0.6 0.0 0.1 0.9 1.0 0.20 1 $output_both/$both.mask.ras >> $output_both/history.txt

#   echo 2. Set reference pixel, and unwrap
# Unwrap (set also reference pixel)
#   mcf $output_both/$both.diff_sm3 $output_both/$both.smcc $output_both/$both.mask.ras $output_both/$both.diff_sm.unw $widthslc1 1 - - - - 1 1 - 1000 1000 >> $output_both/history.txt

#disrmg $output_both/$both.diff_sm.unw $date1mli $widthslc1 1 1 0 1.0 1. .20 0.

#   echo 3. Geocode back the unwrapped interferogram to map geometry.
# Geocode unwrapped
#   geocode_back $output_both/$both.diff_sm.unw $widthslc1 $output_both/$date1.lt_fine $output_both/$both.diff.unw.geo $width_dem - 0 >> $output_both/history.txt

 #  echo 4. Save as PNG
# Output raster
###   rasrmg $output_both/$both.diff.unw.geo $output_both/EQA.mli $width_dem 1 1 0 4 4 1. 1. .20 0 1 $output_both/$both.diff.unw.geo.bmp >> $output_both/history.txt
#   rasdt_pwr $output_both/$both.diff.unw.geo $output_both/EQA.mli $width_dem - - 1 1 - - - - $output_both/$both.diff.unw.geo.pwr.bmp >> $output_both/history.txt

# Convert to png with transparency of black masked out
#   convert $output_both/$both.diff.unw.geo.bmp -transparent black $output_both/$both.diff.unw.geo.pwr.png >> $output_both/history.txt


## BUT, if terrain correction is done, skip to here.
   else #if 11 (nested in if 10) - if we want the terrain correction, but it has already been done, then:
   echo "Terrain correction already completed."
fi # if 11

   fi #if 10

echo ................................................................................................
echo "Completed :)"
echo ................................................................................................
