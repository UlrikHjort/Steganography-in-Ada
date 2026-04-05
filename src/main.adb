-- ***************************************************************************
--                      Steganography - Main
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
--  steg - hide or reveal a text message inside a PNG image.
--
--  Usage:
--    steg encode <input.png> <output.png> <message>
--    steg decode <input.png>

with Ada.Command_Line;  use Ada.Command_Line;
with Ada.Text_IO;       use Ada.Text_IO;
with PNG_IO;
with Steg_Core;

procedure Main is

   procedure Print_Usage is
   begin
      Put_Line ("Usage:");
      Put_Line ("  steg encode <input.png> <output.png> <message>");
      Put_Line ("  steg decode <input.png>");
   end Print_Usage;

begin
   if Argument_Count < 2 then
      Print_Usage;
      Set_Exit_Status (Failure);
      return;
   end if;

   declare
      Command : constant String := Argument (1);
   begin

      -- ----------------------------------------------------------------
      if Command = "encode" then

         if Argument_Count < 4 then
            Put_Line ("Error: 'encode' requires input.png, output.png and a message.");
            Print_Usage;
            Set_Exit_Status (Failure);
            return;
         end if;

         declare
            Input   : constant String := Argument (2);
            Output  : constant String := Argument (3);
            Message : constant String := Argument (4);
            Img     : PNG_IO.Image    := PNG_IO.Load (Input);
            Cap     : constant Natural := PNG_IO.Capacity (Img);
         begin
            Put_Line ("Image    : " & Input &
                      " (" & Natural'Image (PNG_IO.Width (Img)) &
                      " x" & Natural'Image (PNG_IO.Height (Img)) & " px)");
            Put_Line ("Capacity :" & Natural'Image (Cap) & " bytes");
            Put_Line ("Message  :" & Natural'Image (Message'Length) & " bytes");

            if Message'Length > Cap then
               Put_Line ("Error: message is too large for this image.");
               PNG_IO.Free (Img);
               Set_Exit_Status (Failure);
               return;
            end if;

            Steg_Core.Encode (Img, Message);
            PNG_IO.Save (Output, Img);
            PNG_IO.Free (Img);
            Put_Line ("Done  -> " & Output);
         end;

      -- ----------------------------------------------------------------
      elsif Command = "decode" then

         declare
            Input   : constant String := Argument (2);
            Img     : PNG_IO.Image    := PNG_IO.Load (Input);
            Message : constant String := Steg_Core.Decode (Img);
         begin
            PNG_IO.Free (Img);
            if Message'Length = 0 then
               Put_Line ("No hidden message found in " & Input & ".");
            else
               Put_Line ("Hidden message: """ & Message & """");
            end if;
         end;

      -- ----------------------------------------------------------------
      else
         Put_Line ("Error: unknown command '" & Command & "'.");
         Print_Usage;
         Set_Exit_Status (Failure);
      end if;

   exception
      when PNG_IO.Invalid_Image =>
         Put_Line ("Error: could not load or save image.");
         Set_Exit_Status (Failure);
      when Constraint_Error =>
         Put_Line ("Error: message or image data issue.");
         Set_Exit_Status (Failure);
   end;

end Main;
