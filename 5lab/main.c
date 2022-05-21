#include "process_img.h"
#include <stdlib.h>
#include <stdio.h>
#include <time.h>

int main(int argc, char* argv[]) {
    if(argc != 3) {
        printf("Usage: %s input_image output_image\n", argv[0]);
        return 1;
    }

    const char* input = argv[1];
    const char* output = argv[2];

    struct timespec t1, t2;
    Image img;

    unsigned char* p = read_image(input, &img);

    if(!p) {
        printf("Didn't read file\n");
        return 1;
    }

    unsigned char* tmp_buffer = create_tmp_image(img.x, img.y, img.channels, img.buffer);

    clock_t start = clock();
    process_image(img.x, img.y, img.channels, img.buffer, tmp_buffer);
    clock_t finish = clock();
    printf("With C function: %lg\n", (double)(finish - start) / CLOCKS_PER_SEC);

    start = clock();
    process_image_asm(img.x, img.y, img.channels, img.buffer, tmp_buffer);
    finish = clock();
    printf("With asm function: %lg\n", (double)(finish - start) / CLOCKS_PER_SEC);

    int res = write_image(output, &img);

    if(res == -1) {
        printf("Didn't write to the file\n");
        return 1;
    }

    return 0;
}
