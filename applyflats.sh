#!/bin/zsh

setopt no_nomatch # if there are no matches for globs, leave them alone and execute the command

# applyflats - Flatfield multispectral images and create RGB versions of all folios.
# Script should be called from the folder containing all of the Daily folders.
# Will prompt for an output folder if not given one as an argument.

echo
echo -------------------------------------------------------
echo Applyflats - The Multispectral Flatfielding Application
echo -------------------------------------------------------
echo

## Check for output folder passed from calling script/shell
if [ $# -eq 0 ]; then
	while true; do
	read "output_folder?Enter output location (NOTE: Folders can be dropped onto the Terminal window): "
	# echo $output_folder
	if  [[ -d $output_folder && -w $output_folder ]]; then
		echo
		echo "You have selected $output_folder"
		break
	else
		if [[ ! -d $output_folder || ! -w $output_folder ]]; then
		echo "This is not a valid selection. Please select again."
		echo
		continue
		fi
	fi
	done
	
	## Create setup log file
	setuplog="$output_folder/$(date +"%F")_$(date +"%T")_setup.log"
	echo "output_folder   $output_folder" >> $setuplog
	echo >> $setuplog
else
	## Import variables from setup log
	output_folder=$(cat "$1" | grep output_folder | awk '{ print $2 }')
	setuplog="$1"
fi

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
			printf "\r																													"
			printf "\r$j" 1>&2
			export RED=""
			export GREEN=""
			export BLUE=""
			
			# Check for a Processed folder for the page
			if [[ -d "$j"/Processed ]]; then
			  # In the flatfields folder, make a new folder for flatfield processed images, then a new folder for the page being processed
			  mkdir -p $output_folder/$vol_name/flatfielded/$page_name
			  mkdir -p $output_folder/$vol_name/png/$page_name
			  # For every tif inside the page's processed folder...
			  for k in "$j"/Processed/*.tif; do
				# Set flatfielded image filepath to new flatfielded folder
				OUTFILE_TIF="$output_folder/$vol_name/flatfielded/$page_name/$(basename $k)"
				OUTFILE_PNG="$output_folder/$vol_name/png/$page_name/$(basename $k | sed 's/\(.*\)\..*/\1/').png"
				NOEXT_TIFOUT=$(echo $OUTFILE_TIF | sed 's/\(.*\)\..*/\1/')
				NOEXT_PNGOUT=$(echo $OUTFILE_PNG | sed 's/\(.*\)\..*/\1/')
				
				# Gets wavelength of file
				WAVELENGTH=$(exiv2 -qpa $k | grep Exif.Photo.SpectralSensitivity|awk '{print substr($0, index($0,$4))}')
				
				# If it finds an RGB wavelength, stores file path for processing
				if [[ -n $WAVELENGTH && "$WAVELENGTH" =~ "638nm" ]]; then
				  export RED=$OUTFILE_TIF
				elif [[ -n $WAVELENGTH && "$WAVELENGTH" =~ "535nm" ]]; then
				  export GREEN=$OUTFILE_TIF
				elif [[ -n $WAVELENGTH && "$WAVELENGTH" =~ "465nm" ]]; then
				  export BLUE=$OUTFILE_TIF
				else
				  # echo "$WAVELENGTH not a primary color" 1>&2
				fi
		
				# If flatfielded TIF output doesn't already exist...
				if [[ ! -e $OUTFILE_TIF ]]; then
				  # And if the flatfields folder has a matching wavelength...
				  if [[ -n $wavelengths[$WAVELENGTH] ]]; then
					# Build a flatten command and add it to the an array of flatfields commands
					FLATFIELD=$wavelengths[$WAVELENGTH]
					NOEXT_FLAT=$(echo $FLATFIELD | sed 's/\(.*\)\..*/\1/')
					FLATFIELDTIF_COMMANDS+="~/source/multispectral-toolkit/flatfield/pngflatten $FLATFIELD $k $OUTFILE_TIF && cp $NOEXT_FLAT.exv $NOEXT_TIFOUT.exv && exiv2 -ia $NOEXT_TIFOUT.tif && rm $NOEXT_TIFOUT.exv\n"
				  else
					echo "Skipping $k, no wavelength match in flatfields" 1>&2
				  fi
				else
				  echo "Skipping $k, $OUTFILE_TIF already exists" 1>&2
				fi
				
				# If flatfielded PNG output doesn't already exist...
				if [[ ! -e $OUTFILE_PNG ]]; then
				  # And if the flatfields folder has a matching wavelength...
				  if [[ -n $wavelengths[$WAVELENGTH] ]]; then
					# Build a flatten command and add it to the an array of flatfields commands
					FLATFIELD=$wavelengths[$WAVELENGTH]
					NOEXT_FLAT=$(echo $FLATFIELD | sed 's/\(.*\)\..*/\1/')
					FLATFIELDPNG_COMMANDS+="~/source/multispectral-toolkit/flatfield/pngflatten $FLATFIELD $k $OUTFILE_PNG && cp $NOEXT_FLAT.exv $NOEXT_PNGOUT.exv && exiv2 -ia $NOEXT_PNGOUT.png && rm $NOEXT_PNGOUT.exv\n"
				  else
					echo "Skipping $k, no wavelength match in flatfields" 1>&2
				  fi
				else
				  echo "Skipping $k, $OUTFILE_PNG already exists" 1>&2
				fi
			  done
			  
			  # If we found R,G, & B pictures...
			  if [[ -n $RED && -n $GREEN && -n $BLUE ]]; then
				mkdir -p $output_folder/$vol_name/rgb
				mkdir -p $output_folder/$vol_name/rgb_jpg
				if [[ ! -e $output_folder/$vol_name/rgb/$page_name.tif ]]; then 
				echo "Performing RGB for $(basename $j), was R:$RED G:$GREEN B:$BLUE" >> $setuplog
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

#echo "EXV_COMMANDS" >> $setuplog
#echo $EXV_COMMANDS >> $setuplog
#echo >> $setuplog
#echo $CLEANUP_COMMANDS >>$setuplog
#echo
#echo $FLATFIELD_COMMANDS >> $setuplog
#exit

# Run all accumulated commands at once
echo
echo "$(date +"%F") :: $(date +"%T") :: Extracting metadata..." 1>&2
echo $EXV_COMMANDS | parallel -eta -u -j 8
echo
echo "$(date +"%F") :: $(date +"%T") :: Flatfielding TIFs..." 1>&2
echo $FLATFIELDTIF_COMMANDS | parallel --eta -u -j 8
echo
echo "$(date +"%F") :: $(date +"%T") :: Flatfielding PNGs..." 1>&2
echo $FLATFIELDPNG_COMMANDS | parallel --eta -u -j 8
echo
echo "$(date +"%F") :: $(date +"%T") :: RGB..." 1>&2
echo $RGB_COMMANDS | parallel --eta -u -j 8
echo
echo "$(date +"%F") :: $(date +"%T") :: JPG..." 1>&2
echo $RGB_JPG_COMMANDS | parallel --eta -u -j 8
echo
echo "$(date +"%F") :: $(date +"%T") :: Cleaning up..." 1>&2
echo $CLEANUP_COMMANDS | parallel -eta -u -j 8

exit