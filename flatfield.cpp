
#include <stdio.h>
#include <dirent.h>
#include <cv.h>
#include <highgui.h>

int tif_filter( struct dirent * d )
{
  if( d && d->d_name && strlen(d->d_name) > 4 &&
      ( strcmp( &d->d_name[strlen(d->d_name)-4], ".tif" ) == 0 ||
        strcmp( &d->d_name[strlen(d->d_name)-4], ".TIF" ) == 0 ) )
    return 1;
  return 0;
}

IplImage * flatten_image( const char *flat, const char *img )
{
  IplImage * flat_img = cvLoadImage( flat,
      CV_LOAD_IMAGE_ANYCOLOR|CV_LOAD_IMAGE_ANYDEPTH );
  printf( "Loading '%s', depth %u\n", flat, flat_img->depth );
  IplImage * image = cvLoadImage( img,
      CV_LOAD_IMAGE_ANYCOLOR|CV_LOAD_IMAGE_ANYDEPTH );
  printf( "Loading '%s', depth %u\n", img, image->depth );

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
  const char *flat_dir = argv[1];
  const char *img_dir = argv[2];
  const char *out_file = argv[3];

  struct dirent **flatlist = NULL, **imglist = NULL;
  int num_flat = scandir( flat_dir, &flatlist, tif_filter, alphasort );
  int num_img  = scandir( img_dir, &imglist, tif_filter, alphasort );

  char flat_path[1024], img_path[1024];
  IplImage *red = NULL, *green = NULL, *blue = NULL;
  for( int i=1, j=1; i<num_img && j<num_flat; ++i, ++j )
  {
    if( num_img < num_flat && i==1 ) { free( flatlist[j++] ); }

    snprintf( flat_path, sizeof(flat_path), "%s/%s",
        flat_dir, flatlist[j]->d_name );
    snprintf( img_path, sizeof(img_path), "%s/%s",
        img_dir, imglist[i]->d_name );
    switch( j )
    {
      case 2:
        blue = flatten_image( flat_path, img_path );
        printf( "blue:  %08x\n", blue );
        break;
      case 4:
        green = flatten_image( flat_path, img_path );
        printf( "green: %08x\n", green );
        break;
      case 7:
        red = flatten_image( flat_path, img_path );
        printf( "red:   %08x\n", red );
        break;
    }

    free( flatlist[j] );
    free( imglist[i] );
  }

  if( red && green && blue )
  {
    IplImage *rgb = cvCreateImage( cvGetSize(red), red->depth, 3 );
    cvMerge( blue, green, red, NULL, rgb );
    cvSaveImage( out_file, rgb );
    cvReleaseImage( &rgb );
  }
  if( red ) cvReleaseImage( &red );
  if( green ) cvReleaseImage( &blue );
  if( blue ) cvReleaseImage( &green );

  return 0;
}

