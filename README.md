## Make screenshots galleries
- __Consists of two scripts:__  
  - *make-screens.sh* for Linux *bash* (tested in Ubuntu 14.04)
  - *make-screens.cmd* for Windows *CMD.EXE* (tested in Windows 7)  
- __Dependencies:__  
  - both: 'ffmpeg', 'Imagemagick' package (*montage* and *convert*) 
  - Linux: additionally 'bc'  
  - 'ffmpeg.exe' must be in the PATH (under Windows)
- __Pretty fast.__ The approach is to divide the file into *N* intervals, one for each picture, and pick the first keyframe after the midpoint of each interval. This is done quickly with a single run of ffmpeg, given the duration of each interval. This way ffmpeg has *not* to decode *every* single frame which gives us the speed.  
- __Known limitations:__ Length of the video. The shortest video I've run with success was 30 seconds, though the number of screens was limited (by the number of keyframes).  

---  

### make-screens.sh
Bash shell script to make screenshot gallery pages from movies with ffmpeg.  

Uses 'bc' and the 'montage' and 'convert' tools from 'Imagemagick' package.  
One could get almost the same output with only bash and ffmpeg's drawtext+tile+scale filters, though.  
But quoting/escaping in ffmpeg is a nightmare.  
So here I used 'Imagemagick' and 'bc' for better results and flexibility and because I'm lazy ;-)
~~~
  Command line usage: 
  make-screens.sh INPUT [COLUMNS (7)] [ROWS (6)] [SIZE (2160)] [OUTPUT]

  INPUT is the path to the input file (the only mandatory argument).

  COLUMNS and ROWS are defaulted to 7x6 grid.

  SIZE is the length of the longer side of the output and defaulted to 2160 px.

  OUTPUT is the output file name, default is <INPUT_NAME>_preview.jpg.

  Example: make-screens.sh video.mp4 5 6 1440 thumbnails.png.
~~~
Without arguments except INPUT the script makes a screenshots gallery of 42 pictures in a 7x6 grid and with a width of 2160, the height will be calculated accordingly to the AR of the input.

To make screenshot pages without timecode change the command line inside the script (there's a commented one).  
I plan to add another argument to chose this per command line.

---  

### make-screens.cmd
Windows batch-adapted version of make-screens.sh to make screenshot gallery pages from movies with ffmpeg.

Uses the 'montage' and 'convert' tools from 'Imagemagick-portable' package.  
I got this (portable) 'Imagemagick' version from [here](https://sourceforge.net/projects/imagemagick/). There's no need to install anything, just un-zip the file and you're done.  
One could get almost the same output with only CMD.EXE and ffmpeg's drawtext+tile+scale filters, though.  
But quoting/escaping in ffmpeg is a nightmare.  
So I here used 'Imagemagick' for better results and flexibility and because I'm lazy ;-)  
As this is Windows-Country you have to define the path to the executables (*montage* and *convert*) inside the script, of course.
~~~
  Command line usage:
  make-screens.cmd COLUMNS ROWS SIZE INPUT

  COLUMNS and ROWS  of the wanted grid.  
  SIZE (px) is the length of the longer side of the output.  
  INPUT is the path to the input file.  
  (Remember to put path with blanks in quotes!)  

  All Arguments are mandatory.

  OUTPUT is the input name, appended with _preview.jpg.

  Example: make-screens.cmd 5 6 1440 video.mp4
~~~
I here changed  in comparison to the bash shell script the sequence of arguments. INPUT is now the very last argument. There can be no defaults now because it's not known if and how many arguments would be given. (I could not figure out how to do this. Batch files seem to be quite unflexible on this.)  

The reason and imho benefit is that now you can make use of the drag'n'drop feature of Windows:  
Put a link to the batch file on your desktop. Go to its properties and append columns, rows and size to the command (i.e. `"drive:\path\to\make-screens.cmd" 7 6 1440`) and point to a directory of your choice. Then you can drag'n'drop video files onto this link and get your screensheets in the target directory.  

To make screensheets without timecode just change the command line in the script (there's a commented one).

---
Example of screenshot gallery page

![Example of screenshot gallery page](https://user-images.githubusercontent.com/23389748/31731887-cd9bf856-b436-11e7-90b1-efb2f713a074.jpg)
