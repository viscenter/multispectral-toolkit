#!/bin/sh

# Add copyright information to image files.
# Run on folder containing output from mstk.sh or applyflats.sh.


echo
echo -----------------------------------------------------
echo Copyrighter - The Multispectral Copyright Application
echo -----------------------------------------------------
echo "             Hit CTRL + C to exit."

if [[ -z $fullcopyright ]]; then
# Get copyright information from user
while true; do
echo
read -p "Please enter the copyright holder's name: " copyright_name
read -p "Please enter the copyright year: " copyright_year
echo
echo "Select a copyright template:"
echo "    1) Copyright, $copyright_name, $copyright_year. All rights reserved."
while true; do
	read -p "Make a selection: " preset
		case $preset in
			[1] ) 
				fullcopyright="Copyright, $copyright_name, $copyright_year. All rights reserved.";
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
fi


for file in $(find $PWD -type f \( -name "*.png" -or -name "*.jpg" -or -name "*.tif" \)); do
		CURRENTCOPY=$(exiv2 -g Exif.Image.Copyright -Pt $file)
		if [[ $CURRENTCOPY != "$fullcopyright" ]]; then
			printf "\r																																	 "
			printf "\r$(date +"%F") :: $(date +"%T") :: Writing copyright metadata to $(basename "$file")..."
			exiv2 -M"del Exif.Image.Copyright" -M"set Exif.Image.Copyright Ascii $fullcopyright" $file
		fi
done
echo