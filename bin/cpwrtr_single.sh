#!/bin/sh

# Single Volume Processing for Copywriter

	if [[ ! -d flatfielded ]]; then
		echo "$(date +"%F") :: $(date +"%T") :: No flatfielded folder."
	else
	for i in flatfielded/*; do
		for j in $i/*.tif; do
			CURRENTCOPY=$(exiv2 -pa $j | grep Exif.Image.Copyright|awk '{print substr($0, index($0,$4))}')
			if [[ $CURRENTCOPY != "Copyright, $copyright_name, $copyright_year. All rights reserved." ]]; then
				printf "\r																																		"
				printf "\r$(date +"%F") :: $(date +"%T") :: Writing copyright metadata to $(basename "$j")..."
				exiv2 -M"del Exif.Image.Copyright" -M"set Exif.Image.Copyright Ascii Copyright, $copyright_name, $copyright_year. All rights reserved." $j
			fi
		done
	done
	fi
	echo
	if [[ ! -d multispectral ]]; then
		echo "$(date +"%F") :: $(date +"%T") :: No multispectral folder."
	else
	for i in multispectral/*; do
		for j in $i/*.png; do
			CURRENTCOPY=$(exiv2 -pa $j | grep Exif.Image.Copyright|awk '{print substr($0, index($0,$4))}')
			if [[ $CURRENTCOPY != "Copyright, $copyright_name, $copyright_year. All rights reserved." ]]; then
				printf "\r																																		"
				printf "\r$(date +"%F") :: $(date +"%T") :: Writing copyright metadata to $j..."
				exiv2 -M"del Exif.Image.Copyright" -M"set Exif.Image.Copyright Ascii Copyright, $copyright_name, $copyright_year. All rights reserved." $j
			fi
		done
	done
	fi
	echo
	if [[ ! -d rgb ]]; then
		echo "$(date +"%F") :: $(date +"%T") :: No rgb folder."
	else
	for i in rgb/*.tif; do
			CURRENTCOPY=$(exiv2 -pa $i | grep Exif.Image.Copyright|awk '{print substr($0, index($0,$4))}')
			if [[ $CURRENTCOPY != "Copyright, $copyright_name, $copyright_year. All rights reserved." ]]; then
				printf "\r																																		"
				printf "\r$(date +"%F") :: $(date +"%T") :: Writing copyright metadata to $i..."
				exiv2 -M'del Exif.Image.Copyright' -M"set Exif.Image.Copyright Ascii Copyright, $copyright_name, $copyright_year. All rights reserved." $i
			fi
	done
	fi
	echo
	if [[ ! -d rgb_jpg ]]; then
		echo "$(date +"%F") :: $(date +"%T") :: No rgb_jpg folder."
	else
	for i in rgb_jpg/*.jpg; do
			CURRENTCOPY=$(exiv2 -pa $i | grep Exif.Image.Copyright|awk '{print substr($0, index($0,$4))}')
			if [[ $CURRENTCOPY != "Copyright, $copyright_name, $copyright_year. All rights reserved." ]]; then
				printf "\r																																		"
				printf "\r$(date +"%F") :: $(date +"%T") :: Writing copyright metadata to $i..."
				exiv2 -M'del Exif.Image.Copyright' -M"add Exif.Image.Copyright Ascii Copyright, $copyright_name, $copyright_year. All rights reserved." $i
			fi
	done
	fi
	echo
	if [[ ! -d png ]]; then
		echo "$(date +"%F") :: $(date +"%T") :: No png folder."
	else
	for i in png/*; do
		for j in $i/*.png; do
			CURRENTCOPY=$(exiv2 -pa $j | grep Exif.Image.Copyright|awk '{print substr($0, index($0,$4))}')
			if [[ $CURRENTCOPY != "Copyright, $copyright_name, $copyright_year. All rights reserved." ]]; then
				printf "\r																																		"
				printf "\r$(date +"%F") :: $(date +"%T") :: Writing copyright metadata to $j..."
				exiv2 -M"del Exif.Image.Copyright" -M"set Exif.Image.Copyright Ascii Copyright, $copyright_name, $copyright_year. All rights reserved." $j
			fi
		done
	done
	fi