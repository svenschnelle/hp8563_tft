LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use std.textio.all;
ENTITY top_tb IS
END top_tb;

ARCHITECTURE behavior OF top_tb IS
	signal clk50: std_logic := '0';
	signal reset: std_logic := '1';
	signal cpu_data: std_logic_vector(15 downto 0);
	signal cpu_addr: std_logic_vector(12 downto 0) := (others => '0');
	signal cpu_wr_s: std_logic := '1';
component top is
	port (clk: in std_logic;
	-- lcd port
	vsync_o: out std_logic;
	hsync_o: out std_logic;
	r: out std_logic_vector(2 downto 0);
	g: out std_logic_vector(2 downto 0);
	b: out std_logic_vector(2 downto 0);
	-- cpu interface
	cpu_data: in std_logic_vector(15 downto 0);
	cpu_addr: in std_logic_vector(12 downto 0);
	cpu_wel: in std_logic;
	cpu_weh: in std_logic;
	cpu_clk: in std_logic;
	-- sram
	sram_addr: out std_logic_vector(19 downto 0);
	sram_data: inout std_logic_vector(15 downto 0);
	sram_oe: out std_logic;
	sram_we: out std_logic;

	led1: out std_logic;
	debug_txe: in std_logic;
	debug_rxf: in std_logic;
	debug_d: inout std_logic_vector(7 downto 0));
  end component;

component async_1Mx16 is
generic
	(ADDR_BITS			: integer := 20;
	DATA_BITS			 : integer := 16;
	depth 				 : integer := 1048576;
	TimingInfo			: BOOLEAN := TRUE;
	TimingChecks	: std_logic := '1'
	);
port (
    CE_b: IN Std_Logic;	                                                -- Chip Enable CE#
    WE_b: Std_Logic;	                                                -- Write Enable WE#
    OE_b: IN Std_Logic;                                                 -- Output Enable OE#
    BHE_b: IN std_logic;                                                 -- Byte Enable High BHE#
    BLE_b: IN std_logic;                                                 -- Byte Enable Low BLE#
    A: IN Std_Logic_Vector(addr_bits-1 downto 0);                    -- Address Inputs A
    DQ: INOUT Std_Logic_Vector(DATA_BITS-1 downto 0):=(others=>'Z')   -- Read/Write Data IO
    );
end component;

component testrom is
	port(read_clock_i: in std_logic;
	     read_addr_i: in integer range 0 to 8191;
	     read_data_o: out std_logic_vector(15 downto 0));
end component;

signal romaddr_s: integer range 0 to 8191;
signal romdata_s: std_logic_vector(15 downto 0);

signal sram_addr_s: std_logic_vector(19 downto 0);
signal sram_data_s: std_logic_vector(15 downto 0);
signal sram_we_s: std_logic;
signal sram_oe_s: std_logic;
signal write_addr_s: integer;
signal debug_d_s: std_logic_vector(7 downto 0);
signal debug_txe_s: std_logic := '0';
signal debug_rxf_s: std_logic := '1';
type ramfile is file of character;
type state_t is (READ, DELAY, WRITE, WRITE2);

BEGIN
	uut: top port map(
		clk => clk50,
		cpu_clk => clk50,
		cpu_data => cpu_data,
		cpu_addr => cpu_addr,
		cpu_wel => cpu_wr_s,
		cpu_weh => cpu_wr_s,
		sram_addr => sram_addr_s,
		sram_data => sram_data_s,
		sram_oe => sram_oe_s,
		sram_we => sram_we_s,
		debug_txe => debug_txe_s,
		debug_rxf => debug_rxf_s,
		debug_d => debug_d_s);

	rom: testrom port map(
		read_clock_i => clk50,
		read_addr_i => romaddr_s,
		read_data_o => romdata_s);

	sram: async_1Mx16 port map(
		CE_b => '0',
		BHE_b => '0',
		BLE_b => '0',
		OE_b => sram_oe_s,
		WE_b => sram_we_s,
		A => sram_addr_s,
		DQ => sram_data_s);

clocker: process is
begin
	wait for 10 ns;
	clk50 <= not clk50;
end process clocker;

main: process(clk50)
variable i: integer := 0;
variable state: state_t;
variable charbufh: character;
variable charbufl: character;
file datafile: ramfile open read_mode is "sim/sweep_wrong_color.bin";
begin
	if (rising_edge(clk50)) then
		case state is
			when READ =>
				cpu_wr_s <= '1';
				if (i < 4095) then
					cpu_addr <= std_logic_vector(to_unsigned(i, cpu_addr'length));
					Read(datafile, charbufh);
					Read(datafile, charbufl);
					state := DELAY;
				end if;
			when DELAY =>
				state := WRITE;
				cpu_data <= std_logic_vector(to_unsigned(natural(character'pos(charbufh)), 8)) &
					    std_logic_vector(to_unsigned(natural(character'pos(charbufl)), 8));
			when WRITE =>
				cpu_wr_s <= '0';
				state := WRITE2;
				i := i + 1;
			when WRITE2 =>
				state := READ;
		end case;
	end if;

end process;
END;
