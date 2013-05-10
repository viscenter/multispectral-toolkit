#!/bin/sh

# Summarize - Preprocessing Report on Multispectral Data
# Script should be called from the folder containing all of the Daily folders.

echo
echo ------------------------------------------------------
echo Summarize - Preprocessing Report on Multispectral Data
echo ------------------------------------------------------
echo

report="$(date +"%F")_$(date +"%T")_summarizereport.txt"

echo "Summarize Report - $PWD - $(date +"%F") - $(date +"%T")">>$report
echo >>$report

all_vol_names=()
Chad=()
exists=""

## Collect Volume names and page numbers
for i in */; do
	echo "Daily folder: $(basename $i)">>$report
	echo >>$report
	for j in $(basename $i)/*; do
		  if [[ $j =~ FLATS_* ]]; then
			  echo "Flatfield folder found: $j" 
		  else
			  # Get volume name
			  vol_name=$(basename "$j" | sed 's/\(.*\)-[0-9]*/\1/')
			  page_name=$(basename "$j" | sed 's/.*-\([0-9]*\)/\1/')
			  
			  # Create volume array if doesn't exist
			  
			  for stored_vol in ${all_vol_names[@]}; do
			  	if [[ "$stored_vol" == "$vol_name" ]]; then exists="TRUE"; fi
			  done
			  	
			  if [[ "$exists" != "TRUE" ]]; then all_vol_names+=("$vol_name"); fi
			  exists=""
			  
			  echo ${!vol_name}
			  #${!vol_name}+=("$page_name")
		  fi
	
	done	  
		
done

exit

for i in ${all_vol_names[@]}; do
echo $i
	TEMP="\${$i[*]}"  
    ROW=`eval echo $TEMP`
    for j in $ROW; do
    	echo $j
    done
done

exit