----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:25:03 07/16/2026 
-- Design Name: 
-- Module Name:    processing_top - Behavioral 
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

entity processing_top is
  generic (
    PIXEL_WIDTH  : integer := 8;
    ADDR_WIDTH   : integer := 15
  );
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           en : in  STD_LOGIC;
           done : out  STD_LOGIC;
           px_in : in  STD_LOGIC_VECTOR (PIXEL_WIDTH-1 downto 0);
           px_out : out  STD_LOGIC_VECTOR (PIXEL_WIDTH-1 downto 0);
           sel : in  STD_LOGIC_VECTOR (1 downto 0);
           px_in_addr : out  STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
           px_out_addr : in  STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0));
end processing_top;

architecture Behavioral of processing_top is
signal px_none : std_logic_vector(15 downto 0); --default algorithm selection, passthrough
signal px_out : STD_LOGIC_VECTOR (PIXEL_WIDTH-1 downto 0);
signal px_r, px_g, px_b: unsigned (7 downto 0);
signal px_sum           : unsigned(15 downto 0);
signal px_sobel, px_median, px_gray: unsigned (7 downto 0);

begin

process (rst, clk) begin
if (rst = '0') then
-- reset all.. not sure how
done <= '0';
px_out <= (others => '0');
px_out_addr <= (others => '0');
px_in_addr <= (others => '0');

elsif rising_edge(clk) then
-- convert to grayscale
px_r <= px_in(R_MSB DOWNTO R_LSB) & "000"; --normalize to 8bit format
px_g <= px_in(G_MSB DOWNTO G_LSB) & "00";
px_b <= px_in(B_MSB DOWNTO B_LSB) & "000";

px_sum  <= (px_r * to_unsigned(77, 8)) + (px_g * to_unsigned(150, 8)) + (px_b * to_unsigned(29, 8));
px_gray <= px_sum(15 downto 8);


-- select according to sel
case sel is
when "01" => --grayscale
px_gray <= px_sum(15 downto 8);

when "10" => --sobel
px_sobel <= sobel(px_gray);

when "11" => --median

when others => --transfer as is

end case;
end if;
end process;

end Behavioral;

