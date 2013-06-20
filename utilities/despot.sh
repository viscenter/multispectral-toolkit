#!/bin/sh

# despot - Flatfield Spot Removal
# Fills in dark spots on flatfields. Created to account for disruptive texturing in flatfielding surface (i.e. paper pulp)
# Run from the flatfields' Processed folder
# This script is not really ready for primetime. It causes some strange issues in the outputs of applyflats and spectralize.


echo
echo -------------------------------
echo Despot - Flatfield Spot Removal
echo -------------------------------
echo "    Hit CTRL + C to exit."
echo

echo "$(date +"%F") :: $(date +"%T") :: Accumulating list of images..." 1>&2

for i in *.tif; do

	outfile="$(basename "$i" | sed 's/\(.*\)\..*/\1/')"

		if [[ ! -d "$outfile"-store ]]; then
			mkdir "$outfile"-store
		fi

	DESPOTCOMMANDS+="~/source/multispectral-toolkit/flatfield/despot "$i" removed_"$outfile".tif && exiv2 -ea $i && \
					mv "$outfile".exv removed_"$outfile".exv && exiv2 -ia removed_"$outfile".tif && mv -f -v "$i" "$outfile"-store/"$outfile".tif && \
					mv -f -v removed_"$outfile".exv "$outfile"-store/removed_"$outfile".exv\n"
done

echo "$(date +"%F") :: $(date +"%T") :: Running despot on all images..." 1>&2
echo $DESPOTCOMMANDS | parallel --eta -u -j 8


echo
echo "$(date +"%F") :: $(date +"%T") :: Spot Removal Complete"