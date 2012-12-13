#!/bin/zsh

setopt no_nomatch # if there are no matches for globs, leave them alone and execute the command

# mstk_flats - The mstk version of applyflats. Flatfield multispectral images and create RGB versions of all folios.
# STOP: Don't run this script on its own. Should be called from mstk.sh. 

echo
echo -------------------------------------------------------
echo Applyflats - The Multispectral Flatfielding Application
echo -------------------------------------------------------
echo

## Import variables from setup log
output_folder=$(cat "$1" | grep output_folder | awk '{ print $2 }')

## Setup
FLATFIELD_COMMANDS=""
RGB_COMMANDS=""
RGB_JPG_COMMANDS=""
EXV_COMMANDS=""
CLEANUP_COMMANDS=""

## Begin work
echo "$(date +"%F") :: $(date +"%T") :: Checking folder structure and building commands..." 1>&2
echo
for i in */; do
	declare -A wavelengths
	if [ -d $(basename $i)/FLATS_* ]; then
		currentflat=$(find `PWD`/$(basename $i) -type d -name "FLATS_*")
		
		# Setup for applying flatfields to appropriate exposures for each page
		# Checks wavelength of each flatfields image and send to array in format: wavelengths[638nm]="638nm"
		for j in $currentflat/Processed/*.tif; do
		  WAVELENGTH=$(exiv2 -qpa $j | grep Exif.Photo.SpectralSensitivity|awk '{print substr($0, index($0,$4))}')
		  wavelengths[$WAVELENGTH]=$j
		  if [ ! -f $(echo $j | sed 's/\(.*\)\..*/\1/').exv ]; then
		  	EXV_COMMANDS+="exiv2 -qea $j\n"
		  fi
		  CLEANUP_COMMANDS+="rm $(echo $j | sed 's/\(.*\)\..*/\1/').exv\n"
		done
		
		# For everything in the shoot folder
		for j in $(basename $i)/*; do
		  # Get volume name
		  vol_name=$(basename "$j" | sed 's/\(.*\)-[0-9]*/\1/')
		  page_name=$(basename "$j")
		  		  
		  # Check to make sure it's a page's directory and not a random file
		  if [[ -d "$j" ]]; then
			# Print name to stderr and clear out RGB arrays
			printf "\r$j          " 1>&2
			export RED=""
			export GREEN=""
			export BLUE=""
			
			# Check for a Processed folder for the page
			if [[ -d "$j"/Processed ]]; then
			  # In the flatfields folder, make a new folder for flatfield processed images, then a new folder for the page being processed
			  mkdir -p $output_folder/$vol_name/flatfielded/$page_name
			  # For every tif inside the page's processed folder...
			  for k in "$j"/Processed/*.tif; do
				# Set flatfielded image filepath to new flatfielded folder
				OUTFILE="$output_folder/$vol_name/flatfielded/$page_name/$(basename $k)"
				NOEXT_OUT=$(echo $OUTFILE | sed 's/\(.*\)\..*/\1/')
				
				# Gets wavelength of file
				WAVELENGTH=$(exiv2 -qpa $k | grep Exif.Photo.SpectralSensitivity|awk '{print substr($0, index($0,$4))}')
				
				# If it finds an RGB wavelength, stores file path for processing
				if [[ -n $WAVELENGTH && "$WAVELENGTH" =~ "638nm" ]]; then
				  export RED=$OUTFILE
				elif [[ -n $WAVELENGTH && "$WAVELENGTH" =~ "535nm" ]]; then
				  export GREEN=$OUTFILE
				elif [[ -n $WAVELENGTH && "$WAVELENGTH" =~ "465nm" ]]; then
				  export BLUE=$OUTFILE
				else
				  # echo "$WAVELENGTH not a primary color" 1>&2
				fi
		
				# If flatfielded output doesn't already exist...
				if [[ ! -e $OUTFILE ]]; then
				  # And if the flatfields folder has a matching wavelength...
				  if [[ -n $wavelengths[$WAVELENGTH] ]]; then
					# Build a flatten command and add it to the an array of flatfields commands
					FLATFIELD=$wavelengths[$WAVELENGTH]
					NOEXT_FLAT=$(echo $FLATFIELD | sed 's/\(.*\)\..*/\1/')
					FLATFIELD_COMMANDS+="~/source/multispectral-toolkit/flatfield/flatten $FLATFIELD $k $OUTFILE && cp $NOEXT_FLAT.exv $NOEXT_OUT.exv && exiv2 -ia $NOEXT_OUT.tif && rm $NOEXT_OUT.exv\n"
				  else
					echo "Skipping $k, no wavelength match in flatfields" 1>&2
				  fi
				else
				  echo "Skipping $k, $OUTFILE already exists" 1>&2
				fi
			  done
			  
			  # If we found R,G, & B pictures...
			  if [[ -n $RED && -n $GREEN && -n $BLUE ]]; then
				echo "Performing RGB for $(basename $j), was R:$RED G:$GREEN B:$BLUE" >> $1
				mkdir -p $output_folder/$vol_name/rgb
				mkdir -p $output_folder/$vol_name/rgb_jpg
				if [[ ! -e $output_folder/$vol_name/rgb/$page_name.tif ]]; then 
				RGB_COMMANDS+="convert -quiet $RED $GREEN $BLUE -channel RGB -combine $output_folder/$vol_name/rgb/$page_name.tif\n"
				fi
				if [[ ! -e $output_folder/$vol_name/rgb_jpg/$page_name.jpg ]]; then
				RGB_JPG_COMMANDS+="convert -quiet $output_folder/$vol_name/rgb/$page_name.tif $output_folder/$vol_name/rgb_jpg/$page_name.jpg\n"
				fi
			  else
				echo "Skipping RGB for $(basename $j), was R:$RED G:$GREEN B:$BLUE" 1>&2
			  fi
		
			else
			  echo "Skipping $j, no processed directory" 1>&2
			fi
		  else
			echo "Skipping $j, not a directory" 1>&2
		  fi
		done
	else
		echo "No flatfields folder found for $(basename $i). It will not be processed."
		echo
	fi
	unset wavelengths
done

#echo "EXV_COMMANDS" >> $1
#echo $EXV_COMMANDS >> $1
#echo >> $1
#echo $CLEANUP_COMMANDS >>$1
#echo
#echo $FLATFIELD_COMMANDS >> $1
#exit

# Run all accumulated commands at once
echo
echo "$(date +"%F") :: $(date +"%T") :: Extracting metadata..." 1>&2
echo $EXV_COMMANDS | parallel -eta -u -j 8
echo
echo "$(date +"%F") :: $(date +"%T") :: Flatfielding..." 1>&2
echo $FLATFIELD_COMMANDS | parallel --eta -u -j 8
echo
echo "$(date +"%F") :: $(date +"%T") :: RGB..." 1>&2
echo $RGB_COMMANDS | parallel --eta -u -j 8
echo
echo "$(date +"%F") :: $(date +"%T") :: JPG..." 1>&2
echo $RGB_JPG_COMMANDS | parallel --eta -u -j 8
echo
echo "$(date +"%F") :: $(date +"%T") :: Cleaning up..." 1>&2
echo $CLEANUP_COMMANDS | parallel -eta -u -j 8