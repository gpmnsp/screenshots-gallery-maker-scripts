@echo off & setlocal
goto ENDCOMNT

################################################################################
# Windows batch adapted version of make-screens.sh to make screenshot gallery  #
# pages from movies with ffmpeg (must be in PATH).                             #
#                                                                              #
# Uses the 'montage' and 'convert' tools from 'Imagemagick-portable'           #
# package, so these must be installed.                                         #
#                                                                              #
# Works pretty fast. The approach is to divide the file into N intervals,      #
# one for each picture and pick the first keyframe after the midpoint of       #
# each interval. This is done quickly with a single run of ffmpeg, given       #
# the duration of each interval.                                               #
#                                                                              #
# Known limitations: Length of the video. The shortest video I've run with     #
# success was 30 seconds, though the number of screens was limited             #
# (by the number of keyframes in the video).                                   #
#                                                                              #
# Instead of ffmpeg's drawtext+tile+scale filters I here used 'Imagemagick'    #
# for better results and flexibility.                                          #
# I got the portable 'Imagemagick' version (x64) from here:                    #
#                                                                              #
# https://sourceforge.net/projects/imagemagick/                                #
#                                                                              #
# There is no need to install anything. Just un-zip the file and you're done.  #
#                                                                              #
# As this is Windows-Country you have to define the path to the executables    #
# (montage and convert) inside the script, of course.                          #
#                                                                              #
# Usage (to run on command line):                                              #
# make-screens.cmd COLUMNS ROWS SIZE INPUT                                     #
#                                                                              #
# COLUMNS and ROWS of the wanted grid.                                         #
# SIZE (px) is the length of the longer side of the output.                    #
# INPUT is the path to the input file.                                         #
# (Remember to put path with blanks in quotes!)                                #
#                                                                              #
# All Arguments are mandatory.                                                 #
#                                                                              #
# OUTPUT is the input name, appended with _preview.jpg.                        #
#                                                                              # 
# Example: make-screens.cmd 5 6 1440 video.mp4                                 #
#                                                                              #
# I here changed in comparison to the bash shell script the sequence of        #
# arguments. INPUT is now the very last argument. There can be no defaults     #
# now because it's not known if and how many arguments would be given.         #
# (I could not figure out how to do it. Batch files seem to be quite           #
# unflexible on this.)                                                         #
#                                                                              #
# The reason and imho benefit is that now you can make use of the              #
# drag'n'drop feature of Windows:                                              #
#                                                                              #
# Put a link to the batch file on your desktop, go to its properties and       #
# append columns, rows and size to the command like so:                        #
#                                                                              #
# "Drive:\Path\to\make-screens.cmd" 5 6 1440                                   #
#                                                                              #
# and (optionally) point to a target directory of your choice.                 #
#                                                                              #
# Just leave out the INPUT argument, this will become the dropped file.        #
#                                                                              #
# Then you can drag'n'drop video files onto this link and get your             #
# screenshots gallery made in the target directory.                            #
#                                                                              #
# To make galleries without timecode just change the command line in           #
# the script (there is a commented one).                                       #
#                                                                              #
# To change the used font look out for the 'drw' variable.                     #
#                                                                              #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~ Script starts here ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
:ENDCOMNT

if not [%4] EQU [] goto CONTIN1

echo.
echo   **************************************************************************
echo   *                                                                        *
echo   *  This script uses 'ffmpeg' and the tools 'montage' and 'convert'       *
echo   *  from the 'Imagemagick' package, so these must be installed.           *
echo   *                                                                        *
echo   *  ffmpeg must be in the %%PATH%%, the path to 'montage' and 'convert'     *
echo   *  must be assigned in the script itself.                                *
echo   *                                                                        *
echo   *  Takes as input columns, rows and size ^(px^) of the screensheet         *
echo   *  and a video file and makes a screenshot gallery very fast.            *
echo   *                                                                        *
echo   *  Usage: make-screens.cmd COLUMNS ROWS SIZE INPUT                       *
echo   *                                                                        *
echo   *  COLUMNS and ROWS are the ones of the used grid.                       *
echo   *                                                                        *
echo   *  SIZE is the longer side of the output ^(px^).                           *
echo   *                                                                        *
echo   *  INPUT is the path to the input file                                   *
echo   *  ^(REMEMBER TO PUT PATH WITH SPACES IN QUOTES!^)                         *
echo   *                                                                        *
echo   *  ALL arguments are mandatory.                                          *
echo   *                                                                        *
echo   *  OUTPUT is input name appended with "_preview.jpg" ^(in %%cd%%^)           *
echo   *                                                                        *
echo   *  Example: make-screens.cmd 5 8 1440 video.mp4 -^> "video_preview.jpg"   *
echo   *                                                                        *
echo   **************************************************************************
echo.
goto:eof

:CONTIN1
REM : initialize and setting defaults
set COLS=%1
set ROWS=%2
set SIZE=%3
set MOVIE="%~4"

set OUT_DIR=%cd%
set OUTPUT=%~n4_preview.jpg
set OUT_FILEPATH=%OUT_DIR%\%OUTPUT%

REM : to generate screens in a /tmp folder - will be deleted at exit
set TMPDIR="%TMP%.\thumbnails-%RANDOM%"
set MOVIE_NAME="%~n4"
mkdir %TMPDIR%

REM : ffmpeg/ffprobe input options:

REM : prevent the initial ffmpeg banner and stdout (actually it is stderr)
set hb=-hide_banner -loglevel panic

REM : accelerate the processing by only use keyframes (p and b frames aren't useful as images anyway)
set io=-skip_frame nokey -discard nokey

REM : get duration (seconds) of input:
for /F "tokens=1,2 delims=." %%a in ('ffprobe -i %MOVIE% -show_entries format^=duration -v quiet -of csv^=^"p^=0^"') do (
REM : split the output to further processing
	set first_part=%%a
	set second_part=%%b )

REM : we can't go on if we don't get DURATION so then we use a fallback method
if [%first_part%]==[N/A] goto FALLBACK
if [%first_part%]==[] goto FALLBACK

REM : otherwise round the value to int
set /a DUR=%first_part% )
set second_part=%second_part:~0,2%
if defined second_part if %second_part% GEQ 50 (
	set /a DUR=%first_part%+1 )

goto CONTIN2

:FALLBACK
REM : fallback method to get DURATION:

REM :  write ffprobe stderr to file
set FILE=%TMPDIR%.\file
ffprobe %MOVIE% 2>%FILE%

REM :  get the 'Duration' (h:m:s) from the written file
for /F "tokens=2 delims=, "  %%a in ('findstr /L Duration %FILE%') do (
	set first_part=%%a )

REM :  we still can't go on if we don't get DURATION
if [%first_part%]==[N/A] goto ERROR
if [%first_part%]==[] goto ERROR

REM :  get the duration in seconds and make shure there are no leading zeros
REM :  (CMD might interpret this otherwise as hex numbers)
for /F "tokens=1,2,3,4 delims=:."  %%a in ("%first_part%") do (
    set /a hour=100%%a %% 100
    set /a minute=100%%b %% 100
    set /a second=100%%c %% 100
    set /a decsec=100%%d %% 100 )

set /a DUR=%hour%*60*60+%minute%*60+%second%
set decsec=%decsec:~0,2%
if %decsec% GEQ 50 (
    set /a DUR=%DUR%+1 )


:CONTIN2
REM : get frame rate (tbr) of input
for /F "tokens=2,3 delims==/" %%a in ('ffprobe %hb% -show_streams -select_streams v:0 %MOVIE% ^| findstr avg_frame_rate') do (
    set first_part=%%a
    set second_part=%%b )

if defined second_part if %second_part% GEQ 5 (
    set /a TBR=%first_part% / %second_part% +1
) else (
    set /a TBR=%first_part% / %second_part% )


REM : get dimensions of input frames
for /F "tokens=2 delims==" %%a in ('ffprobe %hb% -show_streams -select_streams v:0 %MOVIE% ^| Findstr height') do (
    set /a HEIGHT=%%a )

for /F "tokens=2 delims==" %%a in ('ffprobe %hb% -show_streams -select_streams v:0 %MOVIE% ^| Findstr width') do (
    set /a WIDTH=%%a )

REM : set fontsize and shadow proportional to height of input to get reasonable text size
REM : ~ 7% here, you may change this
set /a fs=%HEIGHT% *7/100
set /a sh=%HEIGHT%/180

REM : number of screens 'N' is calculated eventually
set /a N=%COLS%*%ROWS%

REM : interval 'Iv' for image extraction, to be used in ffmpeg
set /a Iv=%DUR% / %N%

REM : tile pattern to be used in 'montage'
set TILE=%COLS%x%ROWS%

echo.
echo   ffmpeg extracting screens from: %MOVIE_NAME%...
echo.
echo  ^(TMPDIR is: %TMPDIR%^)
echo.
echo   Dimension of input frames: %WIDTH%x%Height% px
echo   Fontsize: %fs% px  Shadow: %sh%
echo   %DUR% sec @ %TBR% FPS
echo.

REM : ffmpeg processing options:

REM :  set params to write timecode and ifr number in upper left corner
REM :  (if you want, change the used font here)
set drw="drawtext=text='%%{pts\:hms} - ifr %%{n}':r=%TBR%:fontfile='C\:\\Windows\\Fonts\\ARIALBD.TTF':shadowx=%sh%:shadowy=%sh%:fontcolor=lightyellow:fontsize=%fs%:x=12:y=8"

REM :  set params to select frames according to interval
set po="select='eq(n\,0)+gte(mod(t\,%Iv%)\,%Iv%/2)*gte(t\-prev_selected_t\,%Iv%/2)'"

REM : ffmpeg command line with timecode
ffmpeg %hb% %io% -i %MOVIE% -an -sn -vf %drw%,%po%,trim=1 -vsync 0 -vframes %N% %TMPDIR%\thumb%%03d.jpg

REM : ffmpeg command line without time code
REM : uncomment this and comment the above one (just skips the drawtext options)
REM ffmpeg %hb% %io% -i %MOVIE% -an -sn -vf %po%,trim=1 -vsync 0 -vframes %N% %TMPDIR%\thumb%%03d.jpg

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ffmpeg: Image extraction failed!
    echo.
    goto END
) else (
    echo   Total number of images: %N%
    echo.
    echo   montage and convert... )
	
REM : mount the screens in one page neatly and resize
REM : (set here the location of the executables to be used)
set MONTAGE="D:\Program Files\ImageMagick-6.8.6-8\montage.exe"
set CONVERT="D:\Program Files\ImageMagick-6.8.6-8\convert.exe"

%MONTAGE% %TMPDIR%\thumb*.jpg ^
-background white -shadow -geometry +5+5 -tile %COLS%x %TMPDIR%\output.jpg

%CONVERT% %TMPDIR%\output.jpg -resize %SIZE%x%SIZE% "%OUTPUT%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   Something went wrong, Montage/Convert failed! Try again.
    echo.
    rmdir /s /q %TMPDIR%
    echo  ^(TMPDIR removed^)
    goto ERROR1
)

REM : get dimensions of output frames
for /F "tokens=2 delims==" %%a in ('ffprobe %hb% -show_streams -select_streams v:0 "%OUTPUT%" ^| Findstr height') do (
    set /a HEIGHT=%%a )

for /F "tokens=2 delims==" %%a in ('ffprobe %hb% -show_streams -select_streams v:0 "%OUTPUT%" ^| Findstr width') do (
    set /a WIDTH=%%a )


echo   Tile pattern: %TILE%
echo   Screenshot gallery with %WIDTH%x%Height% px written to:
echo.
echo   "%OUT_FILEPATH%"
goto END )
	
:ERROR
echo.
echo. Aborted. Could not get DURATION of:
echo.
echo   "%~4",
echo.
echo  can't go on!
:ERROR1
echo.
rmdir /s /q %TMPDIR%
echo  ^(TMPDIR removed^)
echo.
endlocal
timeout 4
exit /b 1

:END
echo.
rmdir /s /q %TMPDIR%
echo  ^(TMPDIR removed^)
echo.
endlocal
timeout 4
exit /b 0
