--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:21:54 08/07/2026
-- Design Name:   
-- Module Name:   /home/fafaaa/image_processing_spartan6/ctrl_fsm_test.vhd
-- Project Name:  image_processing_spartan6
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ctrl_fsm
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
 
ENTITY ctrl_fsm_test IS
END ctrl_fsm_test;
 
ARCHITECTURE behavior OF ctrl_fsm_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ctrl_fsm
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         capture_en : OUT  std_logic;
         capture_done : IN  std_logic;
         process_en : OUT  std_logic;
         processing_done : IN  std_logic;
         tx_en : OUT  std_logic;
         tx_done : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal capture_done : std_logic := '0';
   signal processing_done : std_logic := '0';
   signal tx_done : std_logic := '0';

 	--Outputs
   signal capture_en : std_logic;
   signal process_en : std_logic;
   signal tx_en : std_logic;

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ctrl_fsm PORT MAP (
          clk => clk,
          rst => rst,
          capture_en => capture_en,
          capture_done => capture_done,
          process_en => process_en,
          processing_done => processing_done,
          tx_en => tx_en,
          tx_done => tx_done
        );

	clk <= not clk after 10 ns; -- clk period = 20ns
	 
   -- Stimulus process
   stim_proc: process
	  begin
		 rst <= '1';
		 wait for 40 ns;
		 rst <= '0';

		 -- should now be sitting in CAPTURE, capture_en should be '1'
		 wait for 20 ns;
		 assert capture_en = '1'
			report "FAIL: expected capture_en high after reset" severity error;
		 report "In CAPTURE, capture_en=1 as expected";

		 -- simulate img_src finishing capture
		 capture_done <= '1';
		 wait for 20 ns;
		 capture_done <= '0';  -- done pulses, doesn't stay high forever in real hardware
		 wait for 20 ns;

		 assert process_en = '1'
			report "FAIL: expected process_en high after capture_done" severity error;
		 report "In PROCESS_FRAME, process_en=1 as expected";

		 -- simulate processing_top finishing
		 processing_done <= '1';
		 wait for 20 ns;
		 processing_done <= '0';
		 wait for 20 ns;

		 assert tx_en = '1'
			report "FAIL: expected tx_en high after processing_done" severity error;
		 report "In TRANSMIT, tx_en=1 as expected";

		 -- simulate tx finishing -> should loop back to CAPTURE, not INIT
		 tx_done <= '1';
		 wait for 20 ns;
		 tx_done <= '0';
		 wait for 20 ns;

		 assert capture_en = '1'
			report "FAIL: expected capture_en high again (loop back to CAPTURE)" severity error;
		 report "Looped back to CAPTURE correctly, capture_en=1 again";

		 report "ctrl_fsm testbench complete.";
		 wait;
	  end process;

END;
