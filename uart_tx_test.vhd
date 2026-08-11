--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   21:35:57 08/10/2026
-- Design Name:   
-- Module Name:   /home/fafaaa/image_processing_spartan6/uart_tx_test.vhd
-- Project Name:  image_processing_spartan6
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: uart_tx_clk
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY uart_tx_test IS
END uart_tx_test;
 
ARCHITECTURE behavior OF uart_tx_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT uart_tx_clk
	 	generic (
		 CLK_FREQ  : integer := 100_000_000; -- 100MHz, Spartan 6's internal clk freq
		 BAUD_RATE : integer := 115200
	  );
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         send : IN  std_logic;
         din : IN  std_logic_vector(7 downto 0);
         busy : OUT  std_logic;
         uart_txd : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal send : std_logic := '0';
   signal din : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal busy : std_logic;
   signal uart_txd : std_logic;

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: uart_tx_clk 
		generic map (CLK_FREQ => 200, BAUD_RATE => 100)  -- fake, fast ratio for testing purposes
		PORT MAP (
          clk => clk,
          rst => rst,
          send => send,
          din => din,
          busy => busy,
          uart_txd => uart_txd
        );

    clk <= not clk after 10 ns;

  stim: process
  begin
    rst <= '1';
    wait for 40 ns;
    rst <= '0';
	 wait for 40 ns;

    send <= '1';
	 din <= "01010011";
	 wait until busy = '1'; 
	 send <= '0';
	 wait until busy = '0';
	 report "uart frame transmitted";
	 wait; -- MANDATORY FOR EVERY TESTBENCH OTHERWISE IT'LL GO ON AN INFINITE LOOP FROM THE START

   end process;

END;
