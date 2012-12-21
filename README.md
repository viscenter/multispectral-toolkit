multispectral-toolkit
=====================

A set of tools for organizing and processing multispectral data.


**Latest Updates**

* 12.20.2012 - mstk.sh: Flatfielded images and PNGs are now created using pngflatten. flatten currently being kept for applyflats.sh support.
* 12.13.2012 - First version of mstk and its subscripts. mstk takes a folder of dailies and outputs a fully processed collection.
* 12.7.2012 - Added To-Do list. File reorganization in anticipation of future changes.
* 12.5.2012 - Update to Copyrighter to work with either single volumes or collections of volumes.
* 12.4.2012 - Added Copyrighter to toolkit. Added some ID UI to all scripts.
* 12.3.2012 - Initial commit. First versions of despot and spectralize. Subtree merge with csparker247/flatfield. All flatfield development moving to this project.


**Installation**

* Open Terminal
* $ mkdir ~/source  
$ cd ~/source  
$ git clone https://github.com/csparker247/multispectral-toolkit.git  
$ cd ~/source/multispectral-toolkit/flatfield  
$ make
* Invoke all scripts from inside the folders you want to process. Check the MANUAL and the header of each script for more information. 


**Known Issues/Special Notes**

* Making flatten and pngflatten requires OpenCV to be installed.
* ImageMagick should be compiled with TIFF support.
* Despot can cause irregularities when rendering RGB and Multispectral images. As such, the original flats are always kept. Use with caution.

**Other Software**

This repo is developed and maintained on OSX. As such, all external software below is installed via homebrew.

* OpenCV - http://opencv.org/
* ImageMagick - http://www.imagemagick.org/
* Exiv2 - http://www.exiv2.org/
* teem - http://teem.sourceforge.net/
* GNU parallel - http://www.gnu.org/software/parallel/
* flatfield project - https://github.com/csparker247/flatfield

