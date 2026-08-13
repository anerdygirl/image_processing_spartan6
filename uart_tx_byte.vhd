----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:11:06 08/12/2026 
-- Design Name: 
-- Module Name:    uart_tx_byte - Behavioral 
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

entity uart_tx_byte is
	-- nothing special. extra entity so that top_level testbench compiles
    port (clk, rst, send : in std_logic; din : in std_logic_vector(7 downto 0);
          busy : out std_logic; uart_txd : out std_logic);
end uart_tx_byte;

architecture Behavioral of uart_tx_byte is

begin


end Behavioral;

