#!/bin/sh

# mstk_spectral - The mstk version of spectralize. Create various multispectral measurements from flatfielded images.
# STOP: Don't run this script on its own. Should be called from mstk.sh. 

echo
echo -----------------------------------------------
echo Spectralize - Render Multispectral Measurements
echo -----------------------------------------------
echo

ROOT="$PWD"

for i in */; do
	cd $i
	VOLUME="$PWD"
	
	cd $VOLUME/flatfielded
		for j in */; do
			cd $j
			PAGE=$PWD
			folio="$(basename $j)"
			
## Legacy PNG conversion via ImageMagick
#				if [[ ! -d $VOLUME/png/$folio ]]; then
#					mkdir -p $VOLUME/png/$folio
#				fi
#			for k in *.tif; do
#				output="$(basename "$k" | sed 's/\(.*\)\..*/\1/').png"
#				if [[ ! -e $VOLUME/png/$folio/$output ]]; then
#					printf "\r																													"
#					printf "\r$(date +"%F") :: $(date +"%T") :: Converting "$(basename $k)"..."
#					convert $PAGE/$k -quiet -depth 16 $VOLUME/png/$folio/$output
#				fi
#			done
				
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
					unu join -a 2 -i *_002.png *_014.png *_003.png *_004.png *_005.png *_006.png *_007.png *_008.png *_009.png *_010.png *_011.png *_012.png *_013.png -o $VOLUME/nrrd/$folio/$folio.nrrd
				echo
				echo "$(date +"%F") :: $(date +"%T")" :: Applying measures...
					for l in min max mean median variance skew intc slope error sd product sum L1 L2 Linf; do echo $l; done | parallel --eta -u unu project -a 2 -i $VOLUME/nrrd/$folio/$folio.nrrd -o $VOLUME/nrrd/$folio/$folio-f-m-{}.nrrd -m {}
				echo
				echo "$(date +"%F") :: $(date +"%T")" :: Remapping and quantizing results...
					if [ ! -f $VOLUME/nrrd/darkhue.txt ]; then
						wget -nv -P $VOLUME/nrrd/ http://teem.sourceforge.net/nrrd/tutorial/darkhue.txt
					fi
					for m in $VOLUME/nrrd/$folio/*-f-m-*.nrrd; do echo $m; done | parallel --eta -u "unu rmap -m $VOLUME/nrrd/darkhue.txt -i {} | unu quantize -b 8 -o $VOLUME/multispectral/$folio/{/.}-noheq.png; unu heq -b 3000 -a 0.5 -i {} | unu rmap -m $VOLUME/nrrd/darkhue.txt | unu quantize -b 8 -o $VOLUME/multispectral/$folio/{/.}-heq.png"
				
				echo	
				echo "$(date +"%F") :: $(date +"%T")" :: "$folio" done.
				echo
			fi
		fi
		
		cd $VOLUME/flatfielded
		done
	cd $ROOT
done