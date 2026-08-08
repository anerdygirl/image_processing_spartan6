--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:01:39 08/03/2026
-- Design Name:   
-- Module Name:   /home/fafaaa/image_processing_spartan6/img_src_test.vhd
-- Project Name:  image_processing_spartan6
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: img_src
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
use work.pixel_pkg.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY img_src_test IS
END img_src_test;
 
ARCHITECTURE behavioral OF img_src_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT img_src
	generic (IMG_WIDTH : integer := 160; 
				IMG_HEIGHT : integer := 120; 
				ADDR_WIDTH : integer := 15);
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         en : IN  std_logic;
         done : OUT  std_logic;
         rd_addr : IN  std_logic_vector(ADDR_WIDTH-1 downto 0);
         frame_in_dout : OUT  std_logic_vector(15 downto 0);
         frame_gray_dout : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal en : std_logic := '0';
   signal rd_addr : std_logic_vector(14 downto 0) := (others => '0');

 	--Outputs
   signal done : std_logic;
   signal frame_in_dout : std_logic_vector(15 downto 0);
   signal frame_gray_dout : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant TB_PIXELS : integer := 16;  -- only capture 16 addresses, not the full 19200

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: img_src 
	generic map (IMG_WIDTH => 4, 
					IMG_HEIGHT => 4, 
					ADDR_WIDTH => 15)  -- 4x4 = 16 pixels
	PORT MAP (
          clk => clk,
          rst => rst,
          en => en,
          done => done,
          rd_addr => rd_addr,
          frame_in_dout => frame_in_dout,
          frame_gray_dout => frame_gray_dout
        );

   clk <= not clk after 10 ns;

  stim: process
  begin
    rst <= '1';
    wait for 40 ns;
    rst <= '0';

    en <= '1';
    wait until done = '1';
    report "Capture finished, addr_cnt reached target";

    -- now read back each captured pixel through the exposed read port
    for i in 0 to TB_PIXELS-1 loop
      rd_addr <= std_logic_vector(to_unsigned(i, 15));
      wait for 40 ns;  -- one clock, for the read to land
      report "addr=" & integer'image(i) &
             "  frame_in=" & integer'image(to_integer(unsigned(frame_in_dout))) &
             "  frame_gray=" & integer'image(to_integer(unsigned(frame_gray_dout)));
    end loop;

    report "img_src testbench complete.";
    wait;
  end process;

END;
