#!/bin/bash

## Script to create resampled interferograms for StaMPS in a loop.
# Resampling all the SLCs to one common geometry - 19970905

# Start from 1992/05/05 to 1999/10/14

# All the SLCs have been resampled, and I am now making interferograms
# for all of the resampled SLCs.
# Aim as best as you can to make this an automated process.

## Natalie Forrest
## 30th September 2022: updated 6th December 2022

#############################
## Define parameters

### Input file
# Run for postseismic interferograms 1995-1999 (before March 2000 gyro failure)
inpfile="$nat/Geodesy/ERS/baseline/output_data/20230329.baseline_track50.300.1100.txt"

terrain_correction=1 # do the terrain correction if 1

#module load gamma/20201216

nlines=`cat $inpfile | wc -l` # word count to extract number of lines

for i in $(seq 2 $nlines); # count from second line, there is a title
do 

#echo $i
echo ................................................................................................

# Define date1 as the second column in the each line
date1=`cat $inpfile | awk 'NR=='$i' {print $2}'`

# Define date2 as the fourth column in the each line
date2=`cat $inpfile | awk 'NR=='$i' {print $4}'`

echo $[$i - 1] $date1 $date2

##### RUN EACH COMMAND

## 1 Run the batch script - Note I have taken out the ramp correction
./bin/GAMMA_makeifg_single.sh $date1 $date2 $terrain_correction

#./bin/GAMMA_makeifg_filter_single.sh $date1 $date2 $terrain_correction
#./bin/BASH_make_tif.sh $date1 $date2

## 2 Run the script which transfers important data to a StaMPS folder
./bin/BASH_move2stamps.sh $date1 $date2

done

echo ................................................................................................
echo "Finished all $nlines interferograms :)"
echo ................................................................................................
