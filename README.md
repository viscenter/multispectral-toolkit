multispectral-toolkit
=====================

A set of tools for organizing and processing multispectral data.


**Latest Updates**

* 12.3.2012 - Initial commit. First versions of despot and spectralize. Subtree merge with csparker247/flatfield. All flatfield development moving to this project.


**Installation**

* Open Terminal
* $ mkdir ~/source
  $ cd ~/source
  $ git clone https://github.com/csparker247/multispectral-toolkit.git
  $ cd ~/source/multispectral-toolkit/flatfield
  $ make flatten
* Invoke all scripts from inside the folders you want to process. Check the header of each script for more information. 


**Known Issues/Special Notes**

* Making flatten requires OpenCV to be installed.
* Make sure to build ImageMagick with TIFF support.

**Other Software**

This repo is developed and maintained on OSX. As such, all external software below is installed via homebrew.

* OpenCV - http://opencv.org/
* ImageMagick - http://www.imagemagick.org/
* Exiv2 - http://www.exiv2.org/
* teem - http://teem.sourceforge.net/
* GNU parallel - http://www.gnu.org/software/parallel/
* flatfield project - https://github.com/csparker247/flatfield

