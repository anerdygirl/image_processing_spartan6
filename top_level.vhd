----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:59:59 08/11/2026 
-- Design Name: 
-- Module Name:    top_level - Behavioral 
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

entity top_level is
  generic (
    IMG_WIDTH  : integer := 160;
    IMG_HEIGHT : integer := 120;
    ADDR_WIDTH : integer := 15
  );
-- wire all components together into a big single piece
	port(
    clk, rst   : in  std_logic;
    sel        : in  std_logic_vector(1 downto 0);   -- from DIP switches
    uart_txd   : out std_logic;                          -- to USB-UART bridge
	 
	 -- for tb purposes only. to be removed later
	 dbg_capture_done    : out std_logic;
    dbg_processing_done : out std_logic;
    dbg_tx_done         : out std_logic;
	 dbg_capture_en       : out std_logic;
	 dbg_process_en        : out std_logic;
	 dbg_tx_en              : out std_logic
	);
end top_level;

architecture Behavioral of top_level is
	-- instanciate all + inner signals specific to each
	component ctrl_fsm
	port(    
	 clk, rst        : in  std_logic;
    capture_en      : out std_logic;
    capture_done    : in  std_logic;
    process_en      : out std_logic;
    processing_done : in  std_logic;
    tx_en           : out std_logic;
    tx_done         : in  std_logic
  );
	end component;
	signal process_en, processing_done : std_logic;
	
	component img_src
	generic (
		IMG_WIDTH, IMG_HEIGHT, ADDR_WIDTH : integer
		);
	port(
		clk : in  STD_LOGIC;
		rst : in  STD_LOGIC;
		en : in  STD_LOGIC;
		done : out  STD_LOGIC;
		rd_addr : in  STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
		frame_in_dout : out  STD_LOGIC_VECTOR (15 downto 0);
		frame_gray_dout : out  STD_LOGIC_vector(7 downto 0));
	end component;
	
	component src_mux
	port(
		frame_in : in  STD_LOGIC_VECTOR (15 downto 0);
		frame_gray : in  STD_LOGIC_VECTOR (7 downto 0);
		src_sel : in  STD_LOGIC;
		frame_process : out  STD_LOGIC_VECTOR (15 downto 0)
	);
	end component;
	signal capture_en, capture_done        : std_logic;   -- en/done, driven by ctrl_fsm
	signal rd_addr         : std_logic_vector(ADDR_WIDTH-1 downto 0);  -- driven by processing_top
	signal frame_in_dout   : std_logic_vector(15 downto 0);  -- feeds into src_mux
	signal frame_gray_dout : std_logic_vector(7 downto 0);   -- feeds into src_mux
	
	component frame_out
	port (clka : in std_logic; 
			wea : in std_logic_vector(0 downto 0);
			addra : in std_logic_vector(14 downto 0); 
			dina : in std_logic_vector(15 downto 0);
			clkb : in std_logic; 
			addrb : in std_logic_vector(14 downto 0);
			doutb : out std_logic_vector(15 downto 0));
	end component;
	signal px_out_valid_sig : std_logic;
	signal px_out_we : std_logic_vector(0 downto 0);
	
	component processing_top1
	generic (
		PIXEL_WIDTH, ADDR_WIDTH: integer
	);
	port(
		clk : in  STD_LOGIC;
		rst : in  STD_LOGIC;
		en : in  STD_LOGIC;
		done : out  STD_LOGIC;
		px_in : in  STD_LOGIC_VECTOR (PIXEL_WIDTH-1 downto 0);
		px_out : out  STD_LOGIC_VECTOR (PIXEL_WIDTH-1 downto 0);
		px_out_valid : out std_logic;
		sel : in  STD_LOGIC_VECTOR (1 downto 0);
		src_select: out std_logic;
		px_in_addr : out  STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
		px_out_addr : out  STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0)
	);
	end component;
	signal mux_out                       : std_logic_vector(15 downto 0);  -- from src_mux
	signal px_out_sig                    : std_logic_vector(15 downto 0);  -- to frame_out
	signal px_out_addr_sig               : std_logic_vector(14 downto 0);  -- to frame_out
	signal src_select_sig                : std_logic;                       -- to src_mux
	
	-- uart_tx_clk is internal to TX. not needed here
	
	component TX
	generic (IMG_WIDTH, IMG_HEIGHT , ADDR_WIDTH, CLK_FREQ, BAUD_RATE : integer);
	port(
		clk, rst, en : in  std_logic;
		 done         : out std_logic;
		 rd_addr      : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		 rd_data      : in  std_logic_vector(15 downto 0);
		 uart_txd     : out std_logic
	);
	end component;
	signal tx_en, tx_done   : std_logic;                               -- driven by ctrl_fsm
	signal tx_rd_addr        : std_logic_vector(14 downto 0);            -- into frame_out's read port
	signal tx_rd_data        : std_logic_vector(15 downto 0);            -- from frame_out's read port
	-- uart_txd is a top_level ENTITY port (uart cable), not an internal signal — goes straight to the physical pin
	
begin
	px_out_we(0) <= px_out_valid_sig;
	dbg_capture_done    <= capture_done;
	dbg_processing_done <= processing_done;
	dbg_tx_done          <= tx_done;
	dbg_capture_en        <= capture_en;
	dbg_process_en          <= process_en;
	dbg_tx_en                <= tx_en;

	img_src_inst : img_src
	  generic map (IMG_WIDTH => 160, IMG_HEIGHT => 120, ADDR_WIDTH => 15)
	  port map (
		 clk => clk,
		 rst => rst,
		 en  => capture_en,
		 done => capture_done,
		 rd_addr => rd_addr,
		 frame_in_dout   => frame_in_dout,
		 frame_gray_dout => frame_gray_dout
	  );
	  
	tx_inst : tx
		generic map (IMG_WIDTH => 160, IMG_HEIGHT => 120, ADDR_WIDTH => 15,
					CLK_FREQ => 100_000_000, BAUD_RATE => 115200)
		port map (
			clk => clk,
			rst => rst,
			en  => tx_en,
			done => tx_done,
			rd_addr => tx_rd_addr,
			rd_data => tx_rd_data,
			uart_txd => uart_txd    -- wired straight to top_level's own external port
	);
	
	src_mux_inst : src_mux
	-- you don't just map to itself blindly
		port map (
			frame_in      => frame_in_dout,     -- from img_src
			frame_gray    => frame_gray_dout,   -- from img_src
			src_sel       => src_select_sig,     -- from processing_top
			frame_process => mux_out             -- into processing_top's px_in
		);
	
	ctrl_fsm_inst: ctrl_fsm
		port map (    
			clk => clk,
			rst => rst,
			capture_en => capture_en,
			capture_done => capture_done,
			process_en => process_en,
			processing_done => processing_done,
			tx_en => tx_en,
			tx_done => tx_done
  );
  
	processing_top_inst : processing_top1
		generic map (PIXEL_WIDTH => 16, ADDR_WIDTH => 15)
		port map (
			clk          => clk,
			rst          => rst,
			en           => process_en,
			done         => processing_done,
			px_in        => mux_out,
			px_out       => px_out_sig,
			px_out_valid => px_out_valid_sig,
			sel          => sel,
			src_select   => src_select_sig,
			px_in_addr   => rd_addr,
			px_out_addr  => px_out_addr_sig
	  );
	
	frame_out_inst : frame_out
		port map (
			clka  => clk,
			wea   => px_out_we,   -- driven by processing_top's new output
			addra => px_out_addr_sig,
			dina  => px_out_sig,
			clkb  => clk,
			addrb => tx_rd_addr,
			doutb => tx_rd_data
	);

end Behavioral;

