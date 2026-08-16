----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:05:21 08/09/2026 
-- Design Name: 
-- Module Name:    TX - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TX is
  generic (IMG_WIDTH : integer := 80; IMG_HEIGHT : integer := 60; ADDR_WIDTH : integer := 13; CLK_FREQ: integer := 100_000_000;
				BAUD_RATE : integer := 115200);
  port (
    clk, rst, en : in  std_logic;
    done         : out std_logic;
    rd_addr      : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    rd_data      : in  std_logic_vector(15 downto 0);
    uart_txd     : out std_logic
  );
end TX;

architecture Behavioral of TX is
  component uart_tx_clk
	generic (CLK_FREQ, BAUD_RATE : integer);
    port (clk, rst, send : in std_logic; din : in std_logic_vector(7 downto 0);
          busy : out std_logic; uart_txd : out std_logic);
  end component;

  signal send, busy   : std_logic := '0';
  signal din       : std_logic_vector(7 downto 0);

  type state_t is (IDLE, 		-- wait for en signal from ctrl_fsm to start transmission
						WAIT_BUSY_HIGH, -- Wait for uart_tx_clk to set busy = '1'
						WAIT_BYTE_DONE, -- Wait for uart_tx_clk to return to busy = '0'
						SEND_WH, 	-- send width top half (for @ calc)
						SEND_WL, 	-- send width bottom half
						SEND_HH, 	-- height top half
						SEND_HL,		-- height bottom half
						WAIT_ROM_PIX,
                  SEND_PIX_HI, -- current px top half, 1st uart frame (px width is 16btis and uart frame is 8bits)
						SEND_PIX_LO, -- current px bottom half
						SEND_END, 	-- ended px transmission
						DONE_ST);	-- send tx_en = '1', return to CAPTURE state
  signal state, next_state   : state_t := IDLE;
  signal pix_cnt  : integer range 0 to IMG_WIDTH*IMG_HEIGHT-1 := 0;

begin

  uart_byte_inst : uart_tx_clk generic map(CLK_FREQ  => CLK_FREQ,
														BAUD_RATE => BAUD_RATE)
										 port map (clk=>clk, 
														rst=>rst, 
														send=>send,
														din=>din, 
														busy=>busy, 
														uart_txd=>uart_txd);

  process(clk, rst)
  begin
    if rst = '1' then
      state <= IDLE; pix_cnt <= 0; send <= '0'; done <= '0';elsif rising_edge(clk) then
  send <= '0'; -- default: only pulse high for one cycle per byte

  case state is
    when IDLE =>
      done <= '0';
      if en = '1' then
        din        <= x"AA";     -- Byte 1: Start Marker
        send       <= '1';       -- Trigger UART
        next_state <= SEND_WH;   -- Next byte will be Width High
        state      <= WAIT_BUSY_HIGH; -- Go through the deadlock-prevention state!
      end if;

	when WAIT_BUSY_HIGH =>
      -- Wait until uart_tx_clk acknowledges send by raising busy
      if busy = '1' then
        state <= WAIT_BYTE_DONE;
      end if;

    when WAIT_BYTE_DONE => 
      -- Wait until uart_tx_clk finishes transmitting
      if busy = '0' then
        state <= next_state;
      end if;

    when SEND_WH =>
      din        <= std_logic_vector(to_unsigned(IMG_WIDTH, 16)(15 downto 8));
      send       <= '1';
      next_state <= SEND_WL;
      state      <= WAIT_BUSY_HIGH;

    when SEND_WL =>
      din        <= std_logic_vector(to_unsigned(IMG_WIDTH, 16)(7 downto 0));
      send       <= '1';
      next_state <= SEND_HH;
      state      <= WAIT_BUSY_HIGH;

    when SEND_HH =>
      din        <= std_logic_vector(to_unsigned(IMG_HEIGHT, 16)(15 downto 8));
      send       <= '1';
      next_state <= SEND_HL;
      state      <= WAIT_BUSY_HIGH;

    when SEND_HL =>
      din        <= std_logic_vector(to_unsigned(IMG_HEIGHT, 16)(7 downto 0));
      send       <= '1';
      next_state <= WAIT_ROM_PIX;
      state      <= WAIT_BUSY_HIGH;

    when WAIT_ROM_PIX =>
		-- request px N from ram
      -- rd_addr    <= std_logic_vector(to_unsigned(0, ADDR_WIDTH)); -- Address pixel 0
		rd_addr <= std_logic_vector(to_unsigned(pix_cnt, ADDR_WIDTH));
      -- 1 cycle latency for BRAM output to settle
      state <= SEND_PIX_HI;

    when SEND_PIX_HI =>
      din        <= rd_data(15 downto 8); -- High byte
		--din <= "01010101"; -- Send 85 (0x55) for testing
      send       <= '1';
      next_state <= SEND_PIX_LO;
      state      <= WAIT_BUSY_HIGH;       

    when SEND_PIX_LO =>
      din  <= rd_data(7 downto 0); -- Low byte
      send <= '1';
      if pix_cnt = (IMG_WIDTH * IMG_HEIGHT - 1) then
        next_state <= SEND_END;
      else
        pix_cnt    <= pix_cnt + 1;
        next_state <= WAIT_ROM_PIX;
      end if;
      state <= WAIT_BUSY_HIGH;

    when SEND_END =>
      din        <= x"55"; -- Frame End Marker
      send       <= '1';
      next_state <= DONE_ST;
      state      <= WAIT_BUSY_HIGH;

    when DONE_ST =>
      done <= '1';
      if en = '0' then
        state   <= IDLE;
        pix_cnt <= 0;
      end if;

  end case;		  
  end if;
  end process;

end Behavioral;