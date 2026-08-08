----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:54:28 08/08/2026 
-- Design Name: 
-- Module Name:    src_mux - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity src_mux is
    Port ( frame_in : in  STD_LOGIC_VECTOR (15 downto 0);
           frame_gray : in  STD_LOGIC_VECTOR (7 downto 0);
           src_sel : in  STD_LOGIC;
           frame_process : out  STD_LOGIC_VECTOR (15 downto 0));
end src_mux;

architecture Behavioral of src_mux is
begin
	frame_process <= frame_in when src_sel = '1' else "00000000" & frame_gray;

end Behavioral;

