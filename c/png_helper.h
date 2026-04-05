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
#ifndef PNG_HELPER_H
#define PNG_HELPER_H

#include <stdint.h>

/*
 * Load a PNG file into a flat, heap-allocated RGB byte array.
 * The image is normalised to 8-bit RGB (alpha stripped, palette expanded,
 * 16-bit depth reduced to 8-bit, greyscale converted to RGB).
 *
 * On success returns 0 and sets *width, *height, and *data.
 * The caller must free *data with png_free_image().
 * On error returns a negative value and leaves the out parameters unchanged.
 */
int png_load_image(const char *filename,
                   int        *width,
                   int        *height,
                   uint8_t   **data);

/*
 * Save a flat RGB byte array (width * height * 3 bytes, row-major) as PNG.
 * Returns 0 on success, negative on error.
 */
int png_save_image(const char    *filename,
                   int            width,
                   int            height,
                   const uint8_t *data);

/* Free data returned by png_load_image. */
void png_free_image(uint8_t *data);

#endif /* PNG_HELPER_H */
