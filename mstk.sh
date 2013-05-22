#!/bin/sh

# mstk - Fully automated processing of daily folders.

echo
echo -------------------------------------------------------
echo mstk - Fully automated processing of multispectral data
echo -------------------------------------------------------
echo "              Hit CTRL + C to exit."
echo
echo
echo "This application was written with a very specific"
echo "folder structure in mind. It should be run from the"
echo "folder containing a project's daily folders. Each"
echo "daily folder should contain a flatfields folder that"
echo "is date-stamped (e.g. FLATS_[YYYYMMDD]). For more info,"
echo "reference the MANUAL file."
echo
echo "Many of this application's tasks should be non-destructive"
echo "in that the original folder structure and files will"
echo "be duplicated to a new working folder before they are"
echo "reorganized and processed. Since many new files are also"
echo "created by this process, please ensure that your output"
echo "folder has at least double the amount of space taken up"
echo "by your current dailies folder."
echo
echo -------------------------------------------------------
echo

# Initial Variable Setup
# Get runtime options
if [[ $1 == "--minimal" ]]; then
	echo "Minimal output mode selected."
	echo
	flatjpg_true="y"
	flattif_true="n"
	flatpng_true="n"
	rgbtif_true="n"
	multijpg_true="y"
	multipng_true="n"
	keepnrrd="n"
elif [[ $1 == "--standard" ]]; then
	echo "Standard output mode selected."
	echo
	flatjpg_true="n"
	flattif_true="y"
	flatpng_true="n"
	rgbtif_true="y"
	multijpg_true="n"
	multipng_true="y"
	keepnrrd="y"
elif [[ $1 == "--mega" ]]; then
	echo "Mega output mode selected."
	echo
	flatjpg_true="y"
	flattif_true="y"
	flatpng_true="y"
	rgbtif_true="y"
	multijpg_true="y"
	multipng_true="y"
	keepnrrd="y"
elif [[ $1 == "--google" ]]; then
	echo "Google CI output mode selected."
	echo
	flatjpg_true="y"; flattif_true="n"; flatpng_true="n"; rgbtif_true="n"
	multijpg_true="y"; multipng_true="n"; keepnrrd="n"; measures="variance"
fi

## Set Output Folder

while true; do
	read -p "Enter output location (NOTE: Folders can be dropped onto the Terminal window): " output_folder
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
setuplog=$(date +"%F")_$(date +"%T")_setup.log
echo "output_folder   $output_folder" >> $output_folder/$setuplog
echo >> $output_folder/$setuplog
echo

## Ask for applyflats.sh output formats
if [[ -z $flatjpg_true ]]; then
	while true; do
		read -p "Create JPG output of flatfielded images? (y/n) " flatjpg_true
			case $flatjpg_true in
				[YyNn] ) break;;
				* ) echo "Please answer y or n.";;
			esac
	done
fi
if [[ -z $flattif_true ]]; then
	while true; do
		read -p "Keep TIF output of flatfielded images? (y/n) " flattif_true
			case $flattif_true in
				[YyNn] ) break;;
				* ) echo "Please answer y or n.";;
			esac
	done
fi
if [[ -z $flatpng_true ]]; then
	while true; do
	read -p "Keep PNG output of flatfielded images? (y/n) " flatpng_true
		case $flatpng_true in
			[YyNn] ) break;;
			* ) echo "Please answer y or n.";;
		esac
	done
fi
if [[ -z $rgbtif_true ]]; then
	while true; do
		read -p "Keep TIF output of RGB images? (y/n) " rgbtif_true
			case $rgbtif_true in
				[YyNn] ) break;;
				* ) echo "Please answer y or n.";;
			esac
	done
fi

## Ask for spectralize.sh output formats
if [[ -z $multijpg_true ]]; then
	while true; do
		read -p "Create JPG output of multispectral measurements? (y/n) " multijpg_true
			case $multijpg_true in
				[YyNn] ) break;;
				* ) echo "Please answer y or n.";;
			esac
	done
fi
if [[ -z $multipng_true ]]; then
	while true; do
		read -p "Create PNG output of multispectral measurements? (y/n) " multipng_true
			case $multipng_true in
				[YyNn] ) break;;
				* ) echo "Please answer y or n.";;
			esac
	done
fi
if [[ -z $keepnrrd ]]; then
	while true; do
		read -p "Keep nrrd files? (y/n) " keepnrrd
			case $keepnrrd in
				[YyNn] ) break;;
				* ) echo "Please answer y or n.";;
			esac
	done
fi

## Set Copyright Information
while true; do
echo
read -p "Please enter the copyright holder's name: " copyright_name
read -p "Please enter the copyright year: " copyright_year
echo
echo "Select a copyright template:"
echo "    1) © $copyright_name, $copyright_year. All rights reserved."
echo "    2) © $copyright_name"
while true; do
	read -p "Make a selection: " preset
		case $preset in
			[1] ) 
				fullcopyright="© $copyright_name, $copyright_year. All rights reserved.";
				break;;
			[2] ) 
				fullcopyright="© $copyright_name";
				break;;
			* ) echo "Please select from the list.";;
		esac
	done

echo "Your copyright will be saved as: $fullcopyright"
	while true; do
	read -p "Is this correct? (y/n) " yn
		case $yn in
			[YyNn] ) break;;
			* ) echo "Please answer y or n.";;
		esac
	done
case $yn in
	[Yy]* ) break;;
	[Nn]* ) continue;;
esac
done

# Start Processing
${HOME}/source/multispectral-toolkit/applyflats.sh "$output_folder/$setuplog" "$flatjpg_true" "$flattif_true" "$rgbtif_true"

echo
echo "$(date +"%F") :: $(date +"%T") :: Flatfielding Complete"

cd $output_folder

. ${HOME}/source/multispectral-toolkit/spectralize.sh

echo
echo "$(date +"%F") :: $(date +"%T") :: Multispectral Rendering Complete"

cd $output_folder

. ${HOME}/source/multispectral-toolkit/copyrighter.sh

echo
echo ----------------------
echo "  ALL WORK COMPLETE"
echo "$(date +"%F") :: $(date +"%T")"
echo ----------------------