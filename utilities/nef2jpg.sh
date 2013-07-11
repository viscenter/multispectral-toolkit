#!/bin/sh
# Uses ufraw to convert NEFs to JPGs
# Run from NEF folder

config=~/source/multispectral-toolkit/utilities/nef2jpg.ufraw

if [ ! -d "../JPG" ]; then
	mkdir "../JPG"
fi

ufraw-batch --conf=$config --out-type=jpg --out-path=../JPG/ $(echo *.nef)

for i in *.nef; do
	name=$(basename "$i" | sed 's/\(.*\).nef/\1/')
	exiv2 -qea "$i"
	mv "${name}.exv" "../JPG/${name}.exv"
done

cd ../JPG

for i in *.jpg; do
	name=$(basename "$i" | sed 's/\(.*\).jpg/\1/')
	exiv2 -ia "$i"
	rm "${name}.exv"
done