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


if [[ ! -d flatfielded ]]; then
	echo "$(date +"%F") :: $(date +"%T") :: No flatfielded folder..."
else
for i in flatfielded/*; do
	for j in $i/*.tif; do
		CURRENTCOPY=$(exiv2 -pa $j | grep Exif.Image.Copyright|awk '{print substr($0, index($0,$4))}')
  		if [[ $CURRENTCOPY != "Copyright, $copyright_name, $copyright_year. All rights reserved." ]]; then
			echo "$(date +"%F") :: $(date +"%T") :: Writing copyright metadata to $j..."
			exiv2 -M"del Exif.Image.Copyright" -M"set Exif.Image.Copyright Ascii Copyright, $copyright_name, $copyright_year. All rights reserved." $j
		fi
	done
done
fi

if [[ ! -d multispectral ]]; then
	echo "$(date +"%F") :: $(date +"%T") :: No multispectral folder..."
else
for i in multispectral/*; do
	for j in $i/*.png; do
		CURRENTCOPY=$(exiv2 -pa $j | grep Exif.Image.Copyright|awk '{print substr($0, index($0,$4))}')
  		if [[ $CURRENTCOPY != "Copyright, $copyright_name, $copyright_year. All rights reserved." ]]; then
			echo "$(date +"%F") :: $(date +"%T") :: Writing copyright metadata to $j..."
			exiv2 -M"del Exif.Image.Copyright" -M"set Exif.Image.Copyright Ascii Copyright, $copyright_name, $copyright_year. All rights reserved." $j
		fi
	done
done
fi

if [[ ! -d rgb ]]; then
	echo "$(date +"%F") :: $(date +"%T") :: No rgb folder..."
else
for i in rgb/*.tif; do
		CURRENTCOPY=$(exiv2 -pa $j | grep Exif.Image.Copyright|awk '{print substr($0, index($0,$4))}')
  		if [[ $CURRENTCOPY != "Copyright, $copyright_name, $copyright_year. All rights reserved." ]]; then
			echo "$(date +"%F") :: $(date +"%T") :: Writing copyright metadata to $i..."
			exiv2 -M'del Exif.Image.Copyright' -M"set Exif.Image.Copyright Ascii Copyright, $copyright_name, $copyright_year. All rights reserved." $i
		fi
done
fi

if [[ ! -d rgb_jpg ]]; then
	echo "$(date +"%F") :: $(date +"%T") :: No rgb_jpg folder..."
else
for i in rgb_jpg/*.jpg; do
		CURRENTCOPY=$(exiv2 -pa $j | grep Exif.Image.Copyright|awk '{print substr($0, index($0,$4))}')
		if [[ $CURRENTCOPY != "Copyright, $copyright_name, $copyright_year. All rights reserved." ]]; then
			echo "$(date +"%F") :: $(date +"%T") :: Writing copyright metadata to $i..."
			exiv2 -M'del Exif.Image.Copyright' -M"add Exif.Image.Copyright Ascii Copyright, $copyright_name, $copyright_year. All rights reserved." $i
		fi
done
fi