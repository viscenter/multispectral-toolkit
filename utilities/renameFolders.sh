# Converts folder names from format Name### to format Name-###
for i in */; do
	if [[ "$(basename $i)" != FLATS_* ]]; then
		volume=$(basename $i | sed 's/\([A-Za-z]*\)[0-9]*[A-Za-z]*/\1/')
		page=$(basename $i | sed 's/[A-Za-z]*\([0-9]*[A-Za-z]*\)/\1/')
		mv $(basename $i) $volume-$page
	fi
done