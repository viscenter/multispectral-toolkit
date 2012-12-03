#!/bin/bash

TODAY=`date +%Y%m%d`
RAW="/Volumes/rawdata/MVDaily_$TODAY"
PROC="/Volumes/processed/MVDaily_$TODAY"
FLAT="Flat$TODAY.tif"
SHOT=$1

if [[ -z "$SHOT" ]] ; then
echo "Please specify a folio name."
exit
fi

#if [[ ! -d "$PROC/TIFF" ]] ; then
#mkdir "$PROC/TIFF"
#fi
if [[ ! -d "$PROC/JPG" ]] ; then
mkdir "$PROC/JPG"
fi

if [[ `echo $SHOT | cut -c7` == "r" ]] ; then
	ROTATE="-rotate 90"
elif [[ `echo $SHOT | cut -c7` == "v" ]] ; then
	ROTATE="-rotate 270"
else
	ROTATE=""
fi

echo "Waiting for TIFFs to develop for $SHOT..."
#while [[ `ls "$RAW/$SHOT/Processed/" | wc -l` > 13 ]] ; do 
#	sleep 5
#done
#sleep 15
NUM=`ls "$RAW/$SHOT/Mega/" | wc -l`
echo "Waiting for $NUM images..."
for ((i=0; i<60 && `ls "$RAW/$SHOT/Processed/" | wc -l` != $NUM; i++)) ; do
sleep 4
done
#while [[ `ls "$RAW/$SHOT/Processed/" | wc -l` != $NUM ]] ; do 
#	sleep 5
#done


echo "Compositing RGB for $SHOT..."
BASE=$RAW/$SHOT/Processed/$SHOT
if [[ "$NUM" -eq "13" ]] ; then
convert "$BASE"_007.tif "$BASE"_004.tif "$BASE"_002.tif -combine $SHOT.tif 2>/dev/null
else
convert "$BASE"_008.tif "$BASE"_005.tif "$BASE"_003.tif -combine $SHOT.tif 2>/dev/null
fi

echo "Compressing JPEG for $SHOT..."
convert $SHOT.tif -quality 99 $ROTATE $PROC/JPG/$SHOT.jpg

if [[ -f "$FLAT" ]] ; then
if [[ ! -d "$PROC/Flat" ]] ; then
mkdir "$PROC/Flat"
fi
echo "Flattening $SHOT..."
./flatten "$FLAT" $SHOT.tif $SHOT.png
open $SHOT.png
mv $SHOT.png "$PROC/Flat/$SHOT.png"
fi

#echo "Copying TIFF for $SHOT..."
#mv $SHOT.tif $PROC/TIFF/$SHOT.tif
rm $SHOT.tif

echo Done.
echo

