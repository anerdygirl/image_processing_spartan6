----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:40:58 07/27/2026 
-- Design Name: 
-- Module Name:    ctrl_fsm - Behavioral 
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

library ieee;
use ieee.std_logic_1164.all;

entity ctrl_fsm is
  port (
    clk, rst        : in  std_logic;
    process_en      : out std_logic;
    processing_done : in  std_logic;
    tx_en           : out std_logic;
    tx_done         : in  std_logic
  );
end ctrl_fsm;

architecture Behavioral of ctrl_fsm is
  type state_t is (INIT, PROCESS_FRAME, WAIT_FLUSH, TRANSMIT);
  signal state : state_t := INIT;
  signal flush_cnt : integer range 0 to 63 := 0;  -- generous margin, cheap to afford
begin
  process(clk, rst)
  begin
    if rst = '1' then
      state <= INIT;
      flush_cnt <= 0;
    elsif rising_edge(clk) then
      case state is
        when INIT =>
          state <= PROCESS_FRAME;

        when PROCESS_FRAME =>
          if processing_done = '1' then
            flush_cnt <= 0;
            state <= WAIT_FLUSH;
          end if;

        when WAIT_FLUSH =>
          if flush_cnt = 63 then
            state <= TRANSMIT;
          else
            flush_cnt <= flush_cnt + 1;
          end if;

        when TRANSMIT =>
          if tx_done = '1' then
            state <= PROCESS_FRAME;
          end if;
      end case;
    end if;
  end process;
  
	-- Outputs stay zero during WAIT_FLUSH
  process_en <= '1' when state = PROCESS_FRAME else '0';
  tx_en      <= '1' when state = TRANSMIT else '0';
end Behavioral;