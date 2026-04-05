/***************************************************************************
--                 Steganography - PNG Helper 
--
--           Copyright (C) 2026 By Ulrik Hørlyk Hjort
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- ***************************************************************************/
#include "png_helper.h"

#include <png.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int png_load_image(const char *filename,
                   int        *width,
                   int        *height,
                   uint8_t   **data) {
    FILE *fp = fopen(filename, "rb");
    if (!fp)
        return -1;

    png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING,
                                             NULL, NULL, NULL);
    if (!png) { fclose(fp); return -2; }

    png_infop info = png_create_info_struct(png);
    if (!info) { png_destroy_read_struct(&png, NULL, NULL); fclose(fp); return -3; }

    if (setjmp(png_jmpbuf(png))) {
        png_destroy_read_struct(&png, &info, NULL);
        fclose(fp);
        return -4;
    }

    png_init_io(png, fp);
    png_read_info(png, info);

    *width  = (int)png_get_image_width(png, info);
    *height = (int)png_get_image_height(png, info);

    png_byte color_type = png_get_color_type(png, info);
    png_byte bit_depth  = png_get_bit_depth(png, info);

    /* Normalise everything to 8-bit RGB. */
    if (bit_depth == 16)
        png_set_strip_16(png);
    if (color_type == PNG_COLOR_TYPE_PALETTE)
        png_set_palette_to_rgb(png);
    if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8)
        png_set_expand_gray_1_2_4_to_8(png);
    if (png_get_valid(png, info, PNG_INFO_tRNS))
        png_set_tRNS_to_alpha(png);
    if (color_type == PNG_COLOR_TYPE_GRAY ||
        color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
        png_set_gray_to_rgb(png);
    /* Strip alpha channel if present. */
    if ((color_type & PNG_COLOR_MASK_ALPHA) ||
        png_get_valid(png, info, PNG_INFO_tRNS))
        png_set_strip_alpha(png);

    png_read_update_info(png, info);

    size_t row_bytes = (size_t)(*width) * 3;
    *data = (uint8_t *)malloc(row_bytes * (size_t)(*height));
    if (!*data) {
        png_destroy_read_struct(&png, &info, NULL);
        fclose(fp);
        return -5;
    }

    png_bytep *rows = (png_bytep *)malloc(sizeof(png_bytep) * (size_t)(*height));
    if (!rows) {
        free(*data);
        *data = NULL;
        png_destroy_read_struct(&png, &info, NULL);
        fclose(fp);
        return -6;
    }

    for (int y = 0; y < *height; y++)
        rows[y] = *data + (size_t)y * row_bytes;

    png_read_image(png, rows);
    free(rows);
    png_destroy_read_struct(&png, &info, NULL);
    fclose(fp);
    return 0;
}

int png_save_image(const char    *filename,
                   int            width,
                   int            height,
                   const uint8_t *data) {
    FILE *fp = fopen(filename, "wb");
    if (!fp)
        return -1;

    png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING,
                                              NULL, NULL, NULL);
    if (!png) { fclose(fp); return -2; }

    png_infop info = png_create_info_struct(png);
    if (!info) { png_destroy_write_struct(&png, NULL); fclose(fp); return -3; }

    if (setjmp(png_jmpbuf(png))) {
        png_destroy_write_struct(&png, &info);
        fclose(fp);
        return -4;
    }

    png_init_io(png, fp);
    png_set_IHDR(png, info,
                 (png_uint_32)width, (png_uint_32)height,
                 8, PNG_COLOR_TYPE_RGB,
                 PNG_INTERLACE_NONE,
                 PNG_COMPRESSION_TYPE_DEFAULT,
                 PNG_FILTER_TYPE_DEFAULT);
    png_write_info(png, info);

    size_t     row_bytes = (size_t)width * 3;
    png_bytep *rows      = (png_bytep *)malloc(sizeof(png_bytep) * (size_t)height);
    if (!rows) {
        png_destroy_write_struct(&png, &info);
        fclose(fp);
        return -5;
    }

    for (int y = 0; y < height; y++)
        rows[y] = (png_bytep)(data + (size_t)y * row_bytes);

    png_write_image(png, rows);
    free(rows);
    png_write_end(png, NULL);
    png_destroy_write_struct(&png, &info);
    fclose(fp);
    return 0;
}

void png_free_image(uint8_t *data) {
    free(data);
}
