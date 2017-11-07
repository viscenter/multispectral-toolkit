#include <climits>
#include <string>
#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#include <stdio.h>

int main( int argc, char *argv[] )
{
    if (argc < 4) {
        fprintf(stderr, "Usage: %s flat_file image_file out_file\n", argv[0]);
    }
    auto flat_file = argv[1];
    auto img_file = argv[2];
    auto out_file = argv[3];

    auto flat_img = cv::imread(flat_file, -1);
    auto image = cv::imread(img_file, -1);

    cv::GaussianBlur(
        flat_img, flat_img, cv::Size(3, 3), 0, 0, cv::BORDER_REPLICATE);
    cv::divide(
        image, flat_img, image, image.depth() == 0 ? UCHAR_MAX : USHRT_MAX);
    std::vector<int> compression_params;
    compression_params.push_back(CV_IMWRITE_PNG_COMPRESSION);
    compression_params.push_back(9);
    cv::imwrite(out_file, image, compression_params);

    return EXIT_SUCCESS;
}
