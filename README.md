## Make screenshots galleries
- __Consists of three scripts:__  
  - *make-screens.sh* for Linux *bash* (tested in Ubuntu 16.04)
  - *make-screens-nt.sh* for Linux *bash* (tested in Ubuntu 16.04)
  - *make-screens.cmd* for Windows *CMD.EXE* (tested in Windows 7)  
- __Dependencies:__  
  - all: 'ffmpeg', 'Imagemagick' package (*montage* and *convert*) 
  - Linux: additionally 'bc'  
  - Windows: 'ffmpeg.exe' must be in the PATH
- __Pretty fast.__ The approach is to divide the file into *N* intervals, one for each picture, and pick the first keyframe after the midpoint of each interval. This is done quickly with a single run of ffmpeg, given the duration of each interval. This way ffmpeg has *not* to decode *every* single frame which gives us the speed.  
- __Fonts__: To change the font of the text you may edit the script (in variable *'drw'*).
- __Known limitations:__ Length of the video. The shortest video I have run with success was 30 seconds, though the number of screens was limited (by the number of keyframes).  
- __Motivation:__ The screenshots plugin in the ruTorrent installation on my server did not work. The screenshots did not work in the ruTorrent Filemanager plugin either. I did not find a solution and tried to write my own script for it. I got my first idea from [this post](https://superuser.com/questions/538112/meaningful-thumbnails-for-a-video-using-ffmpeg) and refined my script after [this post](https://superuser.com/questions/1248665/how-to-increase-file-numbers-in-a-for-loop-ffmpeg).  
However, I've never written a shell script before, and I'm a little proud that I made it.  
After that, I thought it would be fun to have something similar on my home computer on Windows and also created the batch file.

---  

### make-screens.sh
Bash shell script to make screenshot gallery pages from movies with ffmpeg.  

Uses 'bc' (to properly round integers) and the 'montage' and 'convert' tools from 'Imagemagick' package.  
One could get almost the same output with only bash and ffmpeg's drawtext+tile+scale filters, though.  
But quoting/escaping in ffmpeg is a nightmare (for me, at least!).  
So here I used 'Imagemagick' and 'bc' for better results and flexibility and because I'm lazy ;-)  
Command line usage: 
~~~
  make-screens.sh INPUT [COLUMNS (6)] [ROWS (5)] [SIZE (2900)] [OUTPUT]
  INPUT is the path to the input file (the only mandatory argument).
  COLUMNS and ROWS are defaulted to 6x5 grid.
  SIZE is the length of the longer side of the output and defaulted to 2900 px.
  OUTPUT is the output file name, default is <INPUT_NAME>_prev.jpg.
   Example 1: make-screens.sh video.mp4 5 6 1440 thumbnails.jpg
   Example 2: make-screens.sh movie.avi 4
~~~
The default format is JPG. You have to edit the script for alteration.  

Without arguments except INPUT the script makes a screenshots gallery of 30 pictures in a 6x5 grid and width of 2900, the height will be calculated accordingly to the AR of the input.

To make screenshot pages without timecode use make-screens-nt.sh.

---  

### make-screens-nt.sh
Bash shell script identical to make-screens.sh, except it doesn't write time codes in the thumbnails.
The output default file name is <INPUT_NAME>_ntprev.jpg.

---  

### make-screens.cmd
Windows batch adapted version of make-screens.sh to make screenshot gallery pages from movies with ffmpeg.

Uses the 'montage' and 'convert' tools from 'Imagemagick-portable' package.  
I got this (portable) 'Imagemagick' version from [here](https://sourceforge.net/projects/imagemagick/). There's no need to install anything, just un-zip the file and you're done.  
One could get almost the same output with only CMD.EXE and ffmpeg's drawtext+tile+scale filters, though.  
But quoting/escaping in ffmpeg seems to be a nightmare.  
So I here used 'Imagemagick' for better results and flexibility and because I'm lazy ;-)  
As this is Windows country you have to define the path to the executables (*montage* and *convert*) inside the script, of course.  
Command line usage:
~~~
  make-screens.cmd COLUMNS ROWS SIZE INPUT

  COLUMNS and ROWS  of the wanted grid.  
  SIZE (px) is the length of the longer side of the output.  
  INPUT is the path to the input file.  
  (Remember to put path with blanks in quotes!)  

  ALL arguments are mandatory.

  OUTPUT is the input name, appended with _preview.jpg.

  Example: make-screens.cmd 5 6 1440 video.mp4
~~~
Compared to the bash shell script I here changed the sequence of arguments. INPUT is now the very last argument. There can be no defaults now because it's not known if and how many arguments would be given. (I could not figure out how to do it. Batch files seem to be quite unflexible on this.)  

The reason and imho benefit is that now you can make use of the drag'n'drop feature of Windows:  
Put a link to the batch file on your desktop. Go to its properties and append columns, rows and size to the command (for example:  `"drive:\path\to\make-screens.cmd" 7 6 1440`) and point to a directory of your choice. Then you can just drag'n'drop video files onto this link and get your screenshot galleries in the target directory.  

To make galleries without timecode just change the command line in the script (there is a commented one).

---
Example of screenshot gallery page (Can you name the movie?)

![Example of screenshot gallery page](https://user-images.githubusercontent.com/23389748/31731887-cd9bf856-b436-11e7-90b1-efb2f713a074.jpg)
