#!/bin/bash

## Script to make an interferogram from two resampled Envisat SLCs.

# The two dates need to be defined in advance, 
# as well as the track and frame.

# Natalie Forrest
## 2nd February 2023

##############################
# PRE-PROCESSING

echo "................................................................................................"
echo "PRE-PROCESSING"

echo "1. Defining parameters."

date1=$1           ## Primary SLC
date2=$2           ## Secondary SLC

track=$3           ## Track to process, e.g. track143_asc
frame=$4           ## Frame to process

both=${date1}_${date2}
output_both=$track/resampled_ifgs/$both

## List
## $nat/Geodesy/Envisat/metadata/output_data/1_metadata_track50.f2799.txt

output_resample_date1=$track/resampled_ifgs/1output_resampled/$date1
output_resample_date2=$track/resampled_ifgs/1output_resampled/$date2

module load gamma/20201216

echo "2. Processing data $date1 and $date2, for $track and frame $frame."

## Firstly, check if the interferogram already exists. If yes, terminate script. If no, make directory.
if [ -d $output_both/ ]
then
echo "Files already exist - Completed :)"
echo ................................................................................................
## TERMINATE SCRIPT
exit 0
fi

## If script doesn't terminate, assume that we need to start from scratch and go
echo "Note: $output_both doesn't exist. Making now."
mkdir $output_both

## Next, move resampled data to the output folder.
echo "3. Copying resampled files to the $output_both directory."

cp $output_resample_date1/$date1.rslc* $output_both/
cp $output_resample_date1/$date1.rmli* $output_both/

cp $output_resample_date2/$date2.rslc* $output_both/
cp $output_resample_date2/$date2.rmli* $output_both/

echo "4. Defining variables from the SLC parameter files - width of SLC and ERS satellite number."

### Define width of the SLC
widthslc1=`cat $output_both/$date1.rslc.par | grep range_samples | awk '{print $2}'`
widthslc2=`cat $output_both/$date2.rslc.par | grep range_samples | awk '{print $2}'`

echo ................................................................................................
echo Primary SLC --------- $date1, with a width of $widthslc1.
echo Secondary SLC ------- $date2, with a width of $widthslc2.
echo ................................................................................................

######################## 
##### Create interferogram

echo "CREATING INTERFEROGRAM $both."

echo "1. Generate the offset files between the two SLCs."

## Generate initial offset file
create_offset $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off 1 1 1 0 > $output_both/history.txt
## First 1: the algorithm for offset estimation is intensity cross-correlation
## Second & Third 1: number of interferogram range looks & azimuth looks are 1 and 1
## Zero: Interactive mode is off

## Estimate initial offset with orbital vectors within the parameter file
init_offset_orbit $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off >> $output_both/history.txt

## Estimate initial offset (1): Multi-looked offset
init_offset $output_both/$date1.rslc $output_both/$date2.rslc $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off 1 5 >> $output_both/history.txt
 
## Estimate initial offset (2): Full resolution update
init_offset $output_both/$date1.rslc $output_both/$date2.rslc $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off 1 1 >> $output_both/history.txt

## Compute precise orbit & reiterate
# 128 128: range & azimuth patch size
# 1: SLC oversampling factor (default is 2)
# 8 8: number of offset estimates in range & azimuth direction (could be default from offset parameter file)
# 0.15: cross-correlation threshold

offset_pwr $output_both/$date1.rslc $output_both/$date2.rslc $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/offs $output_both/ccp 128 128 $output_both/offsets 1 8 8 0.15 >> $output_both/history.txt

offset_pwr $output_both/$date1.rslc $output_both/$date2.rslc $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/offs $output_both/ccp 64 64 $output_both/offsets 1 8 8 0.10 >> $output_both/history.txt

## Generate offsets polynomial & reiterate
# 0.15: cross-correlation threshold
# 3: number of polynomial parameters (options: 1,3,4,6)
offset_fit $output_both/offs $output_both/ccp $output_both/$both.off $output_both/coffs $output_both/coffsets 0.15 3 0 >> $output_both/history.txt
offset_fit $output_both/offs $output_both/ccp $output_both/$both.off $output_both/coffs $output_both/coffsets 0.1 3 0 >> $output_both/history.txt

echo "2. Generate interferogram."
SLC_intf $output_both/$date1.rslc $output_both/$date2.rslc $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$both.int 1 5 - - 1 1 >> $output_both/history.txt

rasmph $output_both/$both.int $widthslc1 >> $output_both/history.txt
convert $output_both/$both.int.bmp $output_both/$both.int.png >> $output_both/history.txt

echo "3. Calculate interferometric baselines."

## 1 Estimate the baseline using the orbital information. 
## FFT is estimated in window of 1024x1024 pixels.
base_init $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$both.int $output_both/$both.base 2 1024 1024 >> $output_both/history.txt

## 2 Displays how the parallel and perpendicular component of the baseline changes 
## both along- and across-track
base_perp $output_both/$both.base $output_both/$date1.rslc.par $output_both/$both.off >> $output_both/$both.base.perp

##### Curved Earth phase trend removal ("flattening")
## 3 Calculate the phase trend expected for a smooth curved earth
ph_slope_base $output_both/$both.int $output_both/$date1.rslc.par $output_both/$both.off $output_both/$both.base $output_both/$both.flt >> $output_both/history.txt

echo "4. Converting flattened interferogram to PNG."
rasmph $output_both/$both.flt $widthslc1 >> $output_both/history.txt
convert $output_both/$both.flt.bmp $output_both/$both.flt.png >> $output_both/history.txt

echo "................................................................................................"
echo "GEOCODING MLI AND DEM PREPARATION"

echo "1. Calculate terrain-geocoding lookup table."

## Calculate terrain-geocoding lookup table and DEM derived data products
gc_map1 $output_both/$date1.rmli.par - data/topo/grevena.dem_par data/topo/grevena.dem $output_both/EQA.dem_par $output_both/EQA.dem $output_both/$date1.lt 2 2 $output_both/$date1.sim_sar $output_both/u $output_both/v $output_both/inc $output_both/psi $output_both/pix $output_both/$date1.ls_map 8 2 >> $output_both/history.txt

echo "1b. Defining width of the DEM:"
width_dem=`cat $output_both/EQA.dem_par | grep width | awk '{print $2}'`
echo $width_dem pixels.

echo "2. Calculate terrain correction."

# Refine the geocoding lookup table, by calculating terrain-based normalisation factors
# pix_sigma0 pix_gamma0
pixel_area $output_both/$date1.rmli.par $output_both/EQA.dem_par $output_both/EQA.dem $output_both/$date1.lt $output_both/$date1.ls_map $output_both/inc $output_both/pix_sigma0 $output_both/pix_gamma0 >> $output_both/history.txt

### Correction to geocoding table based upon simulated and real MLI image

echo "3. Correcting geocoding table using sim_sar."
create_diff_par $output_both/$date1.rmli.par - $output_both/$date1.diff_par 1 0 >> $output_both/history.txt

offset_pwrm $output_both/pix_sigma0 $output_both/$date1.rmli $output_both/$date1.diff_par $output_both/offs $output_both/cpp 256 256 $output_both/offsets 2 64 64 0.5 >> $output_both/history.txt

offset_fitm $output_both/offs $output_both/cpp $output_both/$date1.diff_par $output_both/coffs $output_both/coffsets 0.5 1 >> $output_both/history.txt

gc_map_fine $output_both/$date1.lt $width_dem $output_both/$date1.diff_par $output_both/$date1.lt_fine 1 >> $output_both/history.txt

# Geocode mli image using lookup table
echo "4. Geocoding MLI image with lookup table."
geocode_back $output_both/$date1.rmli $widthslc1 $output_both/$date1.lt_fine $output_both/EQA.mli $width_dem - 2 0 >> $output_both/history.txt

### Transforming DEM heights into SAR Geometry of MLI
echo "5. Transform DEM data into SAR geometry." #5335
geocode $output_both/$date1.lt_fine $output_both/EQA.dem $width_dem $output_both/$date1.hgt $widthslc1 - 2 0 >> $output_both/history.txt

# Geocode back DEM
echo "6. Geocode back DEM."
geocode_back $output_both/$date1.hgt $widthslc1 $output_both/$date1.lt_fine $output_both/$date1.hgt.geo $width_dem - 0 0 >> $output_both/history.txt

echo "................................................................................................"
###################################
## 7. I then remove the terrain correction
echo "CALCULATE BASELINES"

echo 1. Estimating interferometric baseline
## 1 Estimate the baseline using the orbital information. 
## FFT is estimated in window of 1024x1024 pixels.
base_init $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$both.int $output_both/$both.base 2 1024 1024 >> $output_both/history.txt

echo 2. Estimating perpendicular baseline.
## 2 Displays how the parallel and perpendicular component of the baseline changes 
## both along- and across-track
base_perp $output_both/$both.base $output_both/$date1.rslc.par $output_both/$both.off >> $output_both/$both.base.perp

echo "................................................................................................"
echo "REMOVE TERRAIN CORRECTION"

# Simulate unwrapped topographic phase
echo "1. Simulate unwrapped topographic phase."
phase_sim $output_both/$date1.rslc.par $output_both/$both.off $output_both/$both.base $output_both/$date1.hgt $output_both/$both.sim_unw 0 0 >> $output_both/history.txt

# Parameter file for ifgm
echo "2. Create ifg parameter file."
create_diff_par $output_both/$both.off - $output_both/$both.diff_par 0 0 >> $output_both/history.txt

# Subtract topographic phase
echo "3. Subtract topographic phase."
sub_phase $output_both/$both.int $output_both/$both.sim_unw $output_both/$both.diff_par $output_both/$both.diff_int 1 >> $output_both/history.txt

# Removal of linear phase trends
echo "4. Subtract linear phase trends."
base_init $output_both/$date1.rslc.par $output_both/$date2.rslc.par $output_both/$both.off $output_both/$both.diff_int $output_both/$both.base_res 4 >> $output_both/history.txt

# Improved baseline
echo "5. Improving baseline."
base_add $output_both/$both.base $output_both/$both.base_res $output_both/$both.base1 1 >> $output_both/history.txt

# Generate unwrapped phase with new baseline
echo "6. Generate unwrapped phase with new baseline."
phase_sim $output_both/$date1.rslc.par $output_both/$both.off $output_both/$both.base1 $output_both/$date1.hgt $output_both/$both.sim_unw1 0 0 - - >> $output_both/history.txt

# Subtract new simulated phase 
echo "7. Subtract new simulated phase."
sub_phase $output_both/$both.int $output_both/$both.sim_unw1 $output_both/$both.diff_par $output_both/$both.diff_int1 1 0 >> $output_both/history.txt

echo "8. Convert to PNG."
rasmph $output_both/$both.diff_int1 $widthslc1 >> $output_both/history.txt
convert $output_both/$both.diff_int1.bmp $output_both/$both.diff_int1.png >> $output_both/history.txt

############################################################
# GEOCODE INTERFEROGRAM
echo "................................................................................................"
echo "GEOCODE INTERFEROGRAM"

## This is the only line that doesn't work?? Fixed Nov 2022 (widthdem was written, not width_dem)
echo "1. Geocode back to map geometry"
geocode_back $output_both/$both.diff_int1 $widthslc1 $output_both/$date1.lt_fine $output_both/$both.diff.geo $width_dem - 0 1 >> $output_both/history.txt

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

echo "Finished! :)"
echo "................................................................................................"
