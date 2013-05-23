#!/bin/sh

# Summarize - Preprocessing Report on Multispectral Data
# Script should be called from the folder containing all of the Daily folders.

echo
echo ------------------------------------------------------
echo Summarize - Preprocessing Report on Multispectral Data
echo ------------------------------------------------------
echo

# Function for comparing two arrays
containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

# Generate report name and setup report
report="Summarize Report - $(date +"%F")_$(date +"%T").txt"

echo >>$report
echo "Summarize Report - $PWD - $(date +"%F") - $(date +"%T")">>$report
echo >>$report

# Collect Volume names and page numbers
echo "---------------------------">>$report
echo "Folder Structure and Naming">>$report
echo "---------------------------">>$report
echo >>$report
all_vol_names=()
vol_exists=""
ROOT=$PWD
# For each daily folder
for i in */; do
	echo "Daily folder: $(basename $i)">>$report
	multi_flats=""
	flat_exists=""
	# Check each subitem, if it's a folder...
	for j in $(basename $i)/*; do
		  if [[ -d $j ]]; then
		  # Report if you find a flatfield, else process Volume and Page info
		  if [[ $j =~ FLATS_* ]]; then
			  echo "     Flatfield folder found: $j">>$report
			  # If already found a flatfield, call a warning
			  if [[ $flat_exists == "true" ]]; then
			  	multi_flats="true"
			  	flatserror="y"
			  fi
			  # If first flatfield found, collect multispectral info
			  if [[ $flat_exists != "true" ]]; then
			  	for k in $(basename $i)/$(basename $j)/Processed/*.tif; do
			  		eval "$(basename $i)+=( "$(exiv2 -qpa $k | grep Exif.Photo.SpectralSensitivity | awk '{print $4}' | sed 's/(\([0-9A-Za-z]*\)nm,/\1/')" )"
			  	done
			  fi
			  flat_exists="true"
		  else
			  # Get volume name
			  j=$(basename $j)
			  vol_name=${j%-*}
			  page_name=${j#*-}
			  
			  # Check master volumes array to see if we've seen this volume before
			  for stored_vol in ${all_vol_names[@]}; do
			  	if [[ "$stored_vol" == "$vol_name" ]]; then vol_exists="true"; fi
			  done
			  
			  # If we haven't seen it, then add it to the master volumes array and add a sub-array
			  if [[ "$vol_exists" != "true" ]]; then all_vol_names+=("$vol_name"); declare -a $vol_name; fi
			  vol_exists=""
			  
			  # Fancy string substitution
			  TEMP="\${$vol_name[@]}"
			  LIST=`eval echo $TEMP`
			  # See if this page already exists in our folio list. If it does, call a warning. NOTE: This can probably be updated with the compare function
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
		  fi
	done	  
	# Call a warning if there isn't a flatfield folder in the daily folder
	if [[ "$flat_exists" != "true" ]]; then
		echo "     WARNING: Flatfield folder not detected for $(basename $i)!">>$report
	fi
	# If we found multiple flats in this daily folder...
	if [[ "$multi_flats" == "true" ]]; then
		echo "     WARNING: Multiple flatfield folders detected for $(basename $i)!">>$report 
		# For each flatfield folder, create a variable: flatfield_wavelength=exposure time
		for j in $(basename $i)/FLATS_*; do
			mainfolder=$(basename $j)
				for k in ${j}/Processed/*.tif; do
					wavelength=$(exiv2 -g Exif.Photo.SpectralSensitivity -qPt $k | awk '{print $1}' | sed 's/(\([0-9A-Za-z]*\)nm,/\1/')
						if [[ "$wavelength" == "non" ]]; then wavelength="000"; fi
					exposure=$(exiv2 -g Exif.Photo.SpectralSensitivity -qPt $k | awk '{print $2}' | sed 's/\([0-9]*.[0-9]*\)s,/\1/')
					eval "${mainfolder}_${wavelength}=$exposure"
				done
		done
		
		# For each page folder in this daily folder...
		for page in ${i}*-[0-9A-Za-z]*; do
			echo "        $(basename $page) matches exposure data for:" >>$report
			# Iterate through all the flats folders again...
			for k in $(basename $i)/FLATS_*; do
				# Matches the flatfield by default
				matches="y"
				flatname=$(basename $k)
				# Get the exposure information for each image in the page folder
				for image in ${j}/Processed/*.tif; do
					imageinfo=$(exiv2 -g Exif.Photo.SpectralSensitivity -qPt $image)
					wavelength=$(echo $imageinfo | awk '{print $1}' | sed 's/(\([0-9A-Za-z]*\)nm,/\1/')
						if [[ "$wavelength" == "non" ]]; then wavelength="000"; fi
					exposure=$(echo $imageinfo | awk '{print $2}' | sed 's/\([0-9]*.[0-9]*\)s,/\1/')
					
					# Substitution magic
					FLATTEMP="\${${flatname}_$wavelength}"
					FLATTEMP=`eval echo $FLATTEMP`
			
					#echo "$(basename $image): $exposure"
					#echo "	${flatname}_${wavelength}: $FLATTEMP"
					
					# If we earlier found this wavelength in the currently checked flatfield folder...
					if [[ $FLATTEMP ]]; then
							# Compare the exposure times of that flatfield file and the current file we're on
							# If they don't match, then that flatfield folder doesn't match this page
							if [[ "$exposure" != "$FLATTEMP" ]]; then
								matches="n"
							fi
					# If there isn't a corresponding wavelength in the flatfield folder, then this page doesn't match
					else
						matches="n"
					fi
				done
				# If, after all of that, this page still matches the flatfield, then report it
				if [[ "$matches" == "y" ]]; then
					echo "          ${flatname}" >>$report
				fi
			done	
		done
	fi
echo >>$report
done

# List the folios and corresponding pages discovered in the previous process
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

# Multiple flatfields folders causes issues with the rest of the script. Error out if we found multiple flatfields in any daily folder.
if [[ $flatserror == "y" ]]; then
	echo "     WARNING: Multiple flatfields detected in a daily folder! Resolve before continuing." 1>&2
	echo "     Please see $report for more details." 1>&2
	echo 1>&2
	exit 1
fi


echo >>$report
echo "-----------------------------">>$report
echo "  Multispectral Information">>$report
echo "-----------------------------">>$report
MASTER=( 365 450 465 505 535 592 625 638 700 730 780 850 940 non )

for i in */; do
# List values found in Flats folder
TEMP="\${$(basename $i)[@]}"  
LIST=`eval echo $TEMP`
LIST=$(for k in $LIST; do echo "$k "; done | sort | tr -d '\n')

echo >>$report
echo "     Flatfield wavelengths for $(basename $i):">>$report
echo "          $LIST">>$report

	for j in $(basename $i)/*; do
	echo >>$report
		if [[ "$(basename $j)" != FLATS_* ]]; then
		# If there's a processed folder in this subfolder...
		if [[ -d $(basename $i)/$(basename $j)/Processed ]]; then
		# Create an array for this subfolder that contains all the discovered wavelengths
		for k in $(basename $i)/$(basename $j)/Processed/*.tif; do
			test_array+=("$(exiv2 -qpa $k | grep Exif.Photo.SpectralSensitivity | awk '{print $4}' | sed 's/(\([0-9A-Za-z]*\)nm,/\1/')")
			test_array=( $(for m in ${test_array[@]}; do echo "$m "; done | sort | tr -d '\n') )
		done
		# Report this array		
		echo "     Wavelengths for $(basename $j):">>$report
		echo "          ${test_array[@]}">>$report
		echo >>$report
		# Compare the array against the "Standard" wavelengths
		for k in ${MASTER[@]}; do
			containsElement "$k" "${test_array[@]}"
			if [[ $? == "1" ]]; then
				echo "     WARNING: $(basename $j) in daily folder $(basename $i) is missing Standard Eureka Vision exposure ${k}nm">>$report
			fi
		done
		# Compare the array against the discovered flatfield exposures to see if we're missing an exposure that was in the flatfields
		for k in $LIST; do
			containsElement "$k" "${test_array[@]}"
			if [[ $? == "1" ]]; then
				echo "     WARNING: $(basename $j) in daily folder $(basename $i) is missing exposure ${k}nm found in the flatfields folder">>$report
			fi
		done
		# Compare against the discovered flatfields to see if an exposure is missing a corresponding flatfield
		for k in ${test_array[@]}; do
			containsElement "$k" $LIST
			if [[ $? == "1" ]]; then
				echo "     WARNING: $(basename $j) in daily folder $(basename $i) is missing a corresponding flatfield for exposure ${k}nm">>$report
			fi		
		done
		
		unset test_array
		else
			# Call a warning if there isn't a Processed folder
			echo "     WARNING: Processed folder not found in $j">>$report
			echo >>$report
		fi
		fi	
	done
done

# Read back any warnings in the report to the console
cat "$report" | grep "WARNING"
echo
echo Report Generated to $report
echo
exit