#!/bin/bash 
#
################################################################################
#                                                                              #
# make-screens.sh                                                              #
#                                                                              #
# Shell script to make screenshot pages from movies with 'ffmpeg'.             #
#                                                                              #
# Uses 'bc' and the 'montage' and 'convert' tools from 'Imagemagick'           #
# package, so these must be installed.                                         #
#                                                                              #
# Works pretty fast. The approach is to divide the file into N intervals,      #
# one for each picture and pick the first keyframe after the midpoint of       #
# each interval. This is done quickly with a single run of ffmpeg, given       #
# the duration of each interval.                                               #
#                                                                              #
# Known limitations: Length of the video. The shortest video I've run with     #
# success was 30 seconds, though the number of screens was limited (by the     #
# number of keyframes in the video).                                           #
#                                                                              #
# One could get almost the same output with only bash and ffmpeg's             #
# drawtext+tile+scale filter, though.                                          #
# But quoting/escaping in ffmpeg is a nightmare.                               #
# So here I used 'Imagemagick' and 'bc' for better results and flexibility.    #
#                                                                              #
#                                                                              #
# Usage: make-screens.sh INPUT [COLUMNS (7)] [ROWS (6)] [SIZE (2160)] [OUTPUT] #
#                                                                              #
# INPUT is the path to the input file (the only mandatory argument).           #
#                                                                              #
# COLUMNS and ROWS are defaulted to 7x6 grid.                                  #
#                                                                              #
# SIZE is the length of the longer side of the output and defaulted to 2160 px.#
#                                                                              #
# OUTPUT is the output file name, default is <INPUT_NAME>_preview.jpg.         #
#                                                                              #
# Example: make-screens.sh video.mp4 5 6 1440 thumbnails.png.                  #
#                                                                              #
# Without arguments except INPUT the script makes a screensheet of             #
# 42 thumbnails in a 7x6 grid and with a width of 2160, the height will        #
# be calculated accordingly.                                                   #
#                                                                              #
#                                                                              #
# To make screenshot pages without timecode change the command line in         #
# the script (there's a commented one).                                        #
# I plan to add another argument to chose this per command line.               #
#                                                                              #
################################################################################
# 
#  ~~~~~~~~~~~~~~~~~~~~~~~~~~~ Script starts here ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
### initialize
MOVIE=$1		# Input
N=			# Number of thumbnails - will be calculated
COLS=$2			# Columns
ROWS=$3			# Rows
HEIGHT=			# Height of each thumbnail
SIZE=$4			# Length of the longer side of the screenshot page 
OUTPUT=$5		# Output file name - defaults to: Input_preview.jpg

if [[ $1 = "" ]]; then
    echo -e "wrong usage

 Usage: make-screens.sh INPUT [COLUMNS (7)] [ROWS (6)] [SIZE (2160)] [OUTPUT]

 INPUT is the path to the input file
 COLUMNS and ROWS are defaulted to 6x5 grid
 SIZE is the length of the longer side of the output
 OUTPUT is the output file name

 Example: make-screens.sh video.mp4 5 6 1440 thumbnails.png \n\n"
    exit 1
fi

### get video name without path and extension
MOVIE_NAME=$(basename "$MOVIE")

### setting defaults
if [[ -z $N ]]; then N=30; fi
if [[ -z $COLS ]]; then COLS=6; fi
if [[ -z $ROWS ]]; then ROWS=5; fi
if [[ -z $HEIGHT ]]; then HEIGHT=300; fi
if [[ -z $SIZE ]]; then SIZE=3000; fi
if [[ -z $OUTPUT ]]; then OUTPUT="${MOVIE_NAME%.*}_preview.jpg"; fi

OUT_DIR=$(pwd)
OUT_FILEPATH="$OUT_DIR/$OUTPUT"
echo -e "\n  Out-path: $OUT_FILEPATH \n"

TILE="$COLS"x"$ROWS"			# to be used in 'montage'
HEIGHT=$(echo "$SIZE" / "$ROWS" | bc)	# is calculated eventually
N=$(( COLS*ROWS ))

### ffmpeg/ffprobe input options
hb="-hide_banner"					# supress the initial ffmpeg banner
io="-skip_frame nokey -discard nokey -loglevel panic"	# accelerates the processing

### get duration of input:
D=$(echo "$(ffprobe $hb -i "$MOVIE" 2>&1 | sed  -n 's/.*: \(.*\), start:.*/\1/p' | sed 's/:/*60+/g;s/*60/&&/') / 1" | bc)

### get frame rate (tbr) of input'
W=$(ffprobe $hb "$MOVIE" 2>&1 | sed -n 's/.*, \(.*\) tbr.*/\1/p')

### get frame count of input'
Z=$(ffprobe $hb -show_streams -select_streams v:0 "$MOVIE" 2>&1 | grep nb_frames | head -n1 | sed 's/.*=//')

### some containers don't provide this value, so as a fallback we calculate
### the frame count from duration and frame rate, very unprecise, though
[[ $Z = "N/A" ]] || [[ $Z = "" ]] && Z=$(echo "$D * $W / 1" | bc)

### get height of input:
H=$(ffprobe -show_streams -select_streams v:0 "$MOVIE" 2>&1 | grep height | head -n1 | sed 's/.*=//')

### set fontsize as 7% of height of input:
F=$(echo "$H * 7 / 100" | bc)
SH=$(echo "$H / 200" | bc)

### interval for image extraction, used in ffmpeg
I=$(echo "$D / $N / 1" | bc)

### generate screens in the /tmp folder
TMPDIR=/tmp/thumbnails-${RANDOM}/
mkdir $TMPDIR

echo -e "  Making screens from: $MOVIE_NAME ...

(TMPDIR is: $TMPDIR)

  Height of Movie is: $H
  Fontsize is 7% of $H: $F
  Movie duration is: $Z frames / $D seconds @ $W fps

  ffmpeg extracting screens..."

### ffmpeg processing options:
 # write the timecode in upper left corner 
drw="drawtext=text='%{pts\:hms}' - ifr %{n}:r=$W:x=12:y=8:shadowx=$SH:shadowy=$SH:fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:fontcolor=lightyellow:fontsize=$F"
 # select frames according to interval
po="select=eq(n\,0)+gte(mod(t\,$I)\,$I/2)*gte(t-prev_selected_t\,$I/2),trim=1"

### ffmpeg command line:
ffmpeg $io $hb -ss 0 -i "$MOVIE" -an -sn -vf "$drw","$po" -vsync 0 -vframes $N ${TMPDIR}thumb%03d.jpg

### same without time code - uncomment this and comment the above one
#ffmpeg $io $hb -ss 20 -i "$MOVIE" -an -sn -vf "$po" -vsync 0 -vframes $N ${TMPDIR}thumb%03d.jpg

ret_val=$?

if [[ ! $ret_val -eq 0 ]]; then
    echo -e "  ffmpeg: Image extraction failed!\n "
    exit $ret_val
else
    echo -e "  Total number of images: $N\n"
    echo -e "  montage and convert..."

    ### mount the thumbnail pics in one page neatly
    montage ${TMPDIR}thumb*.jpg -background white -shadow -geometry +5+5 -tile ${COLS}x ${TMPDIR}output.jpg
    convert ${TMPDIR}output.jpg -resize ${SIZE}x${SIZE} "$OUTPUT"

    ret_val=$?

        if [[ ! $ret_val -eq 0 ]]; then
            echo -e "\n  montage/convert failed!\n"
            exit $ret_val
        else
            echo -e "  Tile pattern: $TILE\n"
            echo -e "  Screens successfully written to: $OUTPUT\n"
    rm -R $TMPDIR
    echo -e "(TMPDIR removed) \n\n\n"
        fi
fi
