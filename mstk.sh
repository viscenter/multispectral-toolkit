#!/bin/zsh

# mstk - Fully automated processing of daily folders.
# This script will reorganize
# Run on folder containing output from applyflats.sh.

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
echo "reference the HELP file."
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

## Set Output Folder
output_folder=
while true; do
	vared -p "Enter output location (NOTE: Folders can be dropped onto the Terminal window): " output_folder
	if  [[ -d "$output_folder" ]]; then
		echo
		echo "You have selected $output_folder"
		break
	else
		if [[ ! -d "$output_folder" ]]; then
		echo "This is not a valid selection. Please select again."
		echo
		continue
		fi
	fi
done

## Create setup log file
setuplog=$(date +"%F")_$(date +"%T")_setup.log
echo "mstk Setup Information" > $output_folder/$setuplog
echo >> $output_folder/$setuplog

## Set Copyright Information
while true; do
echo
vared -p "Please enter the copyright holder's name: " copyright_name
vared -p "Please enter the copyright year: " copyright_year
echo
echo "Your copyright will be saved as: Copyright, $copyright_name, $copyright_year. All rights reserved."
	while true; do
	vared -p "Is this correct? (y/n) " yn
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
echo "**Copyright Information**" >> $output_folder/$setuplog
echo "Copyright, $copyright_name, $copyright_year. All rights reserved." >> $output_folder/$setuplog
echo >> $output_folder/$setuplog


## Find flats
echo
echo "Validating folder structure..."
echo

echo "**Flats Locations**" >> $output_folder/$setuplog
declare -a flatfields
for i in */; do
	if [ ! -d "$i"/FLATS_* ]; then
		echo "No flatfields folder found for $(basename $i). It will not be processed."
		echo
	else
		currentflat=$(find `PWD`/$(basename $i) -type d -name "FLATS_*")
		flatfields=(${flatfields[@]} "$currentflat")
		echo "$currentflat" >> $output_folder/$setuplog
	fi
done
echo >> $output_folder/$setuplog

## Export variables to env. Does some trickery to carry an array into the ENV.
export copyright_name
export copyright_year
export global_flats="$(for i in ${flatfields[@]}; do echo \"$i\"; done)"


${HOME}/source/multispectral-toolkit/bin/mstk_flats.sh
