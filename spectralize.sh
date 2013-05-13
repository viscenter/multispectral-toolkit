#!/bin/sh

# Script for creating various multispectral measurements from flatfielded images. Requires imagemagick, teem/unu, and parallel.
# Assumes shots are numbered according to the VisCenter N-Shot Table Standard. See readme for more details and pre-processing information.
# Called by mstk.sh, or run standalone from inside the output folder created by applyflats.sh.

echo
echo -----------------------------------------------
echo Spectralize - Render Multispectral Measurements
echo -----------------------------------------------
echo

## Ask for spectralize.sh output formats
if [[ -z $flatpng_true ]]; then
	while true; do
	read -p "Keep PNG output of flatfielded images? (y/n) " flatpng_true
		case $flatpng_true in
			[YyNn] ) break;;
			* ) echo "Please answer y or n.";;
		esac
	done
fi
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

if [ $multipng_true == "N" ] || [ $multipng_true == "n" ]; then
	if [ $multijpg_true == "N" ] || [ $multijpg_true == "n" ]; then
		if [ $keepnrrd == "N" ] || [ $keepnrrd == "n" ]; then
			echo
			echo "$(date +"%F") :: $(date +"%T") :: WARNING :: No outputs selected. Exiting..."
			echo
			exit 1
		fi
	echo
	echo "$(date +"%F") :: $(date +"%T") :: WARNING :: No image outputs selected. Only nrrd's will be created."
	echo
	fi
fi

ROOT="$PWD"
# Go through each volume folder, then go through each page folder. If there's not a multispectral folder, make one and start processing
for i in */; do
	cd $i
	VOLUME="$PWD"
	cd $VOLUME/png
		for j in */; do
			cd $j
			PAGE=$PWD
			folio="$(basename $j)"

		if [[ ! -d $VOLUME/png/$folio ]]; then
			echo
			echo "$(date +"%F") :: $(date +"%T")" :: "$folio": No PNGs found
		else
			if [[ ! -d $VOLUME/multispectral/$folio ]]; then
				echo
				echo "$(date +"%F") :: $(date +"%T") :: Beginning work on $folio"
				
					if [ $multipng_true == "Y" ] || [ $multipng_true == "y" ]; then
						if [[ ! -d $VOLUME/multispectral/$folio ]]; then
							mkdir -p $VOLUME/multispectral/$folio
						fi
					fi
					
					if [ $multijpg_true == "Y" ] || [ $multijpg_true == "y" ]; then
						if [[ ! -d $VOLUME/multispectral_jpg/$folio ]]; then
							mkdir -p $VOLUME/multispectral_jpg/$folio
						fi
					fi
					
					if [[ ! -d $VOLUME/nrrd/$folio ]]; then
						mkdir -p $VOLUME/nrrd/$folio
					fi
				
				cd $VOLUME/png/$folio/
				echo		
				echo "$(date +"%F") :: $(date +"%T")" :: Creating volume...
					for k in *.png; do
					WAVELENGTH="$(exiv2 -qpa $k | grep Exif.Photo.SpectralSensitivity | awk '{print $4}' | sed 's/(\([0-9A-Za-z]*\)nm,/\1/')"
					if [[ "$WAVELENGTH" != "non" ]]; then
						echo "$WAVELENGTH $k">>sort.txt
					fi
					done
					# Make the nrrd volume for the page
					unu join -a 2 -i $(sort sort.txt | awk '{print $2}') -o $VOLUME/nrrd/$folio/$folio.nrrd
					rm sort.txt
				echo
				echo "$(date +"%F") :: $(date +"%T")" :: Applying measures...
					# Perform different measurements on the nrrd volume
					# 'product' has been taken out of the list below. I've only had it produce null results and cause errors when quantizing.//SP
					for l in min max mean median variance skew intc slope error sd sum L1 L2 Linf; do echo $l; done | parallel --eta -u unu project -a 2 -i $VOLUME/nrrd/$folio/$folio.nrrd -o $VOLUME/nrrd/$folio/$folio-f-m-{}.nrrd -m {}
				echo
				
				if [ $multipng_true == "Y" ] || [ $multipng_true == "y" ] || [ $multijpg_true == "Y" ] || [ $multijpg_true == "y" ]; then
				echo "$(date +"%F") :: $(date +"%T")" :: Remapping and quantizing results...
					# Download the color remapping file. Use curl if wget isn't installed. Important since OSX 10.8 doesn't come with wget
					if [ ! -f $VOLUME/nrrd/darkhue.txt ]; then
						if command -v wget >/dev/null; then
							wget -nv -P $VOLUME/nrrd/ http://teem.sourceforge.net/nrrd/tutorial/darkhue.txt
						else
							echo "$(date +"%F") :: $(date +"%T")" :: wget not found. Using curl...
							curl --progress-bar http://teem.sourceforge.net/nrrd/tutorial/darkhue.txt -o "$VOLUME/nrrd/darkhue.txt"	
						fi
					fi

					# Remap each measurement nrrd and output to jpg/png, then histogram equalize each nrrd, remap it, and output it to jpg/png
					
						for m in $VOLUME/nrrd/$folio/*-f-m-*.nrrd; do
							STRIPPEDM=$(basename $m | sed 's/\(.*\)\..*/\1/')
							if [ $multipng_true == "Y" ] || [ $multipng_true == "y" ]; then
								QUANTIZECOMMANDS+="unu rmap -m $VOLUME/nrrd/darkhue.txt -i $m | unu quantize -b 8 -o $VOLUME/multispectral/$folio/$STRIPPEDM-noheq.png\n"
								QUANTIZECOMMANDS+="unu heq -b 3000 -a 0.5 -i $m | unu rmap -m $VOLUME/nrrd/darkhue.txt | unu quantize -b 8 -o $VOLUME/multispectral/$folio/$STRIPPEDM-heq.png\n"
							fi
							if [ $multijpg_true == "Y" ] || [ $multijpg_true == "y" ]; then	
								QUANTIZECOMMANDS+="unu rmap -m $VOLUME/nrrd/darkhue.txt -i $m | unu quantize -b 8 -o $VOLUME/multispectral_jpg/$folio/$STRIPPEDM-noheq.ppm && cjpeg -q 100 -outfile $VOLUME/multispectral_jpg/$folio/$STRIPPEDM-noheq.jpg $VOLUME/multispectral_jpg/$folio/$STRIPPEDM-noheq.ppm && rm -f $VOLUME/multispectral_jpg/$folio/$STRIPPEDM-noheq.ppm\n"
								QUANTIZECOMMANDS+="unu heq -b 3000 -a 0.5 -i $m | unu rmap -m $VOLUME/nrrd/darkhue.txt | unu quantize -b 8 -o $VOLUME/multispectral_jpg/$folio/$STRIPPEDM-heq.ppm && cjpeg -q 100 -outfile $VOLUME/multispectral_jpg/$folio/$STRIPPEDM-heq.jpg $VOLUME/multispectral_jpg/$folio/$STRIPPEDM-heq.ppm && rm -f $VOLUME/multispectral_jpg/$folio/$STRIPPEDM-heq.ppm\n"
							fi
						done
					# echo $QUANTIZECOMMANDS > $PWD/commands.txt
					# Run the quantize/remapping commands for each page
					echo $QUANTIZECOMMANDS | parallel --eta -u -j 8
					QUANTIZECOMMANDS=""
				fi
				echo	
				echo "$(date +"%F") :: $(date +"%T")" :: "$folio" done.
				echo
			fi
		fi
		
		cd $VOLUME/png
		done
	# Remove nrrd's if we don't want them
		if [ $keepnrrd == "N" ] || [ $keepnrrd == "n" ]; then
			rm -rf $VOLUME/nrrd
		fi
	# Remove rgb folder if we don't want it...	
		if [[ "$rgbtif_true" == "N" || "$rgbtif_true" == "n" ]]; then
			rm -rf $VOLUME/rgb
		fi
	# Remove rgb folder if we don't want it...	
		if [[ "$flatpng_true" == "N" || "$flatpng_true" == "n" ]]; then
			rm -rf $VOLUME/png
		fi
	cd $ROOT
done