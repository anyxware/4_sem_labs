
typedef struct Image {
    unsigned char* buffer;
    int x;
    int y;
    int channels;
} Image;

unsigned char* read_image(char const* filename, Image* img);
unsigned char* create_tmp_image(int _x, int _y, int channels, unsigned char* _buffer);
void process_image(int _x, int _y, int channels, unsigned char* _buffer, unsigned char* tmp_buffer);
int write_image(char const* filename, Image* img);
