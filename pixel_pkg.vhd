--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package pixel_pkg is
-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;

-- populate 3*3 pixel window for sobel/median
	type pixel_window is array(0 to 8) of unsigned(7 downto 0);
	
	type row_col is record
	  r : integer;
	  c : integer;
	end record row_col;
	
	type t_lut is array (0 to 8) of row_col;

-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
	constant IMG_WIDTH  : integer := 80;
	constant IMG_HEIGHT : integer := 60; -- used to be 160*120. reduced bc of physical resources constraints

--not needed anymore apparently
--  constant R_MSB : natural := 15;
--  constant R_LSB : natural := 11;
--  constant G_MSB : natural := 10;
--  constant G_LSB : natural := 5;
--  constant B_MSB : natural := 4;
--  constant B_LSB : natural := 0;

  -- 3*3 window stuff
	constant ROW_COL_LUT : t_lut := (
	  0 => (r => -1, c => -1),
	  1 => (r => -1, c => 0),
	  2 => (r => -1, c => 1),
	  3 => (r => 0, c => -1),
	  4 => (r => 0, c => 0),
	  5 => (r => 0, c => 1),
	  6 => (r => 1, c => -1),
	  7 => (r => 1, c => 0),
	  8 => (r => 1, c => 1)
	);
  
 
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
	function sobel( p : pixel_window ) return unsigned;
	function median9(p : pixel_window) return unsigned;
	function to_gray(rgb : std_logic_vector(15 downto 0)) return unsigned;
	procedure sort2(variable a, b : inout unsigned(7 downto 0));
--

end pixel_pkg;

package body pixel_pkg is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

	function to_gray(rgb : std_logic_vector(15 downto 0)) return unsigned is
		variable r_8, g_8, b_8 : unsigned(7 downto 0);
		variable gray          : unsigned(7 downto 0);
		begin
		r_8  := unsigned(rgb(15 downto 11) & "000");
		g_8  := unsigned(rgb(10 downto 5)  & "00");
		b_8  := unsigned(rgb(4 downto 0)   & "000");
		gray := shift_right(r_8, 2) + shift_right(g_8, 1) + shift_right(b_8, 3);
		return gray;
	end function;

	function sobel(p : pixel_window) return unsigned is
	  variable gx, gy : signed(10 downto 0);
	  variable mag    : signed(11 downto 0);
	begin
	  gx := signed(resize(p(2),11)) - signed(resize(p(0),11))
			+ shift_left(signed(resize(p(5),11)), 1) - shift_left(signed(resize(p(3),11)), 1)
			+ signed(resize(p(8),11)) - signed(resize(p(6),11));

	  gy := signed(resize(p(6),11)) + shift_left(signed(resize(p(7),11)), 1) + signed(resize(p(8),11))
			- signed(resize(p(0),11)) - shift_left(signed(resize(p(1),11)), 1) - signed(resize(p(2),11));

	  mag := resize(abs(gx),12) + resize(abs(gy),12);
	  if mag > 255 then
		 return to_unsigned(255, 8);
	  else
		 return unsigned(mag(7 downto 0));
	  end if;
	end function;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;

-- Median-of-9: 19-comparator min/max network, avoids full sort
	procedure sort2(variable a, b : inout unsigned(7 downto 0)) is
	  variable tmp : unsigned(7 downto 0);
	begin
	  if a > b then
		 tmp := a; a := b; b := tmp;
	  end if;
	end procedure;

	function median9(p : pixel_window) return unsigned is --swap px by px
	  variable v : pixel_window;
	begin
		v := p;
	  sort2(v(1), v(2)); sort2(v(4), v(5)); sort2(v(7), v(8));
	  sort2(v(0), v(1)); sort2(v(3), v(4)); sort2(v(6), v(7));
	  sort2(v(1), v(2)); sort2(v(4), v(5)); sort2(v(7), v(8));
	  sort2(v(0), v(3)); sort2(v(5), v(8)); sort2(v(4), v(7));
	  sort2(v(3), v(6)); sort2(v(1), v(4)); sort2(v(2), v(5));
	  sort2(v(4), v(7)); sort2(v(4), v(2)); sort2(v(6), v(4));
	  sort2(v(4), v(2));
	  return v(4);
	end function;
 
end pixel_pkg;
