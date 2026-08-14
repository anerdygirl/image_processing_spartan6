-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

  ENTITY top_level_test IS
  END top_level_test;

  ARCHITECTURE behavior OF top_level_test IS 

	component top_level
	  generic (IMG_WIDTH, IMG_HEIGHT, ADDR_WIDTH : integer);
	  port (clk, rst : in std_logic; sel : in std_logic_vector(1 downto 0);
			  uart_txd : out std_logic;
			  dbg_capture_done, dbg_processing_done, dbg_tx_done : out std_logic;
			  dbg_capture_en, dbg_process_en, dbg_tx_en : out std_logic);
	end component;

  constant TB_CLK_FREQ  : integer := 100_000_000;
  constant TB_BAUD      : integer := 115200;
  constant TICKS_PER_BIT: integer := TB_CLK_FREQ / TB_BAUD;

  signal clk, rst, uart_txd : std_logic := '0';
  signal sel                 : std_logic_vector(1 downto 0) := "00";  -- grayscale mode

  type byte_array_t is array (0 to 40) of std_logic_vector(7 downto 0);
  signal received      : byte_array_t;
  signal received_count : integer := 0;
  
  -- same. for tb purposes only
  signal dbg_capture_done, dbg_processing_done, dbg_tx_done, dbg_capture_en, dbg_process_en, dbg_tx_en : std_logic;

begin

  uut: top_level
    generic map (IMG_WIDTH => 4, IMG_HEIGHT => 4, ADDR_WIDTH => 15)
	  port map (clk=>clk, rst=>rst, sel=>sel, uart_txd=>uart_txd,
					dbg_capture_done=>dbg_capture_done,
					dbg_processing_done=>dbg_processing_done,
					dbg_tx_done=>dbg_tx_done,
					dbg_capture_en=>dbg_capture_en,
					dbg_process_en=>dbg_process_en,
					dbg_tx_en=>dbg_tx_en);

  clk <= not clk after 10 ns;

  -- UART receiver: waits for a start bit (falling edge), samples 8 data bits
  -- at mid-bit intervals, checks the stop bit, records the byte.
  rx_proc: process
    variable byte_val : std_logic_vector(7 downto 0);
	 constant BIT_PERIOD : time := 1 sec / TB_BAUD; -- 1 bit period = 1000 ms / 115200 / 100MHz ticks = ~8.6805 us (8680.5 ns)
  begin
    wait until falling_edge(uart_txd);              -- start bit detected
    wait for BIT_PERIOD * 1.5;                -- 1.5 bit periods: land mid-bit-0
    for i in 0 to 7 loop
      byte_val(i) := uart_txd;
      wait for BIT_PERIOD;                 -- advance one full bit period
    end loop;
    -- uart_txd should now be high (stop bit) -- not asserted here, just informational
    received(received_count) <= byte_val;
    report "RX byte #" & integer'image(received_count) & " = " &
           integer'image(to_integer(unsigned(byte_val)));
    received_count <= received_count + 1;
	 -- Wait for stop bit to finish before looking for next start bit
	 wait for BIT_PERIOD / 2;
  end process;

  stim: process
  begin
    rst <= '1';
    wait for 40 ns;
    rst <= '0';
	 report "rst deasserted, now = " & std_logic'image(rst);

    wait for 5 ms;  -- generous margin for one 4x4-frame full cycle at 115200 baud

    report "=== Checking header ===";
    assert received(0) = x"AA" report "FAIL: start marker mismatch" severity error;
    assert received(1) = x"00" report "FAIL: width high byte mismatch" severity error;
    assert received(2) = x"04" report "FAIL: width low byte mismatch (expected 4)" severity error;
    assert received(3) = x"00" report "FAIL: height high byte mismatch" severity error;
    assert received(4) = x"04" report "FAIL: height low byte mismatch (expected 4)" severity error;

    report "=== Spot-checking known pixels (grayscale mode) ===";
    -- pixel 0 (black, 0x0000) -> grayscale 0
    assert received(5) = x"00" report "FAIL: pixel 0 high byte" severity error;
    assert received(6) = x"00" report "FAIL: pixel 0 low byte" severity error;

		wait for 100 us;
		report "At 100us: cap_en=" & std_logic'image(dbg_capture_en) &
				 " cap_done=" & std_logic'image(dbg_capture_done) &
				 " proc_en=" & std_logic'image(dbg_process_en) &
				 " proc_done=" & std_logic'image(dbg_processing_done) &
				 " tx_en=" & std_logic'image(dbg_tx_en) &
				 " tx_done=" & std_logic'image(dbg_tx_done);

		wait for 900 us;  -- now at 1ms total
		report "At 1ms: capture_done=" & std_logic'image(dbg_capture_done) &
		" processing_done=" & std_logic'image(dbg_processing_done) &
		" tx_done=" & std_logic'image(dbg_tx_done);
		 
    report " integration test complete.";
    wait;
  end process;

  END;
