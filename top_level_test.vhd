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
			  dbg_processing_done, dbg_tx_done : out std_logic;
			  dbg_process_en, dbg_tx_en : out std_logic);
	end component;

  constant TB_CLK_FREQ  : integer := 100_000_000;
  constant TB_BAUD      : integer := 115200;
  constant TICKS_PER_BIT: integer := TB_CLK_FREQ / TB_BAUD;
  
  constant TB_WIDTH  : integer := 4;
  constant TB_HEIGHT : integer := 4;

  signal clk, rst, uart_txd : std_logic := '0';
  signal sel                 : std_logic_vector(1 downto 0) := "00";  -- grayscale mode

  type byte_array_t is array (0 to 40) of std_logic_vector(7 downto 0);
  signal received      : byte_array_t;
  signal received_count : integer := 0;
  
  -- same. for tb purposes only
  signal dbg_processing_done, dbg_tx_done, dbg_process_en, dbg_tx_en : std_logic;

begin

  uut: top_level
    generic map (IMG_WIDTH  => 4, IMG_HEIGHT => 4, ADDR_WIDTH => 13)
	  port map (clk=>clk, rst=>rst, sel=>sel, uart_txd=>uart_txd,
					dbg_processing_done=>dbg_processing_done,
					dbg_tx_done=>dbg_tx_done,
					dbg_process_en=>dbg_process_en,
					dbg_tx_en=>dbg_tx_en);

  clk <= not clk after 5 ns;

  -- UART receiver: waits for a start bit (falling edge), samples 8 data bits
  -- at mid-bit intervals, checks the stop bit, records the byte.
	rx_proc: process
		 variable byte_val : std_logic_vector(7 downto 0);
		 constant BIT_PERIOD : time := 1 sec / TB_BAUD; -- ~8.68 us at 115200 baud
	  begin
		 -- 1. Wait for falling edge of START bit
		 wait until falling_edge(uart_txd);
		 
		 -- 2. Move to middle of bit 0 (1.5 bit periods)
		 wait for BIT_PERIOD * 1.5;
		 
		 -- 3. Sample 8 data bits at exact center of each bit period
		 for i in 0 to 7 loop
			byte_val(i) := uart_txd;
			wait for BIT_PERIOD;
		 end loop;
		 
		 -- 4. Record received byte
		 received(received_count) <= byte_val;
		 report "RX byte #" & integer'image(received_count) & " = " &
				  integer'image(to_integer(unsigned(byte_val)));
		 received_count <= received_count + 1;
		 
		 -- 5. Wait for stop bit to finish before waiting for next start bit
		 wait for BIT_PERIOD;
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
	 -- Width High & Low Bytes
	 assert received(1) = std_logic_vector(to_unsigned(TB_WIDTH / 256, 8)) 
	 report "FAIL: width high byte mismatch" severity error;
    assert received(2) = std_logic_vector(to_unsigned(TB_WIDTH mod 256, 8)) 
	 report "FAIL: width low byte mismatch" severity error;
    -- Height High & Low Bytes
    assert received(3) = std_logic_vector(to_unsigned(TB_HEIGHT / 256, 8)) 
      report "FAIL: height high byte mismatch" severity error;
    assert received(4) = std_logic_vector(to_unsigned(TB_HEIGHT mod 256, 8)) 
      report "FAIL: height low byte mismatch" severity error;
		
    report "=== Spot-checking known pixels (grayscale mode) ===";
    -- pixel 0 (black, 0x0000) -> grayscale 0
    assert received(5) = x"00" report "FAIL: pixel 0 high byte" severity error;
    assert received(6) = x"00" report "FAIL: pixel 0 low byte" severity error;

		wait for 100 us;
		report "At 100us: proc_en=" & std_logic'image(dbg_process_en) &
				 " proc_done=" & std_logic'image(dbg_processing_done) &
				 " tx_en=" & std_logic'image(dbg_tx_en) &
				 " tx_done=" & std_logic'image(dbg_tx_done);

		wait for 900 us;  -- now at 1ms total
		report "At 1ms: processing_done=" & std_logic'image(dbg_processing_done) &
		" tx_done=" & std_logic'image(dbg_tx_done);
		 
    report " integration test complete.";
    wait;
  end process;

  END;
