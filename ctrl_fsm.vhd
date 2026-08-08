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
    capture_en      : out std_logic;
    capture_done    : in  std_logic;
    process_en      : out std_logic;
    processing_done : in  std_logic;
    tx_en           : out std_logic;
    tx_done         : in  std_logic
  );
end ctrl_fsm;

architecture Behavioral of ctrl_fsm is
  type state_t is (INIT, CAPTURE, PROCESS_FRAME, TRANSMIT);
  signal state : state_t := INIT;
begin
  process(clk, rst)
  begin
    if rst = '1' then
      state <= INIT;
    elsif rising_edge(clk) then
	 -- Moore machine. input doesn't really matter here, only current state.
      case state is
        when INIT          => state <= CAPTURE;
        when CAPTURE        => if capture_done = '1' then state <= PROCESS_FRAME; end if;
        when PROCESS_FRAME  => if processing_done = '1' then state <= TRANSMIT; end if;
        when TRANSMIT        => if tx_done = '1' then state <= CAPTURE; end if;  -- loop for next frame
      end case;
    end if;
  end process;

  capture_en <= '1' when state = CAPTURE else '0';
  process_en <= '1' when state = PROCESS_FRAME else '0';
  tx_en      <= '1' when state = TRANSMIT else '0';

end Behavioral;