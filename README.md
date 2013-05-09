multispectral-toolkit
=====================

A set of tools for organizing and processing multispectral data.


**Latest Updates**

* 5.9.2013 - Branch for v2.0. Sync spectralize.sh, applyflats.sh with their mstk counterparts. 
* 1.15.2013 - despot now uses in-painting via OpenCV. Spot isolation needs a lot of work.
* 12.20.2012 - mstk.sh: Flatfielded images and PNGs are now created using pngflatten. flatten currently being kept for applyflats.sh support.
* 12.13.2012 - First version of mstk and its subscripts. mstk takes a folder of dailies and outputs a fully processed collection.


**Installation**

* Check MANUAL.md for installation instructions  


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

