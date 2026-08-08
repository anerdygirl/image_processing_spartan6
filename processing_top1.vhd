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


entity processing_top1 is
  generic (
    PIXEL_WIDTH  : integer := 16; --allows rgb565 px to pass through, no processing
    ADDR_WIDTH   : integer := 15 -- 2^addr_width >= width * height . basic arch processeurs stuff
  );
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           en : in  STD_LOGIC; -- "done" signal of the previous state
           done : out  STD_LOGIC;
           px_in : in  STD_LOGIC_VECTOR (PIXEL_WIDTH-1 downto 0);
           px_out : out  STD_LOGIC_VECTOR (PIXEL_WIDTH-1 downto 0);
           sel : in  STD_LOGIC_VECTOR (1 downto 0);
			  src_select: out std_logic;
           px_in_addr : out  STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
           px_out_addr : out  STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0));
end processing_top1;

architecture Behavioral of processing_top1 is
type fetch_state_t is (FETCH, WAIT_DATA, COMPUTE, WAIT_SINGLE);
signal fetch_state : fetch_state_t := FETCH;
signal count, row, col : integer;
signal px_result: std_logic_vector(PIXEL_WIDTH-1 downto 0);
signal window: pixel_window;
signal single_px: STD_LOGIC_VECTOR (PIXEL_WIDTH-1 downto 0); --for passthrough

begin
	process(clk, rst)
  variable addr : integer;
	begin
	  if rst = '1' then
		 fetch_state <= FETCH;
		 count       <= 0;
		 row         <= 0;
		 col         <= 0;
		 done        <= '0';

	  elsif rising_edge(clk) then
		 case fetch_state is

			when FETCH =>
			  if sel = "01" or sel = "10" then
				 -- Sobel or Median: full 3x3 neighborhood from frame_gray
				 addr := (row + ROW_COL_LUT(count).r) * IMG_WIDTH + (col + ROW_COL_LUT(count).c);
				 px_in_addr  <= std_logic_vector(to_unsigned(addr, px_in_addr'length));
				 src_select  <= '1';
				 fetch_state <= WAIT_DATA;

			  elsif sel = "00" then
				 -- Grayscale: only need the center pixel from frame_gray
				 -- grayscale algorithm is moved to CAPTURE state

				 addr := row * IMG_WIDTH + col;
				 px_in_addr  <= std_logic_vector(to_unsigned(addr, px_in_addr'length));
				 src_select  <= '1';
				 fetch_state <= WAIT_SINGLE;

			  else
				 -- Passthrough: center pixel from frame_in (16-bit color)
				 addr := row * IMG_WIDTH + col;
				 px_in_addr  <= std_logic_vector(to_unsigned(addr, px_in_addr'length));
				 src_select  <= '0';
				 fetch_state <= WAIT_SINGLE;
			  end if;

			when WAIT_DATA =>
			  -- px_in is 16 bits, but frame_gray data only occupies the lower byte
			  window(count) <= unsigned(px_in(7 downto 0));
			  if count = 8 then
				 count       <= 0;
				 fetch_state <= COMPUTE;
			  else
				 count       <= count + 1;
				 fetch_state <= FETCH;
			  end if;

			when WAIT_SINGLE =>
			  single_px   <= px_in;   -- full 16 bits; only lower byte meaningful for grayscale
			  fetch_state <= COMPUTE;

			when COMPUTE =>
			  case sel is
				 when "01"   => px_result <= "00000000" & std_logic_vector(sobel(window));
				 when "10"   => px_result <= "00000000" & std_logic_vector(median9(window));
				 when "00"   => px_result <= "00000000" & std_logic_vector(window(4));
				 when others => px_result <= single_px;  -- passthrough, full 16-bit color
			  end case;

			  px_out     <= px_result;
			  px_out_addr <= std_logic_vector(to_unsigned(row * IMG_WIDTH + col, px_out_addr'length));

			  count <= 0;
			  if col = IMG_WIDTH - 1 then
				 col <= 0;
				 if row = IMG_HEIGHT - 1 then
					row  <= 0;
					done <= '1';
				 else
					row <= row + 1;
					fetch_state <= FETCH;
				 end if;
			  else
				 col <= col + 1;
				 fetch_state <= FETCH;
			  end if;

		 end case;
	  end if;
	end process;

end Behavioral;

