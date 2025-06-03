#!/bin/bash

## Script to create resampled ERS interferograms for StaMPS in a loop.
# Resampling all the SLCs to one common geometry - 19970905

# Start from 1992/05/05 to 1999/10/14

# First, resample all the SLCs, but don't make interferograms for all of the resampled SLCs.
# Aim as best as you can to make this an automated process.

## Natalie Forrest
## 30th September 2022: updated 4th November 2022

#############################
## Define parameters

#inpfile="./data/input.txt"
#inpfile="./data/input/20230206_ordmetadata_track50_post2000.txt"

inpfile="$nat/Geodesy/ERS/baseline/20230207_metadata_track50.txt"

module load gamma/20201216

nlines=`cat $inpfile | wc -l` # word count to extract number of lines

for i in $(seq 2 $nlines); # count from second line, there is a title
do 

#echo $i
echo ................................................................................................

# Define date2 as the first column in the each line
date2=`cat $inpfile | awk 'NR=='$i' {print $2}'`

echo $(($i-1)) $date2

## Run the batch script

./bin/GAMMA_resample_single.sh $date2

done
