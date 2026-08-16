----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:24:15 08/09/2026 
-- Design Name: 
-- Module Name:    uart_tx_clk - Behavioral 
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

-- level to pulse converter, 100mhz to 115200 (standard UART baud rate) + transmit uart frame
entity uart_tx_clk is						
	generic (
		 CLK_FREQ  : integer := 100_000_000; -- 100MHz, Spartan 6's internal clk freq
		 BAUD_RATE : integer := 115200 -- uart's baud rate
	  );
	 Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           send : in  STD_LOGIC;			-- send request sent by TX
           din : in  STD_LOGIC_VECTOR (7 downto 0);
           busy : out  STD_LOGIC;		-- status indicator. TX (data to UART) watches it
           uart_txd : out  STD_LOGIC);
end uart_tx_clk;

architecture Behavioral of uart_tx_clk is
  constant TICKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
  signal tick_cnt   : integer range 0 to TICKS_PER_BIT-1 := 0;
  
  type state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
  signal state     : state_t := IDLE;
  signal shift_reg : std_logic_vector(7 downto 0);
  signal bit_idx   : integer range 0 to 7 := 0;
begin

  process(clk, rst)
  begin
    if rst = '1' then
      state    <= IDLE;
      uart_txd <= '1';
      busy     <= '0';
      tick_cnt <= 0;
      bit_idx  <= 0;
    elsif rising_edge(clk) then
      case state is

        when IDLE =>
          uart_txd <= '1';
          busy     <= '0';
          tick_cnt <= 0;
          bit_idx  <= 0;
          if send = '1' then
            shift_reg <= din;
            busy      <= '1';
            state     <= START_BIT;
          end if;

        when START_BIT =>
          busy     <= '1';
          uart_txd <= '0'; -- Hold Start bit LOW for exactly 1 full bit period
          if tick_cnt = TICKS_PER_BIT - 1 then
            tick_cnt <= 0;
            state    <= DATA_BITS;
          else
            tick_cnt <= tick_cnt + 1;
          end if;

        when DATA_BITS =>
          busy     <= '1';
          uart_txd <= shift_reg(bit_idx); -- Hold current data bit for 1 full bit period
          if tick_cnt = TICKS_PER_BIT - 1 then
            tick_cnt <= 0;
            if bit_idx = 7 then
              bit_idx <= 0;
              state   <= STOP_BIT;
            else
              bit_idx <= bit_idx + 1;
            end if;
          else
            tick_cnt <= tick_cnt + 1;
          end if;

        when STOP_BIT =>
          busy     <= '1';
          uart_txd <= '1'; -- Hold Stop bit HIGH for 1 full bit period
          if tick_cnt = TICKS_PER_BIT - 1 then
            tick_cnt <= 0;
            busy     <= '0';
            state    <= IDLE;
          else
            tick_cnt <= tick_cnt + 1;
          end if;

      end case;
    end if;
  end process;

end Behavioral;