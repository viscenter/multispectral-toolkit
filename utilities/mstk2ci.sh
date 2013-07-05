#!/bin/sh
# From mstk to Google CI
# Copies and renames multispectral measurement JPGs specific to Google CI upload process
# Run from output folder created by mstk.sh

echo
echo -------------------------------
echo mstk output to Google CI script
echo -------------------------------
echo

while true; do
	read -p "Enter output location (NOTE: Folders can be dropped onto the Terminal window): " output_folder
	# echo $output_folder
	if  [[ -d $output_folder && -w $output_folder ]]; then
		echo
		echo "You have selected $output_folder"
		break
	else
		if [[ ! -d $output_folder || ! -w $output_folder ]]; then
		echo "This is not a valid selection. Please select again."
		echo
		continue
		fi
	fi
done
echo
COPY_COMMANDS=""
echo "$(date +"%F") :: $(date +"%T") :: Scanning directory structure..." 1>&2
for i in */; do
	if [ -d "$(basename $i)"/multispectral_jpg ]; then
		for sourcepath in $(find "$(basename $i)"/multispectral_jpg -type f -name "*.jpg"); do
			sourcefile=$(basename $sourcepath)
			
			#Intercepts
			if [[ "$sourcefile" =~ "intc-heq" ]]; then
				if [[ ! -d ${output_folder}/MSIntercept ]]; then
					mkdir -p ${output_folder}/MSIntercept
				fi
				
				outfile=$(echo "$sourcefile" | sed 's/\(.*\)-\([0-9A-Za-z]*\)-f-m-intc-heq\.jpg/\1-MSIntercept-\2\.jpg/')
				outpath=${output_folder}/MSIntercept/$outfile
				
				COPY_COMMANDS+="cp $sourcepath $outpath\n"
			fi
			
			#Standard Deviation
			if [[ "$sourcefile" =~ "sd-heq" ]]; then
				if [[ ! -d ${output_folder}/MSStdDev ]]; then
					mkdir -p ${output_folder}/MSStdDev
				fi
				
				outfile=$(echo "$sourcefile" | sed 's/\(.*\)-\([0-9A-Za-z]*\)-f-m-sd-heq\.jpg/\1-MSStdDev-\2\.jpg/')
				outpath=${output_folder}/MSStdDev/$outfile
				
				COPY_COMMANDS+="cp $sourcepath $outpath\n"
			fi
			
			#Skew
			if [[ "$sourcefile" =~ "skew-heq" ]]; then
				if [[ ! -d ${output_folder}/MSSkew ]]; then
					mkdir -p ${output_folder}/MSSkew
				fi
				
				outfile=$(echo "$sourcefile" | sed 's/\(.*\)-\([0-9A-Za-z]*\)-f-m-skew-heq\.jpg/\1-MSSkew-\2\.jpg/')
				outpath=${output_folder}/MSSkew/$outfile
				
				COPY_COMMANDS+="cp $sourcepath $outpath\n"
			fi			
		done
	fi
	if [ -d "$(basename $i)"/rgb_jpg ]; then
		for sourcepath in $(find "$(basename $i)"/rgb_jpg -type f -name "*.jpg"); do
			sourcefile=$(basename $sourcepath)
			
			#RGB
				if [[ ! -d ${output_folder}/RGB ]]; then
					mkdir -p ${output_folder}/RGB
				fi
				
				outfile=$(echo "$sourcefile" | sed 's/\([0-9A-Za-z]*\)-\([0-9A-Za-z]*\)\.jpg/\1-RGB-\2\.jpg/')
				outpath=${output_folder}/RGB/$outfile
				
				COPY_COMMANDS+="cp $sourcepath $outpath\n"
		done
	fi
done
# Run all accumulated commands at once
echo
echo "$(date +"%F") :: $(date +"%T") :: Copying all files..." 1>&2
echo $COPY_COMMANDS | parallel -eta -u -j 8
echo
echo ----------------------
echo "  ALL WORK COMPLETE"
echo "$(date +"%F") :: $(date +"%T")"
echo ----------------------
echo
		