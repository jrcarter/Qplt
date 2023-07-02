-- Quick Plot: an Ada-GUI program to quickly produce a plot of a data set
--
-- Copyright (C) by PragmAda Software Engineering
--
-- Released under the terms of the 3-Clause BSD License. See https://opensource.org/licenses/BSD-3-Clause

with Ada.Command_Line;
with Ada.Containers.Vectors;
with Ada.Exceptions;
with Ada.Float_Text_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada_GUI;
with PragmARC.Conversions.Unbounded_Strings;
with PragmARC.Conversions.Vectors;

procedure Qplt is
   use Ada.Strings.Unbounded;
   use PragmARC.Conversions.Unbounded_Strings;

   type Plot_Point is record
      X : Float;
      Y : Float;
   end record;

   package Point_Lists is new Ada.Containers.Vectors (Index_Type => Positive, Element_Type => Plot_Point);

   type Point_List is array (Positive range <>) of Plot_Point;

   package Convert is new PragmARC.Conversions.Vectors
      (Index => Positive, Element => Plot_Point, Fixed => Point_List, Unbounded => Point_Lists);

   subtype Positive_Float is Ada_GUI.Plotting.Positive_Float;

   function Tick_Multiple (Value : Positive_Float; Tick : Positive_Float) return Positive_Float;
   -- Returns 1, 2, 5, or 10 times Tick, whichever is the smallest multiple > Value,
   -- or the smallest multiple > Value if Value > 10 * Tick

   function Spacing (Span : Positive_Float) return Positive_Float;
   -- Returns the axis tick spacing for values with a range (Max - Min) of Span

   procedure Get_Axis_Range (Min : in Float; Max : in Float; Tick : in Positive_Float; Min_Axis : out Float; Max_Axis : out Float)
   with Pre => Min < Max, Post => Min_Axis < Max_Axis;
   -- Determines the min and max axis values for data that ranges from Min to Max with an axis spacing of Tick

   procedure Usage;
   -- Outputs usage instructions to standard output

   function Tick_Multiple (Value : Positive_Float; Tick : Positive_Float) return Positive_Float is
      -- Empty
   begin -- Tick_Multiple
      if Value > 10.0 * Tick then
         return Tick * Float'Floor (Value / Tick) + Tick;
      elsif Value > 5.0 * Tick then
         return 10.0 * Tick;
      elsif Value > 2.0 * Tick then
         return 5.0 * Tick;
      elsif Value > Tick then
         return 2.0 * Tick;
      else
         return Tick;
      end if;
   end Tick_Multiple;

   function Spacing (Span : Positive_Float) return Positive_Float is
      Raw : constant Float   := Span / 10.0;
      Img : constant String  := Raw'Image;
      E   : constant Natural := Ada.Strings.Fixed.Index (Img, "E", Ada.Strings.Backward);
      Exp : constant Integer := Integer'Value (Img (E + 1 .. Img'Last) );
   begin -- Spacing
      return Tick_Multiple (Raw, 10.0 ** Exp);
   end Spacing;

   procedure Get_Axis_Range (Min : in Float; Max : in Float; Tick : in Positive_Float; Min_Axis : out Float; Max_Axis : out Float)
   is
      Span : constant Float := Max - Min;
   begin -- Get_Axis_Range
      Max_Axis := Max + 0.05 * Span;
      Min_Axis := Min - 0.05 * Span;

      if Max < 0.0 then
         Max_Axis := (if abs Max < Span then Tick else Max + Tick);
      else
         Max_Axis := Tick_Multiple (Max_Axis, Tick);
      end if;

      Max_Axis := (if Max_Axis = 0.0 then Tick else Max_Axis);

      if Min > 0.0 then
         Min_Axis := (if Min < Span then -Tick else Min - Tick);
      else
         Min_Axis := -Tick_Multiple (abs Min_Axis, Tick);
      end if;

      Min_Axis := (if Min_Axis = 0.0 then -Tick else Min_Axis);
   end Get_Axis_Range;

   procedure Usage is
      -- Empty
   begin -- Usage
      Ada.Text_IO.Put_Line (Item => "Usage: qplt [options] [<filename>]");
      Ada.Text_IO.Put_Line (Item => "   options:");
      Ada.Text_IO.Put_Line (Item => "      -h");
      Ada.Text_IO.Put_Line (Item => "      -?");
      Ada.Text_IO.Put_Line (Item => "      --help       Output this information and exit");
      Ada.Text_IO.Put_Line (Item => "      nl           (No Lines) plot data points only");
      Ada.Text_IO.Put_Line (Item => "      np           (No Points) plot lines only");
      Ada.Text_IO.Put_Line (Item => "                   If multiple of nl and np occur, only the last has effect");
      Ada.Text_IO.Put_Line (Item => "                   If neither are given, both data points and lines connecting");
      Ada.Text_IO.Put_Line (Item => "                      them are plotted");
      Ada.Text_IO.Put_Line (Item => "      -t <title>   Use <title> as the title of the window and plot");
      Ada.Text_IO.Put_Line (Item => "                   If not given, the plot is untitled and the window title is");
      Ada.Text_IO.Put_Line (Item => "                      'Quick Plot'");
      Ada.Text_IO.Put_Line (Item => "      -x <label>   Use <label> as the X-axis label; no label if not supplied");
      Ada.Text_IO.Put_Line (Item => "      -y <label>   Use <label> as the Y-axis label; no label if not supplied");
      Ada.Text_IO.Put_Line (Item => "   Anything else is considered to be <filename>");
      Ada.Text_IO.Put_Line (Item => "      If multiple occur, only the last is used");
      Ada.Text_IO.Put_Line (Item => "   Data are read from <filename> if given, or from standard input if not");
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line (Item => "   Data are lines, each containing a single 'X Y' pair separated by spaces");
      Ada.Text_IO.Put_Line (Item => "   Values may any format accepted by Ada.Text_IO.Float_IO.Get");
      Ada.Text_IO.Put_Line (Item => "   Most formats output by other programs should be OK");
      Ada.Text_IO.Put_Line (Item => "   The X value may be preceded by spaces; anything after the Y value is ignored");
   end Usage;

   type Option_ID is (Lines, Both, Points);

   Index      : Positive  := 1;
   Option     : Option_ID := Both;
   Title_Text : Unbounded_String;
   Y_Text     : Unbounded_String;
   X_Text     : Unbounded_String;
   File_Name  : Unbounded_String;
   Input      : Ada.Text_IO.File_Type;
   Data_U     : Point_Lists.Vector;
   Min_X      : Float := Float'Last;
   Max_X      : Float := Float'First;
   Min_Y      : Float := Float'Last;
   Max_Y      : Float := Float'First;
   X_Span     : Float;
   Y_Span     : Float;
   X_Tick     : Float;
   Y_Tick     : Float;
   Min_XA     : Float;
   Max_XA     : Float;
   Min_YA     : Float;
   Max_YA     : Float;

   Title   : Ada_GUI.Widget_ID;
   Graph   : Ada_GUI.Widget_ID;
begin -- Qplt
   Process_Args : loop
      exit Process_Args when Index > Ada.Command_Line.Argument_Count;

      if Ada.Command_Line.Argument (Index) = "-h" or
         Ada.Command_Line.Argument (Index) = "-?" or
         Ada.Command_Line.Argument (Index) = "--help"
      then
         Ada_GUI.End_GUI;
         Usage;

         return;
      elsif Ada.Command_Line.Argument (Index) = "nl" then
         Option := Points;
         Index := Index + 1;
      elsif Ada.Command_Line.Argument (Index) = "np" then
         Option := Lines;
         Index := Index + 1;
      elsif Ada.Command_Line.Argument (Index) = "-t" and Index < Ada.Command_Line.Argument_Count then
         Title_Text := +Ada.Command_Line.Argument (Index + 1);
         Index := Index + 2;
      elsif Ada.Command_Line.Argument (Index) = "-y" and Index < Ada.Command_Line.Argument_Count then
         Y_Text := +Ada.Command_Line.Argument (Index + 1);
         Index := Index + 2;
      elsif Ada.Command_Line.Argument (Index) = "-x" and Index < Ada.Command_Line.Argument_Count then
         X_Text := +Ada.Command_Line.Argument (Index + 1);
         Index := Index + 2;
      else
         File_Name := +Ada.Command_Line.Argument (Index);
         Index := Index + 1;
      end if;
   end loop Process_Args;

   Ada_GUI.Set_Up (Title => (if Title_Text = "" then "Quick Plot" else +Title_Text) );

   if File_Name /= "" then
      Open_File : begin
         Ada.Text_IO.Open (File => Input, Mode => Ada.Text_IO.In_File, Name => +File_Name);
         Ada.Text_IO.Set_Input (File => Input);
      exception -- Open_File
      when E : others =>
         Ada_GUI.Log (Message => "Unable to open " & (+File_Name) & ": " & Ada.Exceptions.Exception_Information (E) );
         Ada_GUI.End_GUI;
         Usage;

         return;
      end Open_File;
   end if;

   Title := Ada_GUI.New_Background_Text (Text => "<b>" & (+Title_Text) & "</b>");
   Graph := Ada_GUI.New_Graphic_Area
               (Width => 9 * Ada_GUI.Window_Width / 10, Height => 9 * Ada_GUI.Window_Height / 10, Break_Before => True);

   Get_Data : begin
      All_Points : loop
         exit All_Points when Ada.Text_IO.End_Of_File;

         One_Point : declare
            Line : constant String := Ada.Text_IO.Get_Line;

            Value : Plot_Point;
            Last  : Natural;
         begin -- One_Point
            Ada.Float_Text_IO.Get (From => Line, Item => Value.X, Last => Last);
            Min_X := Float'Min (Value.X, Min_X);
            Max_X := Float'Max (Value.X, Max_X);
            Ada.Float_Text_IO.Get (From => Line (Last + 1 .. Line'Last), Item => Value.Y, Last => Last);
            Min_Y := Float'Min (Value.Y, Min_Y);
            Max_Y := Float'Max (Value.Y, Max_Y);
            Data_U.Append (New_Item => Value);
         end One_Point;
      end loop All_Points;
   exception -- Get_Data
   when Ada.Text_IO.End_Error =>
      null;
   end Get_Data;

   X_Span := Max_X - Min_X;
   Y_Span := Max_Y - Min_Y;
   X_Tick := Spacing (X_Span);
   Y_Tick := Spacing (Y_Span);
   Get_Axis_Range (Min => Min_X, Max => Max_X, Tick => X_Tick, Min_Axis => Min_XA, Max_Axis => Max_XA);
   Get_Axis_Range (Min => Min_Y, Max => Max_Y, Tick => Y_Tick, Min_Axis => Min_YA, Max_Axis => Max_YA);

   Create_Plot : declare
      Plot : Ada_GUI.Plotting.Plot_Info :=
         Ada_GUI.Plotting.New_Plot (ID => Graph, X_Min => Min_XA, X_Max => Max_XA, Y_Min => Min_YA, Y_Max => Max_YA);

      Event : Ada_GUI.Next_Result_Info;

      use type Ada_GUI.Event_Kind_ID;
   begin -- Create_Plot
      Plot.Draw_X_Axis (Interval => X_Tick, Length => 10, Label => +X_Text);
      Plot.Draw_Y_Axis (Interval => Y_Tick, Length => 10, Label => +Y_Text);

      Get_List : declare
         Data : constant Point_List := Convert.To_Fixed (Data_U);
      begin -- Get_List
         if Option in Both .. Points then
            Draw_Points : for P of Data loop
               Plot.Draw_Point (X => P.X, Y => P.Y);
            end loop Draw_Points;
         end if;

         if Option in Lines .. Both then
            Draw_Segments : for I in Data'First .. Data'Last - 1 loop
               Plot.Draw_Line (From_X => Data (I).X,
                               From_Y => Data (I).Y,
                               To_X   => Data (I + 1).X,
                               To_Y   => Data (I + 1).Y,
                               Color  => Ada_GUI.To_Color (Ada_GUI.Red) );
            end loop Draw_Segments;
         end if;
      end Get_List;

      Wait : loop
         Event := Ada_GUI.Next_Event;

         exit Wait when not Event.Timed_Out and then Event.Event.Kind = Ada_GUI.Window_Closed;
      end loop Wait;

      Ada_GUI.End_GUI;
   end Create_Plot;

   if File_Name /= "" then
      Ada.Text_IO.Close (File => Input);
   end if;
exception -- Qplt
when E : others =>
   if Ada_GUI.Set_Up then
      Ada_GUI.Log (Message => "Qplt ended by exception: " & Ada.Exceptions.Exception_Information (E) );
      Ada_GUI.End_GUI;
   else
      Ada.Text_IO.Put_Line (Item => "Qplt ended by exception: " & Ada.Exceptions.Exception_Information (E) );
   end if;

   Usage;
end Qplt;
