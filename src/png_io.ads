-- ***************************************************************************
--                      Steganography - PNG_IO
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
-- ***************************************************************************
--  PNG image I/O for steganography.
--  Always works with 8-bit RGB (3 channels).  Alpha is stripped on load.

with System;

package PNG_IO is

   --  Unsigned byte, matches the C uint8_t / png_byte type.
   type Byte is mod 256;
   for Byte'Size use 8;

   --  An in-memory PNG image.  Data points to C-allocated RGB pixel memory
   --  (row-major, 3 bytes per pixel: R G B).
   type Image is private;

   Invalid_Image : exception;

   --  Load a PNG from disk.  Raises Invalid_Image on failure.
   function Load (Filename : String) return Image;

   --  Write an Image back to disk as PNG.  Raises Invalid_Image on failure.
   procedure Save (Filename : String; Img : Image);

   --  Release C-allocated pixel memory and reset the Image record.
   procedure Free (Img : in out Image);

   --  Image dimensions (pixels).
   function Width  (Img : Image) return Positive;
   function Height (Img : Image) return Positive;

   --  Read / write a single colour channel of a pixel.
   --  Channel: 0 = R, 1 = G, 2 = B.
   function  Get_Pixel (Img : Image; X, Y, Channel : Natural) return Byte;
   procedure Set_Pixel (Img : Image; X, Y, Channel : Natural; Value : Byte);

   --  Maximum number of message bytes that fit in the image
   --  (accounting for the 4-byte length header).
   function Capacity (Img : Image) return Natural;

private

   type Image is record
      W    : Natural        := 0;
      H    : Natural        := 0;
      Data : System.Address := System.Null_Address;
   end record;

end PNG_IO;
