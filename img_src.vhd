----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:55:37 08/02/2026 
-- Design Name: 
-- Module Name:    img_src - Behavioral 
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

entity img_src is
  generic (
    IMG_WIDTH  : integer := 160;
    IMG_HEIGHT : integer := 120;
    ADDR_WIDTH : integer := 15
  );
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           en : in  STD_LOGIC;
           done : out  STD_LOGIC;
           rd_addr : in  STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);   -- shared read address between frame_in and frame_gray, driven by processing_top via top-level wiring
           frame_in_dout : out  STD_LOGIC_VECTOR (15 downto 0);
           frame_gray_dout : out  STD_LOGIC_vector(7 downto 0));
end img_src;

architecture Behavioral of img_src is

  component img_rom  -- ROM instance
    port (clka : in std_logic; addra : in std_logic_vector(ADDR_WIDTH-1 downto 0);
          douta : out std_logic_vector(15 downto 0));
  end component;

  component frame_in-- frame_in instance
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
  end component;

  component frame_gray -- frame_gray instance
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
  end component;

  signal rom_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal rom_data : std_logic_vector(15 downto 0);

  signal fin_we, fgray_we     : std_logic_vector(0 downto 0) := "0";
  signal fin_addr, fgray_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal fin_din              : std_logic_vector(15 downto 0);
  signal fgray_din            : std_logic_vector(7 downto 0);

  type state_t is (IDLE, CAPTURE, WAIT_ROM, DONE_ST);
  signal state    : state_t := IDLE;
  signal addr_cnt : integer range 0 to IMG_WIDTH*IMG_HEIGHT-1 := 0;

  -- grayscale conversion, combinational, operating on whatever rom_data currently holds
  signal px_r, px_g, px_b : unsigned(7 downto 0);
  signal px_sum           : unsigned(15 downto 0);
  signal px_gray          : unsigned(7 downto 0);

begin

  rom_inst       : img_rom       port map (clka=>clk, addra=>rom_addr, douta=>rom_data);
  frame_in_inst  : frame_in 		port map (clka=>clk, wea=>fin_we, addra=>fin_addr, dina=>fin_din,
                                             clkb=>clk, addrb=>rd_addr, doutb=>frame_in_dout);
  frame_gray_inst: frame_gray		port map (clka=>clk, wea=>fgray_we, addra=>fgray_addr, dina=>fgray_din,
                                             clkb=>clk, addrb=>rd_addr, doutb=>frame_gray_dout);

  -- grayscale math (moved here from the old standalone version, using pixel_pkg constants)
  px_r <= unsigned(rom_data(R_MSB downto R_LSB) & "000");
  px_g <= unsigned(rom_data(G_MSB downto G_LSB) & "00");
  px_b <= unsigned(rom_data(B_MSB downto B_LSB) & "000");
  px_sum  <= (px_r * to_unsigned(77,8)) + (px_g * to_unsigned(150,8)) + (px_b * to_unsigned(29,8));
  px_gray <= px_sum(15 downto 8);

	process(clk, rst)
	  begin
		 if rst = '1' then
			state      <= IDLE; 
			addr_cnt   <= 0; 
			fin_we     <= "0"; 
			fgray_we   <= "0"; 
			done       <= '0';
			rom_addr   <= (others => '0');
			fin_addr   <= (others => '0');
			fgray_addr <= (others => '0');

		 elsif rising_edge(clk) then
			case state is
			  when IDLE =>
				 done     <= '0';
				 fin_we   <= "0";
				 fgray_we <= "0";
				 if en = '1' then
					rom_addr <= (others => '0');
					state    <= WAIT_ROM;
				 end if;

			  when WAIT_ROM =>
				 -- 1 clock cycle latency for Block ROM read output
				 state <= CAPTURE;

			  when CAPTURE =>
				 fin_addr   <= std_logic_vector(to_unsigned(addr_cnt, ADDR_WIDTH));
				 fin_din    <= rom_data;
				 fin_we     <= "1";
				 
				 fgray_addr <= std_logic_vector(to_unsigned(addr_cnt, ADDR_WIDTH));
				 fgray_din  <= std_logic_vector(px_gray);
				 fgray_we   <= "1";

				 if addr_cnt = (IMG_WIDTH * IMG_HEIGHT - 1) then
					state <= DONE_ST;
				 else
					addr_cnt <= addr_cnt + 1;
					rom_addr <= std_logic_vector(to_unsigned(addr_cnt + 1, ADDR_WIDTH));
				 end if;

			  when DONE_ST =>
				 -- Immediately disable write enables on entry
				 fin_we   <= "0"; 
				 fgray_we <= "0"; 
				 done     <= '1';
				 
				 if en = '0' then
					state    <= IDLE;
					addr_cnt <= 0;
				 end if;

			end case;
		 end if;
	  end process;

end Behavioral;

