#!/bin/bash

## Script to create resampled Envisat SLCs, 
## ready to create interferograms that can be input into StaMPS in a loop.

# Resampling all the SLCs to one common geometry - 20041008
# Start from May 2003 to June 2010

# First, resample all the SLCs, but don't make interferograms for all of the resampled SLCs.
# Aim as best as you can to make this an automated process.

## Natalie Forrest
## 30th September 2022: updated for Envisat 2nd Feb 2023

#############################
## Define parameters

track=track50_des
frame=2799

inpfile="$nat/Geodesy/Envisat/metadata/output_data/1_input_metadata_track50.f2799.txt"
nlines=`cat $inpfile | wc -l` # word count to extract number of lines

module load gamma/20201216


for i in $(seq 2 $nlines); # count from first line, no title
do 
echo "................................................................................................"

# Define the primary SLC
date1=20041008

# Define date2 as the first column in the each line
date2=`cat $inpfile | awk 'NR=='$i' {print $2}'`

echo $(($i -1)) $date1 $date2 $track $frame

## Run the batch script
./bin/GAMMA_1resample_single.sh $date1 $date2 $track $frame

done
