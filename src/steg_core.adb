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
with PNG_IO; use PNG_IO;

package body Steg_Core is

   -- -----------------------------------------------------------------------
   --  Bit-level pixel helpers
   -- -----------------------------------------------------------------------

   --  Translate a flat bit index (0, 1, 2, ...) into pixel coordinates and
   --  channel, then return that pixel channel's LSB.
   function Get_Bit (Img : Image; Bit_Index : Natural) return Byte is
      Pixel_Num : constant Natural := Bit_Index / 3;
      Channel   : constant Natural := Bit_Index mod 3;
      X         : constant Natural := Pixel_Num mod Width (Img);
      Y         : constant Natural := Pixel_Num / Width (Img);
   begin
      return Get_Pixel (Img, X, Y, Channel) and 1;
   end Get_Bit;

   --  Write Bit (0 or 1) into the LSB of the channel at position Bit_Index.
   procedure Set_Bit (Img       : Image;
                      Bit_Index : Natural;
                      Bit       : Byte)
   is
      Pixel_Num : constant Natural := Bit_Index / 3;
      Channel   : constant Natural := Bit_Index mod 3;
      X         : constant Natural := Pixel_Num mod Width (Img);
      Y         : constant Natural := Pixel_Num / Width (Img);
      Old_Val   : constant Byte    := Get_Pixel (Img, X, Y, Channel);
   begin
      Set_Pixel (Img, X, Y, Channel, (Old_Val and 16#FE#) or Bit);
   end Set_Bit;

   -- -----------------------------------------------------------------------
   --  Encode
   -- -----------------------------------------------------------------------

   procedure Encode (Img : Image; Message : String) is
      Bit_Index : Natural := 0;
      Msg_Len   : constant Natural := Message'Length;

      --  Write one byte into the image, LSB first, advancing Bit_Index.
      procedure Write_Byte (B : Byte) is
      begin
         for I in 0 .. 7 loop
            Set_Bit (Img, Bit_Index, (B / Byte (2 ** I)) mod 2);
            Bit_Index := Bit_Index + 1;
         end loop;
      end Write_Byte;

   begin
      if Msg_Len > Capacity (Img) then
         raise Constraint_Error with
           "Message (" & Natural'Image (Msg_Len) &
           " bytes) exceeds image capacity (" &
           Natural'Image (Capacity (Img)) & " bytes)";
      end if;

      --  4-byte little-endian length header.
      Write_Byte (Byte (Msg_Len                     mod 256));
      Write_Byte (Byte ((Msg_Len /         256)     mod 256));
      Write_Byte (Byte ((Msg_Len /       65_536)    mod 256));
      Write_Byte (Byte ((Msg_Len /   16_777_216)    mod 256));

      --  Message payload.
      for Ch of Message loop
         Write_Byte (Byte (Character'Pos (Ch)));
      end loop;
   end Encode;

   -- -----------------------------------------------------------------------
   --  Decode
   -- -----------------------------------------------------------------------

   function Decode (Img : Image) return String is
      Bit_Index : Natural := 0;

      --  Read one byte from the image, LSB first, advancing Bit_Index.
      function Read_Byte return Byte is
         B : Byte := 0;
      begin
         for I in 0 .. 7 loop
            B         := B or (Get_Bit (Img, Bit_Index) * Byte (2 ** I));
            Bit_Index := Bit_Index + 1;
         end loop;
         return B;
      end Read_Byte;

      Msg_Len : Natural := 0;

   begin
      --  Read 4-byte little-endian length header.
      for I in 0 .. 3 loop
         Msg_Len := Msg_Len + Natural (Read_Byte) * (256 ** I);
      end loop;

      --  Sanity check: reject obviously invalid lengths.
      if Msg_Len = 0 or else Msg_Len > Capacity (Img) then
         return "";
      end if;

      declare
         Result : String (1 .. Msg_Len);
      begin
         for I in 1 .. Msg_Len loop
            Result (I) := Character'Val (Natural (Read_Byte));
         end loop;
         return Result;
      end;
   end Decode;

end Steg_Core;
