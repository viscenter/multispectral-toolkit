#!/bin/sh

for i in FLATS_*/; do
	mainfolder=$(basename $i)
		for j in ${i}Processed/*.tif; do
			wavelength=$(exiv2 -g Exif.Photo.SpectralSensitivity -qPt $j | awk '{print $1}' | sed 's/(\([0-9A-Za-z]*\)nm,/\1/')
				if [[ "$wavelength" == "non" ]]; then wavelength="000"; fi
			exposure=$(exiv2 -g Exif.Photo.SpectralSensitivity -qPt $j | awk '{print $2}' | sed 's/\([0-9]*.[0-9]*\)s,/\1/')
			eval "${mainfolder}_${wavelength}=$exposure"
		done
done

for i in *-[0-9]*/; do
	echo "$(basename $i)"
	pagename=$(basename $i | tr "-" "_")
	for j in FLATS_*/; do
		matches="y"
		flatname=$(basename $j)
		for image in ${i}Processed/*.tif; do
			imageinfo=$(exiv2 -g Exif.Photo.SpectralSensitivity -qPt $image)
			wavelength=$(echo $imageinfo | awk '{print $1}' | sed 's/(\([0-9A-Za-z]*\)nm,/\1/')
				if [[ "$wavelength" == "non" ]]; then wavelength="000"; fi
			exposure=$(echo $imageinfo | awk '{print $2}' | sed 's/\([0-9]*.[0-9]*\)s,/\1/')

			FLATTEMP="\${${flatname}_$wavelength}"
			FLATTEMP=`eval echo $FLATTEMP`
			
			#echo "$(basename $image): $exposure"
			#echo "	${flatname}_${wavelength}: $FLATTEMP"
			
			if [[ $FLATTEMP ]]; then
					if [[ "$exposure" != "$FLATTEMP" ]]; then
						matches="n"
					elif [[ "$exposure" == "$FLATTEMP" ]] && [[ $matches != "n" ]]; then
						matches="y"
					fi
			else
				matches="n"
			fi
		done
		if [[ "$matches" == "y" ]]; then
			echo "	Matches $flatname"
		fi
	done	
		
done


exit

