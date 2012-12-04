#!/bin/sh

# Script for creating various multispectral measurements from flatfielded images. Requires imagemagick, teem/unu, and parallel.
# Assumes shots are numbered according to the VisCenter N-Shot Table Standard. See readme for more details and pre-processing information.
# Run from a collection's flatfielded folder.

echo
echo -----------------------------------------------
echo Spectralize - Render Multispectral Measurements
echo -----------------------------------------------
echo "           Hit CTRL + C to exit."
echo

for i in */; do
	cd $i
	folio="$(basename $i)"
	
if [[ ! -d png ]]; then
	mkdir png
fi

	for j in *.tif; do
		output="$(basename "$j" | sed 's/\(.*\)\..*/\1/').png"
		if [[ ! -e png/$output ]]; then
			echo "$(date +"%F") :: $(date +"%T")" :: Converting "$(basename $j)"...
			convert $j -depth 16 png/$output
		fi
	done
		
if [[ ! -d png ]]; then
	echo "$(date +"%F") :: $(date +"%T")" :: "$folio": No PNGs found
else
	if [[ ! -d ../../multispectral/$folio ]]; then
		echo "Beginning work on $folio"
				
		echo "$(date +"%F") :: $(date +"%T")" :: Creating volume...
			unu join -a 2 -i png/*_002.png png/*_014.png png/*_003.png png/*_004.png png/*_005.png png/*_006.png png/*_007.png png/*_008.png png/*_009.png png/*_010.png png/*_011.png png/*_012.png png/*_013.png -o $folio.nrrd
		
		echo "$(date +"%F") :: $(date +"%T")" :: Applying measures...
			for l in min max mean median variance skew intc slope error sd product sum L1 L2 Linf; do echo $l; done | parallel --eta -u unu project -a 2 -i $folio.nrrd -o $folio-f-m-{}.nrrd -m {}
		
		echo "$(date +"%F") :: $(date +"%T")" :: Remapping and quantizing results...
			wget http://teem.sourceforge.net/nrrd/tutorial/darkhue.txt
			for m in *-f-m-*.nrrd; do echo $m; done | parallel --eta -u "unu rmap -m darkhue.txt -i {} | unu quantize -b 8 -o {.}-noheq.png; unu heq -b 3000 -a 0.5 -i {} | unu rmap -m darkhue.txt | unu quantize -b 8 -o {.}-heq.png"
		
		echo "$(date +"%F") :: $(date +"%T")" :: Cleaning up...
			
			if [[ ! -d ../../multispectral ]]; then
				mkdir ../../multispectral
			fi
			if [[ ! -d ../../multispectral/$folio ]]; then
				mkdir ../../multispectral/$folio
			fi
			if [[ ! -d nrrd ]]; then
				mkdir nrrd
			fi
			
			for n in *.png; do
				mv $(basename $n) ../../multispectral/$folio/$(basename $n)
			done
			
			for n in *.nrrd; do
				mv $(basename $n) nrrd/$(basename $n)
			done
			
		echo "$(date +"%F") :: $(date +"%T")" :: "$folio" done.
	fi
fi

cd ..

done