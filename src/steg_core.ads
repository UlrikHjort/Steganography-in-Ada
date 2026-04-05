-- ***************************************************************************
--                      Steganography - Steg_Core
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
--  Steganography core: LSB encoding and decoding.
--
--  Algorithm
--  ---------
--  Each colour channel (R, G, B) of every pixel carries one hidden bit in
--  its least-significant bit.  Pixels are visited in row-major order; within
--  each pixel the channels are visited R -> G -> B.
--
--  The first 32 bits (4 bytes, little-endian) encode the message byte-length.
--  The remaining bits carry the message bytes, LSB of each byte first.

with PNG_IO;

package Steg_Core is

   --  Hide Message inside Img.
   --  Raises Constraint_Error when the message is too large for the image.
   procedure Encode (Img : PNG_IO.Image; Message : String);

   --  Recover a message previously hidden with Encode.
   --  Returns an empty string when no (valid) message is found.
   function Decode (Img : PNG_IO.Image) return String;

end Steg_Core;
