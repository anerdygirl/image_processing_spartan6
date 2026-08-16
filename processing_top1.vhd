----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:42:36 07/29/2026 
-- Design Name: 
-- Module Name:    processing_top1 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.pixel_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

----------------------------------------------------------------------------------
-- Module Name:    processing_top1 - Behavioral 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pixel_pkg.all;

entity processing_top1 is
  generic (
    PIXEL_WIDTH  : integer := 16;  --allows rgb565 px to pass through, no processing
    ADDR_WIDTH   : integer := 13  -- 2^addr_width >= width * height . basic arch processeurs stuff
  );
  Port ( 
    clk          : in  STD_LOGIC;
    rst          : in  STD_LOGIC;
    en           : in  STD_LOGIC;	-- "done" signal of the previous state
    done         : out STD_LOGIC;
    px_in        : in  STD_LOGIC_VECTOR (PIXEL_WIDTH-1 downto 0); -- Directly from img_rom
    px_out       : out STD_LOGIC_VECTOR (PIXEL_WIDTH-1 downto 0);
    sel          : in  STD_LOGIC_VECTOR (1 downto 0);
    px_in_addr   : out STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
    px_out_addr  : out STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
    px_out_valid : out STD_LOGIC
  );
end processing_top1;

architecture Behavioral of processing_top1 is
  type fetch_state_t is (FETCH, WAIT_DATA, COMPUTE, WAIT_SINGLE, MEDIAN_SORT, SOBEL_CALC, FRAME_DONE_WAIT);
  signal fetch_state : fetch_state_t := FETCH;
  signal count : integer range 0 to 15 := 0;	-- avoid latches	
  signal done_cnt : integer range 0 to 15 := 0; -- delay done signal, gives more room for the board to process the frame
  signal row : integer range 0 to IMG_HEIGHT-1 := 0;
  signal col : integer range 0 to IMG_WIDTH-1 := 0;
  signal px_result   : std_logic_vector(PIXEL_WIDTH-1 downto 0);
  signal window      : pixel_window;
  signal single_px   : std_logic_vector(PIXEL_WIDTH-1 downto 0);
  signal median_stage : integer range 0 to 6 := 0;
  signal gx_reg, gy_reg : signed(10 downto 0);

begin

  process(clk, rst)
    variable addr : integer;
	 variable median_v : pixel_window;
	 variable gv : unsigned(7 downto 0);
	 variable mag : signed(11 downto 0);
	 variable mag8 : unsigned(7 downto 0);

  begin
    if rst = '1' then
      fetch_state  <= FETCH;
      count        <= 0;
      row          <= 0;
      col          <= 0;
      done         <= '0';
      px_out_valid <= '0';	-- default every cycle, mirrors tx's 'send <= 0' pattern
		median_stage <= 0;

    elsif rising_edge(clk) then
      px_out_valid <= '0'; -- Default pulse pattern

      case fetch_state is
        when FETCH =>
			if en = '1' then
				 if sel = "01" or sel = "10" then
					addr := (row + ROW_COL_LUT(count).r) * IMG_WIDTH + (col + ROW_COL_LUT(count).c);
					px_in_addr  <= std_logic_vector(to_unsigned(addr, px_in_addr'length));
					fetch_state <= WAIT_DATA;
				 else
					-- Single pixel fetch from img_rom (Grayscale or Passthrough)
					addr := row * IMG_WIDTH + col;
					px_in_addr  <= std_logic_vector(to_unsigned(addr, px_in_addr'length));
					fetch_state <= WAIT_SINGLE;
				 end if;
		  end if;

        when WAIT_DATA =>
          -- Convert the 16-bit RGB stream from img_rom into 8-bit Gray on the fly!
          window(count) <= to_gray(px_in);
          
          if count = 8 then
            count       <= 0;
            if sel = "10" then
					median_stage <= 0;
					fetch_state  <= MEDIAN_SORT;
				elsif sel = "01" then
					fetch_state <= SOBEL_CALC;
				 else
					fetch_state <= COMPUTE;
				 end if;
          else
            count       <= count + 1;
            fetch_state <= FETCH;
          end if;

        when WAIT_SINGLE =>
          single_px   <= px_in; -- Retain full 16-bit RGB value
          fetch_state <= COMPUTE;
			 
			when MEDIAN_SORT =>
				  if median_stage = 0 then
					 median_v := window;
				  end if;
				  case median_stage is
					 when 0 => sort2(median_v(1),median_v(2)); sort2(median_v(4),median_v(5)); sort2(median_v(7),median_v(8));
					 when 1 => sort2(median_v(0),median_v(1)); sort2(median_v(3),median_v(4)); sort2(median_v(6),median_v(7));
					 when 2 => sort2(median_v(1),median_v(2)); sort2(median_v(4),median_v(5)); sort2(median_v(7),median_v(8));
					 when 3 => sort2(median_v(0),median_v(3)); sort2(median_v(5),median_v(8)); sort2(median_v(4),median_v(7));
					 when 4 => sort2(median_v(3),median_v(6)); sort2(median_v(1),median_v(4)); sort2(median_v(2),median_v(5));
					 when 5 => sort2(median_v(4),median_v(7)); sort2(median_v(4),median_v(2)); sort2(median_v(6),median_v(4));
					 when 6 => sort2(median_v(4),median_v(2));
					 --when others => null;
				  end case;
				  if median_stage = 6 then
					 fetch_state <= COMPUTE;
				  else
					 median_stage <= median_stage + 1;
				  end if;
				  
			when SOBEL_CALC =>
			  gx_reg <= signed(resize(window(2),11)) - signed(resize(window(0),11))
						 + shift_left(signed(resize(window(5),11)), 1) - shift_left(signed(resize(window(3),11)), 1)
						 + signed(resize(window(8),11)) - signed(resize(window(6),11));
			  gy_reg <= signed(resize(window(6),11)) + shift_left(signed(resize(window(7),11)), 1) + signed(resize(window(8),11))
						 - signed(resize(window(0),11)) - shift_left(signed(resize(window(1),11)), 1) - signed(resize(window(2),11));
			  fetch_state <= COMPUTE;

        when COMPUTE =>
		   case sel is
				when "01" =>
					mag := resize(abs(gx_reg),12) + resize(abs(gy_reg),12);
					  if mag > 255 then
						 mag8 := to_unsigned(255, 8);
					  else
						 mag8 := unsigned(mag(7 downto 0));
					  end if;
					  px_out <= std_logic_vector(mag8(7 downto 3)) & std_logic_vector(mag8(7 downto 2)) & std_logic_vector(mag8(7 downto 3));
				when "10" => px_out <= std_logic_vector(median_v(4)(7 downto 3)) & std_logic_vector(median_v(4)(7 downto 2)) & std_logic_vector(median_v(4)(7 downto 3));
				when "00" => 
					gv := to_gray(single_px);
					px_out <= std_logic_vector(gv(7 downto 3)) & std_logic_vector(gv(7 downto 2)) & std_logic_vector(gv(7 downto 3));
				when others => px_out <= single_px;
          end case;

          px_out_addr  <= std_logic_vector(to_unsigned(row * IMG_WIDTH + col, px_out_addr'length));
          px_out_valid <= '1';

          count <= 0;
          if col = IMG_WIDTH - 1 then
            col <= 0;
            if row = IMG_HEIGHT - 1 then
              row  <= 0;
              done_cnt <= 0;
				  fetch_state <= FRAME_DONE_WAIT;   -- don't assert done yet
            else
              row <= row + 1;
              fetch_state <= FETCH;
            end if;
          else
            col <= col + 1;
            fetch_state <= FETCH;
          end if;
			 
			 when FRAME_DONE_WAIT =>
			  if done_cnt = 15 then
				 done <= '1';
				 fetch_state <= FETCH;
			  else
				 done_cnt <= done_cnt + 1;
			  end if;

      end case;
    end if;
  end process;

end Behavioral;