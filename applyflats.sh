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
	## Import variables from arguments
	output_folder=$(cat "$1" | grep output_folder | awk '{ print $2 }')
	flatjpg_true="$2"
	flattif_true="$3"
	rgbtif_true="$4"
	rgbjpg_true="$5"
	setuplog="$1"
fi

if [[ -z "$flatjpg_true" || -z "$flattif_true" || -z "$rgbtif_true" || -z "$rgbjpg_true" ]]; then
	echo
	## Ask for applyflats.sh output formats
	while true; do
		read "flatjpg_true?Create JPG output of flatfielded images? (y/n) "
			case $flatjpg_true in
				[YyNn] ) break;;
				* ) echo "Please answer y or n.";;
			esac
	done
	while true; do
		read "flattif_true?Create TIF output of flatfielded images? (y/n) "
			case $flattif_true in
				[YyNn] ) break;;
				* ) echo "Please answer y or n.";;
			esac
	done
	while true; do
		read "rgbtif_true?Create TIF output of RGB images? (y/n) "
			case $rgbtif_true in
				[YyNn] ) break;;
				* ) echo "Please answer y or n.";;
			esac
	done
	while true; do
		read "rgbjpg_true?Create JPG output of RGB images? (y/n) "
			case $rgbjpg_true in
				[YyNn] ) break;;
				* ) echo "Please answer y or n.";;
			esac
	done
fi

## Setup
FLATFIELDTIF_COMMANDS=""
FLATFIELDJPG_COMMANDS=""
FLATFIELDPNG_COMMANDS=""
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
		  WAVELENGTH=$(exiv2 -g Exif.Photo.SpectralSensitivity -qPt $j | awk '{print $1}' | sed 's/(\([0-9A-Za-z]*\)nm,/\1/')
		  wavelengths[$WAVELENGTH]=$j
		  if [ ! -f $(echo $j | sed 's/\(.*\)\..*/\1/').exv ]; then
		  	EXV_COMMANDS+="exiv2 -qea $j\n"
		  fi
		  CLEANUP_COMMANDS+="rm $(echo $j | sed 's/\(.*\)\..*/\1/').exv\n"
		done
		
		# For everything in the shoot folder
		for j in $(basename $i)/*; do
		  # Get volume name		  
		  vol_name=$(basename "$j" | sed 's/\(.*\)-[0-9A-Za-z]*/\1/')
		  page_name=$(basename "$j")
		  		  
		  # Check to make sure it's a page's directory and not a random file
		  if [[ -d "$j" ]]; then
			if [[ $(basename $j) != FLATS_* ]]; then
			# Print name to stderr and clear out RGB arrays
			export RED=""
			export GREEN=""
			export BLUE=""
			
			# Check for a Processed folder for the page
			if [[ -d "$j"/Processed ]]; then
			  # In the flatfields folder, make a new folder for flatfield processed images, then a new folder for the page being processed
			  if [ $flattif_true == "Y" ] || [ $flattif_true == "y" ] || [ $flatjpg_true == "Y" ] || [ $flatjpg_true == "y" ] || [ $rgbtif_true == "Y" ] || [ $rgbtif_true == "y" ] || [ $rgbjpg_true == "Y" ] || [ $rgbjpg_true == "y" ]; then
			  mkdir -p "$output_folder/$vol_name/flatfielded/$page_name"
			  fi
			  mkdir -p "$output_folder/$vol_name/png/$page_name"
			  # For every tif inside the page's processed folder...
			  for k in "$j"/Processed/*.tif; do
				# Set flatfielded image filepath to new flatfielded folder
				OUTFILE_TIF="$output_folder/$vol_name/flatfielded/$page_name/$(basename $k)"
				OUTFILE_JPG="$output_folder/$vol_name/flatfielded_jpg/$page_name/$(basename $k | sed 's/\(.*\)\..*/\1/').jpg"
				OUTFILE_PNG="$output_folder/$vol_name/png/$page_name/$(basename $k | sed 's/\(.*\)\..*/\1/').png"
				NOEXT_TIFOUT=$(echo "$OUTFILE_TIF" | sed 's/\(.*\)\..*/\1/')
				NOEXT_JPGOUT=$(echo "$OUTFILE_JPG" | sed 's/\(.*\)\..*/\1/')
				NOEXT_PNGOUT=$(echo "$OUTFILE_PNG" | sed 's/\(.*\)\..*/\1/')
				
				# Gets wavelength of file
				WAVELENGTH=$(exiv2 -g Exif.Photo.SpectralSensitivity -qPt "$k" | awk '{print $1}' | sed 's/(\([0-9A-Za-z]*\)nm,/\1/')

				
				# If it finds an RGB wavelength, stores file path for processing
				if [ $rgbtif_true == "Y" ] || [ $rgbtif_true == "y" ] || [ $rgbjpg_true == "Y" ] || [ $rgbjpg_true == "y" ]; then
					if [[ -n $WAVELENGTH && "$WAVELENGTH" =~ "638" ]]; then
					  export RED=$OUTFILE_TIF
					elif [[ -n $WAVELENGTH && "$WAVELENGTH" =~ "535" ]]; then
					  export GREEN=$OUTFILE_TIF
					elif [[ -n $WAVELENGTH && "$WAVELENGTH" =~ "465" ]]; then
					  export BLUE=$OUTFILE_TIF
					else
					  # echo "$WAVELENGTH not a primary color" 1>&2
					fi
				fi
		
				# If we want to make TIFs or RGB TIFs and flatfielded TIF output doesn't already exist...
				if [[ ! -e $OUTFILE_TIF ]]; then
				  # And if the flatfields folder has a matching wavelength...
				  if [[ -n $wavelengths[$WAVELENGTH] ]]; then
					# If we want to keep TIFs...
					if [ $flattif_true == "Y" ] || [ $flattif_true == "y" ]; then
					# Build a flatten command with exiv2 transfers and add it to the an array of flatfields commands
					FLATFIELD=$wavelengths[$WAVELENGTH]
					NOEXT_FLAT=$(echo $FLATFIELD | sed 's/\(.*\)\..*/\1/')
					FLATFIELDTIF_COMMANDS+="~/source/multispectral-toolkit/flatfield/pngflatten $FLATFIELD $k $OUTFILE_TIF && cp $NOEXT_FLAT.exv $NOEXT_TIFOUT.exv && exiv2 -ia $NOEXT_TIFOUT.tif && rm $NOEXT_TIFOUT.exv\n"
					elif [ "$WAVELENGTH" =~ "638" ] || [ "$WAVELENGTH" =~ "535" ] || [ "$WAVELENGTH" =~ "465" ]; then
						if [ $rgbtif_true == "Y" ] || [ $rgbtif_true == "y" ] || [ $rgbjpg_true == "Y" ] || [ $rgbjpg_true == "y" ]; then
							# Build a flatten command with exiv2 transfers and add it to the an array of flatfields commands
							FLATFIELD=$wavelengths[$WAVELENGTH]
							NOEXT_FLAT=$(echo $FLATFIELD | sed 's/\(.*\)\..*/\1/')
							FLATFIELDTIF_COMMANDS+="~/source/multispectral-toolkit/flatfield/pngflatten $FLATFIELD $k $OUTFILE_TIF && cp $NOEXT_FLAT.exv $NOEXT_TIFOUT.exv && exiv2 -ia $NOEXT_TIFOUT.tif && rm $NOEXT_TIFOUT.exv\n"
						fi
					elif [ $flatjpg_true == "Y" ] || [ $flatjpg_true == "y" ]; then
						# Build a flatten command without exiv2 transfers and add it to the an array of flatfields commands
						FLATFIELD=$wavelengths[$WAVELENGTH]
						NOEXT_FLAT=$(echo $FLATFIELD | sed 's/\(.*\)\..*/\1/')
						FLATFIELDTIF_COMMANDS+="~/source/multispectral-toolkit/flatfield/pngflatten $FLATFIELD $k $OUTFILE_TIF\n"
					fi
				  else
					echo "Skipping TIF output for $k, no wavelength match in flatfields" 1>&2
				  fi
				else
				  echo "Skipping $k, $OUTFILE_TIF already exists" 1>&2
				fi
				
				# If we want to make JPGs and flatfielded JPG output doesn't already exist...
				if [ $flatjpg_true == "Y" ] || [ $flatjpg_true == "y" ]; then
					# If we're keeping the TIFs, copy them to the JPG directory. Otherwise, move them.
					if [ $flattif_true == "Y" ] || [ $flattif_true == "y" ] || [ "$WAVELENGTH" =~ "638" ] || [ "$WAVELENGTH" =~ "535" ] || [ "$WAVELENGTH" =~ "465" ]; then
						move_command="cp"
					else
						move_command="mv"
					fi
				mkdir -p $output_folder/$vol_name/flatfielded_jpg/$page_name
				if [[ ! -e $OUTFILE_JPG ]]; then
				  # And if the flatfields folder has a matching wavelength...
				  if [[ -n $wavelengths[$WAVELENGTH] ]]; then
					# Build a flatten command and add it to the an array of flatfields commands
					FLATFIELD=$wavelengths[$WAVELENGTH]
					NOEXT_FLAT=$(echo $FLATFIELD | sed 's/\(.*\)\..*/\1/')
					FLATFIELDJPG_COMMANDS+="$move_command $OUTFILE_TIF $NOEXT_JPGOUT.tif && cp $NOEXT_FLAT.exv $NOEXT_JPGOUT.exv && convert -quiet -quality 97 $NOEXT_JPGOUT.tif $OUTFILE_JPG && rm $NOEXT_JPGOUT.tif && exiv2 -ia $NOEXT_JPGOUT.jpg && rm $NOEXT_JPGOUT.exv\n"
				  else
					echo "Skipping JPG output for $k, no wavelength match in flatfields" 1>&2
				  fi
				else
				  echo "Skipping $k, $OUTFILE_JPG already exists" 1>&2
				fi
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
					echo "Skipping PNG output for $k, no wavelength match in flatfields" 1>&2
				  fi
				else
				  echo "Skipping $k, $OUTFILE_PNG already exists" 1>&2
				fi
			  done
			  
			  # If we're not keeping the TIFs, add a command to delete the flatfielded folder
			  if [ $flattif_true == "N" ] || [ $flattif_true == "n" ]; then
				CLEANUP_COMMANDS+="rm -rf $output_folder/$vol_name/flatfielded\n"
			  fi
			  
			  # If we found R,G, & B pictures...
			  if [ $rgbtif_true == "Y" ] || [ $rgbtif_true == "y" ] || [ $rgbjpg_true == "Y" ] || [ $rgbjpg_true == "y" ]; then
				  if [[ -n $RED && -n $GREEN && -n $BLUE ]]; then
					mkdir -p $output_folder/$vol_name/rgb
					mkdir -p $output_folder/$vol_name/rgb_jpg
					if [[ ! -e $output_folder/$vol_name/rgb/$page_name.tif ]]; then 
					echo "Performing RGB for $(basename $j), was R:$RED G:$GREEN B:$BLUE" >> $setuplog
					RGB_COMMANDS+="convert -quiet $RED $GREEN $BLUE -channel RGB -combine $output_folder/$vol_name/rgb/$page_name.tif\n"
					fi
					if [[ ! -e $output_folder/$vol_name/rgb_jpg/$page_name.jpg ]]; then
					RGB_JPG_COMMANDS+="convert -quiet -quality 97 $output_folder/$vol_name/rgb/$page_name.tif $output_folder/$vol_name/rgb_jpg/$page_name.jpg\n"
					fi
					# If we're not keeping the RGB TIFs
					if [[ "$rgbtif_true" == "N" || "$rgbtif_true" == "n" ]]; then
						CLEANUP_COMMANDS+="rm $output_folder/$vol_name/rgb/$page_name.tif\n"
				  	fi
				  else
					echo "Skipping RGB for $(basename $j), was R:$RED G:$GREEN B:$BLUE" 1>&2
				  fi
			  fi
		
			else
			  echo "Skipping $j, no processed directory" 1>&2
			fi
			else
				echo "Skipping $j, is a flatfields directory" 1>&2
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

# Run all accumulated commands at once
echo
echo "$(date +"%F") :: $(date +"%T") :: Extracting metadata..." 1>&2
echo $EXV_COMMANDS | parallel -eta -u -j 8
echo
if [ $flattif_true == "Y" ] || [ $flattif_true == "y" ] || [ $flatjpg_true == "Y" ] || [ $flatjpg_true == "y" ] || [ $rgbtif_true == "Y" ] || [ $rgbtif_true == "y" ] || [ $rgbjpg_true == "Y" ] || [ $rgbjpg_true == "y" ]; then
echo "$(date +"%F") :: $(date +"%T") :: Flatfielding TIFs..." 1>&2
echo $FLATFIELDTIF_COMMANDS | parallel --eta -u -j 8
echo
fi
if [ $flatjpg_true == "Y" ] || [ $flatjpg_true == "y" ]; then
echo "$(date +"%F") :: $(date +"%T") :: Flatfielding JPGs..." 1>&2
echo $FLATFIELDJPG_COMMANDS | parallel --eta -u -j 8
echo
fi

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
# Remove rgb folder if we don't want it...	
	if [[ "$rgbtif_true" == "N" || "$rgbtif_true" == "n" ]]; then
		for i in $output_folder/*; do
			if [[ -d "$i" ]]; then
				rm -rf $i/rgb
			fi
		done
	fi
exit