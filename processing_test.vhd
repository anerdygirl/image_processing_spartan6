--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:02:07 08/02/2026
-- Design Name:   
-- Module Name:   /home/fafaaa/image_processing_spartan6/processing_test.vhd
-- Project Name:  image_processing_spartan6
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: processing_top1
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
 
ENTITY processing_test IS
END processing_test;
 
ARCHITECTURE behavior OF processing_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT processing_top1
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         en : IN  std_logic;
         done : OUT  std_logic;
         px_in : IN  std_logic_vector(15 downto 0);
         px_out : OUT  std_logic_vector(15 downto 0);
         sel : IN  std_logic_vector(1 downto 0);
         src_select : out  std_logic;
         px_in_addr : OUT  std_logic_vector(14 downto 0);
         px_out_addr : OUT  std_logic_vector(14 downto 0)
        );
    END COMPONENT;
	 
	  -- keep the test image tiny so simulation finishes fast: 4x4 instead of 160x120
	  constant TB_IMG_WIDTH  : integer := 4;
	  constant TB_IMG_HEIGHT : integer := 4;
	  constant TB_ADDR_WIDTH : integer := 4;   -- covers 0..15

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal en : std_logic := '0';
   signal px_in : std_logic_vector(15 downto 0) := (others => '0');
   signal sel : std_logic_vector(1 downto 0) := (others => '0');
   signal src_select : std_logic := '0';

 	--Outputs
   signal done : std_logic;
   signal px_out : std_logic_vector(15 downto 0);
   signal px_in_addr : std_logic_vector(14 downto 0);
   signal px_out_addr : std_logic_vector(14 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
	
	  -- fake frame_gray memory: 16 pixels, values 0..15 for easy visual tracing
  type mem_t is array(0 to 15) of unsigned(7 downto 0);
  signal fake_gray : mem_t := (
	 0=>to_unsigned(0,8),1=>to_unsigned(1,8),2=>to_unsigned(2,8),3=>to_unsigned(3,8),
	 4=>to_unsigned(4,8),5=>to_unsigned(5,8),6=>to_unsigned(6,8),7=>to_unsigned(7,8),
	 8=>to_unsigned(8,8),9=>to_unsigned(9,8),10=>to_unsigned(10,8),11=>to_unsigned(11,8),
	 12=>to_unsigned(12,8),13=>to_unsigned(13,8),14=>to_unsigned(14,8),15=>to_unsigned(15,8)
  );
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: processing_top1 PORT MAP (
          clk => clk,
          rst => rst,
          en => en,
          done => done,
          px_in => px_in,
          px_out => px_out,
          sel => sel,
          src_select => src_select,
          px_in_addr => px_in_addr,
          px_out_addr => px_out_addr
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
    rst <= '1';
    wait for 40 ns;
    rst <= '0';

    -- test grayscale mode: should just read center pixel straight through
    sel <= "00";
    en  <= '1';
    wait until done = '1';
    report "Grayscale pass finished";

    wait for 40 ns;
    rst <= '1'; wait for 20 ns; rst <= '0';

    -- test Sobel mode: exercises the full 9-address fetch loop
    sel <= "01";
    en  <= '1';
    wait until done = '1';
    report "Sobel pass finished";

    report "processing_top testbench complete.";
    wait;
   end process;

END;
