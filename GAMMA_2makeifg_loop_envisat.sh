#!/bin/bash

## Script to create interferograms from resampled Envisat SLCs.

# All SLCs have been resampled one common geometry - 20041008
# Start from May 2003 to June 2010

## Natalie Forrest
## 30th September 2022: updated for Envisat 2nd Feb 2023

#############################
## Define parameters

track=track50_des
frame=2799

inpfile="$nat/Geodesy/Envisat/metadata/output_data/3_input_baseline_data_filt_track50.f2799.300.1100.txt"

nlines=`cat $inpfile | wc -l` # word count to extract number of lines

#module load gamma/20201216


for i in $(seq 2 $nlines); # count from second line, there is a title
do 
echo "................................................................................................"

# Define date1
date1=`cat $inpfile | awk 'NR=='$i' {print $2}'`

# Define date2 as the first column in the each line
date2=`cat $inpfile | awk 'NR=='$i' {print $4}'`

echo $(($i -1)) $date1 $date2 $track $frame

## Run the batch script
./bin/GAMMA_2makeifg_single.sh $date1 $date2 $track $frame

done
