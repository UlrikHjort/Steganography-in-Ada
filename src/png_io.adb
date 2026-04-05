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
with Ada.Unchecked_Conversion;
with Interfaces.C.Strings;

package body PNG_IO is

   use type System.Address;  --  expose =, /= on System.Address

   -- -----------------------------------------------------------------------
   --  Pixel buffer access
   --  We treat the C-allocated pixel buffer as a very large flat array.
   --  Ada's bounds check will fire only if an index exceeds Natural'Last/2,
   --  which is safe for any realistic image size.
   -- -----------------------------------------------------------------------

   type Raw_Buffer is array (0 .. Natural'Last / 2) of aliased Byte;
   type Raw_Buffer_Ptr is access all Raw_Buffer;

   function To_Buffer_Ptr is
     new Ada.Unchecked_Conversion (System.Address, Raw_Buffer_Ptr);

   function Flat_Index (W : Natural; X, Y, Channel : Natural) return Natural is
     (Y * W * 3 + X * 3 + Channel);

   -- -----------------------------------------------------------------------
   --  Thin C bindings to png_helper.c
   -- -----------------------------------------------------------------------

   function C_Load
     (Filename : Interfaces.C.Strings.chars_ptr;
      Width    : access Interfaces.C.int;
      Height   : access Interfaces.C.int;
      Data     : access System.Address) return Interfaces.C.int
   with Import, Convention => C, External_Name => "png_load_image";

   function C_Save
     (Filename : Interfaces.C.Strings.chars_ptr;
      Width    : Interfaces.C.int;
      Height   : Interfaces.C.int;
      Data     : System.Address) return Interfaces.C.int
   with Import, Convention => C, External_Name => "png_save_image";

   procedure C_Free (Data : System.Address)
   with Import, Convention => C, External_Name => "png_free_image";

   -- -----------------------------------------------------------------------
   --  Public subprograms
   -- -----------------------------------------------------------------------

   function Load (Filename : String) return Image is
      use Interfaces.C;
      use Interfaces.C.Strings;

      CName    : chars_ptr := New_String (Filename);
      W, H     : aliased int;
      Data_Ptr : aliased System.Address;
      Ret      : int;
      Img      : Image;
   begin
      Ret := C_Load (CName, W'Access, H'Access, Data_Ptr'Access);
      Free (CName);
      if Ret /= 0 then
         raise Invalid_Image with "Cannot load '" & Filename & "' (error " &
           int'Image (Ret) & ")";
      end if;
      Img.W    := Natural (W);
      Img.H    := Natural (H);
      Img.Data := Data_Ptr;
      return Img;
   end Load;

   procedure Save (Filename : String; Img : Image) is
      use Interfaces.C;
      use Interfaces.C.Strings;

      CName : chars_ptr := New_String (Filename);
      Ret   : int;
   begin
      Ret := C_Save (CName, int (Img.W), int (Img.H), Img.Data);
      Free (CName);
      if Ret /= 0 then
         raise Invalid_Image with "Cannot save '" & Filename & "' (error " &
           int'Image (Ret) & ")";
      end if;
   end Save;

   procedure Free (Img : in out Image) is
   begin
      if Img.Data /= System.Null_Address then
         C_Free (Img.Data);
         Img.Data := System.Null_Address;
      end if;
      Img.W := 0;
      Img.H := 0;
   end Free;

   function Width  (Img : Image) return Positive is (Img.W);
   function Height (Img : Image) return Positive is (Img.H);

   function Get_Pixel (Img : Image; X, Y, Channel : Natural) return Byte is
      Buf : constant Raw_Buffer_Ptr := To_Buffer_Ptr (Img.Data);
   begin
      return Buf (Flat_Index (Img.W, X, Y, Channel));
   end Get_Pixel;

   procedure Set_Pixel (Img : Image; X, Y, Channel : Natural; Value : Byte) is
      Buf : constant Raw_Buffer_Ptr := To_Buffer_Ptr (Img.Data);
   begin
      Buf (Flat_Index (Img.W, X, Y, Channel)) := Value;
   end Set_Pixel;

   function Capacity (Img : Image) return Natural is
      Total_Bits : constant Natural := Img.W * Img.H * 3;
   begin
      if Total_Bits < 32 then
         return 0;
      end if;
      --  3 bits per pixel (1 LSB per RGB channel); first 4 bytes are the
      --  length header, so subtract those from the usable payload.
      return Total_Bits / 8 - 4;
   end Capacity;

end PNG_IO;
