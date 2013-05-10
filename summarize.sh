#!/bin/sh

# Summarize - Preprocessing Report on Multispectral Data
# Script should be called from the folder containing all of the Daily folders.

echo
echo ------------------------------------------------------
echo Summarize - Preprocessing Report on Multispectral Data
echo ------------------------------------------------------
echo

report="Summarize Report - $(date +"%F")_$(date +"%T").txt"

echo >>$report
echo "Summarize Report - $PWD - $(date +"%F") - $(date +"%T")">>$report
echo >>$report

## Collect Volume names and page numbers
echo "---------------------------">>$report
echo "Folder Structure and Naming">>$report
echo "---------------------------">>$report
echo >>$report
all_vol_names=()
vol_exists=""
# For each daily folder
for i in */; do
	echo "Daily folder: $(basename $i)">>$report
	flat_exists=""
	# Check each subfolder
	for j in $(basename $i)/*; do
		  # Report if you find a flatfield, else process Volume and Page info
		  if [[ $j =~ FLATS_* ]]; then
			  echo "     Flatfield folder found: $j">>$report
			  # If already found a flatfield, call a warning
			  if [[ $flat_exists == "true" ]]; then
			  	echo "     WARNING: Multiple flatfield folders detected for $(basename $i)!">>$report 
			  fi
			  flat_exists="true"
		  else
			  # Get volume name
			  vol_name=$(basename "$j" | sed 's/\(.*\)-[0-9]*/\1/')
			  page_name=${j#*-}
			  
			  # Check master volumes array to see if we've seen this volume before
			  for stored_vol in ${all_vol_names[@]}; do
			  	if [[ "$stored_vol" == "$vol_name" ]]; then vol_exists="true"; fi
			  done
			  
			  # If we haven't seen it, then add it to the master volumes array and add a sub-array
			  if [[ "$vol_exists" != "true" ]]; then all_vol_names+=("$vol_name"); declare -a $vol_name; fi
			  vol_exists=""
			  
			  TEMP="\${$vol_name[@]}"
			  LIST=`eval echo $TEMP`
			  for number in $LIST; do
			  	if [[ "$number" == "$page_name" ]]; then
			  		duplicate="true"
			  	fi
			  done
			  if [[ "$duplicate" == "true" ]]; then
			  	echo "     WARNING: Duplicate folder for $vol_name page $page_name detected in $(basename $i)!">>$report
			  else
			  	eval "$vol_name+=( "$page_name" )"
			  fi
			  duplicate=""
		  fi
	done	  
	if [[ "$flat_exists" != "true" ]]; then
		echo "     WARNING: Flatfield folder not detected for $(basename $i)!">>$report
	fi
	echo >>$report
done

echo "----------------------------">>$report
echo "Summary of Volumes and Pages">>$report
echo "----------------------------">>$report
echo >>$report
for i in ${all_vol_names[@]}; do
echo "     Volume Name: $i">>$report
	TEMP="\${$i[@]}"  
    LIST=`eval echo $TEMP`
    LIST=$(for j in $LIST; do echo "$j "; done | sort | tr -d '\n')
    echo "          $LIST">>$report
echo >>$report
done

cat "$report" | grep "WARNING"
echo
echo Report Generated to $report
echo
exit