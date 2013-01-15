#include <climits>
#include <stdio.h>
#include <string>
#include <opencv/cv.h>
#include <opencv/highgui.h>
#include <opencv2/photo/photo.hpp>

using namespace cv;
using namespace std;

int main( int argc, char *argv[] )
{
  if( argc < 3 )
  {
    fprintf( stderr, "Usage: %s image_file out_file\n", argv[0] );
  }

//	Gets arguments from CLI
	const char *img_file = argv[1];
	const char *out_file = argv[2];

//	Sets up matrices and variables		
	Mat image;
	Mat workingimage;
	Mat lowdepth;
	Mat mask;
	Mat invertmask;
	double minVal, maxVal;
	
//	Load image file	
	image = imread( img_file, CV_LOAD_IMAGE_ANYCOLOR | CV_LOAD_IMAGE_ANYDEPTH );	

//	Get information about image and convert to float working image
	image.convertTo( workingimage, CV_32F );
	int lastcol = workingimage.cols - 1;
	int lastrow = workingimage.rows - 1;
	minMaxLoc(workingimage, &minVal, &maxVal);

//	Points that comprise vector of 1px-wide image border	
	Point px0 = Point( lastcol, 0 );
	Point p0y = Point( 0, lastrow );
	Point pxy = Point( lastcol, lastrow);
	
//	Make mask by thresholding image and growing output		
	threshold( workingimage, mask, 42000, 65535, 0 );
	line( mask, px0 , pxy, (maxVal, maxVal, maxVal), 1);
	line( mask, p0y , pxy, (maxVal, maxVal, maxVal), 1);
		int erosion_size = 1;   
	Mat element = getStructuringElement( MORPH_ELLIPSE,
    					                 Size(2 * erosion_size + 1, 2 * erosion_size + 1), 
                      					 Point(erosion_size, erosion_size) );
	erode ( mask, mask, element );

//	Setup for inpainting
	mask.convertTo( mask, CV_8U );
	bitwise_not( mask, invertmask );
	workingimage.convertTo(lowdepth, CV_8U, 255.0/(maxVal - minVal), -minVal * 255.0/(maxVal - minVal));
	
//	Perform inpainting and blur (currently disabled)
	inpaint(lowdepth, invertmask, lowdepth, 8.0, 1);
	// GaussianBlur( lowdepth, lowdepth, Size( 21, 21 ), 0, 0 );

//	Convert working images back to 16-bit unsigned
	minMaxLoc(lowdepth, &minVal, &maxVal);
	
	lowdepth.convertTo( lowdepth, CV_16U, 65535.0/(maxVal - minVal), -minVal * 65535.0/(maxVal - minVal));
	mask.convertTo( mask, CV_16U, 65535.0/(maxVal - minVal), -minVal * 65535.0/(maxVal - minVal));
	invertmask.convertTo( invertmask, CV_16U, 65535.0/(maxVal - minVal), -minVal * 65535.0/(maxVal - minVal));

//	Subtract bad pixels from original image and add new pixels (limits data loss)
	workingimage = (image - invertmask) + (lowdepth - mask);

//	Write-out image	
	imwrite( out_file, workingimage );
	
  return 0;
}