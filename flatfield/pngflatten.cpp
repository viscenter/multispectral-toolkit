#include <climits>
#include <stdio.h>
#include <string>
#include <opencv/cv.h>
#include <opencv/highgui.h>

using namespace cv;
using namespace std;

int main( int argc, char *argv[] )
{
  if( argc < 4 )
  {
    fprintf( stderr, "Usage: %s flat_file image_file out_file\n", argv[0] );
  }
	const char *flat_file = argv[1];
	const char *img_file = argv[2];
	const char *out_file = argv[3];
	
	Mat flat_img;
	flat_img = imread( flat_file, CV_LOAD_IMAGE_ANYCOLOR | CV_LOAD_IMAGE_ANYDEPTH );	
	Mat image;
	image = imread( img_file, CV_LOAD_IMAGE_ANYCOLOR | CV_LOAD_IMAGE_ANYDEPTH );
		
	GaussianBlur( flat_img, flat_img, cv::Size(3,3), 0, 0, BORDER_REPLICATE );
	divide( image, flat_img, image, image.depth() == 0 ? UCHAR_MAX : USHRT_MAX );
	vector<int> compression_params;
    compression_params.push_back(CV_IMWRITE_PNG_COMPRESSION);
    compression_params.push_back(9);
	imwrite( out_file, image, compression_params );
	
  return 0;
}