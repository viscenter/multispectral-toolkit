#!/bin/sh

# Add copyright information to image files.
# Adds metadata to flatfielded, multispectral, rgb, and rgb_jpg folders.
# Run on folder containing output from applyflats.sh.

echo
echo -----------------------------------------------------
echo Copyrighter - The Multispectral Copyright Application
echo -----------------------------------------------------
echo "             Hit CTRL + C to exit."

while true; do
echo
read -p "Please enter the copyright holder's name: " copyright_name
read -p "Please enter the copyright year: " copyright_year
echo
echo "Your copyright will be saved as: Copyright, $copyright_name, $copyright_year. All rights reserved."
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

echo
echo -----------------------------------------------------
echo
echo "Current working folder is `PWD`"
echo
echo "Is this folder a single volume or a collection of volumes?"
echo "NOTE: A volume represents a single book, with subfolders for each of its pages."
echo
PS3="Enter option number:"
	select SET in "Single Volume" "Collection of Volumes"; do
	  case $SET in
			"Single Volume" ) echo "Working on single volume."
				type="1"
			  	break;;
			"Collection of Volumes" ) echo "Working on collection of volumes."
			  	type="2"
			  	break;;
	  esac
	done
echo
echo -----------------------------------------------------
echo

export copyright_name
export copyright_year

if [ $type = "1" ]; then
	${HOME}/source/multispectral-toolkit/bin/cpwrtr_single.sh
fi

if [ $type = "2" ]; then
	${HOME}/source/multispectral-toolkit/bin/cpwrtr_collection.sh
fi