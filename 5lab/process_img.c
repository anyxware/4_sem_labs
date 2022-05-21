#define STB_IMAGE_IMPLEMENTATION
#include "stb/stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb/stb_image_write.h"

#include <stdlib.h>
#include "process_img.h"

unsigned char* read_image(char const* filename, Image* img) {
    img->buffer = stbi_load(filename,
                            &(img->x),
                            &(img->y),
                            &(img->channels),
                            0);
    return img->buffer;
}

unsigned char* create_tmp_image(int _x, int _y, int channels, unsigned char* _buffer) {
    int x = _x + 2;
    int y = _y + 2;
    unsigned char* buffer = (unsigned char*)malloc(x * y * channels);

    for(int i = 1; i < x - 1; i++) {
        buffer[i * channels] = _buffer[(i - 1) * channels];
        buffer[i * channels + 1] = _buffer[(i - 1) * channels + 1];
        buffer[i * channels + 2] = _buffer[(i - 1) * channels + 2];

        buffer[((y - 1) * x + i) * channels] = _buffer[((_y - 1) * _x + i - 1) * channels];
        buffer[((y - 1) * x + i) * channels + 1] = _buffer[((_y - 1) * _x + i - 1) * channels + 1];
        buffer[((y - 1) * x + i) * channels + 2] = _buffer[((_y - 1) * _x + i - 1) * channels + 2];
    }

    for(int j = 1; j < y - 1; j++) {
        buffer[(j * x) * channels] = _buffer[((j - 1) * _x) * channels];
        buffer[(j * x) * channels + 1] = _buffer[((j - 1) * _x) * channels + 1];
        buffer[(j * x) * channels + 2] = _buffer[((j - 1) * _x) * channels + 2];

        buffer[((j + 1) * x - 1) * channels] = _buffer[(j * _x - 1) * channels];
        buffer[((j + 1) * x - 1) * channels + 1] = _buffer[(j * _x - 1) * channels + 1];
        buffer[((j + 1) * x - 1) * channels + 2] = _buffer[(j * _x - 1) * channels + 2];
    }

    buffer[0] = _buffer[0];
    buffer[1] = _buffer[1];
    buffer[2] = _buffer[2];

    buffer[(x - 1) * channels]   = _buffer[(_x - 1) * channels];
    buffer[(x - 1) * channels + 1]   = _buffer[(_x - 1) * channels + 1];
    buffer[(x - 1) * channels + 2]   = _buffer[(_x - 1) * channels + 2];

    buffer[((y - 1) * x) * channels] = _buffer[((_y - 1) * _x) * channels];
    buffer[((y - 1) * x) * channels + 1] = _buffer[((_y - 1) * _x) * channels + 1];
    buffer[((y - 1) * x) * channels + 2] = _buffer[((_y - 1) * _x) * channels + 2];

    buffer[(x * y - 1) * channels]   = _buffer[(_x * _y - 1) * channels];
    buffer[(x * y - 1) * channels + 1]   = _buffer[(_x * _y - 1) * channels + 1];
    buffer[(x * y - 1) * channels + 2]   = _buffer[(_x * _y - 1) * channels + 2];

    for(int i = 1; i < y - 1; i++) {
        for(int j = 1; j < x - 1; j++) {
            buffer[(i * x + j) * channels] = _buffer[((i - 1) * _x + j - 1) * channels];
            buffer[(i * x + j) * channels + 1] = _buffer[((i - 1) * _x + j - 1) * channels + 1];
            buffer[(i * x + j) * channels + 2] = _buffer[((i - 1) * _x + j - 1) * channels + 2];
        }
    }

    return buffer;
}

int get_element(int a, int b, int c, int channels, unsigned char* tmp_buffer, int channel) {
    int element = (int)tmp_buffer[(a * b + c) * channels + channel];
    return element;
}

void put_element(int element, int i, int j, int x, int channels, int channel, unsigned char* buffer) {
    buffer[((i - 1) * x + j - 1) * channels + channel] = element;
}

unsigned char calc_res(int x, int channels, unsigned char* tmp_buffer, int i, int j, int channel) {
    int a, b, c;
    int res, element;

// 1)
    a = i;
    b = x + 2;
    c = j;
    element = get_element(a, b, c, channels, tmp_buffer, channel);
    res = 8 * element;

// 2)
    a = i - 1;
    b = x + 2;
    c = j - 1;
    element = get_element(a, b, c, channels, tmp_buffer, channel);
    res -= element;

// 3)
    a = i - 1;
    b = x + 2;
    c = j;
    element = get_element(a, b, c, channels, tmp_buffer, channel);
    res -= element;

// 4)
    a = i - 1;
    b = x + 2;
    c = j + 1;
    element = get_element(a, b, c, channels, tmp_buffer, channel);
    res -= element;

// 5)
    a = i;
    b = x + 2;
    c = j - 1;
    element = get_element(a, b, c, channels, tmp_buffer, channel);
    res -= element;

// 6)
    a = i;
    b = x + 2;
    c = j + 1;
    element = get_element(a, b, c, channels, tmp_buffer, channel);
    res -= element;

// 7)
    a = i + 1;
    b = x + 2;
    c = j - 1;
    element = get_element(a, b, c, channels, tmp_buffer, channel);
    res -= element;

// 8)
    a = i + 1;
    b = x + 2;
    c = j;
    element = get_element(a, b, c, channels, tmp_buffer, channel);
    res -= element;

// 9)
    a = i + 1;
    b = x + 2;
    c = j + 1;
    element = get_element(a, b, c, channels, tmp_buffer, channel);
    res -= element;

    if(res > 255)
        res = 255;

    if(res < 0)
        res = 0;

    return (char)res;


}

void process_image(int _x, int _y, int channels,
                   unsigned char* _buffer,
                   unsigned char* tmp_buffer) {

    for(int i = 1; i < _y + 1; i++) {
        for(int j = 1; j < _x + 1; j++) {
            unsigned char res = calc_res(_x, channels, tmp_buffer, i, j, 0);
            put_element(res, i, j, _x, channels, 0, _buffer);

            res = calc_res(_x, channels, tmp_buffer, i, j, 1);
            put_element(res, i, j, _x, channels, 1, _buffer);

            res = calc_res(_x, channels, tmp_buffer, i, j, 2);
            put_element(res, i, j, _x, channels, 2, _buffer);
        }
    }
}

int write_image(char const* filename, Image* img) {
    int quality = img->x * img->channels;

    if(!img->buffer || !img->x || !img->y || img->channels > 4 || img->channels < 1) {
        printf("Erorr\n");
        return -1;
    }

    int res = stbi_write_jpg(filename,
                             img->x,
                             img->y,
                             img->channels,
                             img->buffer,
                             quality);
    return res - 1;
}

/*
int main() {
    /*
     *  1  2  3  4
     *  5  6  7  8
     *  9  0  1  2
     *  3  4  5  6
     */
/*
    int x = 6;
    int y = 5;
    //unsigned char buffer[6 * 5] = {1,2,3,4,0,3, 5,6,7,8,7,5, 9,0,1,2,5,3, 3,4,5,7,2,6, 7,8,9,0,2,7};
    unsigned char buffer[6 * 5] = {1,2,3,4,5,6,
                                   7,8,9,0,1,2,
                                   3,4,5,6,7,8,
                                   9,0,1,2,3,4,
                                   5,6,7,8,9,0};
    unsigned char* new_buf = create_tmp_image(x, y, buffer);
    for(int i = 0; i < y + 2; i++) {
        for(int j = 0; j < x + 2; j++) {
            printf("%d ", new_buf[i * (x+2) + j]);
        }
        printf("\n");
    }
    //process_image(x, y, buffer, new_buf);
    for(int i = 0; i < y; i++) {
        for(int j = 0; j < x; j++) {
            printf("%d ", buffer[i * x + j]);
        }
        printf("\n");
    }

//return 0;

    Image img;
    read_image("img.jpg", &img);
    printf("%d %d", img.x, img.y);
    unsigned char* tmp_buffer = create_tmp_image(img.x, img.y, img.channels, img.buffer);
    process_image(img.x, img.y, img.channels, img.buffer, tmp_buffer);


    write_image("output.jpg", &img);
    free(img.buffer);
    free(tmp_buffer);
}

*/

