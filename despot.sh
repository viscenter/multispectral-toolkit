#!/bin/sh

# despot - Flatfield Spot Removal
# Fills in dark spots on flatfields. Created to account for disruptive texturing in flatfielding surface (i.e. paper pulp)
# Run from the flatfields' Processed folder

for i in *.tif; do

outfile="$(basename "$i" | sed 's/\(.*\)\..*/\1/')"

if [[ ! -d "$outfile"-store ]]; then
	mkdir "$outfile"-store
fi

convert "$i" -threshold 65% "$outfile"_diff_mask1.tif
convert "$outfile"_diff_mask1.tif -negate -morphology Dilate Octagon "$outfile"_diff_mask2.tif
convert "$i" \( "$outfile"_diff_mask2.tif -negate \) -alpha off -compose CopyOpacity -composite -channel RGBA -blur 0x2 +channel -alpha off "$outfile"_diff_fill.tif
convert "$i" "$outfile"_diff_fill.tif "$outfile"_diff_mask2.tif -composite "$outfile"_removed.tif

exiv2 -ea $i 
mv "$outfile".exv "$outfile"_removed.exv
exiv2 -ia "$outfile"_removed.tif

mv -f -v "$i" "$outfile"-store/"$outfile".tif
mv -f -v "$outfile"_diff_mask1.tif "$outfile"-store/"$outfile"_diff_mask1.tif
mv -f -v "$outfile"_diff_mask2.tif "$outfile"-store/"$outfile"_diff_mask2.tif
mv -f -v "$outfile"_diff_fill.tif "$outfile"-store/"$outfile"_diff_fill.tif
mv -f -v "$outfile"_removed.exv "$outfile"-store/"$outfile"_removed.exv

done