----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:51:12 08/01/2026 
-- Design Name: 
-- Module Name:    functions_test - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;
use work.pixel_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity functions_test is
end functions_test;

architecture Behavioral of functions_test is

begin

  stim: process
    variable w        : pixel_window;
    variable result   : unsigned(7 downto 0);
  begin

    ---------------------------------------------------------------
    -- Test 1: Sobel on a flat/uniform region -> expect 0 (no edge)
    ---------------------------------------------------------------
    for i in 0 to 8 loop
      w(i) := to_unsigned(100, 8);
    end loop;
    result := sobel(w);
    assert result = to_unsigned(0, 8)
      report "FAIL: Sobel flat region expected 0, got " & integer'image(to_integer(result))
      severity error;
    report "Sobel flat test: got " & integer'image(to_integer(result));

    ---------------------------------------------------------------
    -- Test 2: Sobel on a strong vertical edge -> expect clamped 255
    -- left column = 0, middle = 100, right column = 255, same each row
    ---------------------------------------------------------------
    w(0) := to_unsigned(0,8);   w(1) := to_unsigned(100,8);  w(2) := to_unsigned(255,8);
    w(3) := to_unsigned(0,8);   w(4) := to_unsigned(100,8);  w(5) := to_unsigned(255,8);
    w(6) := to_unsigned(0,8);   w(7) := to_unsigned(100,8);  w(8) := to_unsigned(255,8);
    result := sobel(w);
    assert result = to_unsigned(255, 8)
      report "FAIL: Sobel vertical edge expected 255 (clamped), got " & integer'image(to_integer(result))
      severity error;
    report "Sobel vertical edge test: got " & integer'image(to_integer(result));

    ---------------------------------------------------------------
    -- Test 3: Median of a known, shuffled set -> expect 5
    -- values: 5,3,8,1,9,2,7,4,6  -> sorted: 1,2,3,4,5,6,7,8,9 -> median = 5
    ---------------------------------------------------------------
    w(0):=to_unsigned(5,8); w(1):=to_unsigned(3,8); w(2):=to_unsigned(8,8);
    w(3):=to_unsigned(1,8); w(4):=to_unsigned(9,8); w(5):=to_unsigned(2,8);
    w(6):=to_unsigned(7,8); w(7):=to_unsigned(4,8); w(8):=to_unsigned(6,8);
    result := median9(w);
    assert result = to_unsigned(5, 8)
      report "FAIL: Median expected 5, got " & integer'image(to_integer(result))
      severity error;
    report "Median test: got " & integer'image(to_integer(result));

    ---------------------------------------------------------------
    -- Test 4: Median with an outlier (noise) -> outlier must be rejected
    -- values: 10,10,10,10,255,10,10,10,10 -> median should stay 10, not shift toward 255
    ---------------------------------------------------------------
    for i in 0 to 8 loop
      w(i) := to_unsigned(10, 8);
    end loop;
    w(4) := to_unsigned(255, 8);  -- single noisy pixel in the center
    result := median9(w);
    assert result = to_unsigned(10, 8)
      report "FAIL: Median noise-rejection expected 10, got " & integer'image(to_integer(result))
      severity error;
    report "Median noise-rejection test: got " & integer'image(to_integer(result));

    report "All pixel_pkg tests completed.";
    wait;  -- halt simulation
  end process;

end Behavioral;

