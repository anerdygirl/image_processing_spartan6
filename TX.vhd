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
  generic (IMG_WIDTH : integer := 160; IMG_HEIGHT : integer := 120; ADDR_WIDTH : integer := 15; CLK_FREQ: integer := 100_000_000;
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
  component uart_tx_byte
    port (clk, rst, send : in std_logic; din : in std_logic_vector(7 downto 0);
          busy : out std_logic; uart_txd : out std_logic);
  end component;

  signal send, busy   : std_logic := '0';
  signal din       : std_logic_vector(7 downto 0);

  type state_t is (IDLE, 		-- wait for en signal from ctrl_fsm to start transmission
						SEND_START, -- starts transmission
						SEND_WH, 	-- send width top half (for @ calc)
						SEND_WL, 	-- send width bottom half
						SEND_HH, 	-- height top half
						SEND_HL,		-- height bottom half
						WAIT_ROM_PIX,
						SEND_PIX_HI2,
                  SEND_PIX_HI, -- current px top half, 1st uart frame (px width is 16btis and uart frame is 8bits)
						SEND_PIX_LO, -- current px bottom half
						SEND_END, 	-- ended px transmission
						DONE_ST);	-- send tx_en = '1', return to CAPTURE state
  signal state    : state_t := IDLE;
  signal pix_cnt  : integer range 0 to IMG_WIDTH*IMG_HEIGHT-1 := 0;

begin

  uart_byte_inst : uart_tx_byte port map (clk=>clk, 
													rst=>rst, 
													send=>send,
													din=>din, 
													busy=>busy, 
													uart_txd=>uart_txd);

  process(clk, rst)
  begin
    if rst = '1' then
      state <= IDLE; pix_cnt <= 0; send <= '0'; done <= '0';

    elsif rising_edge(clk) then
      send <= '0';  -- default: only pulse high for one cycle per byte
      case state is
        when IDLE =>
          done <= '0';
          if en = '1' then
            din <= x"AA";  -- FRAME_START_MARKER, adjust to your actual value
            send    <= '1';
            state   <= SEND_START;
          end if;

        when SEND_START =>
          if busy = '0' and send = '0' then  -- byte finished
            din <= std_logic_vector(to_unsigned(IMG_WIDTH, 16)(15 downto 8));
            send    <= '1';
            state   <= SEND_WH;
          end if;

        -- SEND_WL, SEND_HH, SEND_HL follow the same pattern, omitted for brevity

			when SEND_WL =>
			if busy = '0' and send = '0' then
				din <= std_logic_vector(to_unsigned(IMG_WIDTH, 16)(7 downto 0));
				send <= '1';
				state <= SEND_HH;
			end if;
			
			when SEND_WH =>
			if busy = '0' and send = '0' then
				 din <= std_logic_vector(to_unsigned(IMG_WIDTH, 16)(7 downto 0));
				 send <= '1';
				 state <= SEND_WL;
			end if;
			
		  when SEND_HH =>
			if busy = '0' and send = '0' then
				din <= std_logic_vector(to_unsigned(IMG_HEIGHT, 16)(15 downto 8));
				send <= '1';
				state <= SEND_HL;
			end if;
			
		  when SEND_HL =>
			  if busy = '0' and send = '0' then
				 din <= std_logic_vector(to_unsigned(IMG_HEIGHT, 16)(7 downto 0));
				 send <= '1';
				 rd_addr <= std_logic_vector(to_unsigned(0, ADDR_WIDTH));  -- request pixel 0
				 state <= WAIT_ROM_PIX;   -- go wait for frame_out to respond
			  end if;

			when WAIT_ROM_PIX =>
			  -- one full cycle passes here, doing nothing, just letting frame_out's
			  -- output catch up to the address we set last cycle
			  state <= SEND_PIX_HI;

			when SEND_PIX_HI =>
			  if busy = '0' and send = '0' then
				 din <= rd_data(15 downto 8);   -- rd_data is now valid
				 send <= '1';
				 state <= SEND_PIX_HI2;         -- separate "confirm sent" step, see below
			  end if;

			when SEND_PIX_HI2 =>
			  if busy = '0' and send = '0' then
				 din <= rd_data(7 downto 0);    -- same pixel, low byte, no new address needed
				 send <= '1';
				 state <= SEND_PIX_LO;
			  end if;

			when SEND_PIX_LO =>
			  if busy = '0' and send = '0' then
				 if pix_cnt = IMG_WIDTH*IMG_HEIGHT - 1 then
					din <= x"55";
					send <= '1';
					state <= SEND_END;
				 else
					pix_cnt  <= pix_cnt + 1;
					rd_addr  <= std_logic_vector(to_unsigned(pix_cnt + 1, ADDR_WIDTH));
					state    <= WAIT_ROM_PIX;   -- back to the BRAM wait before the next pixel's HIGH byte
				 end if;
			  end if;
			  
			when SEND_END =>
				if busy = '0' and send = '0' then
					state <= DONE_ST;
				end if;

			when DONE_ST =>
				done <= '1';
				if en = '0' then
					state <= IDLE;
					pix_cnt <= 0;
				end if;
				
			 end case;
		  end if;
  end process;

end Behavioral;
