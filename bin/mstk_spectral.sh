#!/bin/sh

# mstk_spectral - The mstk version of spectralize. Create various multispectral measurements from flatfielded images.
# STOP: Don't run this script on its own. Should be called from mstk.sh. 

echo
echo -----------------------------------------------
echo Spectralize - Render Multispectral Measurements
echo -----------------------------------------------
echo

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
				
					if [[ ! -d $VOLUME/multispectral/$folio ]]; then
						mkdir -p $VOLUME/multispectral/$folio
					fi
					
					if [[ ! -d $VOLUME/nrrd/$folio ]]; then
						mkdir -p $VOLUME/nrrd/$folio
					fi
				
				cd $VOLUME/png/$folio/
				echo		
				echo "$(date +"%F") :: $(date +"%T")" :: Creating volume...
					# Make the nrrd volume for the page
					unu join -a 2 -i *_002.png *_014.png *_003.png *_004.png *_005.png *_006.png *_007.png *_008.png *_009.png *_010.png *_011.png *_012.png *_013.png -o $VOLUME/nrrd/$folio/$folio.nrrd
				echo
				echo "$(date +"%F") :: $(date +"%T")" :: Applying measures...
					# Perform different measurements on the nrrd volume
					# 'product' has been taken out of the list below. I've only had it produce null results and cause errors when quantizing.//SP
					for l in min max mean median variance skew intc slope error sd sum L1 L2 Linf; do echo $l; done | parallel --eta -u unu project -a 2 -i $VOLUME/nrrd/$folio/$folio.nrrd -o $VOLUME/nrrd/$folio/$folio-f-m-{}.nrrd -m {}
				echo
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

					# Remap each measurement nrrd and output to png, then histogram equalize each nrrd, remap it, and output it to png
					for m in $VOLUME/nrrd/$folio/*-f-m-*.nrrd; do
						STRIPPEDM=$(basename $m | sed 's/\(.*\)\..*/\1/')
						QUANTIZECOMMANDS+="unu rmap -m $VOLUME/nrrd/darkhue.txt -i $m | unu quantize -b 8 -o $VOLUME/multispectral/$folio/$STRIPPEDM-noheq.png && unu heq -b 3000 -a 0.5 -i $m | unu rmap -m $VOLUME/nrrd/darkhue.txt | unu quantize -b 8 -o $VOLUME/multispectral/$folio/$STRIPPEDM-heq.png\n"
					done
					# echo $QUANTIZECOMMANDS > $PWD/commands.txt
					# Run the quantize/remapping commands for each page
					echo $QUANTIZECOMMANDS | parallel --eta -u -j 8
					QUANTIZECOMMANDS=""
				echo	
				echo "$(date +"%F") :: $(date +"%T")" :: "$folio" done.
				echo
			fi
		fi
		
		cd $VOLUME/png
		done
	cd $ROOT
done