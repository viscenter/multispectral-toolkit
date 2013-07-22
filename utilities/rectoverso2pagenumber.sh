#!/bin/sh
#recto-verso to page number
# assumes filenames are [descriptor][folionumber][r/v].jpg
	
for file in *.jpg; do
	filename=$(basename $file)
	number=$(echo $filename | sed 's/[A-Za-z-]*\([0-9]*[RrVv]\)\.jpg/\1/')
	descriptor=$(echo $filename | sed 's/\([A-Za-z-]*\)[0-9]*[RrVv]\.jpg/\1/')
	
	rORv=$(echo $number | sed 's/[0-9]*\([RVrv]\)/\1/')
	number=$(echo $number | tr -d "RrVv")
	
	if [ "$rORv" == "R" ] || [ "$rORv" == "r" ] ; then
		number=$(expr $number \* 2 - 1)
	elif [ "$rORv" == "V" ] || [ "$rORv" == "v" ] ; then
		number=$(expr $number \* 2)
	fi
	
	number=$(printf "%03d" $number)
	
	if [ "$1" == "--write" ]; then
		command="mv $file ${descriptor}${number}.jpg"
	elif [ "$1" == "--copy" ]; then
		command="cp $file ${descriptor}${number}.jpg"
	else
		command="echo $file ${descriptor}${number}.jpg"
	fi
	
	eval $command
	
done
	