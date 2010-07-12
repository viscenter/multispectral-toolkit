
#include <stdio.h>
#include <opencv/cv.h>
#include <opencv/highgui.h>

IplImage * flatten_image( const char *flat, const char *img )
{
  IplImage * flat_img = cvLoadImage( flat,
      CV_LOAD_IMAGE_ANYCOLOR|CV_LOAD_IMAGE_ANYDEPTH );
  //printf( "Loading '%s', depth %u\n", flat, flat_img->depth );
  IplImage * image = cvLoadImage( img,
      CV_LOAD_IMAGE_ANYCOLOR|CV_LOAD_IMAGE_ANYDEPTH );
  //printf( "Loading '%s', depth %u\n", img, image->depth );

  if( flat_img && image )
  {
    cvSmooth( flat_img, flat_img );
    cvDiv( image, flat_img, image, 256 );

    cvReleaseImage( &flat_img );
    return image;
  }

  if( flat_img ) cvReleaseImage( &flat_img );
  if( image ) cvReleaseImage( &image );

  return NULL;
}

int main( int argc, char *argv[] )
{
  if( argc < 4 )
  {
    fprintf( stderr, "Usage: %s flat_dir image_dir out_file\n", argv[0] );
  }
  const char *flat_file = argv[1];
  const char *img_file = argv[2];
  const char *out_file = argv[3];

  IplImage *out = flatten_image( flat_file, img_file );
  cvSaveImage( out_file, out );
  cvReleaseImage( &out );

  return 0;
}

