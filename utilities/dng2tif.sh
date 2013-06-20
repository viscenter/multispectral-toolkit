#!/bin/sh
# Uses ufraw to convert DNGs to TIFs
# Run from Mega folder

#cp ~/source/multispectral-toolkit/utilities/dng2tif.ufraw $PWD/dng2tif.ufraw

config=~/source/multispectral-toolkit/utilities/dng2tif.ufraw

ufraw-batch --conf=$config --grayscale=mixer --out-type=tif --out-depth=16 --out-path=../Processed/ $(echo *.dng)

for i in *.dng; do
	name=$(basename $i | sed 's/\(.*\).dng/\1/')
	exiv2 -qea $i
	mv ${name}.exv ../Processed/${name}.exv
done

cd ../Processed

for i in *.tif; do
	name=$(basename $i | sed 's/\(.*\).tif/\1/')
	exiv2 -ia $i
	rm ${name}.exv
done

cd ../Mega