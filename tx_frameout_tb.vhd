--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   21:21:27 08/13/2026
-- Design Name:   
-- Module Name:   /home/fafaaa/image_processing_spartan6/tx_frameout_tb.vhd
-- Project Name:  image_processing_spartan6
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: TX
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tx_frameout_tb IS
END tx_frameout_tb;
 
ARCHITECTURE behavior OF tx_frameout_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT TX
	 generic (IMG_WIDTH, IMG_HEIGHT, ADDR_WIDTH, CLK_FREQ, BAUD_RATE : integer);
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         en : IN  std_logic;
         done : OUT  std_logic;
         rd_addr : OUT  std_logic_vector(14 downto 0);
         rd_data : IN  std_logic_vector(15 downto 0);
         uart_txd : OUT  std_logic
        );
    END COMPONENT;
    
	component frame_out
	port (clka : in std_logic;
		 wea : in std_logic_vector(0 downto 0);
		 addra : in std_logic_vector(14 downto 0);
		 dina : in std_logic_vector(15 downto 0);
		 clkb : in std_logic;
		 addrb : in std_logic_vector(14 downto 0);
		 doutb : out std_logic_vector(15 downto 0));
	end component;

	constant TB_CLK_FREQ   : integer := 100_000_000;
	constant TB_BAUD       : integer := 115200;
	constant TICKS_PER_BIT : integer := TB_CLK_FREQ / TB_BAUD;

	signal clk, rst, en, done, uart_txd : std_logic := '0';
	signal addra                        : std_logic_vector(14 downto 0) := (others => '0');
	signal dina, doutb                  : std_logic_vector(15 downto 0) := (others => '0');
	signal wea                          : std_logic_vector(0 downto 0)  := "0";
	signal rd_addr                      : std_logic_vector(14 downto 0);

	type byte_array_t is array (0 to 40) of std_logic_vector(7 downto 0);
	signal received       : byte_array_t;
	signal received_count : integer := 0;
 
BEGIN 
	  frame_out_inst : frame_out
		 port map (clka => clk, wea => wea, addra => addra, dina => dina,
					  clkb => clk, addrb => rd_addr, doutb => doutb);

	  tx_inst : tx
		 generic map (IMG_WIDTH => 4, IMG_HEIGHT => 4, ADDR_WIDTH => 15,
						  CLK_FREQ => TB_CLK_FREQ, BAUD_RATE => TB_BAUD)
		 port map (clk => clk, rst => rst, en => en, done => done,
					  rd_addr => rd_addr, rd_data => doutb, uart_txd => uart_txd);

	  clk <= not clk after 10 ns;

	  -- same receiver as before, with the corrected 1.5-bit-period constant
	  rx_proc: process
		 variable byte_val : std_logic_vector(7 downto 0);
	  begin
		 wait until falling_edge(uart_txd);
		 wait for (TICKS_PER_BIT * 30) * 1 ns;
		 for i in 0 to 7 loop
			byte_val(i) := uart_txd;
			wait for TICKS_PER_BIT * 20 ns;
		 end loop;
		 received(received_count) <= byte_val;
		 report "RX byte #" & integer'image(received_count) & " = " &
				  integer'image(to_integer(unsigned(byte_val)));
		 received_count <= received_count + 1;
	  end process;

	  stim: process
	  begin
		 rst <= '1';
		 wait for 40 ns;
		 rst <= '0';
		 wait for 40 ns;

		 -- preload 16 known pixel values: 0x00, 0x01, ... 0x0F
		 wea <= "1";
		 for i in 0 to 15 loop
			addra <= std_logic_vector(to_unsigned(i, 15));
			dina  <= std_logic_vector(to_unsigned(i, 16));
			wait for 20 ns;
		 end loop;
		 wea <= "0";
		 wait for 40 ns;

		 en <= '1';
		 wait until done = '1';
		 en <= '0';

		 wait for 200 us;  -- margin for the last byte to finish serializing
		 report "tx isolation test complete. Compare 'received' against the 0x00..0x0F preload above.";
		 wait;
	  end process;
END;
