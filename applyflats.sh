#!/bin/zsh

declare -A wavelengths
for i in Processed/*.tif; do
  WAVELENGTH=$(exiv2 -pa $i | grep Exif.Photo.SpectralSensitivity|awk '{print substr($0, index($0,$4))}')
  wavelengths[$WAVELENGTH]=$i
done

FLATFIELD_COMMANDS=""
RGB_COMMANDS=""
RGB_JPG_COMMANDS=""

declare -A rgb
for i in ${1}/*; do
  if [[ -d $i ]]; then
    echo $i 1>&2
    export RED=""
    export GREEN=""
    export BLUE=""
    if [[ -d $i/Processed ]]; then
      mkdir -p flatfielded/$(basename $i)
      for j in $i/Processed/*.tif; do
        OUTFILE="flatfielded/$(basename $i)/$(basename $j)"
        
        WAVELENGTH=$(exiv2 -pa $j | grep Exif.Photo.SpectralSensitivity|awk '{print substr($0, index($0,$4))}')
        
        if [[ -n $WAVELENGTH && "$WAVELENGTH" =~ "638nm" ]]; then
          export RED=$OUTFILE
        elif [[ -n $WAVELENGTH && "$WAVELENGTH" =~ "535nm" ]]; then
          export GREEN=$OUTFILE
        elif [[ -n $WAVELENGTH && "$WAVELENGTH" =~ "465nm" ]]; then
          export BLUE=$OUTFILE
        else
          # echo "$WAVELENGTH not a primary color" 1>&2
        fi

        if [[ ! -e $OUTFILE ]]; then
          if [[ -n $wavelengths[$WAVELENGTH] ]]; then
            FLATFIELD=$wavelengths[$WAVELENGTH]
            FLATFIELD_COMMANDS+="~/source/flatfield/flatten $FLATFIELD $j $OUTFILE\n"
          else
            echo "Skipping $j, no wavelength match in flatfields" 1>&2
          fi
        else
          echo "Skipping $j, $OUTFILE already exists" 1>&2
        fi
      done

      if [[ -n $RED && -n $GREEN && -n $BLUE ]]; then
        echo "Performing RGB for $(basename $i), was R:$RED G:$GREEN B:$BLUE" 1>&2
        rgb[$(basename $i)]="$RED $GREEN $BLUE"
      else
        echo "Skipping RGB for $(basename $i), was R:$RED G:$GREEN B:$BLUE" 1>&2
      fi

    else
      echo "Skipping $i, no processed directory" 1>&2
    fi
  else
    echo "Skipping $i, not a directory" 1>&2
  fi
done

echo "RGB: ${(k)rgb}" 1>&2

mkdir -p rgb
for i in ${(k)rgb}; do
  if [[ ! -e rgb/$i.tif ]]; then
    RGB_COMMANDS+="convert $rgb[$i] -channel RGB -combine rgb/$i.tif && convert rgb/$i.tif rgb_jpg/$i.jpg\n"
  else
    echo "Skipping RGB for $i, file already exists" 1>&2
  fi
done

mkdir -p rgb_jpg
for i in ${(k)rgb}; do
  if [[ ! -e rgb_jpg/$i.jpg ]]; then
    RGB_JPG_COMMANDS+="convert rgb/$i.tif rgb_jpg/$i.jpg\n"
  else
    echo "Skipping RGB JPG for $i, file already exists" 1>&2
  fi
done

# mkdir -p exif
# for i in flatfielded/*; do
#   for j in i/*.tif; do
#     EXV="exif/$(basename $j .tif).exv"
#     if [[ ! -e $EXV ]]; then
#       echo "exiv2 -l exif -ee ${1}/$(basename $i)/Mega/$(basename $j .tif).dng"
#     fi
#     echo "exiv2 -l exif -M'del Exif.Image.DNGVersion' -M'del Exif.Image.DNGBackwardVersion' -M'del Exif.Image.BlackLevel' -M'del Exif.Image.WhiteLevel' -M'set Exif.Image.ProcessingSoftware Ascii Flatfielded by $(basename $1)/$(basename $pwd)' in $j"
#   done
# done

echo "Flatfielding..." 1>&2
echo $FLATFIELD_COMMANDS | parallel --eta -u -v -j 8
echo "RGB..." 1>&2
echo $RGB_COMMANDS | parallel --eta -u -v
echo "JPG..." 1>&2
echo $RGB_JPG_COMMANDS | parallel --eta -u -v -j 8
